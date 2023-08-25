# Integration to xSAP

This folder contains plugins for the mapping of high-level Gamma (composite) models and fault extension instruction (FEI) models into xSAP through the Gamma-xSTS-SMV translation for safety assessment. The plugins provide support for the seamless integration of Gamma and xSAP, that is, the construction of nominal models in SMV, as well as FEI models that describe fault extensions (fault effects and dynamics) that can affect variables, regions and output events in the nominal Gamma model.

## Setup

1. Set up an Eclipse with the [core Gamma plugins](../../core/README.md).
2. Set up [xSAP](https://xsap.fbk.eu/):
   - Download the corresponding xSAP zip file from [here](https://xsap.fbk.eu/download.html) in accordance with your operating system.
   - Extract the downloaded zip file.
   - Create an environment variable named `XSAP_HOME` that points to the extracted xSAP root folder (absolute path).
   - Add the `xSAP/bin` folder to the `PATH` environment or default search path (depending on your OS). Make sure that the `extend_model` program is contained in this folder in addition to the xSAP binaries.
3. Set up the plugins in this folder.
   - Import all Eclipse projects from the the `safety` folder.
   - Generate the necessary artefacts related to the Gamma FEI metamodel and grammar (use the MWE2 workflows of the `setup/hu.bme.mit.gamma.setup` project).
