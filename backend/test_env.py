#!/usr/bin/env python
"""Test environment variable loading and dependencies."""

import sys
import os

print("=" * 70)
print("ENVIRONMENT SETUP TEST")
print("=" * 70)

# Test 1: Check python-dotenv
print("\n[TEST 1] Checking python-dotenv installation...")
try:
    from dotenv import load_dotenv
    print("✓ python-dotenv is installed")
except ImportError:
    print("✗ python-dotenv not found - install with: pip install python-dotenv")
    sys.exit(1)

# Test 2: Load .env file
print("\n[TEST 2] Loading .env file...")
load_dotenv()
print("✓ .env file loaded")

# Test 3: Check API Key
print("\n[TEST 3] Checking OpenWeather API Key...")
api_key = os.getenv('OPENWEATHER_API_KEY')
if api_key and api_key != 'your_api_key_here':
    print(f"✓ API Key is set: {api_key[:10]}...")
elif api_key == 'your_api_key_here':
    print("⚠ API Key is placeholder - update .env with real key")
else:
    print("✗ API Key not found in .env")

# Test 4: Check other config
print("\n[TEST 4] Checking other configuration...")
config = {
    'ENVIRONMENT': os.getenv('ENVIRONMENT', 'development'),
    'DEBUG': os.getenv('DEBUG', 'False'),
    'LOG_LEVEL': os.getenv('LOG_LEVEL', 'INFO'),
}
for key, value in config.items():
    print(f"  {key}: {value}")

# Test 5: Check required libraries
print("\n[TEST 5] Checking required libraries...")
required_libs = ['fastapi', 'uvicorn', 'joblib', 'numpy', 'pandas', 'sklearn', 'requests']
missing = []
for lib in required_libs:
    try:
        __import__(lib)
        print(f"✓ {lib}")
    except ImportError:
        print(f"✗ {lib} - missing")
        missing.append(lib)

if missing:
    print(f"\n⚠ Missing libraries: {', '.join(missing)}")
    print("Install with: pip install -r requirements.txt")

# Test 6: Check models directory
print("\n[TEST 6] Checking model files...")
models_dir = os.path.join(os.path.dirname(__file__), "models")
required_files = [
    "crop_model.pkl",
    "label_encoder.pkl",
    "feature_scaler.pkl",
    "feature_names.pkl",
    "model_metadata.pkl"
]

if os.path.exists(models_dir):
    print(f"✓ Models directory exists: {models_dir}")
    for filename in required_files:
        path = os.path.join(models_dir, filename)
        if os.path.exists(path):
            size_kb = os.path.getsize(path) / 1024
            print(f"  ✓ {filename} ({size_kb:.1f} KB)")
        else:
            print(f"  ✗ {filename} - missing")
else:
    print(f"✗ Models directory not found: {models_dir}")
    print("  Run train_improved.py to create models")

print("\n" + "=" * 70)
print("SETUP TEST COMPLETE")
print("=" * 70)
