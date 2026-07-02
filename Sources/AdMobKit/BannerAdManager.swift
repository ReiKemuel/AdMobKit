//
//  BannerAdManager.swift
//  AdMobKit
//
//  Created by Rei Cordero on 11/13/25.
//

import Combine
import Foundation
import GoogleMobileAds
import UIKit

@MainActor
final class BannerAdManager: NSObject, ObservableObject {
    static let shared = BannerAdManager()

    private var bannerCache: [AdPlacement: BannerView] = [:]
    private var cancellable: AnyCancellable?

    private override init() {
        super.init()
        cancellable = MockSubscriptionStore.shared.$isSubscribed
            .filter { $0 }
            .sink { [weak self] _ in self?.clearCache() }
    }

    func makeBanner(for placement: AdPlacement) -> BannerView {
        if let cachedBanner = bannerCache[placement] {
            return cachedBanner
        }

        let viewWidth = UIScreen.main.bounds.width
        let adaptiveSize = currentOrientationAnchoredAdaptiveBanner(width: viewWidth)

        let banner = BannerView(adSize: adaptiveSize)
        banner.adUnitID = placement.adUnitID
        banner.placementID = placement.rawValue
        banner.delegate = self
        banner.load(Request())

        bannerCache[placement] = banner
        return banner
    }

    func clearCache() {
        // Call when user subscribes mid-session to stop serving cached banners.
        bannerCache.removeAll()
    }
}
