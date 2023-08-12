# Miscellaneous Rtools that I find useful

#' Extract filename without extension.
#'
#' @description
#' Extract filename without extension. For '/a/b.c' returns 'b'.
#'
#' @param filename character, Full file name
#'
#' @return File name body without extension
#'
#' @examples
#' file_body('/a/b.c')
#'
#' @export
file_body <- function(filename){
  strsplit(basename(filename),'\\.')[[1]][1]
}


#' Get file extension from filename
#'
#' @description
#' Get file extension from filename. For '/a/b.c' returns 'c'.
#'
#' @param filename character, Full file name
#'
#' @return File extension from filename
#'
#' @examples
#' file_ext('/a/b.c')
#'
#' @export
file_ext <- function(filename){
  splits <- strsplit(basename(filename), '\\.')[[1]]
  splits[length(splits)]
}


#' CTAP/BWRC savename parsing
#'
#' @description
#' Parse a CTAP/BWRC casename, often used in filenames when saving data.
#'
#' @param fname character, Full file name
#'
#' @return A list of elements parsed from file name
#'
#' @export
parse.savename <- function(fname){

  fpath <- dirname(fname) #just path
  fname <- basename(fname) #filename only

  splits <- strsplit(fname,'_')[[1]]
  casename <- paste(splits[1:4], collapse = '_')
  notCasename <- paste(splits[5:length(splits)], collapse = '_')
  subject <- splits[1]
  part <- splits[2]
  session <- splits[3]
  measurement <- splits[4]
  task <- splits[5]
  erpid <- splits[6]

  list(path = fpath, filename = fname,
       casename = casename, notcasename = notCasename,
       subject = subject, part = part, session = session, measurement = measurement,
       task = task, erpid = erpid)
}


#' Circularly shift vector elements
#'
#' @description
#' To e.g. change the position of a peak within a series
#' positive n shifts things to the left, negative to the right
#'
#' From: http://stackoverflow.com/questions/30542128/circular-shifting-arrays-in-r-by-distance-n
#'
#' @param x [1,m] numeric, input data
#' @param n [1,1] ind, number of positions to shift,
#'          positive n shifts things to the left, negative to the right
#'
#' @return A shifted version of x
#'
#' @importFrom utils head
#' @importFrom utils tail
#'
#' @export
shifter <- function(x, n) {
  if (n == 0) x else c(utils::tail(x, -n), utils::head(x, n))
}


#' Transform a matrix into a ggplottable data.frame
#'
#' @description
#' Converts a numeric matrix into a ggplot compatible data.frame.
#'
#' @param dmat [n,m] numeric, input data matrix
#' @param dataset character, data set id string
#' @param variable2numeric logical, Should $variable be converted to numeric?
#'
#' @return A data.frame representation of dmat
#'
#' @importFrom reshape2 melt
#'
#' @export
make.ggplot.df <- function(dmat,
                           dataset = NULL,
                           variable2numeric = T){

  pd <- as.data.frame(dmat)

  if ( !is.null(dimnames(dmat)) ){
    pd$row <- dimnames(dmat)[[1]]
  } else {
    pd$row <- 1:nrow(pd)
  }
  pd <- reshape2::melt(pd, id.vars = c('row'))

  if (variable2numeric){
    pd$variable <- as.numeric(as.character(pd$variable))
  }

  if (!is.null(dataset)){
    pd$dataset = dataset
    pd$dsrow = paste0(dataset, '_r', as.character(pd$row))
  }
  pd
}


#' Detect substring and replace if there is a match
#'
#' @description
#' Replaces elements in character vector 'string' with elements found in
#' 'replacement', if the element matches one of the patterns in
#' 'pattern'. Matches of pattern[i] are replaced with replacement[i].
#'
#' Intended usage is to convert a vector of path strings into a vector
#' of class labels.
#'
#' @param string Input vector. Either a character vector, or something coercible to one.
#' @param pattern Vector of patterns to look for. See stringr::str_which() for details.
#' @param replacement Vector of replacement strings. Has to be of the same length as pattern.
#'
#' @return A character vector.
#'
#' @importFrom stringr str_which
#'
#' @export
mystr_detect_replace <- function(string, pattern, replacement = pattern){

  out <- string

  for (i in 1:length(pattern)) {
    out[stringr::str_which(string, pattern[[i]])] <- replacement[[i]]
  }

  out
}
