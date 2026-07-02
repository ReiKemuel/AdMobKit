//
//  BannerAdManager+Ext.swift
//  AdMobKit
//
//  Created by Rei Cordero on 11/13/25.
//

import GoogleMobileAds

extension BannerAdManager: BannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        if let placement = AdPlacement(rawValue: bannerView.placementID) {
            print("[BannerAdManager] Loaded: \(placement.description) [ID: \(placement.adUnitID)]")
        }
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: any Error) {
        if let placement = AdPlacement(rawValue: bannerView.placementID) {
            let nsError = error as NSError
            print("[AdMob] \(placement.description) load failed — code: \(nsError.code), domain: \(nsError.domain), message: \(nsError.localizedDescription)")
        }
    }
}
