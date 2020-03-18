


load.chan.features <- function(src.dir = '/ukko/projects/ReKnow/Data/processed/CENT/channel_rejections'){
  require(R.matlab)

  ## Load all channel properties into a single df
  mfile.arr <- dir(src.dir)
  all.chanprop <- data.frame()
  for (mfile in mfile.arr) {
    d <- R.matlab::readMat(file.path(src.dir, mfile))
    df <- data.frame(scale(d$data))
    #df <- data.frame(d$data)
    names(df) <- d$dim[[4]]
    df$channel <- factor(as.character(d$dim[[2]]))
    df$casename <- gsub("_chanprop.mat","",mfile)
    df$sbjnumber <- as.character(lapply(strsplit(df$casename,"_"), function(x){x[[2]]})) #pick what follows "_"
    df$sbjnumber <- as.integer(sub("[[:alpha:]]+","", df$sbjnumber)) #remove trailing letters
    all.chanprop <- rbind(all.chanprop,df)
  }
  return(all.chanprop)
}


robust.maha.dst <- function(df, features){
  # Compute robust mahalanobis distance (median and MCD)
  require(MASS)
  require(stats)
  cov.mcd <- MASS::cov.rob(df[,features])
  maha.dst <- stats::mahalanobis(df[,features],
                                 center=apply(df[,features],2,median),
                                 cov=cov.mcd$cov,
                                 inverted=F)
  return(maha.dst)
}

dstvec.getrange.density <- function(dstvec, tail.prc=0.05){
  # Note: currently right tail only!
  require(stats)
  require(sfsmisc)
  
  maha.den <- stats::density(dstvec, bw="SJ")

  #interval1 <- c(0, median(maha.dst)/2)
  interval2 <- c(median(dstvec), max(dstvec))
  ur2 <- stats::uniroot(
    function(x){sfsmisc::integrate.xy(maha.den$x,maha.den$y,min(maha.den$x),x)/sfsmisc::integrate.xy(maha.den$x,maha.den$y)-(1-tail.prc)},
    interval2)

  return(list(den=maha.den, normal.data.range=c(0,ur2$root)))
}


plot.dstdist.density <- function(dstvec, den, data.range=NULL, xlim=NULL){
  if (is.null(xlim)){
    xlim <- c(0, max(dstvec))
  }
  plot(den, xlim=xlim)
  lines(c(data.range[1], data.range[1]), c(0, max(den$y)), col="red")
  lines(c(data.range[2], data.range[2]), c(0, max(den$y)), col="red")
}


th.isextreme.match <- function(dstvec, data.range){
  good.chan.match <- (data.range[1] <= dstvec) & (dstvec <= data.range[2])
  bad.chan.match <- !good.chan.match
  cat(sprintf("rejection percentage: %1.1f", sum(bad.chan.match)/length(dstvec)*100))
  is.extreme <- rep(F, length(dstvec))
  is.extreme[bad.chan.match] <- T
  return(is.extreme)
}


create.meas.info <- function(chanprop.df, nchan.th=c(3,8)){
  tb <- xtabs(~ casename + is.extreme, data=chanprop.df)
  meas.info <- data.frame(casename=dimnames(tb)[[1]], n.extreme.chans=tb[,2])
  rownames(meas.info)<-NULL

  meas.info$qclass <- 1
  meas.info$qclass[(nchan.th[1]<meas.info$n.extreme.chans) & (meas.info$n.extreme.chans<nchan.th[2])] <- 2
  meas.info$qclass[nchan.th[2]<=meas.info$n.extreme.chans] <- 3
  meas.info$qclass <- ordered(meas.info$qclass, levels=1:3, labels=c("good","moderate","poor"))

  return(meas.info)
}





