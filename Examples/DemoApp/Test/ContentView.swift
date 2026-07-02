//
//  ContentView.swift
//  AdMobKit + TwoTierPremiumAccess integration demo
//
//  A single-screen debug harness that exercises every public API from both
//  packages and demonstrates how a real app wires them together.
//
//  What this proves:
//    • AdMobKit's banner / rewarded / app-open managers load and present
//      Google test ads end-to-end.
//    • TwoTierPremiumAccess derives `hasPremiumAccess` from the CombineLatest
//      pipeline in real time, including UserDefaults-persisted expiry.
//    • Watching a rewarded ad grants premium access — the packages don't
//      depend on each other, but a 4-line `.onChange` in the view layer
//      bridges the two, which is the exact pattern a production app uses.
//
//  What the debug knobs do:
//    • DebugConfig.appOpenCooldown — shortens AppOpenAdManager's 120-second
//      real-app cooldown so you can rapid-fire test ad-open ads.
//    • DebugConfig.adUnlockDuration — shortens PremiumAccessManager's 1-hour
//      real-app unlock so you can watch the expiry timer fire in-session.
//

import SwiftUI
import AdMobKit
import TwoTierPremiumAccess

// MARK: - Debug configuration

/// Timings tuned for interactive testing.
/// Production apps use the package defaults (120s cooldown, 3600s unlock).
private enum DebugConfig {
    /// AppOpenAdManager cooldown, seconds. Package default: 120.
    static let appOpenCooldown: TimeInterval = 5
    /// PremiumAccessManager ad-unlock duration, seconds. Package default: 3600.
    static let adUnlockDuration: TimeInterval = 15
}

// MARK: - ContentView

struct ContentView: View {

    // TwoTierPremiumAccess: derives hasPremiumAccess from two inputs.
    @StateObject private var access = PremiumAccessManager.shared

    // AdMobKit's stand-in subscription source. In production, swap this
    // for your real subscription manager (StoreKit 2, RevenueCat, backend flag).
    @StateObject private var subs = MockSubscriptionStore.shared

    // AdMobKit ad managers.
    @StateObject private var rewarded = RewardedAdManager.shared
    @StateObject private var appOpen = AppOpenAdManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                bannerSection
                rewardedSection
                appOpenSection
                subscriptionSection
                twoTierSection
            }
            .padding()
        }
        .onAppear { applyDebugConfiguration() }
        .onChange(of: subs.isAdUnlocked) { _, newValue in
            bridgeAdUnlockToPremiumAccess(newValue)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("AdMobKit + TwoTierPremiumAccess")
                .font(.title2).bold()
            Text("Interactive debug harness. Google test-ad IDs — safe to spam.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: - Section 1: Banner

    private var bannerSection: some View {
        GroupBox("Banner ad (loads automatically)") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Placement: \(AdPlacement.homeBanner.description)")
                    .font(.caption).monospaced()
                BannerAdView(.homeBanner)
                    .frame(height: 50)
                caption("Toggle MockSubscriptionStore.isSubscribed below to see the banner suppress — subscribers stop seeing ads instantly via the BannerAdManager cache flush.")
            }
        }
    }

    // MARK: - Section 2: Rewarded

    private var rewardedSection: some View {
        GroupBox("Rewarded ad") {
            VStack(alignment: .leading, spacing: 8) {
                Text("State: \(String(describing: rewarded.adPhase))")
                    .font(.caption).monospaced()

                HStack(spacing: 12) {
                    Button("Load") {
                        Task { await rewarded.loadAd(for: .rewardedAd) }
                    }
                    Button("Show") { rewarded.showAd() }
                        .disabled(!rewarded.isReady)
                }

                caption("Completing the ad calls MockSubscriptionStore.grantAdUnlock() inside AdMobKit. The .onChange bridge on this screen forwards that into PremiumAccessManager (see TwoTier section below flip live).")
            }
        }
    }

    // MARK: - Section 3: App-open

    private var appOpenSection: some View {
        GroupBox("App-open ad") {
            VStack(alignment: .leading, spacing: 8) {
                Text("State: \(String(describing: appOpen.adPhase))")
                    .font(.caption).monospaced()
                Text("Cooldown: \(Int(appOpen.minIntervalBetweenAds))s (debug override — production default is 120s)")
                    .font(.caption).foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button("Load") {
                        Task { await appOpen.loadAd(for: .appOpenAd) }
                    }
                    Button("Show") { appOpen.showAdIfAvailable() }
                }

                caption("showAdIfAvailable() is gated on: not subscribed, ad loaded, cooldown passed, no rewarded ad presenting. Skip reasons print to console.")
            }
        }
    }

    // MARK: - Section 4: MockSubscriptionStore (AdMobKit input)

    private var subscriptionSection: some View {
        GroupBox("MockSubscriptionStore (AdMobKit's subscription stand-in)") {
            VStack(alignment: .leading, spacing: 8) {
                Toggle("isSubscribed", isOn: $subs.isSubscribed)
                Toggle("isAdUnlocked", isOn: $subs.isAdUnlocked)
                caption("Flipping isSubscribed → banner suppresses + app-open suppresses. Flipping isAdUnlocked manually triggers the bridge into PremiumAccessManager (same path the rewarded ad uses).")
            }
        }
    }

    // MARK: - Section 5: TwoTierPremiumAccess

    private var twoTierSection: some View {
        GroupBox("TwoTierPremiumAccess (derived hasPremiumAccess)") {
            VStack(alignment: .leading, spacing: 8) {
                Toggle("isSubscribed", isOn: $access.isSubscribed)

                HStack {
                    Text("hasPremiumAccess:")
                    Text(access.hasPremiumAccess ? "✓ true" : "✗ false")
                        .bold()
                        .foregroundStyle(access.hasPremiumAccess ? .green : .red)
                }

                Button("Grant ad unlock (\(Int(DebugConfig.adUnlockDuration))s debug)") {
                    access.grantAdUnlock()
                }

                caption("hasPremiumAccess = isSubscribed || isAdUnlocked (via CombineLatest). Watch it flip true, wait \(Int(DebugConfig.adUnlockDuration))s, watch it flip back to false unless subscription is on.")

                if access.showExpiryNotice {
                    HStack {
                        Text("⏰ Ad unlock expired")
                            .font(.caption).foregroundStyle(.orange)
                        Spacer()
                        Button("Dismiss") { access.acknowledgeExpiryNotice() }
                            .font(.caption)
                    }
                }
            }
        }
    }

    // MARK: - Behavior

    private func applyDebugConfiguration() {
        appOpen.minIntervalBetweenAds = DebugConfig.appOpenCooldown
        access.unlockDuration = DebugConfig.adUnlockDuration
    }

    /// Bridge from AdMobKit's rewarded-ad grant into TwoTierPremiumAccess.
    ///
    /// The two packages are intentionally independent — AdMobKit ships ads and
    /// tracks its own local "ad unlocked" flag; TwoTierPremiumAccess derives
    /// premium state from a pair of inputs. Real apps wire them together in the
    /// view or app layer, exactly like this.
    private func bridgeAdUnlockToPremiumAccess(_ newValue: Bool) {
        if newValue {
            access.grantAdUnlock()
        }
    }

    // MARK: - Helpers

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
}

#Preview {
    ContentView()
}
