library(readrba)
library(xts)
library(tseries)
library(urca)
library(FinTS)
library(rmarkdown)

#Our variables
#Household final consumption expenditures 
pce.dl<-read_rba(series_id = "GGDPECCVPSH")
pce<-to.quarterly(xts(pce.dl$value, pce.dl$date), 
                         OHLC = FALSE)

#Real household disposable income
inc.dl<-read_rba(series_id = "GGDPICHRDI")
inc<-to.quarterly(xts(inc.dl$value, inc.dl$date), 
                  OHLC = FALSE)

#Interest rates on three-month treasury bills 
int.dl<-read_rba(series_id = "FIRMMTN3D")
int<-to.quarterly(xts(int.dl$value, int.dl$date), 
                  OHLC = FALSE)

#Consumer sentiment indicator
sent.dl<-read_rba(series_id = "GICWMICS")
sent<-to.quarterly(xts(sent.dl$value, sent.dl$date), 
                  OHLC = FALSE)

Y.df <- na.omit(merge(pce, inc, int, sent))
varname_vec<-c("Household final consumption expenditures", "Real household disposable income", "Interest rates on three-month treasury bills","Consumer sentiment indicator" )
colnames(Y.df)<-varname_vec

plot(pce[,0], y=pce[,1], type = "l", 
     ylab = "", xlab = "", lwd = 1.5)
