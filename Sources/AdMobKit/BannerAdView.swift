//
//  BannerAdView.swift
//  AdMobKit
//
//  Created by Rei Cordero on 11/3/25.
//

import GoogleMobileAds
import SwiftUI

private struct BannerAdUIView: UIViewRepresentable {
    let placement: AdPlacement

    func makeUIView(context: Context) -> BannerView {
        BannerAdManager.shared.makeBanner(for: placement)
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}

public struct BannerAdView: View {
    let placement: AdPlacement
    @ObservedObject private var subscriptionStore = MockSubscriptionStore.shared

    public init(_ placement: AdPlacement) {
        self.placement = placement
    }

    public var body: some View {
        // Ad-unlocked users still see banners — only subscribers suppress them.
        if !subscriptionStore.isSubscribed {
            BannerAdUIView(placement: placement)
                .frame(maxWidth: 370, maxHeight: 50)
        }
    }
}
