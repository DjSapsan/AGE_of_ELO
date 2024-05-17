import os

def delete_csv_files_in_script_directory():
    # Get the directory where the script is located
    script_directory = os.path.dirname(os.path.abspath(__file__))

    # List all files in the script directory
    files_in_directory = os.listdir(script_directory)

    # Filter out the files that have .csv extension
    csv_files = [file for file in files_in_directory if file.endswith('.csv')]

    # Loop through the csv files and delete them
    for csv_file in csv_files:
        file_path = os.path.join(script_directory, csv_file)
        os.remove(file_path)
        print(f"Deleted: {file_path}")

# Call the function
delete_csv_files_in_script_directory()
