# Function for running r.cost 

## arguments: the script, x, y, costraster, outputdir
import sys


# set qgis application
from qgis.core import *
import processing
from qgis.analysis import QgsNativeAlgorithms
QgsApplication.setPrefixPath("C:/Program Files/QGIS 3.4", True)
qgs = QgsApplication([], False)
qgs.initQgis()

# set processing tools
sys.path.append("C:/Program Files/QGIS 3.4/apps/qgis/python/plugins")
import processing
from processing.core.Processing import Processing
Processing.initialize()
QgsApplication.processingRegistry().addProvider(QgsNativeAlgorithms())



testdata = "D:/Trabalho/pardasdotiete/PardasdoTiete/experiment005/mapsderived/qualitypredictions/maxentcost.tif"
processing.run("grass7:r.cost",
    {"input": sys.argv[3], 
    "start_coordinates": sys.argv[1],
    "stop_coordinates": sys.argv[2],
    "outdir":sys.argv[4]
    }
    )

qgs.exitQgis()