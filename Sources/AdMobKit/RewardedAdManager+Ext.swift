//
//  RewardedAdManager+Ext.swift
//  AdMobKit
//
//  Created by Rei Cordero on 12/1/25.
//

import GoogleMobileAds

extension RewardedAdManager: FullScreenContentDelegate {
    public func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        DispatchQueue.main.async {
            self.adPhase = .impression
        }
        print("\(#function) called")
    }

    public func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        DispatchQueue.main.async {
            self.adPhase = .click
        }
        print("\(#function) called")
    }

    public func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        DispatchQueue.main.async {
            self.adPhase = .failed(error)
        }
        print("\(#function) called")
    }

    public func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        DispatchQueue.main.async {
            self.adPhase = .presenting
        }
        print("\(#function) called")
    }

    public func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        DispatchQueue.main.async {
            self.adPhase = .willDismiss
        }
        print("\(#function) called")
    }

    public func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        DispatchQueue.main.async {
            self.adPhase = .didDismiss
        }
        print("\(#function) called")

        // Clear the rewarded ad and pre-load the next one.
        rewardedAd = nil

        Task {
            await loadAd(for: .rewardedAd)
        }
    }
}
