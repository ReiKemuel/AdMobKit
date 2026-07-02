//
//  ContentView.swift
//  AdMobKitDemo
//
//  Demo screen showing the three ad formats side-by-side:
//    - Banner ad in a `safeAreaInset` at the bottom
//    - "Watch Rewarded" button
//    - Subscribed toggle (proves the banner + app-open suppression path)
//

import AdMobKit
import SwiftUI

struct ContentView: View {
    @StateObject private var subscriptionStore = MockSubscriptionStore.shared
    @StateObject private var rewardedAd = RewardedAdManager.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Subscription") {
                    Toggle("Subscribed", isOn: $subscriptionStore.isSubscribed)
                    HStack {
                        Text("Ad-unlock granted")
                        Spacer()
                        Text(subscriptionStore.isAdUnlocked ? "Yes" : "No")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Rewarded Ad") {
                    HStack {
                        Text("Phase")
                        Spacer()
                        Text(phaseDescription)
                            .foregroundStyle(.secondary)
                    }
                    Button("Watch Rewarded Ad") {
                        rewardedAd.showAd()
                    }
                    .disabled(!rewardedAd.isReady)
                    Button("Load Rewarded Ad") {
                        Task { await rewardedAd.loadAd(for: .rewardedAd) }
                    }
                }

                Section("App Open Ad") {
                    Button("Show App Open Ad") {
                        AppOpenAdManager.shared.showAdIfAvailable()
                    }
                    Button("Load App Open Ad") {
                        Task { await AppOpenAdManager.shared.loadAd(for: .appOpenAd) }
                    }
                }
            }
            .navigationTitle("AdMobKit Demo")
            .safeAreaInset(edge: .bottom) {
                BannerAdView(.homeBanner)
                    .padding(.bottom, 8)
            }
            .task {
                await rewardedAd.loadAd(for: .rewardedAd)
            }
        }
    }

    private var phaseDescription: String {
        switch rewardedAd.adPhase {
        case .idle: return "Idle"
        case .loading: return "Loading"
        case .loaded: return "Loaded"
        case .failed: return "Failed"
        case .impression: return "Impression"
        case .click: return "Click"
        case .presenting: return "Presenting"
        case .willDismiss: return "Will dismiss"
        case .didDismiss: return "Did dismiss"
        case .reward(let amount): return "Reward: \(amount)"
        }
    }
}

#Preview {
    ContentView()
}
