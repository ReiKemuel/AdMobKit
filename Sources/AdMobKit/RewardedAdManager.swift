//
//  RewardedAdManager.swift
//  AdMobKit
//
//  Created by Rei Cordero on 12/1/25.
//

import GoogleMobileAds

@MainActor
public class RewardedAdManager: NSObject, ObservableObject {
    public static let shared = RewardedAdManager()

    var rewardedAd: RewardedAd?

    @Published public var adPhase: RewardedLifecycleEvent = .idle

    public var isReady: Bool { rewardedAd != nil }
    var isPresenting: Bool { adPhase == .presenting }

    public override init() { super.init() }

    public func loadAd(for placement: AdPlacement) async {
        guard !(adPhase == .loading), rewardedAd == nil else { return }
        adPhase = .loading
        do {
            rewardedAd = try await RewardedAd.load(
                with: placement.adUnitID,
                request: Request()
            )
            rewardedAd?.fullScreenContentDelegate = self
            adPhase = .loaded
        } catch {
            adPhase = .failed(error)
            let nsError = error as NSError
            print("[AdMob] \(placement.description) load failed — code: \(nsError.code), domain: \(nsError.domain), message: \(nsError.localizedDescription)")
        }
    }

    public func showAd() {
        guard !(adPhase == .loading) else {
            return print("Ad is loading")
        }
        guard let rewardedAd = rewardedAd, adPhase != .presenting else {
            return print(
                "Can't show ad — ready: \(rewardedAd != nil), presenting: \(adPhase == .presenting)."
            )
        }

        rewardedAd.present(from: nil) {
            let reward = rewardedAd.adReward
            print("Reward amount: \(reward.amount)")
            Task { @MainActor in
                self.adPhase = .reward(amount: reward.amount.intValue)
                MockSubscriptionStore.shared.grantAdUnlock()
            }
        }
    }
}
