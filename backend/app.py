"""
Agri Expert API v2.0 - Production Ready
========================================
Improved ML Pipeline with Proper Validation and Explainability
Features:
- Single RandomForest model (no ensemble complexity)
- Feature scaling for stable predictions
- Feature importance-based reasoning
- Comprehensive error handling
- Production-grade code
- SECURE API KEY MANAGEMENT using environment variables
"""

# ============================================================================
# SECURITY: Load environment variables from .env file
# ============================================================================
# Never hardcode sensitive information like API keys in your source code!
# 
# Instead, use environment variables with python-dotenv:
# 1. Sensitive data is stored in .env file (not in version control)
# 2. .env is added to .gitignore so it's never pushed to GitHub
# 3. load_dotenv() loads variables from .env into os.environ
# 4. os.getenv() retrieves values safely at runtime
#
# This approach ensures API keys and secrets are not exposed in code.
from dotenv import load_dotenv
import os

# Load environment variables from .env file
# This reads the .env file and populates os.environ with all variables
load_dotenv()

# Retrieve sensitive configuration from environment variables
# If a variable is not found, use the default value (None or empty string)
# NEVER fallback to a hardcoded key!
API_KEY = os.getenv('OPENWEATHER_API_KEY')
ENVIRONMENT = os.getenv('ENVIRONMENT', 'development')
DEBUG = os.getenv('DEBUG', 'False').lower() == 'true'
LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
GEMINI_API_KEY = os.getenv('GEMINI_API_KEY')
GEMINI_MODEL = os.getenv('GEMINI_MODEL', 'gemini-3.8-flash')
MARKET_PRICE_API_URL = os.getenv('MARKET_PRICE_API_URL', '').strip()
MARKET_PRICE_API_KEY = os.getenv('MARKET_PRICE_API_KEY', '').strip()

# Validate that required environment variables are set
if not API_KEY:
    print("[WARNING] OPENWEATHER_API_KEY not set in .env file!")
    print("[HINT] Copy .env.example to .env and add your API key")

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import joblib
import numpy as np
import requests
from datetime import datetime
from typing import Any

# Initialize FastAPI app
app = FastAPI(
    title="Agri Expert API",
    description="Smart Crop Recommendation System",
    version="2.0.0"
)

# Global variable to store latest NPK sensor data
latest_npk_data = {
    "nitrogen": 50,
    "phosphorus": 40,
    "potassium": 30,
    "timestamp": datetime.now().isoformat()
}

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================================
# LOAD MODELS
# ============================================================================
print("[INIT] Loading trained models and artifacts...")

models_dir = os.path.join(os.path.dirname(__file__), "models")

required_files = {
    "crop_model.pkl": "Trained Random Forest model",
    "label_encoder.pkl": "Crop label encoder",
    "feature_scaler.pkl": "Feature scaler",
    "feature_names.pkl": "Feature names",
    "model_metadata.pkl": "Model metadata"
}

for filename, description in required_files.items():
    path = os.path.join(models_dir, filename)
    if not os.path.exists(path):
        raise FileNotFoundError(
            f"ERROR: {description} not found at {path}\n"
            f"Please run train_improved.py first."
        )

try:
    model = joblib.load(os.path.join(models_dir, "crop_model.pkl"))
    label_encoder = joblib.load(os.path.join(models_dir, "label_encoder.pkl"))
    scaler = joblib.load(os.path.join(models_dir, "feature_scaler.pkl"))
    feature_names = joblib.load(os.path.join(models_dir, "feature_names.pkl"))
    metadata = joblib.load(os.path.join(models_dir, "model_metadata.pkl"))
    
    print("[INIT] All models loaded successfully")
    print(f"[INIT] Model: {metadata['model_type']}")
    print(f"[INIT] Test Accuracy: {metadata['test_accuracy']*100:.2f}%")
    print(f"[INIT] CV Accuracy: {metadata['cv_accuracy_mean']*100:.2f}%")
    print(f"[INIT] Crops: {metadata['n_crops']}")
    print(f"[INIT] Features: {metadata['features']}")
    
except Exception as e:
    print(f"[ERROR] Model loading failed: {e}")
    raise

# ============================================================================
# INPUT/OUTPUT SCHEMAS
# ============================================================================

class CropPredictionInput(BaseModel):
    nitrogen: float = Field(..., gt=0, description="Nitrogen (N) 0-140")
    phosphorus: float = Field(..., gt=0, description="Phosphorus (P) 5-145")
    potassium: float = Field(..., gt=0, description="Potassium (K) 5-205")
    temperature: float = Field(..., description="Temperature (Celsius)")
    humidity: float = Field(..., ge=0, le=100, description="Humidity (0-100%)")
    rainfall: float = Field(..., ge=0, description="Rainfall (mm)")
    ph: float = Field(default=6.5, ge=3.5, le=9.5, description="Soil pH")


class CropPredictionResponse(BaseModel):
    recommended_crop: str
    confidence: float
    confidence_level: str
    reasoning: str
    input_summary: dict
    feature_importance: dict


class NPKSensorInput(BaseModel):
    nitrogen: float
    phosphorus: float
    potassium: float
    timestamp: str = Field(default_factory=lambda: datetime.now().isoformat())


class FertilizerRecommendationInput(BaseModel):
    crop: str = Field(..., min_length=2, max_length=80)
    nitrogen: float = Field(..., ge=0)
    phosphorus: float = Field(..., ge=0)
    potassium: float = Field(..., ge=0)
    ph: float = Field(default=6.5, ge=3.5, le=9.5)


class MarketPriceQuery(BaseModel):
    crop: str = Field(..., min_length=2, max_length=80)
    location: str = Field(default="India", min_length=2, max_length=120)


class ChatInput(BaseModel):
    message: str = Field(..., min_length=2, max_length=2000)
    history: list[dict[str, str]] = Field(default_factory=list, max_length=20)


# ============================================================================
# PREDICTION UTILITIES
# ============================================================================

def get_predictions(features_scaled):
    """Generate crop prediction from scaled features."""
    pred_encoded = model.predict(features_scaled)[0]
    probabilities = model.predict_proba(features_scaled)[0]
    crop_name = label_encoder.inverse_transform([pred_encoded])[0]
    confidence = float(np.max(probabilities))
    return crop_name, confidence


def get_top_features(n=3):
    """Get top N most important features."""
    importances = model.feature_importances_
    top_indices = np.argsort(importances)[-n:][::-1]
    result = {}
    for idx in top_indices:
        if idx < len(feature_names):
            result[feature_names[idx]] = round(float(importances[idx]), 4)
    return result


def make_reasoning(n, p, k, temp, humidity, ph, rainfall, crop):
    """Generate explainability reasoning."""
    top_feats = get_top_features(3)
    parts = []
    for feat in top_feats.keys():
        if feat == 'humidity':
            parts.append(f"Humidity {humidity}%")
        elif feat == 'rainfall':
            parts.append(f"Rainfall {rainfall}mm")
        elif feat == 'K':
            parts.append(f"K level {k}")
        elif feat == 'P':
            parts.append(f"P level {p}")
        elif feat == 'N':
            parts.append(f"N level {n}")
        elif feat == 'temperature':
            parts.append(f"Temperature {temp}C")
        elif feat == 'ph':
            parts.append(f"pH {ph}")
    return " | ".join(parts) + f" -> {crop}"


def get_confidence_level(conf):
    """Convert score to category."""
    if conf >= 0.95:
        return "Very High"
    elif conf >= 0.85:
        return "High"
    elif conf >= 0.70:
        return "Medium"
    else:
        return "Low"


# ============================================================================
# API ENDPOINTS
# ============================================================================

@app.get("/")
def root():
    """API health check and info."""
    return {
        "message": "Agri Expert API v2.0 Running",
        "model": metadata['model_type'],
        "accuracy": f"{metadata['test_accuracy']*100:.2f}%",
        "crops": metadata['n_crops'],
        "features": metadata['features']
    }


@app.post("/predict", response_model=CropPredictionResponse)
def predict_crop(input_data: CropPredictionInput):
    """
    Predict best crop based on soil and weather parameters.
    
    The model is a trained Random Forest classifier with 22 crop types.
    All input features are scaled before prediction to match training.
    """
    try:
        # Prepare features in correct order
        raw_features = np.array([[
            input_data.nitrogen,
            input_data.phosphorus,
            input_data.potassium,
            input_data.temperature,
            input_data.humidity,
            input_data.ph,
            input_data.rainfall
        ]])
        
        # Scale features using trained scaler
        features_scaled = scaler.transform(raw_features)
        
        # Make prediction
        crop_name, confidence = get_predictions(features_scaled)
        
        # Get feature importance
        feat_importance = get_top_features(3)
        
        # Generate reasoning
        reasoning = make_reasoning(
            input_data.nitrogen,
            input_data.phosphorus,
            input_data.potassium,
            input_data.temperature,
            input_data.humidity,
            input_data.ph,
            input_data.rainfall,
            crop_name
        )
        
        return CropPredictionResponse(
            recommended_crop=crop_name,
            confidence=round(confidence, 4),
            confidence_level=get_confidence_level(confidence),
            reasoning=reasoning,
            input_summary={
                "nitrogen": input_data.nitrogen,
                "phosphorus": input_data.phosphorus,
                "potassium": input_data.potassium,
                "temperature": input_data.temperature,
                "humidity": input_data.humidity,
                "ph": input_data.ph,
                "rainfall": input_data.rainfall
            },
            feature_importance=feat_importance
        )
    
    except Exception as e:
        print(f"[ERROR] Prediction failed: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")


@app.post("/predict-debug")
def predict_debug(input_data: CropPredictionInput):
    """Debug endpoint showing top 5 predictions."""
    try:
        raw_features = np.array([[
            input_data.nitrogen,
            input_data.phosphorus,
            input_data.potassium,
            input_data.temperature,
            input_data.humidity,
            input_data.ph,
            input_data.rainfall
        ]])
        
        features_scaled = scaler.transform(raw_features)
        probabilities = model.predict_proba(features_scaled)[0]
        
        predictions = [
            {"crop": crop, "confidence": round(float(probabilities[idx]), 4)}
            for idx, crop in enumerate(label_encoder.classes_)
        ]
        predictions.sort(key=lambda x: x['confidence'], reverse=True)
        
        return {
            "top_5": predictions[:5],
            "model": metadata['model_type'],
            "accuracy": metadata['test_accuracy']
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/model-info")
def model_info():
    """Get detailed model information."""
    return {
        "type": metadata['model_type'],
        "test_accuracy": round(metadata['test_accuracy'], 4),
        "cv_accuracy": round(metadata['cv_accuracy_mean'], 4),
        "cv_std": round(metadata['cv_accuracy_std'], 4),
        "f1_score": round(metadata['test_f1_score'], 4),
        "total_crops": metadata['n_crops'],
        "crops": sorted(metadata['crops']),
        "features": metadata['features']
    }


@app.get("/sensor/npk")
def get_sensor_data():
    """Get current NPK sensor reading."""
    return latest_npk_data


@app.post("/sensor/npk/update")
def update_sensor(data: NPKSensorInput):
    """Receive NPK sensor data from ESP32."""
    global latest_npk_data
    latest_npk_data = {
        "nitrogen": data.nitrogen,
        "phosphorus": data.phosphorus,
        "potassium": data.potassium,
        "timestamp": data.timestamp
    }
    return {"status": "success", "data": latest_npk_data}


# ============================================================================
# FARMING ADVISORY FEATURES
# ============================================================================

@app.post("/fertilizer/recommend")
def fertilizer_recommendation(data: FertilizerRecommendationInput):
    """Return screening-level nutrient guidance from soil-test NPK values."""
    # These screening bands are deliberately conservative and are not a
    # substitute for a local soil laboratory or agronomist recommendation.
    thresholds = {
        "nitrogen": (40, 80, "Nitrogen"),
        "phosphorus": (20, 60, "Phosphorus"),
        "potassium": (20, 80, "Potassium"),
    }
    values = {
        "nitrogen": data.nitrogen,
        "phosphorus": data.phosphorus,
        "potassium": data.potassium,
    }
    deficiencies = []
    guidance = []
    for key, (low, adequate, label) in thresholds.items():
        value = values[key]
        status = "low" if value < low else ("adequate" if value <= adequate else "high")
        if status == "low":
            deficiencies.append({
                "nutrient": label,
                "value": value,
                "status": status,
                "action": f"Use a {label.lower()}-containing fertilizer only after confirming the soil-test result.",
            })
            guidance.append(f"{label} appears low; consider a suitable {label.lower()} source.")
        elif status == "high":
            guidance.append(f"{label} is already high; avoid adding more without professional advice.")

    if not deficiencies:
        guidance.append("No clear NPK deficiency was detected by these screening bands.")

    return {
        "crop": data.crop.strip(),
        "nutrient_status": [
            {
                "nutrient": label,
                "value": values[key],
                "status": "low" if values[key] < low else (
                    "adequate" if values[key] <= adequate else "high"
                ),
            }
            for key, (low, adequate, label) in thresholds.items()
        ],
        "deficiencies": deficiencies,
        "guidance": guidance,
        "ph": data.ph,
        "source": "Screening bands informed by general extension soil-test guidance; verify locally.",
        "disclaimer": "This is general educational guidance, not a prescription. Confirm units, field area, crop stage, and application rates with a soil laboratory or agricultural professional.",
    }


@app.post("/market-prices")
def market_prices(query: MarketPriceQuery):
    """Proxy a configured official market-price adapter without inventing prices."""
    if not MARKET_PRICE_API_URL:
        return {
            "status": "unavailable",
            "message": "Verified market-price integration is not configured yet.",
            "source": "Agmarknet (configuration required)",
            "crop": query.crop,
            "location": query.location,
            "records": [],
        }

    try:
        params = {"crop": query.crop, "location": query.location}
        headers = {"Accept": "application/json"}
        if MARKET_PRICE_API_KEY:
            headers["X-API-Key"] = MARKET_PRICE_API_KEY
        response = requests.get(MARKET_PRICE_API_URL, params=params, headers=headers, timeout=10)
        response.raise_for_status()
        payload = response.json()
        records = payload.get("records", payload if isinstance(payload, list) else [])
        if not isinstance(records, list):
            raise ValueError("Market adapter returned an invalid records shape")
        return {
            "status": "available" if records else "unavailable",
            "source": payload.get("source", "Agmarknet") if isinstance(payload, dict) else "Agmarknet",
            "crop": query.crop,
            "location": query.location,
            "records": records,
        }
    except (requests.RequestException, ValueError) as exc:
        print(f"[ERROR] Market price lookup failed: {exc}")
        return {
            "status": "unavailable",
            "message": "Verified market prices are temporarily unavailable.",
            "source": "Agmarknet",
            "crop": query.crop,
            "location": query.location,
            "records": [],
        }


@app.post("/chat")
def agricultural_chat(data: ChatInput):
    """Answer farming questions using Gemini while keeping credentials server-side."""
    if not GEMINI_API_KEY:
        raise HTTPException(status_code=503, detail="AI chat is not configured on the server.")

    contents: list[dict[str, Any]] = []
    for item in data.history:
        role = item.get("role")
        text = item.get("text", "").strip()
        if role in {"user", "model"} and text:
            contents.append({"role": role, "parts": [{"text": text}]})
    contents.append({"role": "user", "parts": [{"text": data.message.strip()}]})
    body = {
        "system_instruction": {
            "parts": [{
                "text": "You are Agri Expert, a helpful agricultural assistant. "
                "Give clear, practical, region-aware answers. Do not invent market prices "
                "or diagnose crop disease with certainty. Recommend a local agriculture "
                "officer, soil lab, or plant pathologist when professional assessment is needed."
            }]
        },
        "contents": contents,
        "generationConfig": {"temperature": 0.3, "maxOutputTokens": 700},
    }
    url = (
        f"https://generativelanguage.googleapis.com/v1beta/models/"
        f"{GEMINI_MODEL}:generateContent?key={GEMINI_API_KEY}"
    )
    try:
        response = requests.post(url, json=body, timeout=30)
        if response.status_code != 200:
            print(f"[ERROR] Gemini returned {response.status_code}: {response.text[:500]}")
            raise HTTPException(
                status_code=503,
                detail="AI chat provider rejected the request. Check the server model and API key settings.",
            )
        payload = response.json()
        text = payload["candidates"][0]["content"]["parts"][0]["text"]
        return {"answer": text, "source": "Google Gemini", "professional_guidance_note": True}
    except (requests.RequestException, KeyError, IndexError, TypeError, ValueError) as exc:
        print(f"[ERROR] AI chat failed: {exc}")
        raise HTTPException(status_code=503, detail="AI chat is temporarily unavailable.")


# ============================================================================
# WEATHER SERVICE ENDPOINTS
# ============================================================================

@app.get("/weather")
def get_weather(latitude: float, longitude: float):
    """
    Fetch weather data from OpenWeatherMap API.
    
    Args:
        latitude: Geographic latitude
        longitude: Geographic longitude
    
    Returns:
        Weather data including temperature, humidity, rainfall, etc.
    
    Error Handling:
        - Returns 401 if API key is missing or invalid
        - Returns 404 if location not found
        - Returns 503 if weather service is unavailable
    """
    # Validate that API key is set
    if not API_KEY:
        raise HTTPException(
            status_code=401,
            detail="API key not configured. Please set OPENWEATHER_API_KEY in .env file."
        )
    
    try:
        # Call OpenWeatherMap API
        url = f"https://api.openweathermap.org/data/2.5/weather"
        params = {
            "lat": latitude,
            "lon": longitude,
            "appid": API_KEY,  # Use environment variable (NOT hardcoded)
            "units": "metric"  # Return temperature in Celsius
        }
        
        response = requests.get(url, params=params, timeout=10)
        
        # Handle different response codes
        if response.status_code == 401:
            print("[ERROR] Invalid API key for OpenWeatherMap")
            raise HTTPException(
                status_code=401,
                detail="Invalid OpenWeatherMap API key. Please verify OPENWEATHER_API_KEY in .env"
            )
        elif response.status_code == 404:
            raise HTTPException(
                status_code=404,
                detail=f"Location not found: ({latitude}, {longitude})"
            )
        elif response.status_code != 200:
            raise HTTPException(
                status_code=response.status_code,
                detail=f"Weather API error: {response.text}"
            )
        
        # Parse weather data
        data = response.json()
        
        # Extract relevant fields for crop prediction
        weather_info = {
            "location": data.get("name", "Unknown"),
            "country": data.get("sys", {}).get("country", ""),
            "temperature": data.get("main", {}).get("temp", None),
            "humidity": data.get("main", {}).get("humidity", None),
            "pressure": data.get("main", {}).get("pressure", None),
            "weather": data.get("weather", [{}])[0].get("main", ""),
            "description": data.get("weather", [{}])[0].get("description", ""),
            "rainfall": data.get("rain", {}).get("1h", 0),  # 1-hour rainfall
            "wind_speed": data.get("wind", {}).get("speed", None),
            "cloudiness": data.get("clouds", {}).get("all", None),
            "timestamp": datetime.now().isoformat()
        }
        
        print(f"[INFO] Weather data fetched for ({latitude}, {longitude})")
        return weather_info
        
    except requests.exceptions.Timeout:
        raise HTTPException(
            status_code=503,
            detail="Weather service timeout. Please try again."
        )
    except requests.exceptions.RequestException as e:
        print(f"[ERROR] Weather API request failed: {e}")
        raise HTTPException(
            status_code=503,
            detail="Failed to fetch weather data. Weather service may be unavailable."
        )
    except ValueError as e:
        raise HTTPException(
            status_code=500,
            detail=f"Invalid location parameters: {str(e)}"
        )
    except Exception as e:
        print(f"[ERROR] Unexpected error in weather endpoint: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Unexpected error: {str(e)}"
        )


@app.get("/weather/info")
def weather_info():
    """
    Get weather service configuration and API status.
    
    Returns:
        - api_configured: Whether OpenWeatherMap API key is set
        - environment: Development/production mode
        - debug_mode: Whether debug logging is enabled
    """
    return {
        "service": "OpenWeatherMap",
        "api_configured": bool(API_KEY),
        "environment": ENVIRONMENT,
        "debug_mode": DEBUG,
        "note": "API key should NOT be exposed in production responses"
    }


# ============================================================================
# MAIN
# ============================================================================

if __name__ == "__main__":
    import uvicorn
    print("\n" + "="*70)
    print("AGRI EXPERT API v2.0")
    print("="*70)
    print(f"Model: {metadata['model_type']}")
    print(f"Accuracy: {metadata['test_accuracy']*100:.2f}%")
    print(f"Crops: {metadata['n_crops']}")
    print("Starting on http://0.0.0.0:8000")
    print("="*70 + "\n")
    uvicorn.run(app, host="0.0.0.0", port=8000)
