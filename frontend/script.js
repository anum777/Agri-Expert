// Configuration
const API_BASE_URL = 'http://localhost:8000';
const PREDICT_ENDPOINT = `${API_BASE_URL}/predict`;

// DOM Elements
const predictionForm = document.getElementById('predictionForm');
const resultSection = document.getElementById('resultSection');
const errorContainer = document.getElementById('errorContainer');
const loadingSpinner = document.getElementById('loadingSpinner');
const submitBtn = document.getElementById('submitBtn');
const submitBtnLabel = submitBtn.querySelector('span');
const getLocationBtn = document.getElementById('getLocationBtn');
const getLocationBtnLabel = document.getElementById('getLocationBtnLabel');
const locationDisplay = document.getElementById('locationDisplay');
const locationCoordinates = document.getElementById('locationCoordinates');
const locationName = document.getElementById('locationName');
const weatherAutofillStatus = document.getElementById('weatherAutofillStatus');

// Crop icons mapping
const cropIcons = {
  'rice': '🍚',
  'maize': '🌽',
  'wheat': '🌾',
  'barley': '🌾',
  'cotton': '🌫️',
  'sugarcane': '🌾',
  'chickpea': '🫘',
  'lentil': '🫘',
  'soyabean': '🌱',
  'groundnut': '🥜',
  'jute': '🌾',
  'coconut': '🥥',
  'potato': '🥔',
  'tomato': '🍅',
  'chick pea': '🫘',
};

// Event Listeners
predictionForm.addEventListener('submit', handleFormSubmit);
if (getLocationBtn) {
  getLocationBtn.addEventListener('click', handleGetLocationAndWeather);
}

/**
 * Get location from browser and auto-fill weather values.
 */
async function handleGetLocationAndWeather() {
  clearError();

  if (!navigator.geolocation) {
    showError('Geolocation is not supported by this browser.');
    updateLocationDisplay('--', 'Not available', 'Browser geolocation not supported');
    return;
  }

  setLocationLoadingState(true);

  try {
    const position = await getCurrentPosition();
    const lat = position.coords.latitude;
    const lon = position.coords.longitude;

    updateLocationDisplay(`${lat.toFixed(5)}, ${lon.toFixed(5)}`, 'Detecting place...', 'Fetching weather details...');

    const place = await getReadableLocation(lat, lon);
    locationName.textContent = place;

    const weatherResult = await fetchWeatherFromCoordinates(lat, lon);
    if (weatherResult.ok) {
      weatherAutofillStatus.textContent = weatherResult.message;
    } else {
      weatherAutofillStatus.textContent = weatherResult.message;
    }
  } catch (error) {
    handleLocationError(error);
  } finally {
    setLocationLoadingState(false);
  }
}

/**
 * Promise wrapper around browser geolocation API.
 */
function getCurrentPosition() {
  return new Promise((resolve, reject) => {
    navigator.geolocation.getCurrentPosition(resolve, reject, {
      enableHighAccuracy: true,
      timeout: 12000,
      maximumAge: 0,
    });
  });
}

/**
 * Convert coordinates into a readable place name.
 */
async function getReadableLocation(lat, lon) {
  const endpoint = `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=jsonv2`;

  try {
    const response = await fetch(endpoint, {
      headers: {
        'Accept-Language': 'en',
      },
    });

    if (!response.ok) {
      return 'Location name unavailable';
    }

    const data = await response.json();
    const address = data.address || {};
    const city = address.city || address.town || address.village || address.county || address.state_district;
    const state = address.state;
    const country = address.country;

    return [city, state, country].filter(Boolean).join(', ') || 'Location name unavailable';
  } catch (error) {
    return 'Location name unavailable';
  }
}

/**
 * Fetch weather from Open-Meteo and fill weather form fields.
 */
async function fetchWeatherFromCoordinates(lat, lon) {
  const endpoint = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,precipitation&timezone=auto`;

  try {
    const response = await fetch(endpoint);
    if (!response.ok) {
      return { ok: false, message: 'Weather details unavailable (API error).' };
    }

    const data = await response.json();
    const current = data.current;
    if (!current) {
      return { ok: false, message: 'Weather details unavailable.' };
    }

    setInputValue('temperature', current.temperature_2m);
    setInputValue('humidity', current.relative_humidity_2m);
    setInputValue('rainfall', current.precipitation);

    return { ok: true, message: 'Temperature, humidity, and rainfall were auto-filled.' };
  } catch (error) {
    return { ok: false, message: 'Location found, but weather autofill failed.' };
  }
}

/**
 * Update location display card values.
 */
function updateLocationDisplay(coordsText, nameText, weatherText) {
  locationDisplay.classList.remove('hidden');
  locationCoordinates.textContent = coordsText;
  locationName.textContent = nameText;
  weatherAutofillStatus.textContent = weatherText;
}

/**
 * Handle geolocation errors with user-friendly messages.
 */
function handleLocationError(error) {
  let message = 'Unable to fetch location. Please try again.';

  if (error && typeof error.code === 'number') {
    if (error.code === error.PERMISSION_DENIED) {
      message = 'Location access denied. Please allow location permission in your browser settings.';
    } else if (error.code === error.POSITION_UNAVAILABLE) {
      message = 'Location information is unavailable right now.';
    } else if (error.code === error.TIMEOUT) {
      message = 'Location request timed out. Please try again.';
    }
  }

  showError(message);
  updateLocationDisplay('--', 'Location unavailable', 'Weather autofill not available');
}

/**
 * Toggle loading state for location button and display.
 */
function setLocationLoadingState(isLoading) {
  getLocationBtn.disabled = isLoading;
  getLocationBtnLabel.textContent = isLoading
    ? 'Detecting Location...'
    : 'Get Location and Weather Details';

  if (isLoading) {
    updateLocationDisplay('Detecting...', 'Detecting...', 'Fetching weather details...');
  }
}

/**
 * Set numeric input value with a clean decimal representation.
 */
function setInputValue(inputId, value) {
  if (value === null || value === undefined || Number.isNaN(Number(value))) {
    return;
  }

  const input = document.getElementById(inputId);
  if (!input) {
    return;
  }

  const numericValue = Number(value);
  input.value = Number.isInteger(numericValue) ? `${numericValue}` : numericValue.toFixed(1);
}

/**
 * Handle form submission
 */
async function handleFormSubmit(e) {
  e.preventDefault();
  
  // Clear previous errors
  clearError();
  
  // Get form values
  const formData = {
    nitrogen: parseFloat(document.getElementById('nitrogen').value),
    phosphorus: parseFloat(document.getElementById('phosphorus').value),
    potassium: parseFloat(document.getElementById('potassium').value),
    temperature: parseFloat(document.getElementById('temperature').value),
    humidity: parseFloat(document.getElementById('humidity').value),
    rainfall: parseFloat(document.getElementById('rainfall').value),
  };

  // Validate form data
  if (!validateFormData(formData)) {
    return;
  }

  // Show loading state
  showLoading(true);
  submitBtn.disabled = true;

  try {
    const response = await fetch(PREDICT_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(formData),
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.detail || 'Prediction failed. Please try again.');
    }

    const result = await response.json();
    
    // Display result
    displayResult(result, formData);
    
  } catch (error) {
    console.error('Error:', error);
    showError(error.message || 'Failed to get crop recommendation. Make sure the backend server is running.');
  } finally {
    showLoading(false);
    submitBtn.disabled = false;
  }
}

/**
 * Validate form data ranges
 */
function validateFormData(data) {
  const rules = {
    nitrogen: { min: 0, max: 140, name: 'Nitrogen' },
    phosphorus: { min: 0, max: 145, name: 'Phosphorus' },
    potassium: { min: 0, max: 205, name: 'Potassium' },
    temperature: { min: -8, max: 50, name: 'Temperature' },
    humidity: { min: 0, max: 100, name: 'Humidity' },
    rainfall: { min: 0, max: 300, name: 'Rainfall' },
  };

  for (const [key, rule] of Object.entries(rules)) {
    const value = data[key];
    if (value < rule.min || value > rule.max) {
      showError(`${rule.name} must be between ${rule.min} and ${rule.max}`);
      return false;
    }
  }

  return true;
}

/**
 * Display prediction result
 */
function displayResult(result, formData) {
  const cropName = result.recommended_crop.toLowerCase();
  const icon = cropIcons[cropName] || '🌾';
  const confidence = Math.round(result.confidence * 100);

  // Update result card
  document.getElementById('cropName').textContent = result.recommended_crop;
  document.querySelector('.crop-icon').textContent = icon;
  document.getElementById('confidenceText').textContent = `${confidence}%`;
  document.getElementById('confidenceBar').style.width = `${confidence}%`;

  // Update parameter display
  document.getElementById('resultN').textContent = `${formData.nitrogen} mg/kg`;
  document.getElementById('resultP').textContent = `${formData.phosphorus} mg/kg`;
  document.getElementById('resultK').textContent = `${formData.potassium} mg/kg`;
  document.getElementById('resultTemp').textContent = `${formData.temperature}°C`;
  document.getElementById('resultHum').textContent = `${formData.humidity}%`;
  document.getElementById('resultRain').textContent = `${formData.rainfall} mm`;

  // Show result section
  resultSection.classList.remove('hidden');

  // Restart reveal animation for repeated predictions
  const resultCard = document.getElementById('resultCard');
  resultCard.style.animation = 'none';
  // Force reflow so animation can restart
  void resultCard.offsetWidth;
  resultCard.style.animation = 'riseIn 0.45s ease';
  
  // Scroll to result
  resultSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

/**
 * Show error message
 */
function showError(message) {
  const errorDiv = document.createElement('div');
  errorDiv.className = 'alert alert-error';
  errorDiv.innerHTML = `
    <strong>Error:</strong> ${message}
    <button type="button" class="close-btn" onclick="this.parentElement.remove()">×</button>
  `;
  errorContainer.innerHTML = '';
  errorContainer.appendChild(errorDiv);
  errorContainer.scrollIntoView({ behavior: 'smooth' });
}

/**
 * Clear error messages
 */
function clearError() {
  errorContainer.innerHTML = '';
}

/**
 * Show/hide loading spinner
 */
function showLoading(show) {
  if (show) {
    loadingSpinner.classList.remove('hidden');
    submitBtnLabel.textContent = 'Analyzing Field Conditions...';
  } else {
    loadingSpinner.classList.add('hidden');
    submitBtnLabel.textContent = 'Get Crop Recommendation';
  }
}

/**
 * Reset form and hide result
 */
function resetForm() {
  predictionForm.reset();
  resultSection.classList.add('hidden');
  locationDisplay.classList.add('hidden');
  clearError();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// Log initialization
console.log('Agri Expert frontend loaded successfully');
console.log(`API connected to: ${API_BASE_URL}`);
