# AdMobKit — Demo App

`DemoApp/` is a **runnable Xcode project** showing AdMobKit in use — banner, rewarded, and app-open ads all rendering live via Google's public test ad-unit IDs. It also demonstrates the intended integration with [TwoTierPremiumAccess](https://github.com/ReiKemuel/TwoTierPremiumAccess) — the two packages are architecturally independent, and this demo shows exactly how a real app wires them together.

## Requirements

- iOS 17+ simulator or device
- Xcode 15+ (project generated with Xcode 26.3)

## Run

```bash
cd Examples/DemoApp
open Test.xcodeproj
```

Then in Xcode: pick an iPhone 17+ simulator → Cmd+R. First launch resolves the two Swift package dependencies (`AdMobKit` from this repo, `TwoTierPremiumAccess` from its repo) which takes 10-20 seconds.

## What you'll see

A single-screen debug harness with five sections:

1. **Banner ad** — loads automatically, disappears when `MockSubscriptionStore.isSubscribed` flips on
2. **Rewarded ad** — Load + Show buttons; completing the ad grants an unlock
3. **App-open ad** — Load + Show buttons; cooldown shrunk to 5 seconds for testing
4. **MockSubscriptionStore** — AdMobKit's stand-in subscription source (toggleable)
5. **TwoTierPremiumAccess** — the derived `hasPremiumAccess` flag, driven by the CombineLatest pipeline

## What the demo proves

- **Both packages consume cleanly via SPM** independently of each other
- **The `.onChange` bridge** in `ContentView.swift` connects AdMobKit's rewarded-ad grant into TwoTierPremiumAccess — 4 lines in the view layer, no cross-package dependency
- **`DebugConfig` tunables** at the top of `ContentView.swift` show how to shorten the app-open cooldown (public `minIntervalBetweenAds`) and the ad-unlock duration (public `unlockDuration`) during development

## Ad IDs

`Info.plist` uses Google's public test app ID: `ca-app-pub-3940256099942544~1458002511`. `AdPlacement.swift` in AdMobKit uses public test ad-unit IDs when built in `DEBUG`. Neither will charge real money or trigger policy enforcement — safe to clone and run.

For your own app, swap in your real AdMob App ID and ad-unit IDs before shipping. See the main [README](../README.md) for the plist setup steps.
