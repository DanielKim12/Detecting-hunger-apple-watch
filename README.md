# Shimmer Device: HRV & EDA Signal Collection for Hunger vs. Satiety Evaluation

## Project Overview

This project utilizes the Shimmer sensor to collect Heart Rate Variability (HRV) and Electrodermal Activity (EDA) signals for developing a model that evaluates an individual’s state of hunger vs. satiety. The collected physiological data will be analyzed to identify patterns and biomarkers related to these states.

## Hardware & Software Requirements

### Hardware
- Shimmer3 GSR+ device (for EDA and HRV signal acquisition)
- Bluetooth-enabled computer (macOS/Linux recommended)

### Software
- Python 3.x
- Required Python libraries:
Refer to the [installation guide](https://github.com/seemoo-lab/pyshimmer/blob/main/README.md) for Pyshimmer setup instructions.

Or use virtual env to run:
```
python3 -m venv shimmer_env
source shimmer_env/bin/activate  # On macOS/Linux
shimmer_env\Scripts\activate     # On Windows
pip install pyshimmer numpy pandas matplotlib serial
```

## Contributors:
- GUK IL KIM 
- DANIEL SEO 
- CHANGMUK OH
- KP [RENAME] 
