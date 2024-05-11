import pandas as pd

# Adjust display settings
pd.set_option('display.max_rows', None)  # Set to None to display all rows
pd.set_option('display.max_columns', None)  # Set to None to display all columns
pd.set_option('display.width', 1000)  # Increase the width of each line

# Load the data
dataName = pd.read_csv("Name.csv", delimiter='\t')
dataElo = pd.read_csv("Elo.csv", delimiter='\t')
dataGames = pd.read_csv("Games.csv", delimiter='\t')
dataWR = pd.read_csv("Winrate.csv", delimiter='\t')

# Initialize dictionary to store player data
player_data = {}

# Extract player names from the first 10 positions of every run and track their positions and indices
for column in dataName.columns:
    for index, name in dataName.iloc[:10][column].items():
        if name not in player_data:
            player_data[name] = {'positions': [], 'elo': [], 'games': [], 'winrate': []}
        player_data[name]['positions'].append(index + 1)  # Store 1-based position
        player_data[name]['elo'].append(dataElo.iloc[index][column])
        player_data[name]['games'].append(dataGames.iloc[index][column])
        # Convert winrate from string to float
        player_data[name]['winrate'].append(float(dataWR.iloc[index][column]))

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
print(sorted_players[['Player', 'average_position', 'average_elo', 'average_games', 'average_winrate']])
