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
library(openxlsx)

rba_data = browse_rba_series()

#Household final consumption expenditures 
pce.dl<-read_rba(series_id = "GGDPECCVPSH")
pce<-to.quarterly(xts(pce.dl$value, pce.dl$date), 
                  OHLC = FALSE)
pce<-pce[163:254,]
#pce = na.omit(as.data.frame(read_rba(series_id = "GGDPECCVPSH")))  
#pce = pce[203:254,]
#pce$date = as.Date(as.character(pce$date),format="%Y-%m-%d")  

#Real household disposable income
inc.dl<-read_rba(series_id = "GGDPICHRDI")
inc<-to.quarterly(xts(inc.dl$value, inc.dl$date), 
                  OHLC = FALSE)
inc<-inc[163:254,]

#Inflation-Consumer Price Index
cpi.dl<-read_rba(series_id = "GCPIAG")
temp_cpi<-to.quarterly(xts(cpi.dl$value, cpi.dl$date), 
                       OHLC = FALSE)
cpi <- 100*diff(temp_cpi)/temp_cpi
cpi<-cpi[312:403]

#Consumer Confidence Index from the Roy Morgan
# Index value, quarterly ; Mar-2000 to Mar-2023
consum_dwnld  = read.xlsx("https://roymorgan-cms-dev.s3.ap-southeast-2.amazonaws.com/wp-content/uploads/2023/03/06052804/9180-ANZ-Roy-Morgan-Australian-CC-Data-1986-2023.xlsx",sheet=20)
consum_dwnld  = data.frame(na.omit(consum_dwnld[,4]))
consum_date   = seq(as.Date('2000-03-31'), as.Date('2023-03-31'), by = "quarter")
row.names(consum_dwnld) = consum_date
consum_tmp    = as.xts(consum_dwnld)
consum_sent    = xts(consum_tmp, seq(as.Date('2000-03-31'), by = "quarter", length.out = length(consum_tmp)))
consum_sent <- consum_sent[1:92,]

#Lending rates
mortgage_rate.dl<-read_rba(series_id = "FILRHL3YF")
mortgage_rate.l<-mortgage_rate.dl[113:391,]
mortgage_rate<-to.quarterly(xts(mortgage_rate.l$value, mortgage_rate.l$date), 
                            OHLC = FALSE)
mortgage_rate<-mortgage_rate[1:92,]
#mortgage_rates = na.omit(as.data.frame(read_rba(series_id = "FILRHL3YF"))) 

#Unemployment rates
unemp_rate.dl<-read_rba(series_id = "GLFSURSA")
unemp_rate.l<-unemp_rate.dl[264:542,]
unemp_rate<-to.quarterly(xts(unemp_rate.l$value, unemp_rate.l$date), 
                         OHLC = FALSE)
unemp_rate<-unemp_rate[1:92,]
#unemp_rate = na.omit(as.data.frame(read_rba(series_id = "GLFSURSA"))) 

plot_pce <- ggplot(data=pce, aes(x=date, y=value))+ scale_y_continuous(labels=scales::comma_format(big.mark=','))+ xlab(NULL)+ ylab(NULL) + geom_line(color="#8DD3C7") +ggtitle("PCE") + theme(plot.title = element_text(size=12))+ theme_minimal()
plot_inc <- ggplot(data=inc, aes(x=date, y=value)) + xlab(NULL)+ ylab(NULL)+ scale_y_continuous(labels=scales::comma_format(big.mark=',')) + geom_line(color="#8DD3C7") +ggtitle("Real household disposable income") + theme(plot.title = element_text(size=12))+ theme_minimal()
plot_sent <- ggplot(data=sent, aes(x=date, y=value)) + xlab(NULL)+ ylab(NULL)+ scale_y_continuous(labels=scales::comma_format(big.mark=',')) + geom_line(color="#BEBADA") +ggtitle("Consumer sentiment indicator") + theme(plot.title = element_text(size=12))+ theme_minimal()
plot_cpi <- ggplot(data=cpi, aes(x=date, y=value)) + xlab(NULL)+ ylab(NULL)+ scale_y_continuous(labels=scales::comma_format(big.mark=',')) + geom_line(color="#BEBADA") +ggtitle("Consumer Price Index") + theme(plot.title = element_text(size=12))+ theme_minimal()
plot_pce+plot_inc+plot_sent+plot_cpi + plot_layout(heights = c(3,3))


# Merge data into one matrix
Y.df  <- data.frame(pce, inc ,cpi,  consum_sent, mortgage_rate, unemp_rate)

varname_vec <- c("PCE", "Real disposable income","CPI", "Consumer Confidence Index","Mortgage rate","Unemployment rate")
colnames(Y.df) <- varname_vec

# Transform into natural logs
df.log <- data.frame(log(pce),
                     log(inc),
                     cpi,
                     log(consum_sent),
                     log(mortgage_rate),
                     log(unemp_rate))

colnames(df.log) <- c("PCE", "Real disposable income","CPI", "Consumer Confidence Index","Mortgage rate","Unemployment rate")
df.log$CPI <- as.numeric(as.character(cpi))


#date <- index(pce)
#T <- length(date)

#######BVAR estimation
#################################################################################
####Basic model

### Specify the setup
N       = ncol(df.log)
p       = 4
K       = 1+N*p
T       = nrow(Y)
S       = c(5000,50000)
h       = 20
set.seed(123456)

### Create Y and X matrices
y       = ts(df.log, start=c(2000,1), frequency=4)
Y       = ts(y[5:nrow(y),], start=c(2001,1), frequency=4)
X       = matrix(1,nrow(Y),1)
for (i in 1:p){
  X     = cbind(X,y[5:nrow(y)-i,])
}

### MLE
A.hat       = solve(t(X)%*%X)%*%t(X)%*%Y
Sigma.hat   = t(Y-X%*%A.hat)%*%(Y-X%*%A.hat)/T

### Specify the priors (Minnesota prior)
kappa.1           = 0.02^2
kappa.2           = 100
A.prior           = matrix(0,nrow(A.hat),ncol(A.hat))
A.prior[2:(N+1),] = diag(N)

priors = list(
  A.prior     = A.prior,
  V.prior     = diag(c(kappa.2,kappa.1*((1:p)^(-2))%x%rep(1,N))),
  S.prior     = diag(diag(Sigma.hat)),
  nu.prior    = N+1 
)

### BVAR function

BVAR = function(Y,X,priors,S){
  
  # normal-inverse Wishard posterior parameters
  V.bar.inv   = t(X)%*%X + diag(1/diag(priors$V.prior))
  V.bar       = solve(V.bar.inv)
  A.bar       = V.bar%*%(t(X)%*%Y + diag(1/diag(priors$V.prior))%*%priors$A.prior)
  nu.bar      = nrow(Y) + priors$nu.prior
  S.bar       = priors$S.prior + t(Y)%*%Y + t(priors$A.prior)%*%diag(1/diag(priors$V.prior))%*%priors$A.prior - t(A.bar)%*%V.bar.inv%*%A.bar
  S.bar.inv   = solve(S.bar)
  
  #posterior draws
  Sigma.posterior   = rWishart(sum(S), df=nu.bar, Sigma=S.bar.inv)
  Sigma.posterior   = apply(Sigma.posterior,3,solve)
  Sigma.posterior   = array(Sigma.posterior,c(N,N,sum(S)))
  A.posterior       = array(rnorm(prod(c(dim(A.bar),sum(S)))),c(dim(A.bar),sum(S)))
  L                 = t(chol(V.bar))
  
  for (s in 1:sum(S)){
    A.posterior[,,s]= A.bar + L%*%A.posterior[,,s]%*%chol(Sigma.posterior[,,s])
  }
  
  posterior = list(
    Sigma.posterior   = Sigma.posterior,
    A.posterior       = A.posterior
  )
  return(posterior)
}

## Apply function BVAR
posterior.draws = BVAR(Y=Y, X=X, priors=priors, S=S)
round(apply(posterior.draws$Sigma.posterior, 1:2, mean),3)
round(apply(posterior.draws$A.posterior, 1:2, mean),3)

#################################################################################
####Extended model

### Modify the priors
kappa.1           = 1
kappa.2           = 10
initial_kappa     = 100
A.prior           = matrix(0,nrow(A.hat),ncol(A.hat))
A.prior[2:(N+1),] = diag(N)

priors = list(
  A.prior            = A.prior,
  V.prior            = diag(c(kappa.2,kappa.1*((1:p)^(-2))%x%rep(1,N))),
  S.prior            = diag(diag(Sigma.hat)),
  nu.prior           = N+1,
  s.kappa.prior      = 2,
  nu.kappa.prior     = 4
)

### Modify BVAR function

BVAR_extension = function(X,Y,priors,initial_kappa,S){
  
  A.posterior        = array(NA, dim = c(K,N,sum(S)))
  Sigma.posterior    = array(NA,dim=c(N,N,sum(S)))
  kappa.posterior    = matrix(NA, sum(S), 1) 
  kappa.posterior[1] = initial_kappa
  
  for (s in 1:sum(S)){
    # full-cond of joint posterior of A and Sigma
    V.bar.inv   = t(X)%*%X + diag(1/diag(kappa.posterior[s]*priors$V.prior))
    V.bar       = solve(V.bar.inv)
    A.bar       = V.bar%*%(t(X)%*%Y + diag(1/diag(kappa.posterior[s]*priors$V.prior))%*%priors$A.prior)
    nu.bar      = nrow(Y) + priors$nu.prior
    S.bar       = priors$S.prior + t(Y)%*%Y + t(priors$A.prior)%*%diag(1/diag(kappa.posterior[s]*priors$V.prior))%*%priors$A.prior - t(A.bar)%*%V.bar.inv%*%A.bar
    S.bar.inv   = solve(S.bar)
    
    
    Sigma.posterior.dist   = rWishart(1, df=nu.bar, Sigma=S.bar.inv)
    Sigma.draw             = apply(Sigma.posterior.dist,3,solve)
    Sigma.posterior[,,s]   = Sigma.draw
    A.posterior[,,s]            = array(rnorm(prod(c(dim(A.bar),1))),c(dim(A.bar),1))
    L                      = t(chol(V.bar))
    A.posterior[,,s]       = A.bar + L%*%A.posterior[,,s]%*%chol(Sigma.posterior[,,s])
    
    #full conditional posterior of kappa
    if (s!=sum(S)){
    s.kappa.bar           = priors$s.kappa.prior + sum(diag(solve( Sigma.posterior[,,s])*t(A.posterior[,,s]-priors$A.prior)%*%diag(1/diag(priors$V.prior))%*%(A.posterior[,,s]-priors$A.prior)))
    nu.kappa.bar          = priors$nu.kappa.prior + (K*N)
    kappa.draw            = s.kappa.bar/rchisq(1, df=nu.kappa.bar)
    kappa.posterior[s+1]  = kappa.draw
    }
  }
  
  posterior.extension = list(
    Sigma.posterior   = Sigma.posterior[,,S[1]+1:S[2]], #getting rid of first S[1] draws
    A.posterior       = A.posterior[,,S[1]+1:S[2]],
    kappa.posterior   = kappa.posterior[S[1]+1:S[2],1]
  )
  return(posterior.extension)
}

## Apply function BVAR_extension
posterior.draws = BVAR_extension(Y=Y, X=X, priors=priors, initial_kappa=initial_kappa, S=S)
round(apply(posterior.draws$Sigma.posterior, 1:2, mean),3)
round(apply(posterior.draws$A.posterior, 1:2, mean),3)
round(mean(posterior.draws$kappa.posterior),3)
round(apply(posterior.draws$kappa.posterior, 1, mean),3)





#########################################################
### Proof of the model

### Specify the setup
p = 1
N = 2
S = c(5000,100000)


### Generate RW data process
rw.1    = cumsum(rnorm(1000,0,1))
rw.2    = cumsum(rnorm(1000,0,1))
y       = matrix(cbind(rw.1,rw.2),nrow=1000,ncol=N)

### Create Y and X matrices
Y       = ts(y[2:nrow(y),])
X       = matrix(1,nrow(Y),1)
X       = cbind(X,y[1:nrow(y)-p,])

###########################################################
### Proof of basic model

### MLE
A.hat       = solve(t(X)%*%X)%*%t(X)%*%Y
Sigma.hat   = t(Y-X%*%A.hat)%*%(Y-X%*%A.hat)/nrow(Y)

### Specify the priors (Minnesota prior)
kappa.1           = 0.02^2
kappa.2           = 100
A.prior           = matrix(0,nrow(A.hat),ncol(A.hat))
A.prior[2:(N+1),] = diag(N)

priors = list(
  A.prior     = A.prior,
  V.prior     = diag(c(kappa.2,kappa.1*((1:p)^(-2))%x%rep(1,N))),
  S.prior     = diag(diag(Sigma.hat)),
  nu.prior    = N+1 
)

## Apply function BVAR
posterior.draws = BVAR(Y=Y, X=X, priors=priors, S=S)
round(apply(posterior.draws$Sigma.posterior, 1:2, mean),3)
round(apply(posterior.draws$A.posterior, 1:2, mean),3)
