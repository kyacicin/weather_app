# WeatherNow iOS

This folder contains the SwiftUI source for the iOS version of WeatherNow. The app reads the same API as the website:

- Simulator base URL: `http://localhost:5050`
- Physical iPhone base URL: change `WeatherService.baseURL` to `http://YOUR_MAC_IP:5050`

## Create the Xcode App

Open the ready-made project:

```bash
open ios/WeatherNow.xcodeproj
```

Then select an iPhone Simulator and press Run. Start the backend from `server/` before running the iOS app.

The project has been validated with Xcode 26.5 using an iPhone Simulator build.
