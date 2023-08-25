# Integration to Theta

This folder contains plugins for the mapping of high-level Gamma (composite) models to a symbolic transition system formalism (xSTS). XSTS models can serve as input for [Theta](https://github.com/ftsrg/theta), a generic, modular and configurable model checking framework. Theta supports the formal verification of xSTS models based on reachability criteria. The plugins provide support for the seamless integration of Gamma and Theta, that is, the construction of queries, their evaluation using Theta, and the back-annotation of the verification results in addition to the automatic transformation of the Gamma models. 

Furthermore, the plugins support the automatic generation of standalone Java statechart code from Gamma statecharts based on xSTS models.

## Setup

1. Set up an Eclipse with the [core Gamma plugins](../README.md).
2. Set up [Theta](https://github.com/ftsrg/theta), more specifically the [`theta-xsts-cli` tool](https://github.com/ftsrg/theta/tree/master/subprojects/xsts/xsts-cli) by going into the _theta-bin_ subfolder and executing `Get-Theta.ps1` (Windows) or `get-theta.sh` (Linux). The script will download the required binary and libraries.
    - _Alternatively, you can check out the [instructions](https://github.com/ftsrg/theta/tree/master/subprojects/xsts/xsts-cli) for other options (e.g., build from source). For Gamma, only the `theta-xsts-cli.jar` and the Z3 libraries are required._
3. Put the downloaded libraries (dll/so files) in the _theta-bin_ folder onto your `PATH`.
4. Create an environment variable with the name of `THETA_XSTS_CLI_PATH`, which points to the downloaded `theta-xsts-cli.jar` binary.
5. Set up the plugins in this folder:
    1. Import all Eclipse projects from the the _xsts_ folder.
    2. Generate the Model plugins of the `hu.bme.mit.gamma.statechart.lowlevel.model`, `hu.bme.mit.gamma.xsts.model` and `hu.bme.mit.gamma.lowlevel.xsts.transformation.traceability` using the `.genmodel` file in the respective `model` folder. The generation of additional plugins (Edit, Editor, Tests) is not necessary.

Now you can use the framework in one of the following ways: you either run a runtime Eclipse and work in that or install the plugins into your host Eclipse.