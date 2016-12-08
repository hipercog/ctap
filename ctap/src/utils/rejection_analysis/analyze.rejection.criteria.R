## Observations
# * none of the features are normal: either fat tails or skewness
# * the mahalanobis distances start a bit like chi-squared but have fatter tail to the right
# * robust statistics should be used throughout
# * problem: mvoutlier channels are not the same as marked by humans in BrokenElectrodes.txt.
#   Fix at least the totally broken electrodes which are interpolated (?). What other reasons?
#   Maybe too little removed in total. Try tail.prc=0.05 identification at subject level.


source("./tools.R")

# Load channel properties
all.chanprop <- load.chan.features()

# Compute mahalanobis disntances
features <- c("corr","var","Hexp")
maha.dst.allchan <- robust.maha.dst(all.chanprop, features)

# Identify outliers
dr <- dstvec.getrange.density(maha.dst.allchan, tail.prc=0.05)
plot.dstdist.density(maha.dst.allchan, dr$den, data.range=dr$normal.data.range, xlim=c(0,100))
all.chanprop$is.extreme <- th.isextreme.match(maha.dst.allchan, dr$normal.data.range)
meas.info <- create.meas.info(all.chanprop, nchan.th=c(3,8))

# Identify outlier from subsets of data
dr.list <- list()
for (cl in levels(meas.info$qclass)){
  cat(sprintf("processing qclass: %s\n", cl))
  casename.arr <- subset(meas.info, qclass==cl)$casename
  all.chan.match <- all.chanprop$casename %in% casename.arr
  dr.list <- c(dr.list,
               list(dstvec.getrange.density(maha.dst.allchan[all.chan.match], tail.prc=0.05)))
#   plot.dstdist.density(maha.dst.allchan[all.chan.match], dr$den, 
#                        data.range=dr$normal.data.range, xlim=c(0,100))
#   readline(prompt="Press [enter] to continue")
}


## Compare mvoutlier bad channels to visually detected ones
# Load bad electrode info
srcfile = '~/work/bitbucket/ctap-pipeline/CENT/BrokenElectrodes.txt'
be <- read.table(file=srcfile, header=T, sep="\t", stringsAsFactors=F)
xtabs(~Name + Pre0.Post1, data=be)
be <- subset(be, Pre0.Post1==0)

# compare
require(plyr)
compute.match <- function(cp, be){
  # testing:
#   bad.chan.saliency <- subset(be, Name==1041)$Saliency
#   cp <- subset(all.chanprop, sbjnumber==1041)
  bad.chan.saliency <- subset(be, Name==unique(cp$sbjnumber))$Saliency
  bad.chan.saliency <- gsub("[[:blank:]]+","",bad.chan.saliency)
  bad.chan.saliency <- unlist(strsplit(bad.chan.saliency, ","))
  n.agree <- sum(cp$channel[cp$is.extreme] %in% bad.chan.saliency)
  return(data.frame(sbj=unique(cp$sbjnumber),
                    n.agree=n.agree,
                    ntot.mv=sum(cp$is.extreme),
                    agree.prc.mv=n.agree/sum(cp$is.extreme)*100,
                    ntot.txt=length(bad.chan.saliency),
                    agree.prc.txt=n.agree/length(bad.chan.saliency)*100))
}
res <- plyr::ddply(all.chanprop, .(sbjnumber), compute.match, be=be)
hist(res$agree.prc.mv, breaks=50)
hist(res$agree.prc.txt, breaks=50)




#==================================================================================================
## Experimental versions of the above
library(R.matlab)


## Setup
src.dir = '/ukko/projects/ReKnow/Data/processed/CENT/channel_rejections'
test.file = file.path(src.dir, '20121106_2001C_chanprop.mat')

## Load all channel properties into a single df
mfile.arr <- dir(src.dir)
#mfile.arr <- mfile.arr[1:2]
all.chanprop <- data.frame()
for (mfile in mfile.arr) {
  d <- R.matlab::readMat(file.path(src.dir, mfile))
  df <- data.frame(scale(d$data))
  #df <- data.frame(d$data)
  names(df) <- d$dim[[4]]
  df$channel <- factor(as.character(d$dim[[2]]))
  df$casename <- gsub("_chanprop.mat","",mfile)
  
  all.chanprop <- rbind(all.chanprop,df)
}
features <- c("corr","var","Hexp")
str(all.chanprop)

## Identify outliers using Mahalanobis distance
cov.mcd <- MASS::cov.rob(all.chanprop[,features])
maha.dst <- stats::mahalanobis(all.chanprop[,features],
                               center=apply(all.chanprop[,features],2,median),
                               cov=cov.mcd$cov,
                               inverted=F)

## Visualize feature data
hist(all.chanprop[,1], breaks=1000)
hist(all.chanprop[,2], breaks=1000)
hist(all.chanprop[,3], breaks=1000)
apply(all.chanprop[,features],2,median)
colMeans(all.chanprop[,features])

stats::shapiro.test(all.chanprop[,1])
stats::shapiro.test(all.chanprop[,2])
stats::shapiro.test(all.chanprop[,3])


## Check the distribution of the mahalanobis values
csd <-scale(rchisq(length(maha.dst),3)) #chi-square distribution
d <- scale(maha.dst)
rob.scale <- function(x){
  (x-median(x))/stats::mad(x)
}
d <- rob.scale(maha.dst)
#d <- csd

qqplot(d, csd, xlim=c(0,10))
qqline(d, distribution = function(p) qchisq(p, df = 3),
       prob = c(0.1, 0.6), col = 2)

#par(mfrow=c(2,1)) #does not work well with RStudio
layout(matrix(c(1,2), 1, 2, byrow = TRUE)) #almost works with RStudio
binsq <- seq(min(csd), max(d)+1, 0.1)
hist(csd, breaks=binsq, xlim=c(0,10), ylim=c(0,200))
hist(d, breaks=binsq, xlim=c(0,10), ylim=c(0,200))

dist.compare.hist <- function(d1,d2,labels){
  require(ggplot2)
  df <- data.frame(value=c(d1, d2), 
                   ds=c(rep(labels[1],length(d1)), rep(labels[2],length(d2))) )
  binsq <- seq(min(df$value), max(df$value), 0.1)
  p <- ggplot(df, aes(x=value, fill=ds))
  p <- p + geom_bar(position="dodge", breaks=binsq) # defaults to stacking
  p <- p + scale_x_continuous(limits=c(0,10))
  print(p)
}
dist.compare.hist(csd, d, c("chisq","maha"))



# 1: Tails with normality assumption & robust location/scale estimation
# pros:
# * familiar
# cons:
# * the data is not normal for sure
hist(maha.dst, breaks=1000, xlim=c(0,100))
maha.mcd <- MASS::cov.rob(maha.dst)
tail.prc <- 0.05
good.data.range <- c(stats::qnorm(tail.prc/2, sd=sqrt(maha.mcd$cov)),
              stats::qnorm(1-(tail.prc/2), sd=sqrt(maha.mcd$cov))) + median(maha.dst)


# 2: Tails using kernel density estimate
# pros:
# * no distribution assumptions
# cons:
# * amount of probability mass in right-tail is dependent on density estimation parameters
#   -> a new parameter and threshold selection problem 

plot(stats::density(maha.dst))
plot(stats::density(maha.dst, bw="SJ"))
plot(stats::density(maha.dst), xlim=c(0,100))
require(sfsmisc)


maha.den <- stats::density(maha.dst, bw="SJ")

tail.prc=0.05
#interval1 <- c(0, median(maha.dst)/2)
#ur1 <- uniroot(function(x){integrate.xy(maha.den$x,maha.den$y,0,x)-(tail.prc/2)}, interval1)
#integrate.xy(maha.den$x,maha.den$y,0,ur1$root)
interval2 <- c(median(maha.dst), max(maha.dst))
ur2 <- stats::uniroot(function(x){sfsmisc::integrate.xy(maha.den$x,maha.den$y,0,x)/sfsmisc::integrate.xy(maha.den$x,maha.den$y)-(1-tail.prc)}, interval2)
#integrate.xy(maha.den$x,maha.den$y,0,ur2$root)
#integrate.xy(maha.den$x,maha.den$y,40,max(maha.den$x))
good.data.range <- c(0,ur2$root)

plot(maha.den, xlim=c(0,100))
#plot(maha.den)
lines(c(ur2$root, ur2$root), c(0, max(maha.den$y)), col="red")


# 3: Hampel identifier = 3 sigma rule with median and MAD
# pros: 
# * ends up with a threshold that matches the visual inspection
# cons:
# * too simple?
# * too heuristic?
good.data.range <- c(0,median(maha.dst)+3*stats::mad(maha.dst))


# 4: Manual definition
good.data.range <- c(0,30)



## Apply thresholds
good.chan.match <- (good.data.range[1] <= maha.dst) & (maha.dst <= good.data.range[2])
bad.chan.match <- !good.chan.match
sum(bad.chan.match)/length(maha.dst)*100
all.chanprop$is.extreme <- bad.chan.match

tb <- xtabs(~ casename + is.extreme, data=all.chanprop)
sbj.info <- data.frame(casename=dimnames(tb)[[1]], n.extreme.chans=tb[,2])
rownames(sbj.info)<-NULL
str(sbj.info)
sbj.info$qclass <- 1
sbj.info$qclass[(3<sbj.info$n.extreme.chans) & (sbj.info$n.extreme.chans<8)] <- 2
sbj.info$qclass[8<=sbj.info$n.extreme.chans] <- 3
sbj.info$qclass <- ordered(sbj.info$qclass, levels=1:3, labels=c("good","moderate","poor"))
str(tb)
hist(tb[,2])


feat = 1
data = all.chanprop[good.chan.match,feat]
#data = all.chanprop[bad.chan.match,feat]
#data = all.chanprop[,feat]

plot(1:length(data), data)
d2 = all.chanprop[bad.chan.match,feat]
points(1:length(d2),d2, col="red")

hist(data, breaks=500)

stats::qqnorm(data)
stats::qqline(data)
shapiro.test(data)


## Examine
#dmat <- as.matrix(all.chanprop[,features])

# plot3d
require(rgl)
rgl::plot3d(all.chanprop$corr[good.chan.match], all.chanprop$var[good.chan.match], all.chanprop$Hexp[good.chan.match], col="blue",
       xlab="", ylab="", zlab="")
rgl::plot3d(all.chanprop$corr[bad.chan.match], all.chanprop$var[bad.chan.match], all.chanprop$Hexp[bad.chan.match], col="red", add=T,
       xlab="", ylab="", zlab="")


# GGobi
#require('rggobi')
#ggobi(all.chanprop)

## Testing
# d <- readMat(test.file)
# str(d$data)
# str(d$dim)

