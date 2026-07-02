# AdMobKit — Demo App

The three files in `DemoApp/` are **not compiled as part of the AdMobKit library target**. They're reference code showing how the library wires into a SwiftUI app.

To run the demo:

1. In Xcode: `File > New > Project > iOS > App` (SwiftUI).
2. Add AdMobKit as a local Swift Package: `File > Add Package Dependencies > Add Local` and point to this repo's root.
3. Copy `AdMobKitDemoApp.swift`, `MockSplashScreen.swift`, and `ContentView.swift` into your new project (delete the auto-generated `App.swift` and `ContentView.swift` first).
4. In your new project's target, link `AdMobKit` under `Frameworks, Libraries, and Embedded Content`.
5. Build and run on an iOS 17+ simulator or device.

The demo uses Google's public test ad-unit IDs, so ads will actually render.
