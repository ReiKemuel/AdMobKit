//
//  AppOpenAdManager+Ext.swift
//  AdMobKit
//
//  Created by Rei Cordero on 11/26/25.
//

import GoogleMobileAds

extension AppOpenAdManager: FullScreenContentDelegate {
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

    public func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        DispatchQueue.main.async {
            self.adPhase = .presenting
            self.lastTimeShown = Date()
        }
        print("App open ad will be presented")
    }

    public func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        appOpenAd = nil
        DispatchQueue.main.async {
            self.adPhase = .didDismiss
        }

        Task {
            await loadAd(for: .appOpenAd)
        }
    }

    public func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        DispatchQueue.main.async {
            self.adPhase = .willDismiss
        }
        print("\(#function) called")
    }

    public func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        appOpenAd = nil

        DispatchQueue.main.async {
            self.adPhase = .failed(error)
        }
    }
}
