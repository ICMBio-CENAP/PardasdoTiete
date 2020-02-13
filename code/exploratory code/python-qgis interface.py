#path to OSgeo shell
# "C:\Program Files\QGIS 3.10\OSGeo4W.bat"
# python-qgis

import sys

from qgis.core import *
from qgis.analysis import QgsNativeAlgorithms

# See https://gis.stackexchange.com/a/155852/4972 for details about the prefix 
QgsApplication.setPrefixPath('C:\\Program Files\\QGIS 3.10\\apps\\qgis', True)
qgs = QgsApplication([], False)
qgs.initQgis()


# Append the path where processing plugin can be found
sys.path.append('C:\\Program Files\\QGIS 3.10\\apps\\qgis\\python\\plugins')
import processing
from processing.core.Processing import Processing
Processing.initialize()
processing.algorithmHelp("grass7:i.fft")
processing.algorithmHelp("qgis:createconstantrasterlayer")

# needed to make grass7 algorithms work
# despite giving error
# see https://gis.stackexchange.com/questions/296502/pyqgis-scripts-outside-of-qgis-gui-running-processing-algorithms-from-grass-prov?rq=1
from processing.algs.grass7.Grass7Utils import Grass7Utils
Grass7Utils.checkGrassIsInstalled()

# Test with QGIS algorithm
resul = processing.run("qgis:createconstantrasterlayer",
                        {"EXTENT": "-10,10,-10,10",
                         "TARGET_CRS":"EPSG:3111",
                         "OUTPUT":"C:\\Users\\jorge\\Desktop\\test.tif"
                         }
)

# testing grass algorithm


resul = processing.run("grass7:i.fft", 
                            {"input":"C:\\Users\\jorge\\Desktop\\Imagecover.tif",
                             "real":"C:\\Users\\jorge\\Desktop\\testgrass1.tif",
                             "imaginary":"C:\\Users\\jorge\\Desktop\\testgrass2.tif"
                            })


for alg in QgsApplication.processingRegistry().algorithms():
        print(alg.id(), "->", alg.displayName())