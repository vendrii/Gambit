#%% Splitting Simple CSV Files in Python by Splitting the DataFrame using midpoint
import pandas as pd
file_path = '###WRITE YOUR FILE PATH HERE###'
df = pd.read_csv(file_path + '###WRITE YOUR FILE NAME TO LOAD HERE###.csv')

midpoint = len(df) // 2

# 3. Split the dataframe
df_pp1 = df.iloc[:midpoint]
df_pp2 = df.iloc[midpoint:]

# 4. Export to the same location
df_pp1.to_csv(file_path + '###WRITE YOUR FILE NAME FOR PART 1 HERE###.csv', index=False)
df_pp2.to_csv(file_path + '###WRITE YOUR FILE NAME FOR PART 2 HERE###.csv', index=False)

print(f"Done! Part 1 has {len(df_pp1)} rows and Part 2 has {len(df_pp2)} rows.")