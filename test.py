import csv

with open('Data/MAAP_Test_Data/2025_SPRING_3-8_EOC_2520.csv', 'r') as f:
    reader = csv.DictReader(f)
    count = 0
    for row in reader:
        if count < 5:
            print(f"MSIS: {row['MSIS']}, D1OP: {row['D1OP']}, DTOP: {row['DTOP']}, SCALE: {row['SCALE_SCORE']}")
        count += 1
    print(f"Total rows: {count}")
