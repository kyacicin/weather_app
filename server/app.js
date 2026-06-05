const express = require('express');
const {
  getForecastByCity,
  getForecastByCoordinates,
  searchLocations,
} = require('./utils/openMeteo');

const app = express();
const port = process.env.PORT || 5050;

app.use(express.json());
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.sendStatus(204);
    return;
  }

  next();
});

app.get('/api/health', (_req, res) => {
  res.json({ ok: true, service: 'weather-api' });
});

app.get('/api/geocode', async (req, res) => {
  try {
    const city = String(req.query.city || req.query.q || '').trim();

    if (city.length < 2) {
      res.status(400).json({ error: 'Search must contain at least 2 characters.' });
      return;
    }

    const locations = await searchLocations(city);
    res.json({ locations });
  } catch (error) {
    res.status(error.status || 502).json({ error: error.message || 'Unable to search locations.' });
  }
});

app.get('/api/weather', async (req, res) => {
  try {
    const unit = req.query.unit === 'imperial' ? 'imperial' : 'metric';
    const city = String(req.query.city || '').trim();
    const latitude = Number.parseFloat(req.query.lat || req.query.latitude);
    const longitude = Number.parseFloat(req.query.lon || req.query.longitude);
    const label = String(req.query.label || 'Current location').trim();

    if (city) {
      const weather = await getForecastByCity(city, unit);
      res.json(weather);
      return;
    }

    if (Number.isFinite(latitude) && Number.isFinite(longitude)) {
      const weather = await getForecastByCoordinates({
        latitude,
        longitude,
        unit,
        location: { name: label },
      });
      res.json(weather);
      return;
    }

    res.status(400).json({ error: 'Provide either city or latitude/longitude.' });
  } catch (error) {
    res.status(error.status || 502).json({ error: error.message || 'Unable to load weather.' });
  }
});

if (require.main === module) {
  app.listen(port, () => {
    console.log(`Weather API is running on port ${port}.`);
  });
}

module.exports = app;
