import time
import csv
import datetime  
from serial import Serial
from pyshimmer import ShimmerBluetooth, DEFAULT_BAUDRATE, DataPacket, EChannelType

collected_data = []

# Calculate Heart rateE(I think this is wrong)
def calibrate_heart_rate(raw_value):
    if raw_value is None:
        return None
    bpm = (raw_value / 1023.0) * 200
    return bpm

# GSR Calculate (I think It is wrong)
def calibrate_gsr(raw_value):
    if raw_value is None:
        return None
    offset = 500
    scale = 0.05 
    return (raw_value - offset) * scale
def handler(pkt: DataPacket) -> None:
    try:
        sensor_timestamp = pkt[EChannelType.TIMESTAMP]
    except KeyError:
        sensor_timestamp = None
    system_timestamp = time.time()
    #Heart Rate
    try:
        heart_rate_raw = pkt[EChannelType.INTERNAL_ADC_13]
    except KeyError:
        heart_rate_raw = None
    heart_rate_cal = calibrate_heart_rate(heart_rate_raw)
    #Skin Conductance (Using GSR_Raw)
    try:
        gsr_raw = pkt[EChannelType.GSR_RAW]
    except KeyError:
        gsr_raw = None
    gsr_cal = calibrate_gsr(gsr_raw)
    # formating but I think this formula is wrong.
    hr_str = f"{heart_rate_cal:.2f} BPM" if heart_rate_cal is not None else "None"
    gsr_str = f"{gsr_cal:.2f} uS" if gsr_cal is not None else "None"
    print(f"Sensor TS: {sensor_timestamp}, System TS: {system_timestamp}, "
          f"HR: {heart_rate_raw} ({hr_str}), GSR: {gsr_raw} ({gsr_str})")
    
    collected_data.append((sensor_timestamp, system_timestamp, heart_rate_raw, heart_rate_cal, gsr_raw, gsr_cal))

def save_data():
    first_name = "gukil"
    session_number = "2_2"
    
    # Get current date and time
    now = datetime.datetime.now()
    date_str = now.strftime('%Y%m%d')  # e.g., "20250313"
    time_str = now.strftime('%I%M%p')  # e.g., "1235PM"
    
    # Format the filename with first_name, session_number, date, and time 
    csv_filename = f"./data/gukil/{first_name}_session{session_number}_{date_str}_{time_str}.csv"
    
    with open(csv_filename, mode="w", newline="") as csv_file:
        csv_writer = csv.writer(csv_file)
        csv_writer.writerow(["sensor_timestamp", "system_timestamp", "heart_rate_raw",
                             "heart_rate_calibrated", "gsr_raw", "gsr_calibrated"])
        csv_writer.writerows(collected_data)
    
    print(f"\nData saved to {csv_filename}")

def main():
    try:
        serial_port = Serial('/dev/cu.Shimmer3-A92D', DEFAULT_BAUDRATE)
        shim_dev = ShimmerBluetooth(serial_port)
        shim_dev.initialize()
        shim_dev.add_stream_callback(handler)
        shim_dev.start_streaming()
        print("Start data streaming. Press Ctrl+C to stop and save data.")

        collection_duration = 1800  # seconds
        time.sleep(collection_duration)

    except KeyboardInterrupt:
        print("\nKeyboardInterrupt detected! Stopping data collection...")
    finally:
        shim_dev.stop_streaming()
        shim_dev.shutdown()
        save_data()
        
if __name__ == '__main__':
    main()
