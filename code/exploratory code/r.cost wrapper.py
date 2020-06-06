# Function for running r.cost 

## arguments: the script, x, y, costraster, outputdir
import sys

args = sys.argv[1:]

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

processing.algorithmHelp("grass7:r.drain")
#processing.algorithmHelp("grass7:r.cost")
processing.run("grass7:r.cost",
    {"input": args[2], 
    "start_coordinates": args[0],
    "stop_coordinates": args[1],
    "outdir":args[3],
    "output": args[4],
    "GRASS_REGION_PARAMETER": args[5]
    }
    )

qgs.exitQgis()
#"C:\Program Files\QGIS 3.4\bin\python-qgis.bat" "./code/exploratory code/r.cost wrapper.py" "622695.5,-1225372" "626235.4,-1198014" "D:/Trabalho/pardasdotiete/PardasdoTiete/experiment005/mapsderived/qualitypredictions/maxentcost.tif" "C:/Users/Jorge/Desktop/test.tif" "C:/Users/Jorge/Desktop/testout.tif" "622675.5,626265.4,-1225402,-1197904"