#' Get summaries of objects in NCBI datasets from a unique ID 
#'
#' Contstructs a query from the given arguments, including a database name and
#' list of of unique IDs for that database then downloads the XML document 
#' created by that query. The XML document is parsed, with the 
#'
#'@export
#'@param db character Name of the database to search for
#'@param \dots character Additional terms to add to the request. Requires either
#'   id (unique id(s) for records in a given database) or WebEnv (a character
#'   containing a cookie created by a previous entrez query).
#'@param config vector configuration options passed to httr::GET  
#'@seealso \code{\link[httr]{config}} for avaliable configs 
#'@return A list of esummary records (if multiple IDs are passed) or a single
#' record.
#'@return file XMLInternalDocument xml file resulting from search, parsed with
#'\code{\link{xmlTreeParse}}
#'@import XML
#' @examples
#'
#'  pop_ids = c("307082412", "307075396", "307075338", "307075274")
#'  pop_summ <- entrez_summary(db="popset", id=pop_ids)
#'  sapply(pop_summ, "[[", "Title")
#'  
#'  # clinvar example
#'  res <- entrez_search(db = "clinvar", term = "BRCA1")
#'  cv <- entrez_summary(db="clinvar", id=res$ids)
#'  cv[[1]] # get the names of the list for each result
#'  sapply(cv, "[[", "title") # titles
#'  lapply(cv, "[[", "trait_set")[1:2] # trait_set
#'  sapply(cv, "[[", "gene_sort") # gene_sort

entrez_summary <- function(db, config=NULL, ...){
    response  <- make_entrez_query("esummary", db=db, config=config,
                                    require_one_of=c("id", "WebEnv"), ...)
    whole_record <- xmlTreeParse(response, useInternalNodes=TRUE)
    if(db == 'clinvar'){
      rec <- lapply(whole_record["//DocumentSummary"], parse_esummary_clinvar)
    } else {
      rec <- lapply(whole_record["//DocSum"], parse_esummary)      
    }
    if(length(rec) == 1){
        return(rec[[1]])
    }
    class(rec) <- c("multiEsummary", class(rec))
    return(rec)
}

#' @export 

print.esummary <- function(x, ...){
    len <- length(x)
    cat(paste("esummary result with", len - 1, "items:\n"))
    print(names(x)[-len])
}

#' @export 
print.multiEsummary <- function(x, ...){
    len <- length(x)
    cat(paste ("list of ", len, "esummary records\n"))
}


# Prase a sumamry XML 
#
# Logic goes like this
# 1. Define functions parse_esumm_* to handle all data types
# 2. For each node detect type, parse accordingly
# 3. wrap it all up in function parse_esummary that 
#
#

parse_esummary <- function(record){
    res <- xpathApply(record, "Item", parse_node)
    names(res) <- xpathApply(record, "Item", xmlGetAttr, "Name")
    res <- c(res, file=record)
    class(res) <- c("esummary", class(res))
    return(res)
}

parse_node <- function(node) {
    node_type <- xmlGetAttr(node, "Type")
    node_fxn <- switch(node_type, 
                       "Integer" = parse_esumm_int,
                       "List" = parse_esumm_list,
                       "Structure" = parse_esumm_list,
                       xmlValue) #unnamed arguments to switch = default val.
    return(node_fxn(node))

}

parse_esumm_int <- function(node) as.integer(xmlValue(node))

parse_esumm_list <- function(node){
    res <- lapply(node["Item"], parse_node)
    names(res) <- lapply(node["Item"], xmlGetAttr, "Name")
    return(res)
}


parse_esummary_clinvar <- function(record){
  easynodes <- c('obj_type','accession','accession_version','title','supporting_submissions',
    'gene_sort','chr_sort','location_sort','variation_set_name')
  res <- sapply(easynodes, function(x) xpathApply(record, x, xmlValue))
  res$clinical_significance <- xpathApply(record, 'clinical_significance', xmlToList)[[1]]
  variation_set <- xpathApply(record, 'variation_set', xmlToList)[[1]]$variation
  variation_set$variation$aliases <- unlist(variation_set$variation$aliases, use.names = FALSE)
  trait_set <- xpathApply(record, 'trait_set', xmlToList)[[1]]$trait
  trait_set$trait$trait_xrefs <- unname(trait_set$trait$trait_xrefs)
  res$variation_set <- variation_set
  res$trait_set <- trait_set
  res <- c(res, file=record)
  class(res) <- c("esummary", class(res))
  return(res)
}
