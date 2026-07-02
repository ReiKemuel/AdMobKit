import GoogleMobileAds

/// Convenience wrapper so consumers only need `import AdMobKit`.
///
/// Under the hood this is `MobileAds.shared.start(...)`. Call once at app launch
/// from your `@main` type's `init()`. See the package README, Step 3.
public enum AdMobKit {
    /// Start the Google Mobile Ads SDK. Idempotent; safe to call multiple times.
    ///
    /// Requires `GADApplicationIdentifier` in your app's Info.plist — the SDK
    /// will crash on first ad-manager touch otherwise. See README Step 2.
    public static func start(completion: (@Sendable (InitializationStatus) -> Void)? = nil) {
        MobileAds.shared.start(completionHandler: completion)
    }
}
