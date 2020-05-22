This folder contains plugins for the mapping of high-level Gamma statecharts to 1) low-level statecharts and an even lower-level 2) symbolic transition system formalism (xSTS). Java code is automatically generated from the resulting xSTS models.

## Eclipse setup

To use the plugins, you will need an Eclipse with the following plugins installed:
* Eclipse Modeling Framework SDK 2.19.0.
* VIATRA SDK 2.2.1.

We recommend to start-up from an Eclipse IDE for Java and DSL Developers as it contains EMF and Xtext so only VIATRA needs to be downloaded.

## Plugin setup

The plugin setup procedure should be done as follows:
1. Import the [hu.bme.mit.gamma.statechart.model](https://github.com/FTSRG/gamma/tree/master/plugins/hu.bme.mit.gamma.statechart.model) project from the public [Gamma repository](https://github.com/FTSRG/gamma).
2. (Optional) If you want to use textually represented Gamma statecharts, import projects [hu.bme.mit.gamma.statechart.language](https://github.com/FTSRG/gamma/tree/master/plugins/hu.bme.mit.gamma.statechart.language), [hu.bme.mit.gamma.statechart.language.ide](https://github.com/FTSRG/gamma/tree/master/plugins/hu.bme.mit.gamma.statechart.language.ide), [hu.bme.mit.gamma.statechart.language.ui](https://github.com/FTSRG/gamma/tree/master/plugins/hu.bme.mit.gamma.statechart.language.ui) project from the public Gamma repository.
2. Run [hu.bme.mit.gamma.statechart.language/src/hu/bme/mit/gamma/statechart/language/GenerateStatechartLanguage.file](https://github.com/FTSRG/gamma/blob/master/plugins/hu.bme.mit.gamma.statechart.language/src/hu/bme/mit/gamma/statechart/language/GenerateStatechartLanguage.mwe2) as a MWE2 Workflow.
2. Import all Eclipse projects from the the xsts-mapping folder.
3. Generate the Model plugins of the hu.bme.mit.gamma.statechart.lowlevel.model, hu.bme.mit.gamma.xsts.model and hu.bme.mit.gamma.lowlevel.xsts.transformation.traceability using the .genmodel file in the _model_ folder. The generation of additional plugins (Edit, Editor, Tests) is not necessary.
