# Apple Watch Biosignal Analysis: Hunger vs. Satiety Detection

## 📋 Project Overview

This project explores how biometric signals—specifically **Heart Rate (BPM)** and **Heart Rate Variability (HRV)**—change based on an individual's state of **hunger** versus **satiety**. By leveraging data collected passively from the **Apple Watch**, we aim to build a model capable of detecting these internal states through physiological signals.

## 💡 Motivation

Can your Apple Watch tell when you’re hungry? This project seeks to answer that question by identifying patterns in biometric signals that shift between hunger and fullness. Our long-term goal is to support the development of personalized wellness and nutrition tracking tools powered by passive signal monitoring.

## 📱 Data Collection

- **Device**: Apple Watch  
- **Signals Used**:
  - Heart Rate (BPM)
  - Heart Rate Variability (HRV)
- **Export Instructions**:
  1. Open the **Health** app on your iOS device.
  2. Go to your profile (top-right corner).
  3. Tap **Export All Health Data**.
  4. Save the `export.xml` file to your computer for analysis.

## ⚙️ Software Requirements

- Python 3.x

## 🚀 Running the Script

1. Place your Apple Health `export.xml` file in the same directory as `main.py`.

2. Open `main.py` and set your desired time window:
modify the number values to match user's start time of the measure, start of eating (make sure to note this value as it will be considered as the start of label transition)
```python
before_eating = datetime.strptime("2025-04-01 11:40:00", "%Y-%m-%d %H:%M:%S")
after_eating = datetime.strptime("2025-04-01 12:00:00", "%Y-%m-%d %H:%M:%S")
```

3. Run the script using:
```
python3 main.py
```

4. A CSV file named heart_rate_output.csv will be generated with the following format:
```
name,timestamp,heart_rate,label
```
Where:
- label = 0 indicates before eating
- label = 1 indicates after eating
- Time steps are generated every 10 seconds
- If a reading is missing at a given time step, the most recent available heart rate value is carried forward

The final CSV includes 300 rows for the 5 minutes before eating, and 300 rows for the 50 minutes after eating, totaling 600 labeled rows for model training or analysis.

## Contributors:
- GUK IL KIM 
- DANIEL SEO 
- CHANGMUK OH
- Kshitij Pawar
