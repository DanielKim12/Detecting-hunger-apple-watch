import xml.etree.ElementTree as ET
import csv
from datetime import datetime, timedelta

# GUK IL KIM 

# config change this
input_xml_path = "export.xml"  
output_csv_path = "data1.csv"
user_name = "guk il kim"

# start time -> started eating, after eating -> label will be 1 started eating
start_time = datetime.strptime("2025-04-01 11:35:00", "%Y-%m-%d %H:%M:%S")
after_eating_start = datetime.strptime("2025-04-01 12:00:00", "%Y-%m-%d %H:%M:%S")
end_time = after_eating_start + timedelta(minutes=50)

# parse xml 
tree = ET.parse(input_xml_path)
root = tree.getroot()

heart_data = []
for record in root.findall("Record"):
    if record.get("type") != "HKQuantityTypeIdentifierHeartRate":
        continue

    value = float(record.get("value"))
    timestamp = datetime.strptime(record.get("startDate"), "%Y-%m-%d %H:%M:%S %z").replace(tzinfo=None)

    if start_time <= timestamp <= end_time:
        heart_data.append((timestamp, value))

heart_data.sort()

# 10 secs partitions 
csv_rows = [["name", "timestamp", "heart_rate", "label"]]
current_time = start_time
last_known_hr = None
data_index = 0

while current_time <= end_time:
    # Move forward in heart_data to find the most recent value before or at current_time
    while data_index < len(heart_data) and heart_data[data_index][0] <= current_time:
        last_known_hr = heart_data[data_index][1]
        data_index += 1

    # Use the last known heart rate (can be None if no earlier data exists)
    if last_known_hr is not None:
        label = 0 if current_time < after_eating_start else 1
        csv_rows.append([user_name, current_time.strftime("%Y-%m-%d %H:%M:%S"), last_known_hr, label])

    current_time += timedelta(seconds=10)

with open(output_csv_path, "w", newline="") as file:
    writer = csv.writer(file)
    writer.writerows(csv_rows)

print(f"✅ Final CSV with 10-second steps saved: {output_csv_path}")
print(f"🔢 Total data rows (excluding header): {len(csv_rows) - 1}")