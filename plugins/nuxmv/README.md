# Integration to nuXmv

This folder contains plugins for the mapping of high-level Gamma (composite) models into SMV through a symbolic transition systems formalism (xSTS). The plugins provide support for the seamless integration of Gamma and nuXmv, that is, the construction of queries (temporal properties), their evaluation using nuXmv, and the back-annotation of the verification results in addition to the automated transformation of the Gamma models.

## Setup

1. Set up an Eclipse with the [core Gamma plugins](../README.md).
2. Set up [nuXmv](https://nuxmv.fbk.eu/):
   - Download the corresponding nuXmv zip file from [here](https://nuxmv.fbk.eu/download.html) in accordance with your operating system (Windows, Linux or Mac OS X, 32- or 64-bit version).
   - Extract the downloaded zip file.
   - Add the `nuXmv/bin` folder to the `PATH` environment or default search path (depending on your OS).
3. Set up the plugins in this folder.
   - Import all Eclipse projects from the the `nuxmv` folder.
