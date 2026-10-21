import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
from sklearn.preprocessing import LabelEncoder
from xgboost import XGBClassifier
import joblib
import os

print("=" * 60)
print("CROP RECOMMENDATION MODEL TRAINING")
print("Random Forest + XGBoost Ensemble")
print("=" * 60)

# Step 1: Load dataset
dataset_path = os.path.join(os.path.dirname(__file__), "data", "Crop_recommendation.csv")

if not os.path.exists(dataset_path):
    print(f"ERROR: CSV file not found at {dataset_path}")
    print("Please place Crop_recommendation.csv inside the data folder")
    exit(1)

df = pd.read_csv(dataset_path)
print(f"\n✓ Dataset loaded: {df.shape[0]} rows, {df.shape[1]} columns")
print(f"✓ Crops found: {df['label'].nunique()} unique crops")
print(f"✓ Crop list: {list(df['label'].unique())}")

# Step 2: Prepare features and label
X = df[['N', 'P', 'K', 'temperature', 'humidity', 'rainfall']]
y = df['label']

print(f"\n✓ Features: {list(X.columns)}")
print(f"✓ Total samples: {len(df)}")

# Step 3: Stratified hold-out test set strategy
# Keep 400 samples for testing, 1800 for training
# Use stratification to ensure all crop types in both sets
from sklearn.model_selection import train_test_split

X_train, X_test, y_train, y_test = train_test_split(
    X, y, 
    test_size=400, 
    random_state=42, 
    stratify=y  # Ensures all crops in both train and test
)

print(f"\n✓ Training samples: {len(X_train)} (stratified)")
print(f"✓ Testing samples:  {len(X_test)} (hold-out test set)")
print(f"✓ Stratification ensures all {y.nunique()} crops in both sets!")
print(f"✓ Hold-out test set is completely separate from training!")

# Encode labels for XGBoost (fit encoder on ALL labels first to avoid unseen labels issue)
label_encoder = LabelEncoder()
label_encoder.fit(y)  # Fit on all labels to ensure all crops are known
y_train_encoded = label_encoder.transform(y_train)
y_test_encoded = label_encoder.transform(y_test)

# Step 4: Train Random Forest model
print("\n⏳ Training Random Forest model...")
rf_model = RandomForestClassifier(
    n_estimators=150,
    max_depth=15,
    min_samples_split=5,
    min_samples_leaf=2,
    random_state=42,
    n_jobs=-1
)
rf_model.fit(X_train, y_train)
print("✓ Random Forest trained!")

# Step 5: Train XGBoost model (uses encoded labels)
print("\n⏳ Training XGBoost model...")
xgb_model = XGBClassifier(
    n_estimators=150,
    max_depth=7,
    learning_rate=0.1,
    subsample=0.8,
    colsample_bytree=0.8,
    random_state=42,
    n_jobs=-1
)
xgb_model.fit(X_train, y_train_encoded)
print("✓ XGBoost trained!")

# Step 6: Create Voting Ensemble
# Manually combine predictions instead of using VotingClassifier to avoid label mismatch
print("\n⏳ Creating prediction logic for ensemble...")

# Step 7: Evaluate all models
print("\n" + "=" * 60)
print("MODEL EVALUATION")
print("=" * 60)

# Random Forest evaluation
print("\n📊 RANDOM FOREST:")
rf_pred = rf_model.predict(X_test)
rf_acc = accuracy_score(y_test, rf_pred)
print(f"Accuracy: {rf_acc * 100:.2f}%")

# XGBoost evaluation (convert predictions back to original labels)
print("\n📊 XGBOOST:")
xgb_pred_encoded = xgb_model.predict(X_test)
xgb_pred = label_encoder.inverse_transform(xgb_pred_encoded)
xgb_acc = accuracy_score(y_test, xgb_pred)
print(f"Accuracy: {xgb_acc * 100:.2f}%")

# Ensemble evaluation
print("\n📊 VOTING ENSEMBLE (Primary Model):")
# We'll evaluate using the ensemble class logic
rf_proba_test = rf_model.predict_proba(X_test)
xgb_proba_encoded_test = xgb_model.predict_proba(X_test)
xgb_pred_encoded_test = xgb_model.predict(X_test)

xgb_proba_test = np.array([[0.0] * len(rf_model.classes_) for _ in range(len(X_test))])
for sample_idx, encoded_class_idx in enumerate(xgb_pred_encoded_test):
    for class_idx, rf_class in enumerate(rf_model.classes_):
        encoded_class = label_encoder.transform([rf_class])[0]
        if encoded_class == encoded_class_idx:
            xgb_proba_test[sample_idx, class_idx] = xgb_proba_encoded_test[sample_idx, encoded_class_idx]

ensemble_proba_test = (rf_proba_test + xgb_proba_test) / 2
ensemble_pred = rf_model.classes_[np.argmax(ensemble_proba_test, axis=1)]
ensemble_acc = accuracy_score(y_test, ensemble_pred)
print(f"Accuracy: {ensemble_acc * 100:.2f}%")
print("\nClassification Report:")
print(classification_report(y_test, ensemble_pred))

# Feature importance
print("\n" + "=" * 60)
print("FEATURE IMPORTANCE")
print("=" * 60)
print("\nRandom Forest Top Features:")
for feat, imp in zip(X.columns, rf_model.feature_importances_):
    print(f"  {feat}: {imp * 100:.2f}%")

print("\nXGBoost Top Features:")
for feat, imp in zip(X.columns, xgb_model.feature_importances_):
    print(f"  {feat}: {imp * 100:.2f}%")

# Step 8: Save models
models_dir = os.path.join(os.path.dirname(__file__), "models")
os.makedirs(models_dir, exist_ok=True)

# Save individual models
rf_path = os.path.join(models_dir, "rf_model.pkl")
xgb_path = os.path.join(models_dir, "xgb_model.pkl")
encoder_path = os.path.join(models_dir, "label_encoder.pkl")

joblib.dump(rf_model, rf_path)
joblib.dump(xgb_model, xgb_path)
joblib.dump(label_encoder, encoder_path)

# For backward compatibility, save a config dict
config = {
    "rf_path": "rf_model.pkl",
    "xgb_path": "xgb_model.pkl",
    "encoder_path": "label_encoder.pkl",
    "model_type": "ensemble"
}
config_path = os.path.join(models_dir, "config.pkl")
joblib.dump(config, config_path)

# Also create crop_model.pkl pointing to the models directory
# This helps app.py know to use ensemble mode
joblib.dump(config, os.path.join(models_dir, "crop_model.pkl"))

print(f"\n✓ Random Forest model saved to: {rf_path}")
print(f"✓ XGBoost model saved to: {xgb_path}")
print(f"✓ Label encoder saved to: {encoder_path}")
print(f"✓ Config saved to: {config_path}")
print(f"\n✓ Using ENSEMBLE: RandomForest + XGBoost with soft voting")
print(f"✓ NO SCALER USED (Tree-based models don't require scaling)")

print("\n" + "=" * 60)
print("TRAINING COMPLETE! Ready for FastAPI.")
print("=" * 60)