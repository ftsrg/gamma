# Building Gamma

## Eclipse setup

You will need Java 11 to setup Gamma.

Gamma has been implemented as a set of Eclipse plugins. To use the
framework, you will need an Eclipse with the following plugins installed:
* Eclipse Modeling Framework SDK 2.23.0.
* Xtext Complete SDK 2.23.0. (It contains Xtend, no need for the additional download
of Xtend.)
* VIATRA SDK 2.4.1.
* Yakindu Statechart Tools 3.5.13.

We recommend to start-up from an Eclipse IDE for Java and DSL Developers as it
contains EMF and Xtext so only VIATRA and Yakindu need to be downloaded.

- Download a new Eclipse IDE for [Java and DSL Developers package](https://www.eclipse.org/downloads/packages/release/2020-09/r/eclipse-ide-java-and-dsl-developers).
- Install the following two packages. The _Install_ window can be opened via the _Help > Install New Software..._ menu item. In the _Install_ window click _Add..._, and paste the necessary URL in the _Location_ text field. 
 - Install VIATRA 2.4.1 from update site: http://download.eclipse.org/viatra/updates/release/2.4.1.
    - Choose the whole _VIATRA Query and Transformation SDK_ package.
 - Intall the Yakindu Statechart Tools 3.5.13. from update site: http://updates.yakindu.com/statecharts/releases/. From the  _YAKINDU Statechart Tools Standard Edition_ package choose
	- _YAKINDU Statechart Tools_,
	- _YAKINDU Statechart Tools Base_,
	- _YAKINDU Statechart Tools Java Code Generator_ and
	- _YAKINDU License Integration For Standard Edition_ subpackages.

_Tip: It is advised to turn on automatic refreshing for the _runtime workspace_. The other option is to refresh it manually with F5 after every Gamma command._

## Plugin setup

The plugin setup procedure should be done as follows:
1. Import all Eclipse projects from the `plugins` folder.
2. Generate the Model plugin of the Gamma Expression Language: `hu.bme.mit.gamma.expression.model`. The Model plugin can be generated from the ecore file using a genmodel.
3. Generate the Model plugin of the Gamma Action Language: `hu.bme.mit.gamma.action.model`. It can be generated the same way as in the previous step.
3. Generate the Model plugin of the Gamma Statechart Language: `hu.bme.mit.gamma.statechart.model`. It can be generated the same way as in the previous step.
4. Generate the Model plugin of the traceability projects:
`hu.bme.mit.gamma.uppaal.transformation.traceability` and
`hu.bme.mit.gamma.yakindu.transformation.traceability`. Again use the ecore file and the genmodel.
5. Generate the Model plugin of the UPPAAL metamodel:
`de.uni_paderborn.uppaal`. Again use the ecore file and the genmodel.
6. Generate the Model plugin of the statechart generator model:
`hu.bme.mit.gamma.genmodel.model`. Again use the ecore file and the genmodel.
6. Generate the Model plugin of the trace model:
`hu.bme.mit.gamma.trace.model`. Again use the ecore file and the genmodel.
7. Run `hu.bme.mit.gamma.expression.language/src/hu/bme/mit/gamma/expression/language/GenerateExpressionLanguage.mwe2` as a MWE2 Workflow.
7. Run `hu.bme.mit.gamma.action.language/src/hu/bme/mit/gamma/action/language/GenerateActionLanguage.mwe2` as a MWE2 Workflow.
8. Run `hu.bme.mit.gamma.statechart.language/src/hu/bme/mit/gamma/statechart/language/GenerateStatechartLanguage.mwe2` as a MWE2 Workflow.
9. Run `hu.bme.mit.gamma.genmodel.language/src/hu/bme/mit/gamma/yakindu/genmodel/language/GenerateGenModel.mwe2` as a MWE2 Workflow.
10. Run `hu.bme.mit.gamma.trace.language/src/hu/bme/mit/gamma/trace/language/GenerateTraceLanguage.mwe2` as a MWE2 Workflow.
11. If needed, create the missing `bin`, `src-gen` and `xtend-gen` folders in the projects indicated in the error log.
12. Clean projects if needed.

Now you can use the framework in one of the following ways: you either run a runtime Eclipse and work in that or install the plugins into your host Eclipse.

Hopefully, now you have an Eclipse with the necessary plugins installed and ready to use the Gamma framework.

### Summary

#### Code generation from EMF artifacts:
| Project | Model | Edit | Editor |
|-|:-:|:-:|:-:|
|`de.uni_paderborn.uppaal`| x | | |
|`hu.bme.mit.gamma.expression.model`| x | | |
|`hu.bme.mit.gamma.action.model`| x | | |
|`hu.bme.mit.gamma.statechart.model`| x |  |  |
|`hu.bme.mit.gamma.trace.model`| x | | |
|`hu.bme.mit.gamma.uppaal.transformation.traceability`| x | | |
|`hu.bme.mit.gamma.genmodel.model`| x | | |
|`hu.bme.mit.gamma.yakindu.transformation.traceability`| x | | |

#### Code generation with MWE2 workflows:
| Project | Path |
|-|-|
| `hu.bme.mit.gamma.expression.language` | `/src/hu/bme/mit/gamma/expression/language/GenerateExpressionLanguage.mwe2` |
| `hu.bme.mit.gamma.action.language` | `/src/hu/bme/mit/gamma/action/language/GenerateActionLanguage.mwe2` |
| `hu.bme.mit.gamma.statechart.language` | `/src/hu/bme/mit/gamma/statechart/language/GenerateStatechartLanguage.mwe2` |
| `hu.bme.mit.gamma.trace.language` | `/src/hu/bme/mit/gamma/yakindu/genmodel/language/GenerateGenModel.mwe2` |
| `hu.bme.mit.gamma.genmodel.language` | `/src/hu/bme/mit/gamma/genmodel/language/GenerateGenModel.mwe2` |
