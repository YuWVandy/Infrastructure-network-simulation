# -*- coding: utf-8 -*-
"""
Created on Sat May 23 12:20:34 2020

@author: 10624
"""
##-------------------------------------Data for network data
##Data for water network
name1 = 'Water'

supply1 = 'Pumping station'
transmission1 = 'Storage tank'
demand1 = 'Deliver Station'

nodenum1 = 49
supplynum1 = 9
trannum1 = 6
demandnum1 = 34
color1 = 'blue'

##Data for power network
name2 = 'Power'

supply2 = 'Power plant'
transmission2 = '12 or 23kv substation'
demand2 = 'Deliver station'

nodenum2 = 60
supplynum2 = 9
trannum2 = 14
demandnum2 = 37
color2 = 'red'

##Data for gas network
name3 = 'Gas'
supply3 = 'Gas pumping station'
transmission3 = 'Intermediate station'
demand3 = 'Deliver station'

nodenum3 = 16
supplynum3 = 3
trannum3 = 7
demandnum3 = 6
color3 = 'green'



##-------------------------------------Data for Basemap
llon, rlon = -90.2, -89.6
llat, rlat = 34.98, 35.4
d_lat, d_lon = 0.01, 0.01
Type1 = 'local'

Tractfile = r'Tract.xlsx'

##-----------------------------------parameter for connecting networks
num = 1

##-----------------------------------data for generating networks using method in ouyangmin paper
m = 3
Type2 = 'Population'
wnodenum2, wsupplynum2 = 43, 9
pnodenum2, psupplynum2 = 46, 9
gnodenum2, gsupplynum2 = 9, 6
