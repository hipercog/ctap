# Rtools
An R package that contains miscellaneous tools for working with EEG data in R. Currently the most important part are the HDF5 -wrappers that are used to read in ERP data from CTAP.

The tools are made into a proper package to make them easier to use. See chapter "howto".


# HOWTO

Follow these steps to install the package.

0. Make sure you have some HDF5 (http://hdfgroup.org/HDF5/) stuff installed:

Debian-based (e.g. Debian >= 8.0, Ubuntu >= 15.04): 'sudo apt-get install libhdf5-dev  
Old Debian-based (e.g Debian < 8.0, Ubuntu < 15.04): Install from source  
OS X using Homebrew: 'brew install homebrew/science/hdf5 --enable-cxx'  
RPM-based (e.g Fedora): 'sudo yum install hdf5-devel'

1. clone the repository to your machine:
```
git clone https://github.com/hipercog/ctap.git
```

2. install it in R:
```
install.packages('devtools')
require(devtools)
devtools::install('path-to-ctap-repo/ctap/ctap_R/ctapRtools')
library(ctapRtools)
```
