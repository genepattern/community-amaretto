## The Regents of the University of California and The Broad Institute
## SOFTWARE COPYRIGHT NOTICE AGREEMENT
## This software and its documentation are copyright (2018) by the
## Regents of the University of California abd the 
## Broad Institute/Massachusetts Institute of Technology. All rights are
## reserved.
##
## This software is supplied without any warranty or guaranteed support
## whatsoever. Neither the Broad Institute nor MIT can be responsible for its
## use, misuse, or functionality.

# Load any packages used to in our code to interface with GenePattern.
# Note the use of suppressMessages and suppressWarnings here.  The package
# loading process is often noisy on stderr, which will (by default) cause
# GenePattern to flag the job as failing even when nothing went wrong. 
suppressMessages(suppressWarnings(library(stringi)))
suppressMessages(suppressWarnings(library(getopt)))
suppressMessages(suppressWarnings(library(optparse)))
suppressMessages(suppressWarnings(library(R.utils)))
suppressMessages(suppressWarnings(library(AMARETTO)))
suppressMessages(suppressWarnings(library(plyr)))
suppressMessages(suppressWarnings(library(igraph)))
suppressMessages(suppressWarnings(library(CommunityAMARETTO)))

# suppressMessages(suppressWarnings(source("/source/Community-AMARETTO/AMARETTO_Communities_Minimal.R")))

# Print the sessionInfo so that there is a listing of loaded packages, 
# the current version of R, and other environmental information in our
# stdout file.  This can be useful for reproducibility, troubleshooting
# and comparing between runs.
sessionInfo()


is.emptyString=function(a){return (trimws(a)=="")}



# Get the command line arguments.  We'll process these with optparse.
# https://cran.r-project.org/web/packages/optparse/index.html
arguments <- commandArgs(trailingOnly=TRUE)

print(packageVersion("AMARETTO"))
# Declare an option list for optparse to use in parsing the command line.
option_list <- list(
  # Note: it's not necessary for the names to match here, it's just a convention
  # to keep things consistent.
  make_option("--amaretto.result.files", dest="amaretto.result.files"),
  make_option("--amaretto.report.files", dest="amaretto.report.files"),
  make_option("--output.file", dest="output.file"),
  make_option("--num.cpu", dest="num.cpu")

  )

# Parse the command line arguments with the option list, printing the result
# to give a record as with sessionInfo.
opt <- parse_args(OptionParser(option_list=option_list), positional_arguments=TRUE, args=arguments)
print(opt)
opts <- opt$options

if (file.exists(opts$amaretto.result.files)){
	resultFileList = readLines(opts$amaretto.result.files)
}
if (file.exists(opts$amaretto.report.files)){
	reportFileList = readLines(opts$amaretto.report.files)
}

AMARETTOdirectories <- list()
resultKeys <- list()
# ResultsDirectory=file.path(getwd(), "results")
# dir.create(file.path(ResultsDirectory))
for (file in resultFileList){
   if (!is.emptyString(file) && file.exists(file)){
         # key is whatever comes before "AMARETTOresults" in the filename
        pos = stri_locate(pattern = '_AMARETTOresults', file, fixed = TRUE)
       
        key =  substr(file, 0, pos[1]-1)
        AMARETTOdirectories[key] <- file
        resultKeys <- append(resultKeys, key)
	}
} 
HTMLsAMARETTOlist <- list()
reportKeys <- list()

# ReportsDirectory=file.path(getwd(), "reports")
# dir.create(file.path(ReportsDirectory))
for (file in reportFileList){
    
     if (!is.emptyString(file) && file.exists(file)){
        # key is whatever comes before "_report.zip" in the file name
        pos = stri_locate(pattern = '_report.zip', file, fixed = TRUE)
       
        key =  substr(file, 0, pos[1]-1)
        HTMLsAMARETTOlist[[key]] <- file
        reportKeys <- append(reportKeys, key)
    }
} 

if (! setequal(resultKeys, reportKeys)){
     warning("Mismatched result and report files provided.  Please ensure for each report zip there is a result zip using the same filename prefix.")

	print("RESULTS")
	print(AMARETTOdirectories)
	print("REPORTS")
	print(HTMLsAMARETTOlist)

     quit(status=999)
}

#AMARETTOPancancerData <- CreatePancancerData(ResultsDirectory)
#AMARETTOPancancer_results <- AMARETTO_Pancancer(AMARETTOPancancerData=AMARETTOPancancerData)
#CommunitiesResults <- AMARETTO_CreateCommunities(AMARETTOPancancer_results)
#save(CommunitiesResults,file=file.path(getwd(),paste(opts$output.file,".RData",sep = "")))

AMARETTO_all <- cAMARETTO_Read(AMARETTOdirectories)
AMARETTOinit_all <- AMARETTO_all$AMARETTOinit_all
AMARETTOresults_all <- AMARETTO_all$AMARETTOresults_all
print("A")
# we have a few params here NCores, 0.10, 5, filterComm
cAMARETTOresults<-cAMARETTO_Results(AMARETTOinit_all,AMARETTOresults_all, NrCores = 4,output_dir = "./")
print("A2")

cAMARETTOnetworkM<-cAMARETTO_ModuleNetwork(cAMARETTOresults,0.10,5)
print("A3")

cAMARETTOnetworkC<-cAMARETTO_IdentifyCom(cAMARETTOnetworkM, filterComm = FALSE)

print("B")
#This part is to write a report. The HTMLsAMARETTOlist are links to the HTML reports for AMARETTO
#  HTMLsAMARETTOlist <- c("LIHC"="./LIHCreport","BLCA"="./BLCAreport","GBM"="./GBMreport")
#  also need a param:  hyper_geo_reference = gmtfile,
cAMARETTO_HTMLreport(cAMARETTOresults,cAMARETTOnetworkM, cAMARETTOnetworkC,HTMLsAMARETTOlist=HTMLsAMARETTOlist, hyper_geo_test_bool = TRUE,  MSIGDB = TRUE, GMTURL = FALSE, output_address= "./“)
print("C")
#cAMARETTO can be exported as a zip
cAMARETTO_ExportResults(cAMARETTOresults,cAMARETTOnetworkM, cAMARETTOnetworkC, output_address="./“)






