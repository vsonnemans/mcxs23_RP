library(readrba)
library(readabs)
library(tseries)
library(xts)

#Our variables
#Household final consumption expenditures 
pce.dl<- read_rba(series_id = "GGDPECCVPSH")

#Real household disposable income
pce.dl<- read_rba(series_id = "GGDPICHRDI")

#Interest rates on three-month treasury bills 
pce.dl<- read_rba(series_id = "FIRMMTN3D")

#Consumer sentiment indicator
pce.dl<- read_rba(series_id = "GICWMICS")




