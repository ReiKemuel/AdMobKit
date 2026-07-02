//
//  AppOpenAdManager.swift
//  AdMobKit
//
//  Created by Rei Cordero on 11/26/25.
//

import GoogleMobileAds
import SwiftUI

@MainActor
public final class AppOpenAdManager: NSObject, ObservableObject {
    public static let shared = AppOpenAdManager()

    var appOpenAd: AppOpenAd?
    var lastTimeShown: Date?
    private var loadTime: Date?

    /// Minimum seconds between successive app-open ad presentations.
    /// Default: 120s. Set lower (e.g. 5s) during development to test rapid ad flow;
    /// keep near AdMob's back-to-back policy floor in production.
    public var minIntervalBetweenAds: TimeInterval = 120

    /// How long a loaded ad is considered fresh before it's re-fetched.
    /// Default: 4 hours — Google's own app-open ad validity window. Do not raise
    /// above this in production; the ad-server will reject the show call.
    public var expirationInSeconds: TimeInterval = 3600 * 4

    @Published public var adPhase: FullScreenLifecycleEvent = .idle

    private override init() {}

    public func loadAd(for placement: AdPlacement) async {
        if adPhase == .loading || isAdAvailable() {
            return
        }

        await MainActor.run {
            adPhase = .loading
        }

        do {
            appOpenAd = try await AppOpenAd.load(
                with: placement.adUnitID,
                request: Request()
            )
            appOpenAd?.fullScreenContentDelegate = self
            loadTime = Date()
            await MainActor.run {
                adPhase = .loaded
            }
        } catch {
            await MainActor.run {
                adPhase = .failed(error)
            }
            let nsError = error as NSError
            print("[AdMob] \(placement.description) load failed — code: \(nsError.code), domain: \(nsError.domain), message: \(nsError.localizedDescription)")
        }
    }

    public func showAdIfAvailable() {
        // Subscribers never see app-open ads. Ad-unlocked users still do —
        // the 120s cooldown below already handles the AdMob "back-to-back"
        // policy after a rewarded ad, so we don't need to suppress across
        // the entire ad-unlock window.
        if MockSubscriptionStore.shared.isSubscribed {
            return
        }

        guard
            let ad = appOpenAd,
            isAdAvailable(),
            isAllowedByTimer(),
            !RewardedAdManager.shared.isPresenting
        else {
            return
        }

        ad.present(from: nil)
    }

    private func isAllowedByTimer() -> Bool {
        guard let last = lastTimeShown else { return true }
        return Date().timeIntervalSince(last) > minIntervalBetweenAds
    }

    private func isAdAvailable() -> Bool {
        guard appOpenAd != nil else { return false }
        return isAdFresh()
    }

    private func isAdFresh() -> Bool {
        guard let loadTime = loadTime else { return false }
        return Date().timeIntervalSince(loadTime) < expirationInSeconds
    }
}
