## try http:// if https:// URLs are not supported
# module specific packages first 

source("http://bioconductor.org/biocLite.R")

# since this is built off the AMARETTO container it should have everything it needs
install.packages(c('igraph'))

library(devtools)

devtools::install_github("broadinstitute/CommunityAMARETTO",ref="develop")


