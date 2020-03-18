Included are:

* a renamed version of jutako/Rtools: ctap_rtools
* some general purpose code (especially ctap_tools_future.R)
* my tswitch example from seamless project

The script tswitch_prepare_erpfeat.R shows how I have been dealing with the data loading and preprocessing. Actual reporting is in the Rmd files.

The example is not a fully working one, but gives the idea. We start with a text file of all HDF5 files which we produce using:

find `pwd` -iname "*.h5" -exec stat -c "%n %Y" {} \; > h5_files.txt

I find that much faster than R:s own tools for directory traversal. There are tools to process this list of files and make some aggregations to see what kind of files there are and how many. All loading is done by selecting a subset of files and loading their data.

ERP feature extraction code in stats_extraction_IA.R might contain links to files that are in the seamless repo, but not in ctap_dev. The code is Jonne's code and difficult for me to make standalone.

Instead of require(Rtools) you should install ctap_rtools and require(ctap_rtools). Code in ctap_tools_future.R should be added to ctap_rtools once it has been found useful enough.
