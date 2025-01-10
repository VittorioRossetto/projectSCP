import pandas as pd

# File paths
original_file = "order_products.csv"  # Replace with your local path or download it from GCS
small_file = "order_products_small.csv"
medium_file = "order_products_medium.csv"

# Define sample sizes (number of rows)
small_sample_size = 10000  # Small dataset: 10,000 rows
medium_sample_size = 100000  # Medium dataset: 100,000 rows

# Read the original CSV file
print("Reading the original dataset...")
try:
    data = pd.read_csv(original_file)
except FileNotFoundError:
    print(f"Error: {original_file} not found. Please make sure the file exists.")
    exit(1)

# Generate small dataset
print(f"Generating {small_file} with {small_sample_size} rows...")
data.sample(n=small_sample_size, random_state=42).to_csv(small_file, index=False)
print(f"{small_file} created successfully.")

# Generate medium dataset
print(f"Generating {medium_file} with {medium_sample_size} rows...")
data.sample(n=medium_sample_size, random_state=42).to_csv(medium_file, index=False)
print(f"{medium_file} created successfully.")
