# Age of Elo Ladder Simulator

AoE II: DE ladder simulator. Predicts rank, Elo, and likely matchups using real leaderboard snapshots.

## Features
- Download up-to-date leaderboard snapshots and track Elo over time.
- Simulate matchmaking and Elo progress.
- Display player base distributions.
- Export predictions to CSV.
- Make scenarios and change players.


## Examples

1. **Predict your rank, ELO and even potential opponents and results against them.You can change your skill and see where and against whom you end up.**

  ![img](https://github.com/DjSapsan/AGE_of_ELO/assets/12209464/3c259f8b-f184-4d59-acaa-ff2a36173d59)
  
---

2. **Predict tournament qualification results. Example is the RB WW El Reinado Last-Chance Qualifier (invited are ommited):**

[Predicted 73 days in advance](https://discord.com/channels/371470646703685635/691898094803091488/1240560720232583168):

  ![img](https://github.com/user-attachments/assets/de939455-fa72-45a6-b120-9a609adfb520)

[Real](https://liquipedia.net/ageofempires/Red_Bull_Wololo/El_Reinado/AoE2/Qualifier):
    
  ![img](https://github.com/user-attachments/assets/932f89f2-fa32-4d56-bd14-dfdf647d0a31)
  
---

3. **Predict general leaderboard.** Don't forget to run multiple attempts and estimate probabilities!
   Below is retrodictions, when simulation almost matched the reality. It's the first result at the very start of AoE 2 DE:

![image](https://github.com/DjSapsan/AGE_of_ELO/assets/12209464/8021d69c-8605-4e07-946c-c23b352b9413)

Actual ladder (~ December 2019)

![image](https://github.com/DjSapsan/AGE_of_ELO/assets/12209464/e458ea84-bbcf-4af5-80a5-1f2540aa83d9)

---

## Repo structure
- `main.lua`: main Love2D entry.
- `Game.lua`: simulation and matchmaking.
- `PlayerDB.lua`: keep leaderboards and player stats.
- `Graphics.lua`: histograms.
- `parameters.lua`: lots of important parameters.
- `scenario.lua`: optional scenarios.
- `LB_RM`, `LB_RB_EW`: leaderboard JSON snapshots.
- `Predictions/`: folder for saved reports and Python helpers for CSV analysis.
- `Fit.lua`: statistical values.

## Getting started
1. Install Love2D.
2. Fetch latest leaderboards:
   ```bash
   lua requestAllLeaderboard.lua
   ```
   Saves snapshots to folders LB_RM or LB_RB_EW (old Redbull ladder), you can modify ladder IDs for other ladders.
3. Launch:
   ```bash
   ./START
   ```
or
   ```bash
   love .
   ```

## Scenarios and predictions
- Change important parameters in parameters.lua.
- Set scenario params in scenario.lua.
- Fine tune activity via grinders.csv , override players in override.csv.
- If savePredictions is enabled, CSV reports go to Predictions/ folder for analysis.

## Disclaimer
The simulation is obviously probabilistic! Always expect it to be **WRONG**.
In the ideal vacuum players converge on their true skill level. Hovever it's not possible in practice! Players are playing differently on different maps, different time zones against different opponents and with different moods. 
The "true skill" is very obscure and it's impossible to determine it, even with lots of data.
Also it can't handle smurfs. Please override known players or excluded obvious smurfs (all with 90% + winrate for example).
Also my code is very suboptimal and requires a lot of refactoring and optimizations. But I can't invest all my efforts into it. Maybe community can make it better.

## License
Released under the [MIT License](LICENSE)
