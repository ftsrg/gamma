# Integration to Theta

This folder contains plugins for the mapping of high-level Gamma (composite) models to a symbolic transition system formalism (xSTS). XSTS models can serve as input for [Theta](https://github.com/theta), a generic, modular and configurable model checking framework. Theta supports the formal verification of xSTS models based on reachability criteria. The plugins provide support for the seamless integration of Gamma and Theta, that is, the construction of queries, their evaluation using Theta, and the back-annotation of the verification results in addition to the automatic transformation of the Gamma models. 

Furthermore, the plugins support the automatic generation of standalone Java statechart code from Gamma statecharts based on xSTS models.

## Setup

First, you have to set up an Eclipse with the [core Gamma plugins](https://github.com/ftsrg/gamma/tree/theta-integration/plugins/core).

Next, you have to set up [Theta](https://github.com/ftsrg/theta), more specifically the [`theta-xsts-cli` tool](https://github.com/ftsrg/theta/tree/master/subprojects/xsts-cli).
You can check out the [instructions](https://github.com/ftsrg/theta/tree/master/subprojects/xsts-cli) for various options for setting up Theta, but we suggest downloading a [binary release](https://github.com/ftsrg/theta/releases).
For Gamma, only the `theta-xsts-cli.jar` is required, and the libraries in the [_lib_ folder](https://github.com/ftsrg/theta/tree/master/lib).
Make sure to put the libraries onto your PATH. 
Furthermore, you have to create an environment variable with the name of _theta-xsts-cli.jar_, which points to the `theta-xsts-cli.jar` binary.

Then, you have to set up the plugins in this folder:
1. Import all Eclipse projects from the the _xsts_ folder.
1. Generate the Model plugins of the `hu.bme.mit.gamma.statechart.lowlevel.model`, `hu.bme.mit.gamma.xsts.model` and `hu.bme.mit.gamma.lowlevel.xsts.transformation.traceability` using the `.genmodel` file in the respective `model` folder. The generation of additional plugins (Edit, Editor, Tests) is not necessary.

Now you can use the framework in one of the following ways: you either run a runtime Eclipse and work in that or install the plugins into your host Eclipse.
