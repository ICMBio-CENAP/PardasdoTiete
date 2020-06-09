# Function for running r.cost 

## arguments: the script, x, y, costraster, outputdir
import sys
import tempfile
import os

# FOR DEBUG:
# args = [None] * 5
# args[0] = "622695.5,-1225372" 
# args[1] = "626235.4,-1198014" 
# args[2] = "D:/Trabalho/pardasdotiete/PardasdoTiete/experiment005/mapsderived/qualitypredictions/maxentcost.tif" 
# args[3] = "C:/Users/Jorge/Desktop/test.tif"
# args[4] = "C:/Users/Jorge/Desktop/testout.tif"


# set qgis application
from qgis.core import *
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

args = sys.argv


#processing.algorithmHelp("grass7:r.drain")
#processing.algorithmHelp("grass7:r.cost")

def lcpaths(cost,origins, dests, outdir):
    tempfile.tempdir = outdir

    costmap = processing.run("grass7:r.cost",
                            {"input": cost, 
                            "start_points": origins,
                            "outdir": tempfile.mktemp(".tif"),
                            "output": tempfile.mktemp(".tif")
                            }
    ) 
    drainmap = processing.run("grass7:r.drain",
        {"input": costmap["output"],
        "direction":costmap["outdir"],
        "-d": True, 
        "start_points": dests,
        "drain":  tempfile.mktemp(".shp"),
        "output": tempfile.mktemp(".tif")
        }
        )
       
    return drainmap["drain"]



lcs = lcpaths(args[1],args[2],args[3],args[4])
qgs.exitQgis()
sys.stdout.write(lcs)
sys.exit(0)
#"C:\Program Files\QGIS 3.4\bin\python-qgis.bat" "./code/exploratory code/r.cost wrapper.py" "622695.5,-1225372" "626235.4,-1198014" "D:/Trabalho/pardasdotiete/PardasdoTiete/experiment005/mapsderived/qualitypredictions/maxentcost.tif" "C:/Users/Jorge/Desktop/test.tif" "C:/Users/Jorge/Desktop/testout.tif" "622675.5,626265.4,-1225402,-1197904"