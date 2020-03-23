# ---
# title:  Function to convert kmz to kml
# author: Jorge Menezes    <jorgefernandosaraiva@gmail.com> 
# date: CENAP-ICMBio/Pro-Carnivoros, Atibaia, SP, Brazil, March 2020
# 
# ---

# Intent: This is a simple function to open take a series of kmz files, and 
# turn them in kml (which is basically unzipping the files). Kml files will
# have the same name as the original kmz.

# Input: [infile] the path to a kmz file.
#        [outfolder] the path to a folder where the kml will be stored.

# Output: A single geodatabase with organize data




# Function to convert kmz file to kml (just unzip it)
kmler <- function(infile,outfolder) {
    unzipped <- unzip(infile, exdir=tempdir(), overwrite=T)
    kmlname <-  strtrim( basename(infile), nchar(basename(infile))-4)
    kmlname <- paste0(outfolder, "/", kmlname, ".kml")
    file.copy(unzipped, kmlname)
    return(kmlname)
    }