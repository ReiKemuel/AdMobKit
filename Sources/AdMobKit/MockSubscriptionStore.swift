//
//  MockSubscriptionStore.swift
//  AdMobKit
//
//  Sample stand-in for a real subscription source (StoreKit 2, RevenueCat, etc).
//  Ad managers gate on `isSubscribed` and call `grantAdUnlock()` — swap this
//  out for your own type that exposes the same interface.
//

import Combine
import Foundation

@MainActor
public final class MockSubscriptionStore: ObservableObject {
    public static let shared = MockSubscriptionStore()

    @Published public var isSubscribed: Bool = false
    @Published public var isAdUnlocked: Bool = false

    private init() {}

    // Called by RewardedAdManager after a successful reward callback.
    // In a real app this grants a time-boxed premium unlock; here it just
    // flips a flag so the demo UI can react.
    public func grantAdUnlock() {
        isAdUnlocked = true
    }
}
