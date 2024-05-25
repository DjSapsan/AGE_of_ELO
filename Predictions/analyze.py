import pandas as pd
import glob

# Adjust display settings
pd.set_option('display.max_rows', None)  # Set to None to display all rows
pd.set_option('display.max_columns', None)  # Set to None to display all columns
pd.set_option('display.width', 1000)  # Increase the width of each line

# Initialize a list to store all the data
all_data = []

# Load all CSV files
for file in glob.glob("*.csv"):
    df = pd.read_csv(file,header=None, delimiter = '\t',on_bad_lines='skip')
    all_data.append(df)

# Concatenate all dataframes into one
combined_data = pd.concat(all_data, ignore_index=False)
print("Debug: First few rows of combined data")
print(combined_data.head())
# Initialize dictionary to store player data
player_data = {}

# Extract player names and their statistics
for index, row in combined_data.iterrows():
    name = row.iloc[1]
    if name not in player_data:
        player_data[name] = {'positions': [], 'elo': [], 'games': [], 'winrate': []}
    player_data[name]['positions'].append(int(row.iloc[0]))
    player_data[name]['elo'].append(int(row.iloc[2]))
    player_data[name]['games'].append(int(row.iloc[3]))
    player_data[name]['winrate'].append(float(row.iloc[4]))

# Calculate averages for position, Elo, games, and win rate
for player, metrics in player_data.items():
    metrics['average_position'] = sum(metrics['positions']) / len(metrics['positions'])
    metrics['average_elo'] = sum(metrics['elo']) / len(metrics['elo'])
    metrics['average_games'] = sum(metrics['games']) / len(metrics['games'])
    metrics['average_winrate'] = sum(metrics['winrate']) / len(metrics['winrate'])

# Convert to DataFrame
players_df = pd.DataFrame.from_dict(player_data, orient='index')
players_df.reset_index(inplace=True)
players_df.rename(columns={'index': 'Player'}, inplace=True)

# Sort by average position and display the top 10 players
sorted_players = players_df.sort_values(by='average_position').head(10)
print(sorted_players[['Player', 'average_position', 'average_elo', 'average_games', 'average_winrate']].applymap(lambda x: f"{x:.2f}" if isinstance(x, (int, float)) else x))
