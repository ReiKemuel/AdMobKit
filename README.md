# AdMobKit

A small Swift Package with the AdMob integration patterns I shipped in Ambio, a live App Store app. Extracted from that codebase, sanitized, and stripped of app-specific details so you can drop it into your own project.

Covers three ad formats — **banner**, **rewarded**, and **app-open** — with the design decisions I made under real production constraints.

> Extracted from Ambio (live on the App Store since May 2026). All files here are sole-authored work of mine from that codebase. I've swapped the app's real subscription source for a `MockSubscriptionStore` so the package is self-contained; wire your own subscription state into it by conforming to the same interface.

---

## Requirements

- iOS 17+
- Xcode 15+
- Swift 5.9+
- Google Mobile Ads SDK 12.0+ (pulled via SPM — no manual install)

## Install

> **Heads-up before you start:** the Google Mobile Ads SDK will hard-crash your app on the first ad-manager touch if you skip Step 2 below (setting `GADApplicationIdentifier` in your Info.plist). There is no graceful fallback — the SDK calls `abort()` and terminates the process. Every consumer trips on this once. Follow all four steps in order and you're safe.

### 1. Add the package to your Xcode project

In Xcode: **File → Add Package Dependencies…** → paste this repo's URL → **Add Package**.

On the "Choose Package Products" screen that appears next, **make sure your app target's checkbox is ticked** in the "Add to Target" column. If you skip that, Xcode downloads the package but doesn't link it, and you'll get `No such module 'AdMobKit'` at build time. Common gotcha.

Or, if you manage dependencies in `Package.swift`:

```swift
.package(url: "https://github.com/ReiKemuel/AdMobKit.git", from: "1.0.0")
```

### 2. Set `GADApplicationIdentifier` in your Info.plist  ← don't skip this

This is the step that crashes your app if you miss it. AdMob refuses to initialize without a valid app-ID key present in the target's Info.plist.

**Xcode 15+ (no separate Info.plist file — settings are inline on the target):**

1. Click your project in the navigator → select your app target
2. Open the **Info** tab
3. Hover over any row → click the **+** button that appears
4. Enter these three values on the new row:
   - **Key:** `GADApplicationIdentifier`
   - **Type:** `String`
   - **Value:** your AdMob App ID (see below)

**Older Xcode / traditional Info.plist file:**

Add these two lines inside the top-level `<dict>` of your `Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
```

**Which App ID to use:**

- **For local dev / test builds:** use Google's public test ID → `ca-app-pub-3940256099942544~1458002511`. Safe to commit; will never charge real money or trigger policy enforcement.
- **Before you ship to the App Store:** swap in your real AdMob App ID from the [AdMob console](https://apps.admob.com/) → Apps → your app → App settings. Shipping with the test ID means zero real revenue and Google may flag the app.

Note the `~` tilde separator — that's the App ID format. Ad unit IDs (which `AdPlacement.swift` handles for you) use `/` instead. They are different strings and are not interchangeable.

### 3. Initialize the SDK at launch

In your app's `@main` type, call `MobileAds.shared.start()` before any ad managers are touched:

```swift
import SwiftUI
import GoogleMobileAds

@main
struct MyApp: App {
    init() {
        MobileAds.shared.start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 4. Use the managers

`import AdMobKit` where you need banner / rewarded / app-open ads. See [`Examples/`](Examples/) for a working SwiftUI shell exercising all three formats.

---

## Verifying it works

Build and run. If you configured the plist correctly, you'll see logs like:

```
<Google> To get test ads on this device, set:
GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = @[ @"..." ];
```

If instead the app crashes on launch with `The Google Mobile Ads SDK was initialized without an application ID`, you skipped Step 2 or typed the key wrong. Recheck the spelling (`GADApplicationIdentifier` — exact case) and that the value is set on the correct target.

---

## What's in the box

```
Sources/AdMobKit/
├── AdPlacement.swift              // Ad-unit-ID enum (prod + test IDs)
├── AdLifecycleEvent.swift         // Typed lifecycle events + Equatable
├── BannerAdManager.swift          // Per-placement banner cache
├── BannerAdManager+Ext.swift      // BannerViewDelegate
├── BannerAdView.swift             // SwiftUI wrapper
├── RewardedAdManager.swift        // Rewarded load/show
├── RewardedAdManager+Ext.swift    // FullScreenContentDelegate
├── AppOpenAdManager.swift         // App-open + frequency cap
├── AppOpenAdManager+Ext.swift     // FullScreenContentDelegate
└── MockSubscriptionStore.swift    // Stand-in — swap this out
```

---

## The three design decisions worth reading the code for

### 1. Banner ads are cached per-placement — one `BannerView` per screen, reused across navigations

Banner ads on iOS have a real cost: each `BannerView` init triggers a network request and eats bandwidth. If you make a fresh `BannerView` every time a user navigates into a screen, you pay for the load every time — and impressions don't count when a banner is torn down before it renders.

The fix in `BannerAdManager`:

```swift
private var bannerCache: [AdPlacement: BannerView] = [:]

func makeBanner(for placement: AdPlacement) -> BannerView {
    if let cachedBanner = bannerCache[placement] {
        return cachedBanner
    }
    // ...build + cache new banner
}
```

One banner per placement, reused across navigations. When a user subscribes mid-session, the manager subscribes (via Combine) to `isSubscribed` flipping true, then flushes the cache:

```swift
cancellable = MockSubscriptionStore.shared.$isSubscribed
    .filter { $0 }
    .sink { [weak self] _ in self?.clearCache() }
```

`BannerAdView` gates on `!isSubscribed` — subscribers stop seeing banners the instant their state flips.

### 2. App-open ads: 120s cooldown + `isSubscribed` gating, not `hasPremiumAccess` gating

AdMob's policy prohibits "back-to-back" full-screen ads. If a user watches a rewarded ad, showing an app-open ad seconds later can flag your account.

The obvious fix is to suppress app-open ads for the entire ad-unlock window (however long you granted the reward for). I did not do that. In `AppOpenAdManager`:

```swift
private let minIntervalBetweenAds = TimeInterval(120)  // 2 min

func showAdIfAvailable() {
    if MockSubscriptionStore.shared.isSubscribed { return }

    guard
        let ad = appOpenAd,
        isAdAvailable(),
        isAllowedByTimer(),
        !RewardedAdManager.shared.isPresenting
    else { return }

    ad.present(from: nil)
}
```

Gating on `isSubscribed` (not "any form of premium access") + a 120-second in-memory cooldown is enough. The rationale: the AdMob "back-to-back" policy is about the cooldown, not about the entire reward duration. Suppressing app-open ads for the full unlock window is over-suppression — you'd be leaving impressions on the table for ad-unlocked users past the point when it matters.

Subscribers never see app-open ads. Ad-unlocked users see them normally after the 120s cooldown. That's my read of AdMob's policy.

### 3. `AdLifecycleEvent` is an enum, not a String

Ad SDKs deal in delegate callbacks (`adDidRecordImpression`, `adWillPresentFullScreenContent`, and so on). If you log those as strings, you can't diff cleanly, you can't switch on them, and you can't `Equatable`-compare when writing tests.

`AdLifecycleEvent.swift` defines two enums — one for full-screen (app-open) ads, one for rewarded — with a manual `Equatable` implementation because `.failed(Error)` and `.reward(amount: Int)` have associated values that break auto-synthesis:

```swift
public enum RewardedLifecycleEvent: Equatable {
    case loaded
    case failed(Error)
    case impression
    case click
    // ...
    case reward(amount: Int)

    public static func == (lhs: RewardedLifecycleEvent, rhs: RewardedLifecycleEvent) -> Bool {
        // manual equality for .failed and .reward
    }
}
```

Delegate methods push `adPhase = .loaded` / `.impression` / `.reward(amount:)` on the `@Published` property. Consumers subscribe via Combine. When it's time to log to Crashlytics as non-fatal errors (or send to your analytics vendor), you switch on the enum — no stringly-typed matching.

---

## Not in the box (yet)

- **UMP (User Messaging Platform) consent** — required for EU/UK growth. In Ambio's backlog, not in this sample.
- **ATT (App Tracking Transparency) prompt** — required to earn IDFA. Same status.
- **Crashlytics non-fatal wiring** — `AdLifecycleEvent` is enum-shaped to plug into `Crashlytics.crashlytics().record()`, but the actual wiring isn't here.
- **Daily rewarded-ad cap** — subscription-conversion lever I have in the backlog for Ambio.
- **Interstitial ads** — Ambio doesn't use them (they're worse UX in an ambient-sound app), so they're not extracted here.

---

## About

Written by me, [Rei Kemuel Cordero](https://github.com/ReiKemuel), while shipping [Ambio](https://apps.apple.com/us/app/ambio-sleep-focus-sounds/id6749637478). I own the monetization layer of the app; the code here is the shape it takes after one production shipping cycle and some code review.

If something looks wrong — patterns you'd change, edge cases I missed, iOS 18 APIs I should be using — open an issue. I'm still growing into the platform and I take review well.

MIT licensed. Use, fork, ship. No warranty.
