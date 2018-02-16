# Computational Testing for Automated Preprocessing (CTAP)
CTAP is a set of tools running in [Matlab](https://se.mathworks.com/products/matlab.html) that facilitate workflow creation, automated quality control and feature export for the [EEGLAB](https://sccn.ucsd.edu/eeglab/index.php)  EEG processing framework.

## What is CTAP? ##
The main aim of the *Computational Testing for Automated Preprocessing (CTAP)* toolbox is to provide:

1. batch processing using EEGLAB functions and
2. testing and comparison of automated methodologies.

The CTAP toolbox provides two main functionalities to achieve these aims:

1. the **core** supports scripted specification of an EEGLAB analysis pipeline and tools for running the pipe, making the workflow transparent and easy to control. Automated output of ‘quality control’ logs and imagery helps to keep track of what's going on.
2. the **testing module** uses synthetic data to generate ground truth controlled tests of preprocessing methods, with capability to generate new synthetic data matching the parameters of the lab’s own data. This allows experimenters to select the best methods for their purpose, or developers to flexibly test and benchmark their novel methods.

_If you use CTAP for your research, __please use the following citation___:
 * Cowley, B., Korpela, J., & Torniainen, J. E. (2017). Computational Testing for Automated Preprocessing: a Matlab toolbox to enable large scale electroencephalography data processing. PeerJ Computer Science, 3:e108. http://doi.org/10.7717/peerj-cs.108


## Installation ##

### System requirements
The following are required:
* Matlab R2016b or later
* EEGLAB 14.1.1 or later

The system has been developed and tested under Matlab R2016b and EEGLAB 14 mainly under Debian/Ubuntu Linux.

### Installation procedure

#### 1. clone the repo
Clone the GitHub repository to your machine using

    git clone https://github.com/bwrc/ctap.git <destination dir>

#### 2. set up Matlab path
Add directory trees `<dst_dir>/ctap/` and `<dst_dir>/dependencies/` to your Matlab path, __including subdirectories__. You also need to have EEGLAB added to your Matlab path.

One option to accomplish both of these to make a local copy of `ctap_set_path.m`, edit the file to match the setup on your machine and run to configure Matlab path.

## Getting started using CTAP ##
A minimalistic working example can be found in `~/ctap/templates/minimalistic_example/`. Try running script

```
runctap_minimal
```

This script should read seed data, create synthetic data and run an example CTAP pipe on the synthetic data. Results are stored under `fullfile(cd(), 'example-project')`.

To start your own pipe, copy the `cfg_minimal.m` and `runctap_minimal.m` files and use them as a starting point. Note: `runctap_minimal.m` takes as input a small dataset included under `~/ctap/data/`, which it uses to generate synthetic data and illustrate several preprocessing steps. To have it find the data, set the Matlab current directory to the root of the CTAP repo you have just cloned, i.e. `<destination dir>`. You can also set the output directory in `runctap_minimal.m`

More examples are available under `~/ctap/templates/`.


## License information

CTAP is released under the MIT license, but depends on some components released under different licenses. Please refer to the file "LICENSE" for license information for the CTAP software, and for terms and conditions for usage, and a disclaimer of all warranties.

CTAP also depends on other software projects with different licenses. These are included with their respective licences in the `dependencies` folder.
