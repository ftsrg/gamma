# Setting up PlantUML Statechart Visualization

To use the statechart visualization function, you need to install the following tools:

* Graphviz 2.26.3 - 2.38,
* PlantUML Eclipse plugin.

## Graphviz

You can download Graphviz from the following site: https://graphviz.gitlab.io/download/.

For Windows, the stable packages for version 2.38 can be found here: https://graphviz.gitlab.io/_pages/Download/Download_windows.html.

Note, that you may have to set your PATH variable to include the installation folder of Graphviz.

## PlantUML

Official PlantUML site: https://plantuml.com/.

Details about the Eclipse plugin can be found here: https://plantuml.com/eclipse.

To set up the PlantUML plugin:
1. Select “Help -> Install New Software…” in your Eclipse IDE.
1. Select “Add”, and type http://hallvard.github.io/plantuml/ in the “Location” bar. 
1. Install all available features.

To open the PlantUML View window, select “Window -> Show View -> Other -> PlantUML” and select the PlantUML view.

## Usage

To create a visualization from a Gamma statechart definition, simply double click on the .gcd file in the Project/Package Explorer, put the focus into the editor (click into it), and the corresponding statechart diagram should appear in the PlantUML view. To copy the PlantUML source code, right click on the diagram, and select “Copy source”.

## Limitations

Currently, the PlantUML statechart visualization does not support 

* multiple top level regions,
* multiple entry states in a region, e.g., an initial state and a history state,
* transitions connecting states in different regions.