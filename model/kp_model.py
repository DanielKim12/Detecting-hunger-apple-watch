import pandas as pd
import numpy as np
import scipy.stats
import random
from sklearn.ensemble import RandomForestClassifier, VotingClassifier
from sklearn.linear_model import LogisticRegression
from xgboost import XGBClassifier
from sklearn.model_selection import cross_validate, StratifiedKFold, train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import make_scorer, accuracy_score, precision_score, recall_score, f1_score
import joblib

from pprint import pprint
import warnings
warnings.filterwarnings("ignore")



# File paths (to be restored if files are re-uploaded)
file_paths = [
    "../data/gukil/data1.csv",
    "../data/gukil/data3.csv",
    "../data/gukil/data2.csv",
    "../data/gukil/data4.csv",
    "../data/gukil/data5.csv",
    "../data/gukil/data6.csv",
    "../data/yechan/data1.csv",
    "../data/yechan/data3.csv",
    "../data/yechan/data2.csv",
    "../data/yechan/data4.csv",
    "../data/yechan/data5.csv",
    "../data/yechan/data6.csv",
]


# Advanced feature extractor for a heart rate segment
def extract_features(hr_series):
    hr_series = hr_series.dropna().values
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
        # 'slope': np.polyfit(np.arange(len(hr_series)), hr_series, 1)[0],
        'slope': slope,
        # 'skew': scipy.stats.skew(hr_series),
        'skew' : scipy.stats.skew(hr_series, nan_policy='omit'),
        # 'kurtosis': scipy.stats.kurtosis(hr_series),
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

# Process labeled segments (label 0 or 1) from each CSV
def extract_labeled_segments(file_path):
    df = pd.read_csv(file_path)
    df['timestamp'] = pd.to_datetime(df['timestamp'])
    df = df.sort_values('timestamp').reset_index(drop=True)

    segments = []
    for label in [0, 1]:
        hr_segment = df[df['label'] == label]['heart_rate']
        if not hr_segment.empty:
            features = extract_features(hr_segment)
            features['label'] = label
            segments.append(features)
    if not segments:
        print(f"Warning: No segments found in {file_path}")
    return segments



# Process all uploaded files
# all_segments = []
# for path in file_paths:
#     all_segments.extend(extract_labeled_segments(path))
all_segments = [seg for path in file_paths for seg in extract_labeled_segments(path)]



# Prepare dataset
segment_df = pd.DataFrame(all_segments)
X = segment_df.drop(columns=['label'])
y = segment_df['label'].values

# Normalize features
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# train/test split
X_train, X_test, y_train, y_test = train_test_split(X_scaled, y, test_size=0.2, stratify=y, random_state=42
) 
# Define base models
rf = RandomForestClassifier(class_weight='balanced', random_state=42)
lr = LogisticRegression(class_weight='balanced', random_state=42)
xgb = XGBClassifier(use_label_encoder=False, eval_metric='logloss', random_state=42)

# Create Voting Ensemble
voting_model = VotingClassifier(estimators=[
    ('rf', rf),
    ('lr', lr),
    ('xgb', xgb)
], voting='soft')

# Fit ensemble model on training data
voting_model.fit(X_train, y_train)

# Predict on test data
y_pred = voting_model.predict(X_test)

# Evaluate
results = {
    "accuracy": accuracy_score(y_test, y_pred),
    "precision": precision_score(y_test, y_pred),
    "recall": recall_score(y_test, y_pred),
    "f1": f1_score(y_test, y_pred),
}

# Print evaluation results
pprint(results)

# Save the trained model
joblib.dump(voting_model, "voting_ensemble_model.pkl")
print("\nVoting Ensemble model saved as 'voting_ensemble_model.pkl'")

# save the standard scaler
joblib.dump(scaler, "scaler.pkl")
print("scaler saved")
# # Train and evaluate models
# models = {
#     "Random Forest": RandomForestClassifier(class_weight= "balanced", random_state= 42),
#     "Logistic Regression": LogisticRegression(class_weight= "balanced", random_state= 42),
#     "XGBoost": XGBClassifier(use_label_encoder=False, eval_metric='logloss', random_state= 42)
# }

# # create a voting ensemble model
# ensemble_model = VotingClassifier(estimators= [
#     ("rf", models["Random Forest"]),
#     ("lr", models["Logistic Regression"]),
#     ("xgb", models["XGBoost"]),
# ], voting= "soft")

# models["Voting Ensemble"] = ensemble_model


# cv = StratifiedKFold(n_splits= 5, shuffle= True, random_state= 42)

# scoring = {
#     'accuracy': make_scorer(accuracy_score),
#     'precision': make_scorer(precision_score),
#     'recall': make_scorer(recall_score),
#     'f1': make_scorer(f1_score)
# }


# # Train and evaluate
# results = {}
# if len(np.unique(y)) > 1:
#     for name, model in models.items():
#         scores = cross_validate(model, X_scaled, y, cv=cv, scoring=scoring)
#         results[name] = {
#             "accuracy_mean": np.mean(scores['test_accuracy']),
#             "precision_mean": np.mean(scores['test_precision']),
#             "recall_mean": np.mean(scores['test_recall']),
#             "f1_mean": np.mean(scores['test_f1']),
#         }
# else:
#     for name in models.keys():
#         results[name] = {
#             "error": "Only one class present in labels"
#         }

# # Output results
# pprint(results)

# # saving the voting ensemble model

# voting_model = models["Voting Ensemble"]
# voting_model.fit(X_scaled, y)

# joblib.dump(voting_model, "250425_voting_ensemble_model.pkl")
# print("Voting ensemble model saved")