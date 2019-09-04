# DER_Gridconnected.py: Problem data preprocessing and visualization (Deterministic)

#### Load Modules

import gdxpds
gdxpds.load_gdxcc("C:\GAMS\win64\26.1\gams.exe")
import pandas as pd
import numpy as np
import os 
import datetime as dt
import itertools

import plotly as py
import plotly
import plotly.tools as tls
get_ipython().run_line_magic('matplotlib', 'inline')
import plotly.graph_objs as go
from plotly.offline import download_plotlyjs, init_notebook_mode, plot, iplot
plotly.offline.init_notebook_mode() 
import plotly.figure_factory as ff

import warnings
import scipy.stats as st
import statsmodels as sm
import matplotlib
import matplotlib.pyplot as plt
from cycler import cycler

from sklearn import preprocessing
from sklearn.cluster import KMeans
from sklearn.preprocessing import MinMaxScaler
from sklearn.metrics import silhouette_score



#### Preprocess data according to required formats

marg_cost_pergen = pd.read_csv('./')
# Column_header - ['Generator name', 'Capacity of generator', 'Marginal cost of generator']
# Sort_by - 'Marginal cost of generator'
# Add Columns - ['Cumulative capacity of generators', 'Cumulative marginal cost of generators']

unit_commit_perday = pd.read_csv('unit_commit_perday.csv').drop('Unnamed: 0', axis = 1)
# Column_header - ['Datetime index', 'Generator name (generation dispatch data per generator)']

unit_commit_perday.index = pd.date_range(start = " ", end = " ", freq = 'H')
unit_commit_perday['Month'] = [i.month for i in unit_commit_perday.index]
unit_commit_perday['Day'] = [i.day for i in unit_commit_perday.index]
unit_commit_perday['Hour'] = [i.hour for i in unit_commit_perday.index]



#### Function for building RDC

    """ Create residual demand curves for the market participant 
        based on available unit commitment and generator specifications 
        data for the entire length of the time period provided.

        Args:
        df_commit --- unit_commitment dataframe
        df_sc --- generator specifications dataframe 
        dict_rdc --- residual demand curve dictionary
        dict_rdc_rep --- representative residual demand curve dictionary"""

### Build month,hour pairs for the entire dataset

def build_pair(df_commit):
    
    """ construct tuples of unique month, hour pairs
        from the unit_commitment data available """

    m_h_pairs = []
    for i in range(0,len(unit_commit_perday.index)):
        m = df_commit.iloc[i,df_commit.columns.get_loc('Month')]
        h = df_commit.iloc[i,df_commit.columns.get_loc('Hour')]
        m_h_pairs.append((m,h))
    m_h_pairs = list(set(m_h_pairs)) 

    return(sorted(m_h_pairs))



### Filter dataset based on month and hour

def filter_dt(df_commit, month, hour): 
    
    """ filter unit_commitment data based on given 
        month and hour """

    df_fil = df_commit.loc[(df["Month"] == month) & (df["Hour"] == hour),:]
    return df_fil



### Build residual demand dataset for given month and hour

def build_rdc(df_commit, df_sc, day):
    
    """ create residual demand curve for given (month,hour) and 
        day based on energy production of all generators """

    ref_dem = df_commit.iloc[0,:-3].sum()
    
    df_day = pd.DataFrame({'energy': [],'energy_cost': []}) 
    gen_name = list(df_sc['Generator_name'].unique())
    
    for i in range(0,len(gen_name)):
        df_day = df_day.append({'energy': ref_dem - df_sc.loc[i,'Cumulative_power'],
                           'energy_cost': df_sc.loc[i,'Cumulative_cost']}, ignore_index = True)
    
    return(df_day)



### Demand profile from unit_commitment dataset

def dem_elec(df_commit):
    
    """ construct electricity demand profile per (month, hour) 
        assuming 

        (total      (aggregator    = (supply of all generators at 
        demand) -  client demand)     the particular hour) """
                       

    ref_dem_mh = pd.DataFrame()
    df_commit['Total_dem'] = df_commit.iloc[:,:-3].sum(axis = 1)
    for i in valid_pairs:
        ref_dem_mh = df_commit.groupby(by = ['Month','Hour'])['Total_dem'].mean().unstack()
        
    return(ref_dem_mh)
    


#### Average of the curves for Representative data

def rep_data(dict_rdc,month,hour):
    
    """ create a representative curve for all residual demand curves
        per hour of every month by calculating the aggregated average 
        of all days"""

    key = (month,hour)
    total_days = []
    
    RDC_avg = pd.DataFrame()
    for days in dict_rdc[key]:
        total_days.append(days)        
   
        for i in total_days:
            RDC_avg = RDC_avg.append(dict_rdc[key][i])
        
    RDC_rep = RDC_avg.groupby(by = RDC_avg.index, axis = 0).mean()
    
    return(RDC_rep)



### Plot RDC for a given month and hour

def rdc_plot(dict_rdc, dict_rdc_rep, month, hour):
    
    """ create the residual demand curves and representative RDC 
        plot for a particular (month, hour) """

    total_days = []
    key = (month,hour)
    for days in dict_rdc[key]:
        total_days.append(days)
    
    x = pd.DataFrame()
    y = pd.DataFrame()
    fig, ax = plt.subplots()
    for i in total_days:
        
        x[i] = pd.DataFrame(dict_rdc[key][i]).energy
        y[i] = pd.DataFrame(dict_rdc[key][i]).energy_cost    
        
        ax.step(x[i], y[i], where = 'post')
    
    x = pd.DataFrame(dict_rdc_rep[key]).energy
    y = pd.DataFrame(dict_rdc_rep[key]).energy_cost  
    ax.step(x, y, where = 'post',color = 'r', linestyle = 'dashed', label = 'Representative')
    
    ax.grid(linestyle=':')
    ax.set_xlabel('Energy (MWh)')
    ax.set_ylabel('Energy price ($/MWh)')
    ax.set_title(f'RDC curves for month:{month} and hour:{hour}')
    plt.legend(loc='upper right')
    
    plt.savefig(f'RDC_M{month}_h{hour}.png')
    plt.close(fig)
    


#### Function: Build RDC for all months and all hours (including plots)

def build_all_RDC(df_commit,df_sc):
    
    """ summing up all the functions together to produce 
        residual demand curves for the entire time horizon """

    RDC = dict()
    RDC_rep = dict()
    valid_pairs = build_pair(df_commit)
    for i in valid_pairs:        
        df_commit_days = filter_dt(df_commit,*i)        
        x = dict()        
        for index,rows in df_commit_days.iterrows():
            day = df_commit_days.loc[index,'Day']
            x.update({day: build_rdc(df_commit_days,df_sc,day)})
        RDC.update({i:x})    
        
        RDC_rep.update({i: rep_data(RDC,*i)}) 
        
        RDC_plot = rdc_plot(RDC, RDC_rep,*i)

    return(RDC, RDC_rep)



#### Write data to gdx for GAMS input

 """ convert pandas dataframe to gdx data format for GAMS input """        

### Electric Demand data

 """ translate electric demand data per (month, hour) to .gdx format """  
        
valid_pairs = build_pair(df_commit)
month = list(set([x[0] for x in valid_pairs]))
hours = list(set([x[1] for x in valid_pairs]))
ref_dem = dem_elec(df_commit)

os.system('rm Dem_Elec.gdx')
out_file = 'Dem_Elec.gdx'
    
with gdxpds.gdx.GdxFile() as gdx: 
    # Create new sets with one dimension
    gdx.append(gdxpds.gdx.GdxSymbol('H',gdxpds.gdx.GamsDataType.Set,dims=['h']))
    data_dem_h = pd.DataFrame([['h' + str(i)] for i in range(1,len(hours)+1)])   
    data_dem_h['value'] = True
    gdx[-1].dataframe = data_dem_h
    
    gdx.append(gdxpds.gdx.GdxSymbol('M',gdxpds.gdx.GamsDataType.Set,dims=['m']))
    data_dem_m = pd.DataFrame([['m' + str(i)] for i in range(1,len(month)+1)])
    data_dem_m['value'] = True
    gdx[-1].dataframe = data_dem_m
    
    # Create a new parameter with one dimension
    gdx.append(gdxpds.gdx.GdxSymbol('pDemandElec',gdxpds.gdx.GamsDataType.Parameter,dims=['m','h']))
    demand_iter = list(itertools.product(range(1,len(month)+1),range(1,len(hours)+1)))
    data_dem = pd.DataFrame(list(itertools.product(data_dem_m.iloc[:,0],data_dem_h.iloc[:,0])))
    data_dem['value'] = [ref_dem.iloc[m-1,h-1] for (m,h) in demand_iter]
    
    gdx[-1].dataframe = data_dem      
    gdx.write(out_file)
    


### Energy Cost curve data X and Y parameters

 """ translate residual demand curve x & y parameters data 
    per (month, hour) to .gdx format """  

os.system('rm RDC_XY.gdx')
out_file = 'RDC_XY.gdx'
    
with gdxpds.gdx.GdxFile() as gdx:
      
    # Create new sets with one dimension
    gdx.append(gdxpds.gdx.GdxSymbol('H',gdxpds.gdx.GamsDataType.Set,dims=['h']))
    data_h = pd.DataFrame([['h' + str(i)] for i in range(1,len(hours)+1)])   
    data_h['value'] = True
    gdx[-1].dataframe = data_h
        
    gdx.append(gdxpds.gdx.GdxSymbol('M',gdxpds.gdx.GamsDataType.Set,dims=['m']))
    data_m = pd.DataFrame([['m' + str(i)] for i in range(1,len(month)+1)])
    data_m['value'] = True
    gdx[-1].dataframe = data_m
        
    gdx.append(gdxpds.gdx.GdxSymbol('XY',gdxpds.gdx.GamsDataType.Set,dims=['xy']))
    data_xy = pd.DataFrame([['xy' + str(i)] for i in range(0,2)])
    data_xy['value'] = True
    gdx[-1].dataframe = data_xy
        
    gdx.append(gdxpds.gdx.GdxSymbol('P',gdxpds.gdx.GamsDataType.Set,dims=['p']))
    data_p = pd.DataFrame([['p' + str(i)] for i in range(1,len(RDC_rep[(m,h)])+1)])
    data_p['value'] = True
    gdx[-1].dataframe = data_p
    
    # Create new parameter with multiple dimensions
    gdx.append(gdxpds.gdx.GdxSymbol('ppCostCurveXY',gdxpds.gdx.GamsDataType.Parameter,dims=['p','xy','m','h']))
    cost_curve_iter = list(itertools.product(range(1,len(RDC_rep[(m,h)])+1),range(0,2),
                                             range(1,len(month)+1),range(1,len(hours)+1)))
    data_pp = pd.DataFrame(list(itertools.product(data_p.iloc[:,0],data_xy.iloc[:,0],
                                                  data_m.iloc[:,0],data_h.iloc[:,0])))
    data_pp['value'] = [RDC_rep[(m,h-1)].iloc[p-1,xy] for (p,xy,m,h) in cost_curve_iter]
    
    gdx[-1].dataframe = data_pp
    gdx.write(out_file)
    


#### Read results from GAMS output 

    """ read .gdx output file after GAMS runs for data visualization """

gdx_file = './der_opr.gdx'
with gdxpds.gdx.GdxFile(lazy_load = False) as f:
    f.read(gdx_file)
    for symbol in f:
        exec("%s_deropr_base = symbol.dataframe" %symbol.name)

