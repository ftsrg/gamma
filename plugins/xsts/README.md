# Integration to Theta

This folder contains plugins for the mapping of high-level Gamma (composite) models to a symbolic transition system formalism (xSTS). XSTS models can serve as input for [Theta](https://github.com/theta), a generic, modular and configurable model checking framework. Theta supports the formal verification of xSTS models based on reachability criteria. The plugins provide support for the seamless integration of Gamma and Theta, that is, the construction of queries, their evaluation using Theta, and the back-annotation of the verification results in addition to the automatic transformation of the Gamma models. 

Furthermore, the plugins support the automatic generation of standalone Java statechart code from Gamma statecharts based on xSTS models.

## Setup

First, you have to set up an Eclipse with the [core Gamma plugins](https://github.com/ftsrg/gamma/tree/theta-integration/plugins/core).

Next, you have to set up [Theta](https://github.com/mondokm/theta/tree/xsts/subprojects/xsts-cli): make sure you put the the _lib_ folder (containing necessary libraries for Theta) onto your PATH. After building Theta, you have to create an environment variable with the name of `theta_xsts_cli`, which points to the generated _theta-xsts-cli-<VERSION>-all.jar_ in the _subprojects/xsts-cli/build/libs/_ folder.

Then, you have to set up the plugins in this folder:
1. Import all Eclipse projects from the the _xsts_ folder.
1. Generate the Model plugins of the `hu.bme.mit.gamma.statechart.lowlevel.model`, `hu.bme.mit.gamma.xsts.model` and `hu.bme.mit.gamma.lowlevel.xsts.transformation.traceability` using the `.genmodel` file in the respective `model` folder. The generation of additional plugins (Edit, Editor, Tests) is not necessary.

Now you can use the framework in one of the following ways: you either run a runtime Eclipse and work in that or install the plugins into your host Eclipse.