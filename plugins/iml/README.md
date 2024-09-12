# Integration to Imandra

This folder contains plugins for the mapping of high-level Gamma (composite) models into IML through a symbolic transition systems formalism (xSTS). The plugins provide support for the integration of Gamma and Imandra, that is, the mapping of Gamma models into IML, mapping reachability/invariant properties to Imandra verify/instance calls, and using Imandra instances hosted in the cloud to carry out verification via Imandra's Python API.

## Setup

1. Set up an Eclipse with the [core Gamma plugins](../README.md).
2. Set up [Imandra](https://imandra.ai/). For this, you will need Python 3:
	- Open a command line and use *pip3* to install *Imandra*: `pip install imandra`.
	- Install the [imandra-cli](https://docs.imandra.ai/imandra-docs/notebooks/installation-simple/) client according to your operating system(i.e., `sh <(curl -s "https://storage.googleapis.com/imandra-do/install.sh")` or `(Invoke-WebRequest https://storage.googleapis.com/imandra-do/install.ps1).Content | powershell -`). Create an account using the *imandra-cli* and agree to the community guidelines, i.e., use the following command in a command line after navigating into the home folder of the installed *imandra-cli*: `imandra-cli auth login`.
3. Set up the plugins in this folder.
   - Import all Eclipse projects from the the `iml` folder.
