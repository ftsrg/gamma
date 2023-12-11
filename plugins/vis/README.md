# Setting up PlantUML Gamma Visualization

To use the visualization function, you need to install the following tools:

* Graphviz 2.44.1,
* PlantUML Eclipse plugin - Version 1.1.30

## Graphviz

For the newest PlantUML version, the installation of Graphviz is no longer necessary as PlantUML is released with packed Graphviz binaries. Nevertheless, you can still install Graphviz separately if you want to as follows.

You can download Graphviz from the following site: https://graphviz.gitlab.io/download/.

For Windows, the stable packages for version 2.44 can be found here: https://github.com/plantuml/graphviz-distributions.

Note, that you may have to set your PATH variable to include the installation folder of Graphviz.

## PlantUML

Official PlantUML site: https://plantuml.com/.

Details about the Eclipse plugin can be found here: https://plantuml.com/eclipse.

The PlantUML plugin can be set up as follows:
1. Select `Help > Install New Software…` in your Eclipse IDE.
1. Select `Add`, and type http://hallvard.github.io/plantuml/ in the `Location` bar. 
1. Install all available features apart from _Source_.

To open the _PlantUML View_ window, select `Window > Show View > Other > PlantUML` and select the `PlantUML View`.

## Usage

To create a visualization from a Gamma statechart or execution trace model, simply double click on the `.gcd` or `.get` file in the `Project/Package Explorer`, put the focus into the editor (click into it), and the corresponding statechart diagram should appear in the PlantUML view. To refresh the editor after modifying the model, reclick on the `.gcd` or `.get` file in the `Project/Package Explorer`. To copy the PlantUML source code, right click on the diagram, and select `Copy source`.

## Limitations

Currently, the PlantUML statechart visualization does not support 

* multiple top level regions,
* multiple entry states in a region, e.g., an initial state and a history state,
* transitions connecting states in different regions.
