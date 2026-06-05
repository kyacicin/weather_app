import { useEffect, useState } from 'react';

import WeatherCard from './components/WeatherCard/WeatherCard.jsx';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '';
const DEFAULT_CITY = 'Almaty';

function buildWeatherUrl(lookup, unit) {
  const params = new URLSearchParams({ unit });

  if (lookup.city) {
    params.set('city', lookup.city);
  } else {
    params.set('lat', String(lookup.latitude));
    params.set('lon', String(lookup.longitude));
    params.set('label', lookup.label || 'Current location');
  }

  return `${API_BASE_URL}/api/weather?${params.toString()}`;
}

function App() {
  const [query, setQuery] = useState(DEFAULT_CITY);
  const [unit, setUnit] = useState('metric');
  const [lastLookup, setLastLookup] = useState({ city: DEFAULT_CITY });
  const [weather, setWeather] = useState(null);
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(true);

  const loadWeather = async (lookup = lastLookup, selectedUnit = unit) => {
    setIsLoading(true);
    setError('');

    try {
      const response = await fetch(buildWeatherUrl(lookup, selectedUnit));
      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Unable to load the forecast.');
      }

      setWeather(data);
      setLastLookup(lookup);
      if (lookup.city) {
        setQuery(lookup.city);
      }
    } catch (err) {
      setError(err.message || 'Unable to load the forecast.');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadWeather({ city: DEFAULT_CITY });
  }, []);

  const handleSearch = (event) => {
    event.preventDefault();
    const city = query.trim();

    if (city.length < 2) {
      setError('Enter at least 2 characters to search a city.');
      return;
    }

    loadWeather({ city });
  };

  const handleUnitChange = (nextUnit) => {
    setUnit(nextUnit);
    loadWeather(lastLookup, nextUnit);
  };

  const handleUseLocation = () => {
    if (!navigator.geolocation) {
      setError('Your browser does not support location access.');
      return;
    }

    setIsLoading(true);
    setError('');
    navigator.geolocation.getCurrentPosition(
      ({ coords }) => {
        loadWeather({
          latitude: coords.latitude,
          longitude: coords.longitude,
          label: 'Current location',
        });
      },
      () => {
        setIsLoading(false);
        setError('Location access was denied. Search by city instead.');
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 300000 },
    );
  };

  return (
    <main className="app-shell">
      <section className="toolbar" aria-label="Weather search">
        <div>
          <p className="eyebrow">WeatherNow</p>
          <h1>Forecast for the places you care about</h1>
        </div>

        <form className="search-form" onSubmit={handleSearch}>
          <label className="search-field">
            <span>City</span>
            <input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Search city"
              type="search"
            />
          </label>
          <button type="submit">Search</button>
          <button className="secondary-button" type="button" onClick={handleUseLocation}>
            Current Location
          </button>
        </form>

        <div className="unit-toggle" aria-label="Temperature unit">
          <button
            className={unit === 'metric' ? 'active' : ''}
            type="button"
            onClick={() => handleUnitChange('metric')}
          >
            C
          </button>
          <button
            className={unit === 'imperial' ? 'active' : ''}
            type="button"
            onClick={() => handleUnitChange('imperial')}
          >
            F
          </button>
        </div>
      </section>

      <WeatherCard
        weather={weather}
        error={error}
        isLoading={isLoading}
        onRetry={() => loadWeather(lastLookup)}
      />
    </main>
  );
}

export default App;
