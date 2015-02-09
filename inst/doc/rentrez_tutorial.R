
## ----, eval=TRUE, echo=FALSE---------------------------------------------
library(knitr)
opts_knit$set(upload.fun = image_uri)
opts_knit$set(fig.keep = "last")
opts_knit$set(fig.show = "hold")



## ----install, eval=FALSE-------------------------------------------------
## install.packages("rentrez")


## ----load, message=FALSE, warning=FALSE----------------------------------
library("rentrez")
library("XML")


## ----pubmed_search, message=FALSE, warning=FALSE, comment=NA, cache=FALSE----
pubmed_search <- entrez_search(db = "pubmed", term = "10.1016/j.ympev.2010.07.013[doi]")
pubmed_search$ids


## ----entrez_link, message=FALSE, warning=FALSE, comment=NA, cache=FALSE----
NCBI_data <- entrez_link(dbfrom = "pubmed", id = pubmed_search$ids, db = "all")
NCBI_data


## ----summ----------------------------------------------------------------
entrez_db_summary("popset")


## ----entrez_summary, message=FALSE, warning=FALSE, comment=NA, cache=FALSE----
data_summaries <- entrez_summary(db = "popset", id = NCBI_data$pubmed_popset)
data_summaries[[1]]
sapply(data_summaries, "[[", "title")


## ----entrez_fetch, message=FALSE, warning=FALSE, comment=NA, cache=FALSE----
coi <- entrez_fetch(db = "popset", rettype = 'fasta', id = NCBI_data$pubmed_popset[1])
rag1 <- entrez_fetch(db = "popset", rettype = 'fasta', id = NCBI_data$pubmed_popset[3])


## ----muscle, eval=FALSE--------------------------------------------------
## library(ape)
## library(stringr)
## clean_and_root <- function(tr, outgroup, resolved = TRUE) {
## 
##     tr$tip.label <- sapply(str_split(tr$tip.label, " "), function(x) paste(x[2:3],
##         collapse = "_"))
##     return(root(tr, outgroup, resolve.root = resolved))
## }
## write(coi, "~/moray_coi_raw.fasta")
## write(rag1, "~/moray_rag1_raw.fasta")
## 
## par(mfrow = c(1, 2))
## 
## coi_ali <- muscle(read.dna("~/moray_coi_raw.fasta", "fasta"))
## coi_tr <- nj(dist.dna(coi_ali, "k81"))
## clean_coi_tr <- clean_and_root(coi_tr, "Uropterygius_macrocephalus")
## plot(clean_coi_tr, direction = "rightwards", cex = 1)
## 
## rag_ali <- muscle(read.dna("~/moray_rag1_raw.fasta", "fasta"))
## rag_tr <- nj(dist.dna(rag_ali, "k81"))
## clean_rag_tr <- clean_and_root(rag_tr, "Uropterygius_macrocephalus")
## plot(clean_rag_tr, direction = "leftward", cex = 1)


## ----fields--------------------------------------------------------------
search_fields <- entrez_db_searchable("nuccore")
search_fields
search_fields$ORGN


## ----webenvs1, message=FALSE, warning=FALSE, comment=NA, cache=FALSE-----
snail_search <- entrez_search(db = "nuccore", "Gastropoda[ORGN] AND COI[Gene]", usehistory = "y")


## ----webenvs2, message=FALSE, warning=FALSE, comment=NA, cache=FALSE-----
cookie <- snail_search$WebEnv
qk <- snail_search$QueryKey
snail_coi <- entrez_fetch(db = "nuccore", WebEnv = cookie, query_key = qk, rettype = "fasta", retmax = 10)


