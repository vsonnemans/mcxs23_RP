library(readrba)
library(xts)
library(tseries)
library(ggplot2)
library(patchwork)
library(dygraphs)
library(timeDate)
library(readabs)
library(zoo)
library(RColorBrewer)

#Our variables
#Household final consumption expenditures 
#pce.dl<-read_rba(series_id = "GGDPECCVPSH")
#pce<-to.quarterly(xts(pce.dl$value, pce.dl$date), 
#                         OHLC = FALSE)
pce = na.omit(as.data.frame(read_rba(series_id = "GGDPECCVPSH")))  
pce = pce[203:254,]
pce$date = as.Date(as.character(pce$date),format="%Y-%m-%d")  

#Real household disposable income
#inc.dl<-read_rba(series_id = "GGDPICHRDI")
#inc<-to.quarterly(xts(inc.dl$value, inc.dl$date), 
#                  OHLC = FALSE)

inc = na.omit(as.data.frame(read_rba(series_id = "GGDPICHRDI")))  
inc = inc[203:254,]
inc$date = as.Date(as.character(inc$date),format="%Y-%m-%d")  


#Interest rates on three-month treasury bills 
#int = na.omit(as.data.frame(read_rba(series_id = "FIRMMTN3D")))  
#int$date = as.Date(as.character(int$date),format="%Y-%m-%d")  

#Consumer sentiment indicator
#sent.dl<-read_rba(series_id = "GICWMICS")
#sent<-to.quarterly(xts(sent.dl$value, sent.dl$date), 
#                  OHLC = FALSE)

sent = na.omit(as.data.frame(read_rba(series_id = "GICWMICS")))  
sent$date = as.Date(as.character(sent$date),format="%Y-%m-%d")  


#Inflation-Consumer Price Index
cpi = na.omit(as.data.frame(read_rba(series_id = "GCPIAG"))) 
cpi = cpi[352:403,]
cpi$date = as.Date(as.character(cpi$date),format="%Y-%m-%d")  



plot_pce <- ggplot(data=pce, aes(x=date, y=value))+ scale_y_continuous(labels=scales::comma_format(big.mark=','))+ xlab(NULL)+ ylab(NULL) + geom_line(color="#8DD3C7") +ggtitle("PCE") + theme(plot.title = element_text(size=12))+ theme_minimal()
plot_inc <- ggplot(data=inc, aes(x=date, y=value)) + xlab(NULL)+ ylab(NULL)+ scale_y_continuous(labels=scales::comma_format(big.mark=',')) + geom_line(color="#8DD3C7") +ggtitle("Real household disposable income") + theme(plot.title = element_text(size=12))+ theme_minimal()
plot_sent <- ggplot(data=sent, aes(x=date, y=value)) + xlab(NULL)+ ylab(NULL)+ scale_y_continuous(labels=scales::comma_format(big.mark=',')) + geom_line(color="#BEBADA") +ggtitle("Consumer sentiment indicator") + theme(plot.title = element_text(size=12))+ theme_minimal()
plot_cpi <- ggplot(data=cpi, aes(x=date, y=value)) + xlab(NULL)+ ylab(NULL)+ scale_y_continuous(labels=scales::comma_format(big.mark=',')) + geom_line(color="#BEBADA") +ggtitle("Consumer Price Index") + theme(plot.title = element_text(size=12))+ theme_minimal()
plot_pce+plot_inc+plot_sent+plot_cpi + plot_layout(heights = c(3,3))

#Put the data in one dataframe
Y.df <- data.frame(pce$date, pce$value, inc$value, cpi$value)
colnames(Y.df) <- c("Date","Household final consumption expenditures","Real household disposable income","Consumer sentiment indicator")

#brewer.pal(4, "Set3")