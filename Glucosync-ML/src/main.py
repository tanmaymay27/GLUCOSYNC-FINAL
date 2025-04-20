import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
import seaborn as sns
import joblib  # Add this import

# Load data
data = pd.read_csv('data/data.csv')
X = data[['X']].values  # Absorbance
y = data['y'].values    # Glucose levels

# Split data into training and testing sets
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.25, random_state=42)

# Create a pipeline with preprocessing and model
pipeline = Pipeline([
    ('scaler', StandardScaler()),
    ('rf', RandomForestRegressor(random_state=42))
])

# Define hyperparameter grid
param_grid = {
    'rf__n_estimators': [50, 100, 150, 200],
    'rf__max_depth': [None, 10, 20, 30],
    'rf__min_samples_split': [2, 5, 10],
    'rf__min_samples_leaf': [1, 2, 4]
}

# Grid search with cross-validation
grid_search = GridSearchCV(
    pipeline, param_grid, cv=5, 
    scoring='neg_mean_absolute_error', 
    verbose=1, n_jobs=-1
)

grid_search.fit(X_train, y_train)

# Get best model
best_model = grid_search.best_estimator_
print(f"Best parameters: {grid_search.best_params_}")

# Make predictions
y_pred = best_model.predict(X_test)

# Evaluate model
mae = mean_absolute_error(y_test, y_pred)
rmse = np.sqrt(mean_squared_error(y_test, y_pred))
mse = mean_squared_error(y_test, y_pred)
r2 = r2_score(y_test, y_pred)

# Print evaluation metrics
print(f"Mean Absolute Error: {mae:.2f} mg/dL")
print(f"Root Mean Squared Error: {rmse:.2f} mg/dL")
print(f"Mean Squared Error: {mse:.2f} mg/dL")
print(f"R² Score: {r2:.4f}")

# Visualize predicted vs actual
plt.figure(figsize=(10, 6))
plt.scatter(y_test, y_pred, alpha=0.7)
plt.plot([min(y_test), max(y_test)], [min(y_test), max(y_test)], 'r--')
plt.title('Predicted vs Actual Glucose Levels')
plt.xlabel('Actual Glucose Level (mg/dL)')
plt.ylabel('Predicted Glucose Level (mg/dL)')
plt.grid(True, alpha=0.3)
plt.show()

print("\nActual vs Predicted Values:")
for actual, predicted in zip(y_test, y_pred):
    print(f"Actual: {actual:.1f}, Predicted: {predicted:.1f}")

# Visualize predictions vs actual using a line plot


# Create prediction function for real-time use
def predict_glucose(absorbance_value):
    value = np.array([[absorbance_value]])
    predicted_glucose = best_model.predict(value)[0]
    return predicted_glucose

# Example usage
test_absorbance = 1
predicted = predict_glucose(test_absorbance)
print(f"For absorbance value of {test_absorbance}, predicted glucose: {predicted:.1f} mg/dL")

# Plot model performance across absorbance range
absorbance_range = np.linspace(min(X.flatten()), max(X.flatten()), 100).reshape(-1, 1)
predictions = best_model.predict(absorbance_range)



# Save the model for inference
joblib.dump(best_model, 'rf_glucose_model.pkl')