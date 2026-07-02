//
//  AdLifecycleEvent.swift
//  AdMobKit
//
//  Created by Rei Cordero on 11/26/25.
//

import Foundation

public enum FullScreenLifecycleEvent: Equatable {
    case loaded
    case failed(Error)
    case impression
    case click
    case idle
    case loading
    case presenting
    case willDismiss
    case didDismiss

    public static func == (
        lhs: FullScreenLifecycleEvent,
        rhs: FullScreenLifecycleEvent
    ) -> Bool {
        switch (lhs, rhs) {
        case (.loaded, .loaded),
            (.impression, .impression),
            (.click, .click),
            (.idle, .idle),
            (.loading, .loading),
            (.presenting, .presenting),
            (.willDismiss, .willDismiss),
            (.didDismiss, .didDismiss):
            return true
        case let (.failed(lhsError), .failed(rhsError)):
            return (lhsError as NSError).domain == (rhsError as NSError).domain
                && (lhsError as NSError).code == (rhsError as NSError).code
        default:
            return false
        }
    }
}

public enum RewardedLifecycleEvent: Equatable {
    case loaded
    case failed(Error)
    case impression
    case click
    case idle
    case loading
    case presenting
    case willDismiss
    case didDismiss
    case reward(amount: Int)

    public static func == (
        lhs: RewardedLifecycleEvent,
        rhs: RewardedLifecycleEvent
    ) -> Bool {
        switch (lhs, rhs) {
        case (.loaded, .loaded),
            (.impression, .impression),
            (.click, .click),
            (.idle, .idle),
            (.loading, .loading),
            (.presenting, .presenting),
            (.willDismiss, .willDismiss),
            (.didDismiss, .didDismiss):
            return true
        case let (.failed(lhsError), .failed(rhsError)):
            return (lhsError as NSError).domain == (rhsError as NSError).domain
                && (lhsError as NSError).code == (rhsError as NSError).code
        case let (.reward(lhsAmount), .reward(rhsAmount)):
            return lhsAmount == rhsAmount
        default:
            return false
        }
    }
}
