import React from 'react';

import PropTypes from 'prop-types';

import './WeatherCard.css';

function formatTemperature(value, unit) {
  if (value === null || value === undefined) {
    return '--';
  }

  return `${Math.round(value)}${unit}`;
}

function formatTime(value) {
  if (!value) {
    return '--';
  }

  const [, time = value] = value.split('T');
  return time.slice(0, 5);
}

function formatDay(value) {
  if (!value) {
    return '--';
  }

  return new Intl.DateTimeFormat(undefined, { weekday: 'short', month: 'short', day: 'numeric' })
    .format(new Date(`${value}T12:00:00`));
}

function WeatherCard({
  weather = null,
  isLoading,
  error = '',
  onRetry,
}) {
  if (isLoading) {
    return (
      <section className="weather-panel status-panel" aria-live="polite">
        <div className="spinner" />
        <p>Loading forecast</p>
      </section>
    );
  }

  if (error) {
    return (
      <section className="weather-panel status-panel" aria-live="polite">
        <p>{error}</p>
        <button type="button" onClick={onRetry}>Try Again</button>
      </section>
    );
  }

  if (!weather) {
    return null;
  }

  const {
    current,
    daily,
    hourly,
    location,
    source,
    units,
  } = weather;
  const place = [location.name, location.admin1, location.country].filter(Boolean).join(', ');

  return (
    <section className="weather-panel" aria-label="Weather forecast">
      <div className="current-panel">
        <div>
          <p className="location-label">{place}</p>
          <h2>{current.summary}</h2>
          <p className="updated-label">
            {source}
            {' '}
            forecast
            {location.timezone ? ` · ${location.timezone}` : ''}
          </p>
        </div>
        <div className="current-visual" aria-hidden="true">
          <span>{current.icon}</span>
          <strong>{formatTemperature(current.temperature, units.temperature)}</strong>
        </div>
      </div>

      <div className="metric-grid">
        <div>
          <span>Feels Like</span>
          <strong>{formatTemperature(current.apparentTemperature, units.temperature)}</strong>
        </div>
        <div>
          <span>Humidity</span>
          <strong>{current.humidity ?? '--'}%</strong>
        </div>
        <div>
          <span>Wind</span>
          <strong>{Math.round(current.windSpeed ?? 0)} {units.windSpeed}</strong>
        </div>
        <div>
          <span>Precipitation</span>
          <strong>{current.precipitation ?? 0} {units.precipitation}</strong>
        </div>
      </div>

      <div className="forecast-section">
        <div className="section-heading">
          <h3>Next 24 Hours</h3>
        </div>
        <div className="hourly-strip">
          {hourly.map((hour) => (
            <article className="hour-card" key={hour.time}>
              <span>{formatTime(hour.time)}</span>
              <strong aria-hidden="true">{hour.icon}</strong>
              <b>{formatTemperature(hour.temperature, units.temperature)}</b>
              <small>{hour.precipitationProbability ?? 0}% rain</small>
            </article>
          ))}
        </div>
      </div>

      <div className="forecast-section">
        <div className="section-heading">
          <h3>7 Day Forecast</h3>
        </div>
        <div className="daily-list">
          {daily.map((day) => (
            <article className="day-row" key={day.date}>
              <div>
                <strong>{formatDay(day.date)}</strong>
                <span>{day.summary}</span>
              </div>
              <span className="day-icon" aria-hidden="true">{day.icon}</span>
              <div className="day-temps">
                <strong>{formatTemperature(day.temperatureMax, units.temperature)}</strong>
                <span>{formatTemperature(day.temperatureMin, units.temperature)}</span>
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

WeatherCard.propTypes = {
  error: PropTypes.string,
  isLoading: PropTypes.bool.isRequired,
  onRetry: PropTypes.func.isRequired,
  weather: PropTypes.shape({
    current: PropTypes.shape({
      apparentTemperature: PropTypes.number,
      humidity: PropTypes.number,
      icon: PropTypes.string.isRequired,
      precipitation: PropTypes.number,
      summary: PropTypes.string.isRequired,
      temperature: PropTypes.number,
      windSpeed: PropTypes.number,
    }).isRequired,
    daily: PropTypes.arrayOf(PropTypes.shape({})).isRequired,
    hourly: PropTypes.arrayOf(PropTypes.shape({})).isRequired,
    location: PropTypes.shape({
      admin1: PropTypes.string,
      country: PropTypes.string,
      name: PropTypes.string.isRequired,
      timezone: PropTypes.string,
    }).isRequired,
    source: PropTypes.string.isRequired,
    units: PropTypes.shape({
      precipitation: PropTypes.string.isRequired,
      temperature: PropTypes.string.isRequired,
      windSpeed: PropTypes.string.isRequired,
    }).isRequired,
  }),
};

export default WeatherCard;
