# Integration to Spin

This folder contains plugins for the mapping of high-level Gamma (composite) models to a process-modeling formalism (Promela) through a symbolic transition system formalism (xSTS). Promela models can serve as input for [Spin](http://spinroot.com/spin/whatispin.html), a tool for analyzing the logical consistency of distributed systems, specifically of data communication protocols. Spin supports the formal verification of Promela models and it supports the verification of linear time temporal constraints. The plugins provide support for the seamless integration of Gamma and Spin, that is, the construction of queries, their evaluation using Spin, and the back-annotation of the verification results in addition to the automatic transformation of the Gamma models.

## Setup

1. Set up an Eclipse with the [core Gamma plugins](../README.md).
2. Set up [Spin](https://spinroot.com/spin/Man/README.html).
   - *Windows*
     1. Download `pc_spin651.zip` from [here](https://spinroot.com/spin/Src/index.html).
     2. Extract the files from `pc_spin.zip`.
     3. Copy `spin.exe` into your default search path.
   - *Linux*
     1. Download version 6.5.1 or higher from [here](https://spinroot.com/spin/Archive/).
     2. Run the following commands:
        - `gunzip *.tar.gz`
        - `tar -xf *.tar`
        - `cd Src*`
        - `make`
     3. Add the `spin` to the `PATH` environment.
3. Set up the plugins in this folder.
   - Import all Eclipse projects from the the promela folder. 

*Note: You also need GCC to use Spin. On Unix/Linux you probably have GCC, or an equivalent, installed. On the Windows you need an installation of GCC. You need to download 32 bit Cygwin (even if your system is 64-bit, because of Spin use 32 bit version) from [here](https://www.cygwin.com/index.html). After downloading run the* `setup-x86.exe` *, then add the* `cygwin/bin` *to the path. The following should be selected in the installer:* `gcc-core`*,* `gcc-g++`*,* `libgcc1`*.*

Now you can use the framework in one of the following ways: you either run a runtime Eclipse and work in that or install the plugins into your host Eclipse.