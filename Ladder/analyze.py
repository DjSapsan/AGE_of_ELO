import pandas as pd

file_path = "table.ods"
sheets_dict = pd.read_excel(file_path, sheet_name=None)

print("Finished reading...")

data = pd.read_excel(file_path, sheet_name=0)  # Adjust sheet_name based on your file

# Create a DataFrame to store the most frequent names and their percentages
top_100 = pd.DataFrame(columns=['Most Frequent Name', 'Percentage'])

# Iterate over each column (run)
for col in data.columns:
    # Get the most frequent name in the column
    most_freq = data[col].value_counts().idxmax()
    frequency = data[col].value_counts().max()
    total = data[col].notna().sum()  # Count non-NaN values for percentage calculation

    # Calculate the percentage
    percentage = (frequency / total) * 100

    # Append the results to the DataFrame
    top_100.loc[col] = [most_freq, percentage]

# Display the results
print(top_100.head(100))