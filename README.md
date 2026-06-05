# WeatherNow

WeatherNow is a small weather product with one backend API, a React website, and a SwiftUI iOS starter app.

The app uses Open-Meteo for forecast and city search data, so no weather API key is required for local development.

## Project Structure

- `server/` - Express API that normalizes Open-Meteo forecast responses.
- `client/` - React + Vite website.
- `ios/WeatherNow/` - SwiftUI iOS source files.

## Run Locally

Install dependencies once:

```bash
cd server
npm install
cd ../client
npm install
```

Start the backend:

```bash
cd server
npm run dev
```

Start the website in a second terminal:

```bash
cd client
npm run dev
```

Open the website at `http://localhost:5173`.

## API

Health check:

```bash
curl http://localhost:5050/api/health
```

Weather by city:

```bash
curl "http://localhost:5050/api/weather?city=Almaty&unit=metric"
```

Weather by coordinates:

```bash
curl "http://localhost:5050/api/weather?lat=43.2389&lon=76.8897&unit=metric"
```

Location search:

```bash
curl "http://localhost:5050/api/geocode?city=Astana"
```

## iOS

See `ios/README.md`. The SwiftUI source is ready to add to an Xcode iOS App target. Keep the backend running while testing the app in Simulator.
