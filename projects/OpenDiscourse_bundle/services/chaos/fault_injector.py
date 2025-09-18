import os, random, time, sys
# Usage: wrap ETL calls; inject `ETL_FAULT_P=0.05`, `ETL_FAULT_LAT_MS=200`
P = float(os.getenv('ETL_FAULT_P','0'))
LAT = int(os.getenv('ETL_FAULT_LAT_MS','0'))/1000
if random.random() < P:
    time.sleep(LAT)
    if random.random() < 0.5:
        sys.exit(1)
