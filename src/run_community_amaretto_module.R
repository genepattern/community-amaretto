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

# Declare an option list for optparse to use in parsing the command line.
option_list <- list(
  # Note: it's not necessary for the names to match here, it's just a convention
  # to keep things consistent.
  make_option("--amaretto.result.files", dest="amaretto.result.files"),
  make_option("--amaretto.report.files", dest="amaretto.report.files"),
  make_option("--output.file", dest="output.file"),
  make_option("--num.cpu", dest="num.cpu"),
  make_option("--inter", dest="inter", type="integer"),
  make_option("--pvalue", dest="pvalue", type="double"),
  make_option("--filterComm", dest="filterComm", type="logical"),
  make_option("--gene.sets.database", dest="gene.sets.database")

)

# Parse the command line arguments with the option list, printing the result
# to give a record as with sessionInfo.
opt <- parse_args(OptionParser(option_list=option_list), positional_arguments=TRUE, args=arguments)
print(opt)
opts <- opt$options

resultFileList=NULL
reportFileList=NULL

if (file.exists(opts$amaretto.result.files)){
	resultFileList = readLines(opts$amaretto.result.files)
}
if (!is.null(opts$amaretto.report.files) ) {
	if (file.exists(opts$amaretto.report.files)){
		reportFileList = readLines(opts$amaretto.report.files)
	}
}

AMARETTOdirectories <- list()
resultKeys <- list()
for (file in resultFileList){
   if (!is.emptyString(file) && file.exists(file)){
         # key is whatever comes before "AMARETTOresults" in the filename
        rFilename = basename(file)
        pos = stri_locate(pattern = '_AMARETTOresults', rFilename, fixed = TRUE)
        key =  substr(rFilename, 0, pos[1]-1)
        print(paste("result key ", key))
        AMARETTOdirectories[key] <- file
        resultKeys <- append(resultKeys, key)
	}
} 
HTMLsAMARETTOZips <- NULL
reportKeys <- list()
if (! is.null(reportFileList) ){
HTMLsAMARETTOZips <- list()
print("reading report list")
for (file in reportFileList){
     print(paste("report file: ", file) )    
     if (!is.emptyString(file) && file.exists(file)){
        # key is whatever comes before "_report.zip" in the file name
        rFilename = basename(file)
        pos = stri_locate(pattern = '_report.zip', rFilename, fixed = TRUE)
       
        key =  substr(rFilename, 0, pos[1]-1)

        print(paste("report key ", key))

        HTMLsAMARETTOZips[[key]] <- file
        reportKeys <- append(reportKeys, key)
    }
} 
}

if ((!is.null( reportFileList) ) && (! setequal(resultKeys, reportKeys))){
     warning("Mismatched result and report files provided.  Please ensure for each report zip there is a result zip using the same filename prefix.")

	print("RESULTS")
	print(AMARETTOdirectories)
	print("REPORTS")
	print(HTMLsAMARETTOZips)

     quit(status=999)
}

hyper.geo.ref = NULL
catGmtFilename = "./amCombinedGmt.gmt"
if ((!is.null(opts$gene.sets.database))){
        if (file.exists(opts$gene.sets.database)){
              print("LOADING GENES FROM GENE SET DATABASE")
              # XXX TODO - need to combine all the file contents, right now its last one wins

              # its potentially a list of gmt files.  Read the file names then load them all in
              catExec = "cat "
              geneSetFileList = readLines(opts$gene.sets.database)
              for (fileRaw in geneSetFileList){
                    file = trimws(fileRaw)
                    print(paste("   ---   loading from ", file))
                    if (!is.emptyString(file) && file.exists(file)){
                           # hyper.geo.ref = as.character(read.delim(file)$V1)
                        catExec = paste(catExec, file)
                        print(paste("Building catexec: ", catExec))
                    } else {
                        print(paste("GMT issue ", file))
                    }
             }
             hyper.geo.ref = catGmtFilename
             catExec <- paste(catExec, " > ", hyper.geo.ref )
             print(paste("running: ", catExec))
             system(catExec)
             #  hyper.geo.ref = as.character(read.delim(opts$hyper.geo.ref.file)$V1)
        } else {
             print("Optional hyper geo ref file was not provided. Using H.C2CP.genesets.gmt")
             hyper.geo.ref="/source/AMARETTO/inst/templates/H.C2CP.genesets.gmt"
        }
} else {
    hyper.geo.ref="/usr/local/bin/community-amaretto/H.C2CP.genesets.gmt"

    print("USING DEFAULT GMT")
}    

print( AMARETTOdirectories)
print( HTMLsAMARETTOZips)

AMARETTO_all <- cAMARETTO_Read(AMARETTOdirectories, unzipParentDirectory="/tmp")
HTMLsAMARETTOlist  <-cAMARETTO_HTML_Read ( HTMLsAMARETTOZips , unzipParentDirectory = "/tmp")

print( HTMLsAMARETTOlist)

AMARETTOinit_all <- AMARETTO_all$AMARETTOinit_all
AMARETTOresults_all <- AMARETTO_all$AMARETTOresults_all
# we have a few params here NCores, 0.10, 5, filterComm
cAMARETTOresults<-cAMARETTO_Results(AMARETTOinit_all,AMARETTOresults_all, NrCores = 4,output_dir = "./")

cAMARETTOnetworkM<-cAMARETTO_ModuleNetwork(cAMARETTOresults,pvalue=opts$pvalue,inter=opts$inter)

cAMARETTOnetworkC<-cAMARETTO_IdentifyCom(cAMARETTOnetworkM, filterComm = opts$filterComm)

#This part is to write a report. The HTMLsAMARETTOlist are links to the HTML reports for AMARETTO
#  HTMLsAMARETTOlist <- c("LIHC"="./LIHCreport","BLCA"="./BLCAreport","GBM"="./GBMreport")
#  also need a param:  hyper_geo_reference = gmtfile,
print(paste("GMT is ", hyper.geo.ref))
print(paste("GMT exists ", file.exists(hyper.geo.ref)))

x <- getwd()
report_address = paste0('./', opts$output.file,"_report/")
dir.create(file.path(report_address), showWarnings = FALSE)

print(paste("created dir: ", report_address, "  ", dir.exists(report_address)))


cAMARETTO_HTMLreport(cAMARETTOresults,cAMARETTOnetworkM, cAMARETTOnetworkC,HTMLsAMARETTOlist=HTMLsAMARETTOlist, hyper_geo_test_bool = TRUE, hyper_geo_reference = hyper.geo.ref, MSIGDB = TRUE, output_address= report_address)

#cAMARETTO can be exported as a zip
print("C Exporting")
cAMARETTO_ExportResults(cAMARETTOresults,cAMARETTOnetworkM, cAMARETTOnetworkC, output_address="./")

x <- getwd()
zip(zipfile = file.path(paste(x,"/", opts$output.file,"_report.zip", sep = "")), files=file.path(report_address) )

if (file.exists(catGmtFilename)){
    unlink(catGmtFilename)
}


unlink("Rplots.pdf")

# remove the expanded result zips
#for (key in reportKeys){
#    unlink(key)
#}



