#' See how many hits there are for a given term across all NCBI Entrez databses
#'
#' 
#'
#'@export
#'@param term the search term to use
#
#'@return a named vector with counts for each a datbase
#' @examples
#' 
#' NCBI_data_on_best_butterflies_ever <- entrez_global_query(term="Heliconius")

entrez_global_query <- function(term){
    args <- c(term=gsub(" ", "+", term),email=entrez_email, tool=entrez_tool)
    url_args <- paste(paste(names(args), args, sep="="), collapse="&")
    base_url <- "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/egquery.fcgi?retmode=xml"
    url_string <- paste(base_url, url_args, sep="&")
    record <- xmlTreeParse(url_string, useInternalNodes=TRUE, isURL=TRUE)
    db_names <- xpathSApply(record, "//ResultItem/DbName", xmlValue)
    get_Ids <- function(dbname){
        path <-  paste("//ResultItem/DbName[text()='", dbname, "']/../Count", sep="")
        res <- as.numeric(xpathSApply(record, path, xmlValue))
    }
    #NCBI limits requests to three per second
    Sys.sleep(0.33)
    res <- structure(sapply(db_names, get_Ids), names=db_names)
    return(res)
}
