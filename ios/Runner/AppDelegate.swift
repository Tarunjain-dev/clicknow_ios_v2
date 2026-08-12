import Flutter
import UIKit
import GoogleMaps
import FirebaseCore
import FirebaseAuth

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [
      UIApplication.LaunchOptionsKey: Any
    ]?
  ) -> Bool {

    if let rawApiKey = Bundle.main.object(
      forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY"
    ) as? String {
      let mapsApiKey = rawApiKey.trimmingCharacters(
        in: .whitespacesAndNewlines
      )

      if !mapsApiKey.isEmpty &&
          mapsApiKey != "YOUR_GOOGLE_MAPS_API_KEY" {
        GMSServices.provideAPIKey(mapsApiKey)
      } else {
        print(
          "Google Maps API key is empty or still using the placeholder."
        )
      }
    } else {
      print(
        "GOOGLE_MAPS_API_KEY was not found in Info.plist."
      )
    }

    GeneratedPluginRegistrant.register(with: self)

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  // Forward the Firebase reCAPTCHA / phone-auth callback URL to FirebaseAuth.
  // This prevents the URL from being treated as a normal deep link and ensures
  // the pending verificationId is not lost when the app resumes.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if Auth.auth().canHandle(url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }
}