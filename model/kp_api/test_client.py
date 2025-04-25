import pandas as pd 
import requests 
import json 


payload = {
    "data": [],
}


df = pd.read_csv("../../data/yechan/data5.csv")
df['timestamp'] = pd.to_datetime(df['timestamp'])
df = df.sort_values('timestamp').reset_index(drop=True)
test_label = 1 # can set either 0 or 1
df = df[df['label'] == test_label]

for _, row in df.iterrows():
    payload["data"].append({
        "timestamp": str(row["timestamp"]),
        "heart_rate":row["heart_rate"]
    })

# print(payload)

# exit()
    
url = "http://localhost:5050/predict"

response = requests.post(url, headers= {
    "Content-Type": "application/json"
}, data= json.dumps(payload))

if response.status_code == 200:
    print("Prediction:", response.json())
    
else:
    print("Error: ", response.status_code, response.text)