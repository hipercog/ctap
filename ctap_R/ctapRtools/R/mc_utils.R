## Utilities to read CTAP measurement config information


#' Load CTAP MC file contents
#'
#' @description
#' Load CTAP MC file contents
#'
#' @param mc_file character, Full path to the MC file
#' @param measurement_sheet character, Name of sheet that lists measurements
#' @param subject_sheet character, Name of sheet that lists subjects
#' @param blocks_sheet character, Name of sheet that lists blocks
#'
#' @return A list with elements
#'         file: mc_file
#'         subject: subject_sheet contents as tibble
#'         measurement: measurement_sheet contents as tibble
#'         blocks: blocks_sheet contents as tibbble
#'
#' @export
load_ctap_mc <- function(mc_file,
                                 measurement_sheet = 'mc',
                                 subject_sheet = 'subject',
                                 blocks_sheet = 'blocks'){

  subject <- load_ctap_mc_subject(mc_file, subject_sheet)
  measurement <- load_ctap_mc_measurement(mc_file, measurement_sheet)
  blocks <- load_ctap_mc_blocks(mc_file, blocks_sheet)

  # if (autofactors){
  #   meas <- create_factors(meas, OPTS, col.names = c('crew','role','part'))
  #   subject <- create_factors(subject, OPTS, col.names = c('role'))
  #   if (block.sheet.name == 'blocks_event'){
  #     blocks <- create_factors(blocks, OPTS, col.names = c('task'))
  #   }
  # }

  list(file = mc_file,
       subject = subject,
       measurement = measurement,
       blocks = blocks)
}


#' Load CTAP MC subject sheet/table
#'
#' @description
#'  Load CTAP MC subject sheet/table. File can be xlsx or sqlite.
#'
#' @param mc_file character, Full path to the MC file
#' @param subject_sheet character, Name of sheet that lists subjects
#'
#' @return A tibble with the contents of the subject_sheet sheet/table
#'
#' @importFrom tibble as_tibble
#' @importFrom xlsx read.xlsx2
#' @importFrom DBI dbConnect
#' @importFrom DBI dbGetQuery
#' @importFrom DBI dbDisconnect
#' @importFrom RSQLite SQLite
#'
#' @export
load_ctap_mc_subject <- function(mc_file, subject_sheet){

  mc_ext <- file_ext(mc_file)
  if (mc_ext == 'xlsx'){
    subject <- xlsx::read.xlsx2(mc_file,
                                sheetName = subject_sheet,
                                stringsAsFactors = F)
    # colIndex = 1:9 -> need to select columns to load: otherwise loads all 1024 columns...

  } else if (mc_ext == 'sqlite'){

    # connect to the sqlite file
    con = DBI::dbConnect(RSQLite::SQLite(), dbname = mc_file)

    # get the populationtable as a data.frame
    qry <- sprintf('select * from %s', subject_sheet)
    subject = DBI::dbGetQuery(con, qry)
    DBI::dbDisconnect(con)
  }

  subject <- tibble::as_tibble(subject)

  subject
}


#' Load CTAP MC measurement sheet/table
#'
#' @description
#'  Load CTAP MC measurement sheet/table. File can be xlsx or sqlite.
#'
#' @param mc_file character, Full path to the MC file
#' @param measurement_sheet character, Name of sheet that lists measurements
#' @param dateformat character, Format for the date column
#'
#' @return A tibble with the contents of the measurement_sheet sheet/table
#'
#' @importFrom tibble as_tibble
#' @importFrom xlsx read.xlsx2
#' @importFrom DBI dbConnect
#' @importFrom DBI dbGetQuery
#' @importFrom DBI dbDisconnect
#' @importFrom RSQLite SQLite
#'
#' @export
load_ctap_mc_measurement <- function(mc_file,
                               measurement_sheet,
                               dateformat = '%d.%m.%Y'){


  mc_ext <- file_ext(mc_file)
  if (mc_ext == 'xlsx'){
    measurement <- xlsx::read.xlsx2(mc_file,
                                    sheetName = measurement_sheet,
                                    stringsAsFactors = F)

  } else if (mc_ext == 'sqlite'){

    # connect to the sqlite file
    con = DBI::dbConnect(RSQLite::SQLite(), dbname = mc_file)

    # get the populationtable as a data.frame
    qry <- sprintf('select * from %s', measurement_sheet)
    measurement = dbGetQuery(con, qry)
    DBI::dbDisconnect(con)
  }


  measurement <- tibble::as_tibble(measurement)
  measurement$date <- as.Date(measurement$date, dateformat)

  measurement
}


#' Load CTAP MC blocks sheet/table
#'
#' @description
#'  Load CTAP MC blocks sheet/table. File can be xlsx or sqlite.
#'
#' @param mc_file character, Full path to the MC file
#' @param blocks_sheet character, Name of sheet that lists blocks
#' @param timeformat character, Format string for time fields
#' @param tz character, Time zone to use
#'
#' @return A tibble with the contents of the blocks_sheet sheet/table
#'
#' @importFrom tibble as_tibble
#' @importFrom xlsx read.xlsx2
#' @importFrom DBI dbConnect
#' @importFrom DBI dbGetQuery
#' @importFrom DBI dbDisconnect
#' @importFrom RSQLite SQLite
#'
#' @export
load_ctap_mc_blocks <- function(mc_file,
                          blocks_sheet,
                          timeformat = "%Y%m%dT%H%M%S",
                          tz = 'UTC'){


  mc_ext <- file_ext(mc_file)
  if (mc_ext == 'xlsx'){
    blocks <- xlsx::read.xlsx2(mc_file,
                               sheetName = blocks_sheet,
                               stringsAsFactors = F)

  } else if (mc_ext == 'sqlite'){

    # connect to the sqlite file
    con = DBI::dbConnect(RSQLite::SQLite(), dbname = mc_file)

    # get the populationtable as a data.frame
    qry <- sprintf('select * from %s', blocks_sheet)
    blocks = dbGetQuery(con, qry)
    DBI::dbDisconnect(con)
  }

  blocks <- tibble::as_tibble(blocks)

  blocks$starttime <-
    as.POSIXct( strptime(as.character(blocks$starttime), timeformat),
                tz = tz)
  blocks$stoptime <-
    as.POSIXct( strptime(as.character(blocks$stoptime), timeformat),
                tz = tz)

  blocks
}
