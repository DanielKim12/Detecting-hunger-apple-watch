from flask import Flask, request, jsonify
import joblib 
import numpy as np 
import pandas as pd 
import scipy.stats


app = Flask(__name__)


# load saved model and scaler 

model = joblib.load("./voting_ensemble_model.pkl")
scaler = joblib.load("scaler.pkl")


def extract_features_from_hr_series(hr_series):
    hr_series = np.array(hr_series)
    if len(hr_series) < 2:
        return {}
    
    hr_diff = np.diff(hr_series)
    slope, _, _, _, _ = scipy.stats.linregress(np.arange(len(hr_series)), hr_series)
    zero_crossings = np.sum(np.diff(np.sign(hr_series - np.mean(hr_series))) != 0)
    pnn50 = np.sum(np.abs(hr_diff) > 50) / len(hr_diff)
    
    return {
        'mean': np.mean(hr_series),
        'std': np.std(hr_series),
        'min': np.min(hr_series),
        'max': np.max(hr_series),
        'range': np.ptp(hr_series),
        'slope': slope,
        'skew': scipy.stats.skew(hr_series, nan_policy='omit'),
        'kurtosis': scipy.stats.kurtosis(hr_series, nan_policy='omit'),
        'median': np.median(hr_series),
        'rmssd': np.sqrt(np.mean(np.square(hr_diff))),
        'mean_abs_change': np.mean(np.abs(hr_diff)),
        'max_diff': np.max(np.abs(hr_diff)),
        'iqr': np.percentile(hr_series, 75) - np.percentile(hr_series, 25),
        'variance': np.var(hr_series),
        'baseline_shift': np.mean(hr_series) - np.median(hr_series),
        'energy': np.sum(np.square(hr_series)),
        'zero_crossings': zero_crossings,
        'pnn50': pnn50
    }

# prediction route
@app.route("/predict", methods= ["POST"])
def predict():
    try:
        input_data = request.get_json()
        
        if "data" not in input_data:
            return jsonify({"error" : "Missing 'data' key"}), 400
        
        
        # parse incoming data
        df = pd.DataFrame(input_data["data"])
        
        if "heart_rate" not in df.columns:
            return jsonify({"error": "missing 'heart_rate' field"}), 400        

        hr_series = df["heart_rate"].dropna().values
        
        # extract features 
        features = extract_features_from_hr_series(hr_series= hr_series)
        
        if not features:
            return jsonify({"error": "Insufficient heart rate data"}), 400
        
        # convert to array and scale
        features_array = np.array(list(features.values())).reshape(1, -1)
        features_scaled = scaler.transform(features_array)
        
        # predict
        prediction = model.predict(features_scaled)[0]
        
        return jsonify({"prediction": int(prediction)})

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    

if __name__ == "__main__":
    app.run(host= "0.0.0.0", port= 5050, debug= True)
        