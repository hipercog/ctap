![](https://upload.wikimedia.org/wikipedia/commons/thumb/3/34/Red_star.svg/200px-Red_star.svg.png)

# Computational Testing for Automated Preprocessing (CTAP ★)
CTAP is a set of tools running in [Matlab](https://se.mathworks.com/products/matlab.html) that facilitate workflow creation, automated quality control and feature export for the [EEGLAB](https://sccn.ucsd.edu/eeglab/index.php)  EEG processing framework.

## What is CTAP? ##
The main aim of the *Computational Testing for Automated Preprocessing (CTAP)* toolbox is to provide:

1. batch processing using EEGLAB functions and
2. testing and comparison of automated methodologies.

The CTAP toolbox provides two main functionalities to achieve these aims:

1. the **core** supports scripted specification of an EEGLAB analysis pipeline and tools for running the pipe, making the workflow transparent and easy to control. Automated output of ‘quality control’ logs and imagery helps to keep track of what's going on.
2. the **testing module** uses synthetic data to generate ground truth controlled tests of preprocessing methods, with capability to generate new synthetic data matching the parameters of the lab’s own data. This allows experimenters to select the best methods for their purpose, or developers to flexibly test and benchmark their novel methods.

_If you use CTAP for your research, __please use the following citations___:
 * Cowley, B., Korpela, J., & Torniainen, J. E. (2017). Computational Testing for Automated Preprocessing: a Matlab toolbox to enable large scale electroencephalography data processing. PeerJ Computer Science, 3:e108. http://doi.org/10.7717/peerj-cs.108
* Cowley, B. U., & Korpela, J. (2018). Computational Testing for Automated Preprocessing 2: practical demonstration of a system for scientific data-processing workflow management for high-volume EEG. Frontiers in Neuroscience, 12(236). http://doi.org/10.3389/fnins.2018.00236

## Installation ##

### System requirements
The following are required:
* Matlab R2019b or later
* EEGLAB v2019.1 or later

The system is under development and tested in Matlab R2019b and EEGLAB v2019.1 for Debian/Ubuntu Linux, Mac, and Windows.

### Installation procedure

#### 1. clone the repo
Clone the GitHub repository to your machine using

    git clone https://github.com/bwrc/ctap.git <destination dir>
    
NOTE 1: you can clone wherever you like, but on Unix-based systems we recommend to clone in the home directory, to be compatible with the [CTAP code generation tool](https://ruoyanmeng.github.io/ctap/#/)
NOTE 2: we have used git LFS to track/manage large data files (in \*.mat and  \*.set format). This implies that you need to set up LFS by

    git lfs install

Unless you want to ignore the data files (which will prevent some example scripts from running); then it is sufficient to clone without LFS installed (for more LFS options [see here](https://sabicalija.github.io/git-lfs-intro/)).

#### 2. set up Matlab path
Add directory trees `<dst_dir>/ctap/` and `<dst_dir>/dependencies/` to your Matlab path, __including subdirectories__. 
One option to accomplish this is to set the Matlab working directory to the CTAP root directory `<destination dir>`, and then run `ctap_set_path.m` to configure Matlab path.

You need to have EEGLAB added to your Matlab path ([instructions here](https://sccn.ucsd.edu/eeglab/downloadtoolbox.php)). `ctap_set_path.m` can also accomplish this, if you edit to match the setup on your machine and run.

To have your preferred path configuration loaded every time Matlab starts, edit your `startup.m` script by copying the contents of `ctap_set_path.m`. See ([Matlab's instructions here] (https://www.mathworks.com/help/matlab/ref/startup.html)) regarding the `startup.m` script.


## Getting started using CTAP ##
A minimalistic working example can be found in `~/ctap/templates/minimalistic_example/`. Try running script

```
runctap_minimal
```

If the seed data packaged with CTAP was found (i.e. the Matlab path was correctly configured), then `runctap_minimal` should read seed data, create synthetic data and run an example CTAP pipe on the synthetic data. Results are stored under `fullfile(cd(), 'example-project')`.

To start your own pipe, copy the `cfg_minimal.m` and `runctap_minimal.m` files and use them as a starting point. Note: `runctap_minimal.m` takes as input a small dataset included under `~/ctap/data/`, which it uses to generate synthetic data and illustrate several preprocessing steps. To have it find the data, set the Matlab current directory to the root of the CTAP repo you have just cloned, i.e. `<destination dir>`. You can also set the output directory in `runctap_minimal.m`

More examples are available under `~/ctap/templates/`.

General documentation can be found in the [CTAP wiki](https://github.com/bwrc/ctap/wiki) pages.


## License information

CTAP is released under the MIT license, but depends on some components released under different licenses. Please refer to the file "LICENSE" for license information for the CTAP software, and for terms and conditions for usage, and a disclaimer of all warranties.

CTAP also depends on other software projects with different licenses. These are included with their respective licences in the `dependencies` folder.
