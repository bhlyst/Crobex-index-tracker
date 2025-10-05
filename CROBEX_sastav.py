#!/usr/bin/env python
# coding: utf-8

# In[1]:


## Importing packages ##

import requests
import pandas as pd
from pandas import json_normalize
import json
from datetime import date
from pathlib import Path


# In[2]:


url = "https://zse.hr/json/IndexComposition?search=&sort=symbol&order=asc&isin=HRZB00ICBEX6&lng=hr"

resp = requests.get(url)
data = resp.json()


# In[3]:


## Diagnostics to ensure the right key for extracting data#
#
# print(type(data))

# print(data.keys())
#
# print(json.dumps(data, indent = 2, ensure_ascii=False))


# In[4]:


df = pd.DataFrame(data["rows"])

df["download_date"] = date.today().strftime("%Y-%m-%d")

print(df.head())


# In[5]:


file = Path("crobex_sastav_povijest.csv")

if file.exists() :
    old = pd.read_csv(file)
    combined = pd.concat([old, df], ignore_index = True)
    combined.to_csv(file, index = False, encoding = "utf-8")
else:
    df.to_csv(file, index = False, encoding = "utf-8")
    


# In[ ]:




