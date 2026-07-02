//
//  TestApp.swift
//  AdMobKit + TwoTierPremiumAccess integration demo
//
//  Boots the Google Mobile Ads SDK via AdMobKit's convenience wrapper.
//  Nothing else lives here — all the interesting logic is in ContentView.
//

import SwiftUI
import AdMobKit

@main
struct TestApp: App {
    init() {
        // Idempotent. Requires GADApplicationIdentifier in Info.plist
        // (Google's public test ID is set for this project — see README).
        AdMobKit.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
