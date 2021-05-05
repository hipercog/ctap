## ----
# Functions to generate Maximum Width Envelope analysis
# from K. Puolamäki, B.Cowley, and T.Tammi
#
# version 04.2021


#' Priority queue
#'
#' @param p order of column, i.e., output of order (x)
#' 
#' @return Lexical closure which contains the following O(1) methods:
#'  $first(), $second(), $last(), $last2(), and $remove(i) as documented
#'  in Korpela et al. (2014), appendix A.
#'  
#' @export
PQ <- function(p) {
  n <- length(p)
  idx <- 1+order(p)  # index at which item i can be found
  p <- c(NA,p,NA)      # head is at p[1] and tail at p[n+2]
  nxt <- c(2:(n+2),NA) # pointer to next
  prv <- c(NA,1:(n+1)) # pointer to previous
  first <- function() p[nxt[1]]
  second <- function() p[nxt[nxt[1]]]
  last <- function() p[prv[n+2]]
  last2 <- function() p[prv[prv[n+2]]]
  history <- rep(NA,n)
  pos <- maxpos <- 0
  remove <- function(i) {
    pos <<- maxpos <<- pos+1 # update position
    history[pos] <<- i       # add this to history
    j <- idx[i]
    prv[nxt[j]] <<- prv[j] # previous of the next is previous of the current 
    nxt[prv[j]] <<- nxt[j] # next of the previous is next of the current
    pos
  }
  ## remove/unremove previously removed items. This is not really needed
  ## but costs nothing to include here at this stage...
  goto <- function(newpos) { 
    if(newpos<pos) { # go backward
      for(i in pos:(newpos+1)) {
        j <- idx[history[i]]
        prv[nxt[j]] <<- j # unremove
        nxt[prv[j]] <<- j # unremove
      }
    } else if(newpos>pos) { # go forward
      for(i in pos:(newpos-1)) {
        j <- idx[history[i]]
        prv[nxt[j]] <<- prv[j] # remove
        nxt[prv[j]] <<- nxt[j] # remove
      }
    }
    pos <<- newpos
    pos
  }
  show <- function() list(idx=idx,p=p,nxt=nxt,prv=prv,pos=pos,
                          history=if(maxpos==0) c() else history[1:maxpos]) # for debugging
  list(first=first,second=second,last=last,last2=last2,remove=remove,goto=goto,show=show)
}


#' Finds MWE efficiently using separate validation data as documented in Korpela et al.
#' (2014). The algorithm has time complexity of O(m*n*log(n)), where m is the length of 
#' time series and n is the rows in the training data or validation data, whichever is
#' larger.
#' 
#' @param max_k integer, maximum value of k searched
#' 
#' @param max_alpha real number, fraction of validation data samples out of MWE
#' 
#' @param data_tr nXm matrix, training data
#' 
#' @param data_va n'Xm matrix, validation data
#' 
#' @return Returns a list that contains number of time series removed k, final alpha 
#'  (should be the largest alpha which is at most max_alpha), and lower and upper 
#'  bounds.
#'  
#' @export
find_mwe <- function(max_k,max_alpha,data_tr,data_va) {
  m <- dim(data_tr)[2]
  # use priority queues for both training and validation set. This finds it efficient
  # to find the largest and smallest non-removed curves.
  q_tr <- apply(data_tr,2,function(x) PQ(order(x))) 
  q_va <- apply(data_va,2,function(x) PQ(order(x)))
  lo0 <- up0 <- NULL
  k <- alpha <- -1
  removed <- 0
  while(k<max_k && removed/dim(data_va)[1]<=max_alpha) {
    idx <- matrix(c(rep(1:m,2),
                    sapply(q_tr,function(q) q$first()), sapply(q_tr,function(q) q$last()),
                    sapply(q_tr,function(q) q$second()),sapply(q_tr,function(q) q$last2())),2*m,3)
    lo <- data_tr[idx[  1:m ,c(2,1)]] # current lower envelope
    up <- data_tr[idx[-(1:m),c(2,1)]] # current upper envelope
    for(i in 1:m) { # column/time index i
      j <- q_va[[i]]$first() # index of the smallest item in validation set
      while(data_va[j,i]<lo[i] && removed/dim(data_va)[1]<=max_alpha) { 
        ## remove if below lower limit
        sapply(q_va,function(q) q$remove(j))
        j <- q_va[[i]]$first()
        removed <- removed+1
      }
      j <- q_va[[i]]$last() # index of the largest item in validation set
      while(up[i]<data_va[j,i] && removed/dim(data_va)[1]<=max_alpha) { 
        ## remove if above upper limit
        sapply(q_va,function(q) q$remove(j))
        j <- q_va[[i]]$last()
        removed <- removed+1
      }
    }
    if(removed/dim(data_va)[1]<=max_alpha) {
      lo0 <- lo
      up0 <- up
      k <- k+1
      alpha <- removed/dim(data_va)[1]
      
      ## greedy MWE algorithm: remove time series which decreases the MWE most:
      a <- aggregate(x=data.frame(gain=abs(data_tr[idx[,c(2,1)]]-data_tr[idx[,c(3,1)]])),
                     by=list(i=idx[,2]),
                     FUN=sum)
      j <- a[which.max(a[,"gain"]),"i"]
      sapply(q_tr,function(q) q$remove(j))
    }
  }
  list(k=k,alpha=alpha,lo=lo0,up=up0)
}


#' Apply the find_mwe() and return dataframe of CBs and CIs
#'
#' @description
#' Apply find_mwe() to a data matrix, and return dataframe of means, MWE confidence bands, and 1-alpha confidence intervals
#'
#' @param data [n,m] numeric, input data
#'
#' @param mtr numeric, number of training resamples
#'
#' @param mva numeric, number of validation resamples
#'
#' @param alpha numeric, value of alpha
#'
#' @param signflip boolean, ...
#'
#' @return dataframe of colMeans plus upper and lower MWE confidence bands, plus 1-alpha confidence intervals
#'
#' @examples
#' findcurves(curvematrix, alpha = a)
#'
#' @export
findcurves <- function(data,mtr=5000,mva=5000,alpha=0.05,signflip=FALSE) {
  n <- dim(data)[1]
  m <- dim(data)[2]
  if(signflip) {
    samples_tr <- t(replicate(mtr,colMeans((sample(c(-1,1),size=n,replace=TRUE) %o% rep(1,m))*data)))
    samples_va <- t(replicate(mva,colMeans((sample(c(-1,1),size=n,replace=TRUE) %o% rep(1,m))*data)))
  } else {
    samples_tr <- t(replicate(mtr,colMeans(data[sample.int(n,replace=TRUE),]))) # training set
    samples_va <- t(replicate(mva,colMeans(data[sample.int(n,replace=TRUE),]))) # validation set
  } 
  a <- find_mwe(mtr-2,alpha,samples_tr,samples_va)
  q <- apply(samples_tr,2,function(x) quantile(x,probs=c(alpha/2,1-alpha/2)))
  data.frame(mean0=colMeans(data),lo=a$lo,up=a$up,k=a$k,alpha=a$alpha,lo0=q[1,],up0=q[2,])
}


#' Apply findcurves() to a dataframe of ERPs and return MWEs
#'
#' @description
#' Wrangle dataframe to matrix and apply findcurves(), to return dataframe of MWEs by group and ERP 
#'
#' @param df dataframe, input data
#'
#' @param timep numeric, timepoints to calculate for
#'
#' @param grp string, participant groups in the dataframe
#'
#' @param erp string, ERP ids
#'
#' @param alpha numeric, value of alpha
#'
#' @return dataframe grouping findcurves dataframes by group and ERPs::
#'   colMeans plus upper and lower MWE confidence bands, plus 1-alpha confidence intervals
#'
#' @examples
#' findcurves(curvematrix, alpha = a)
#'
#' @export
find_erp_curves <- function(df, timep, grp, erp, alpha = 0.05) {
  
  a = alpha
  print(paste(timep, grp, erp))
  
  #data to wide
  dat <- get(df) %>%
    filter(group == grp, erpid == erp, timept == timep) %>%
    select(sbj, time, sbj_mean) %>%
    pivot_wider(names_from = time, values_from = sbj_mean) %>%
    dplyr::select(-sbj)
  
  idx <- which(apply(dat,2,function(x) all(!is.na(x))))  
  
  curvematrix <- as.matrix(dat[,idx])
  
  curve <- tryCatch(findcurves(curvematrix, alpha = a), error=function(e) data.frame(timep, grp, erp))
  
  curve <- curve %>%
    rownames_to_column('time') %>%
    mutate(time = as.numeric(time))
  
  curve %>%
    mutate(group = grp,
           timept = timep,
           erpid = erp)
}


#' Base R line plotting useful for MWEs
#'
#' @description
#' Base R line plotting of MWE dataframe with mean, MWE confidence bands, and 1-alpha confidence intervals
#'
#' @param x dataframe, input data
#'
#' @param tvec numeric, time on x axis, how much of MWE to plot
#'
#' @param CI boolean, plot CIs or not
#'
#' @export
plotlines <- function(x, tvec, ..., CI=TRUE) {
  lines(tvec,x[,"lo0"],lty="dotted",...)
  lines(tvec,x[,"up0"],lty="dotted",...)
  if (CI) {
    lines(tvec,x[,"lo"],lty="dashed",lwd=1.5,...)
    lines(tvec,x[,"up"],lty="dashed",lwd=1.5,...)
  }
  lines(tvec,x[,"mean0"],lty="solid",lwd=1.5,...)
}


#' ggplot2 line plotting for ERP MWEs
#'
#' @description
#' ggplot2 line plotting for lsit of ERP MWE dataframes with mean, MWE confidence bands, and 1-alpha confidence intervals
#'
#' @param curve_list list, input data
#'
#' @param curve_colors vector, hexadecimal strings for two curve colors for MWE and CI respectively
#'
#' @param grp string, participant groups in the dataframe
#'
#' @param erp string, ERP ids
#'
#' @param ylims vector, set manual y limits of the plots
#'
#' @param ymirror boolean, if finding ylims from data, set TRUE to have equal min/max, or FALSE to use data's range
#'
#' @param ybreakstep numeric, size of y axis breaks for ticks, centred on zero
#'
#' @export
plot_ci_one <- function(curve_list, curve_colors = c('#0072B2', '#D55E00'), grp = NA, erp = NA, ylims = NA, ymirror = FALSE, ybreakstep = 5) {
  
  alldata <- bind_rows(curve_list)
  
  if (!is.na(grp)){
    alldata <- filter(alldata, grp)
  }
  if (!is.na(erp)){
    alldata <- filter(alldata, erp)
  }
  
  if (is.na(ylims)){
    if (ymirror){
      ylims = max(abs(min(alldata$lo)), max(alldata$up))
      ylims = c(-ylims, ylims)
    }else{
      ylims = c(min(alldata$lo), max(alldata$up))
    }
  }
  ybreaks = seq(ylims[1] + abs(ylims[1])%%ybreakstep, ylims[2], ybreakstep)
  
  p <- alldata %>%
    ggplot(aes(time, group = interaction(timept, group, erpid), colour = timept)) +
    geom_vline(aes(xintercept=0), alpha=.8) +
    geom_hline(aes(yintercept=0), alpha=.8) +
    geom_line(aes(y = mean0)) +
    geom_ribbon(aes(ymin = lo, ymax = up, fill = timept), alpha=0.2, colour = NA) +
    geom_ribbon(aes(ymin = lo0, ymax = up0), alpha=0, linetype = 'dotted', show.legend = F)  + 
    facet_grid(erpid~group) +
    scale_y_reverse(limits = ylims, breaks = ybreaks) +
    scale_x_continuous(breaks = c(-50, 0, 200, 400), guide = guide_axis(angle = 20)) +
    labs(y = "Amplitude (\U003BCV)",
         x = "Time (ms)") + 
    theme_minimal() + 
    theme(
      text = element_text(size=12),
      axis.title = element_text(size=11),
      axis.text = element_text(size=9),
      legend.text = element_text(size=11),
      strip.text = element_text(size=11),
      legend.title = element_blank(), 
      panel.border = element_blank(),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      legend.position='right', 
      legend.justification='top',
      legend.direction='vertical') +
    scale_color_manual(values = curve_colors) +
    scale_fill_manual(values = curve_colors)  
  
  p
}


#### Example usage: find curves for a set of ERPs and plot them ----
# vars_melody <- expand_grid(df = 'erp_data_Fz',
#                            var1 = c('Pre', 'Post'), 
#                            var2 = c('Control', 'English', 'Music'), 
#                            var3 = c('Key', 'Melody', 'Rhythm', 'Timbre', 'Mistuning'))
# # find melody curves
# curves_melody <- mapply(find_erp_curves, vars_melody$df, vars_melody$var1, vars_melody$var2, vars_melody$var3, SIMPLIFY = F, USE.NAMES = F)
# # plot the curves
# plots <- lapply(curves_melody_alpha, plot_ci_one)