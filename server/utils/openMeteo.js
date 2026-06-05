const FORECAST_API_URL = 'https://api.open-meteo.com/v1/forecast';
const GEOCODING_API_URL = 'https://geocoding-api.open-meteo.com/v1/search';

const WEATHER_CODES = {
  0: { description: 'Clear sky', dayIcon: '☀️', nightIcon: '🌙' },
  1: { description: 'Mainly clear', dayIcon: '🌤️', nightIcon: '🌙' },
  2: { description: 'Partly cloudy', dayIcon: '⛅', nightIcon: '☁️' },
  3: { description: 'Overcast', dayIcon: '☁️', nightIcon: '☁️' },
  45: { description: 'Fog', dayIcon: '🌫️', nightIcon: '🌫️' },
  48: { description: 'Depositing rime fog', dayIcon: '🌫️', nightIcon: '🌫️' },
  51: { description: 'Light drizzle', dayIcon: '🌦️', nightIcon: '🌧️' },
  53: { description: 'Drizzle', dayIcon: '🌦️', nightIcon: '🌧️' },
  55: { description: 'Dense drizzle', dayIcon: '🌧️', nightIcon: '🌧️' },
  56: { description: 'Freezing drizzle', dayIcon: '🌧️', nightIcon: '🌧️' },
  57: { description: 'Dense freezing drizzle', dayIcon: '🌧️', nightIcon: '🌧️' },
  61: { description: 'Slight rain', dayIcon: '🌦️', nightIcon: '🌧️' },
  63: { description: 'Rain', dayIcon: '🌧️', nightIcon: '🌧️' },
  65: { description: 'Heavy rain', dayIcon: '🌧️', nightIcon: '🌧️' },
  66: { description: 'Freezing rain', dayIcon: '🌧️', nightIcon: '🌧️' },
  67: { description: 'Heavy freezing rain', dayIcon: '🌧️', nightIcon: '🌧️' },
  71: { description: 'Slight snow', dayIcon: '🌨️', nightIcon: '🌨️' },
  73: { description: 'Snow', dayIcon: '🌨️', nightIcon: '🌨️' },
  75: { description: 'Heavy snow', dayIcon: '❄️', nightIcon: '❄️' },
  77: { description: 'Snow grains', dayIcon: '🌨️', nightIcon: '🌨️' },
  80: { description: 'Slight rain showers', dayIcon: '🌦️', nightIcon: '🌧️' },
  81: { description: 'Rain showers', dayIcon: '🌦️', nightIcon: '🌧️' },
  82: { description: 'Violent rain showers', dayIcon: '⛈️', nightIcon: '⛈️' },
  85: { description: 'Slight snow showers', dayIcon: '🌨️', nightIcon: '🌨️' },
  86: { description: 'Heavy snow showers', dayIcon: '❄️', nightIcon: '❄️' },
  95: { description: 'Thunderstorm', dayIcon: '⛈️', nightIcon: '⛈️' },
  96: { description: 'Thunderstorm with hail', dayIcon: '⛈️', nightIcon: '⛈️' },
  99: { description: 'Heavy thunderstorm with hail', dayIcon: '⛈️', nightIcon: '⛈️' },
};

function createHttpError(message, status) {
  const error = new Error(message);
  error.status = status;
  return error;
}

async function fetchJson(url, fallbackMessage) {
  const response = await fetch(url);
  const body = await response.json().catch(() => null);

  if (!response.ok || body?.error) {
    throw createHttpError(body?.reason || fallbackMessage, response.status || 502);
  }

  return body;
}

function getWeatherInfo(code, isDay = true) {
  const fallback = { description: 'Unknown conditions', dayIcon: '🌡️', nightIcon: '🌡️' };
  const weather = WEATHER_CODES[Number(code)] || fallback;

  return {
    description: weather.description,
    icon: isDay ? weather.dayIcon : weather.nightIcon,
  };
}

function normalizeLocation(location = {}) {
  return {
    name: location.name || 'Current location',
    admin1: location.admin1 || location.admin || '',
    country: location.country || '',
    countryCode: location.country_code || location.countryCode || '',
    latitude: Number(location.latitude),
    longitude: Number(location.longitude),
    timezone: location.timezone || '',
  };
}

function normalizeHourly(hourly = {}) {
  const times = hourly.time || [];

  return times.slice(0, 24).map((time, index) => {
    const weather = getWeatherInfo(hourly.weather_code?.[index], hourly.is_day?.[index] !== 0);

    return {
      time,
      temperature: hourly.temperature_2m?.[index],
      apparentTemperature: hourly.apparent_temperature?.[index],
      precipitationProbability: hourly.precipitation_probability?.[index],
      windSpeed: hourly.wind_speed_10m?.[index],
      weatherCode: hourly.weather_code?.[index],
      summary: weather.description,
      icon: weather.icon,
      isDay: hourly.is_day?.[index] !== 0,
    };
  });
}

function normalizeDaily(daily = {}) {
  const times = daily.time || [];

  return times.slice(0, 7).map((date, index) => {
    const weather = getWeatherInfo(daily.weather_code?.[index], true);

    return {
      date,
      temperatureMax: daily.temperature_2m_max?.[index],
      temperatureMin: daily.temperature_2m_min?.[index],
      precipitationProbability: daily.precipitation_probability_max?.[index],
      windSpeedMax: daily.wind_speed_10m_max?.[index],
      sunrise: daily.sunrise?.[index],
      sunset: daily.sunset?.[index],
      weatherCode: daily.weather_code?.[index],
      summary: weather.description,
      icon: weather.icon,
    };
  });
}

function normalizeForecast(data, unit, location) {
  const current = data.current || {};
  const currentWeather = getWeatherInfo(current.weather_code, current.is_day !== 0);
  const temperatureUnit = data.current_units?.temperature_2m || (unit === 'imperial' ? '°F' : '°C');
  const windSpeedUnit = data.current_units?.wind_speed_10m || (unit === 'imperial' ? 'mph' : 'km/h');

  return {
    source: 'Open-Meteo',
    fetchedAt: new Date().toISOString(),
    location: {
      ...normalizeLocation(location),
      latitude: data.latitude,
      longitude: data.longitude,
      timezone: data.timezone || location?.timezone || '',
    },
    units: {
      temperature: temperatureUnit,
      windSpeed: windSpeedUnit,
      precipitation: data.current_units?.precipitation || 'mm',
      precipitationProbability: '%',
    },
    current: {
      time: current.time,
      temperature: current.temperature_2m,
      apparentTemperature: current.apparent_temperature,
      humidity: current.relative_humidity_2m,
      precipitation: current.precipitation,
      cloudCover: current.cloud_cover,
      windSpeed: current.wind_speed_10m,
      windDirection: current.wind_direction_10m,
      windGusts: current.wind_gusts_10m,
      weatherCode: current.weather_code,
      summary: currentWeather.description,
      icon: currentWeather.icon,
      isDay: current.is_day !== 0,
    },
    hourly: normalizeHourly(data.hourly),
    daily: normalizeDaily(data.daily),
  };
}

async function searchLocations(city) {
  const params = new URLSearchParams({
    name: city,
    count: '5',
    language: 'en',
    format: 'json',
  });
  const data = await fetchJson(`${GEOCODING_API_URL}?${params}`, 'Unable to search locations.');

  return (data.results || []).map(normalizeLocation);
}

async function getForecastByCoordinates({
  latitude,
  longitude,
  unit = 'metric',
  location = {},
}) {
  if (!Number.isFinite(Number(latitude)) || !Number.isFinite(Number(longitude))) {
    throw createHttpError('Latitude and longitude must be valid numbers.', 400);
  }

  const unitParams = unit === 'imperial'
    ? { temperature_unit: 'fahrenheit', wind_speed_unit: 'mph', precipitation_unit: 'inch' }
    : { temperature_unit: 'celsius', wind_speed_unit: 'kmh', precipitation_unit: 'mm' };
  const params = new URLSearchParams({
    latitude: String(latitude),
    longitude: String(longitude),
    timezone: 'auto',
    forecast_days: '7',
    forecast_hours: '24',
    current: [
      'temperature_2m',
      'relative_humidity_2m',
      'apparent_temperature',
      'is_day',
      'precipitation',
      'weather_code',
      'cloud_cover',
      'wind_speed_10m',
      'wind_direction_10m',
      'wind_gusts_10m',
    ].join(','),
    hourly: [
      'temperature_2m',
      'apparent_temperature',
      'precipitation_probability',
      'weather_code',
      'wind_speed_10m',
      'is_day',
    ].join(','),
    daily: [
      'weather_code',
      'temperature_2m_max',
      'temperature_2m_min',
      'precipitation_probability_max',
      'wind_speed_10m_max',
      'sunrise',
      'sunset',
    ].join(','),
    ...unitParams,
  });
  const data = await fetchJson(`${FORECAST_API_URL}?${params}`, 'Unable to load forecast.');

  return normalizeForecast(data, unit, {
    ...location,
    latitude,
    longitude,
  });
}

async function getForecastByCity(city, unit = 'metric') {
  const locations = await searchLocations(city);

  if (!locations.length) {
    throw createHttpError(`No location found for "${city}".`, 404);
  }

  const [location] = locations;
  return getForecastByCoordinates({
    latitude: location.latitude,
    longitude: location.longitude,
    unit,
    location,
  });
}

module.exports = {
  getForecastByCity,
  getForecastByCoordinates,
  getWeatherInfo,
  searchLocations,
};
