//
//  AdPlacement.swift
//  AdMobKit
//
//  Created by Rei Cordero on 11/13/25.
//

import Foundation

public enum AdPlacement: Int64 {
    case homeBanner = 0
    case detailBanner = 1
    case settingsBanner = 2
    case appOpenAd = 3
    case rewardedAd = 4

    public var adUnitID: String {
        if Bundle.main.isRelease() {
            // TODO: replace with your own AdMob ad-unit IDs from the AdMob console.
            // Format: "ca-app-pub-<PUBLISHER_ID>/<AD_UNIT_ID>"
            switch self {
            case .homeBanner: return "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
            case .detailBanner: return "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
            case .settingsBanner: return "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
            case .appOpenAd: return "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
            case .rewardedAd: return "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
            }
        } else {
            // Google's public test ad-unit IDs — safe to ship in debug builds.
            switch self {
            case .homeBanner, .detailBanner, .settingsBanner:
                return "ca-app-pub-3940256099942544/2435281174"
            case .appOpenAd:
                return "ca-app-pub-3940256099942544/5575463023"
            case .rewardedAd:
                return "ca-app-pub-3940256099942544/1712485313"
            }
        }
    }

    public var description: String {
        switch self {
        case .homeBanner: return "Home Screen Banner"
        case .detailBanner: return "Detail Screen Banner"
        case .settingsBanner: return "Settings Screen Banner"
        case .appOpenAd: return "App Open Ad"
        case .rewardedAd: return "Rewarded Ad"
        }
    }
}

extension Bundle {
    fileprivate func isRelease() -> Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }
}
