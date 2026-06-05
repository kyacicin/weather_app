# WeatherNow iOS

This folder contains the SwiftUI source for the iOS version of WeatherNow. The app reads the same API as the website:

- Simulator base URL: `http://localhost:5050`
- Physical iPhone base URL: change `WeatherService.baseURL` to `http://YOUR_MAC_IP:5050`

## Create the Xcode App

1. Open Xcode and create a new iOS App project named `WeatherNow`.
2. Use SwiftUI for the interface and Swift for the language.
3. Add the files from `ios/WeatherNow/` to the app target.
4. Merge the keys from `ios/WeatherNow/Info.plist` into the generated app Info settings.
5. Start the backend from `server/` before running the iOS app.

The current machine has Command Line Tools selected instead of full Xcode, so iOS Simulator builds cannot be validated from this terminal yet.
