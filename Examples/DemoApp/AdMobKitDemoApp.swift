//
//  AdMobKitDemoApp.swift
//  AdMobKitDemo
//
//  Minimal SwiftUI shell showing how AdMobKit wires into an app.
//  NOT compiled as part of the AdMobKit library target — this is a reference
//  file. Copy the DemoApp folder into a fresh SwiftUI iOS app project, add
//  AdMobKit as a local Swift Package, and it should build.
//

import GoogleMobileAds
import SwiftUI

@main
struct AdMobKitDemoApp: App {
    init() {
        MobileAds.shared.start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            MockSplashScreen()
        }
    }
}
