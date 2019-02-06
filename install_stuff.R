## try http:// if https:// URLs are not supported
# module specific packages first 
print("--- installing")
#source("http://bioconductor.org/biocLite.R")
install.packages("BiocManager")
BiocManager::install(c("ComplexHeatmap"))


# since this is built off the AMARETTO container it should have everything it needs
install.packages(c('devtools'))

library(devtools)

devtools::install_github("broadinstitute/CommunityAMARETTO",ref="develop")
print("Install complete")

