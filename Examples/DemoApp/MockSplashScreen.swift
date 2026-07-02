//
//  MockSplashScreen.swift
//  AdMobKitDemo
//
//  Splash screen that pre-loads the app-open ad and hands off to the
//  main content view after a short delay. In a real app this is where you
//  gate first-render on ad load or SDK init.
//

import AdMobKit
import SwiftUI

struct MockSplashScreen: View {
    @State private var didFinish = false

    var body: some View {
        Group {
            if didFinish {
                ContentView()
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .task {
                    await AppOpenAdManager.shared.loadAd(for: .appOpenAd)
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    AppOpenAdManager.shared.showAdIfAvailable()
                    didFinish = true
                }
            }
        }
    }
}

#Preview {
    MockSplashScreen()
}
