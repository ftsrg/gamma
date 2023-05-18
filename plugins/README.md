# Building Gamma

## Eclipse setup

You will need Java 17 to setup Gamma.

Gamma has been implemented as a set of Eclipse plugins. To use the
framework, you will need an Eclipse with the following plugins installed:
* Eclipse Modeling Framework SDK 2.33.0.
* Xtext Complete SDK 2.30.0. (It contains Xtend, there is no need for the additional download of Xtend.)
* VIATRA SDK 2.7.1.
* Yakindu Statechart Tools 3.5.13.
* PlantUML 1.1.27.

We recommend to start-up from an Eclipse IDE for Java and DSL Developers as it contains EMF and Xtext so only VIATRA, Yakindu and PlantUML need to be downloaded.

- Download a new Eclipse IDE for [Java and DSL Developers package](https://www.eclipse.org/downloads/packages/release/2023-03/r/eclipse-ide-java-and-dsl-developers).
- Run Eclipse. If an error message is thrown about the unavailability of Java (this happens if Java is not added to your path), you have to specifiy the path to your Java installation (`javaw.exe` in the `bin` folder) for Eclipse. Open the `eclipse.ini` file in the root folder of your Eclipse with a text editor and add the following two lines right above the `-vmargs` line:
```
-vm
path_to_your_java_insallation/Java/jdk-version/bin/javaw.exe
```
- Install the following two packages. The _Install_ window can be opened via the _Help > Install New Software..._ menu item. In the _Install_ window click _Add..._, and paste the necessary URL in the _Location_ text field. 
 - Install VIATRA 2.7.1 from update site: http://download.eclipse.org/viatra/updates/release/2.7.1.
    - Choose the whole _VIATRA Query and Transformation SDK_ package.
 - Install the Yakindu Statechart Tools 3.5.13. from update site: http://updates.yakindu.com/statecharts/releases/3.5.13. From the  _YAKINDU Statechart Tools Standard Edition_ package choose
	- _YAKINDU Statechart Tools_,
	- _YAKINDU Statechart Tools Base_,
	- _YAKINDU Statechart Tools Java Code Generator_ and
	- _YAKINDU License Integration For Standard Edition_ subpackages.
	
Furthermore, it is *necessary* to setup the environment for the *PlantUML* visualization plugins located in the [`vis`](vis) folder. The instructions are described in the [`README`](vis/README.md) file of the folder.

If you want to use the *XSTS* formalism for formal verification (via *Theta*) and code generation for standalone statecharts, you will have to setup the plugins located in the [`xsts`](xsts) folder. The instructions are described in the [`README`](xsts/README.md) file of the folder.

If you want to use *UPPAAL* for formal verification, download and extract *UPPAAL 4.1.26*. In order to let Gamma find the UPPAAL executables, add the `bin-Win32` or `bin-Linux` folder to the path environment variable (depending on the operating system being used).
- If you are on more recent Linux distributions *UPPAAL* has issues with the newer `libc`. In [this discussion](https://groups.google.com/g/uppaal/c/B_Fml7_z0IE) you will find a solution to this problem.

If you want to use *Spin* for formal verification, download and extract *Spin 6.5.1* or higher version. In order to let Gamma find the Spin executable, add the `spin.exe` or `spin` to the path environment variable (depending on the operating system being used). The instructions are described in the [`README`](promela/README.md) file of the folder.

Make sure to set the text file encoding of your Eclipse workspace to **UTF-8**: _Window > Preferences..._ Start typing `workspace` in the left upper textfield (in the place of `type filter text`). Select _General > Workspace_ from the filtered item list and check the `Text file encoding` setting at the bottom of the window.

Make sure to set the Java compiler compliance level to **17**: _Window > Preferences..._ Start typing `compiler` in the left upper textfield (in the place of `type filter text`). Select _Java > Compiler_ from the filtered item list and set the `Compiler compliance level` to **17** at the top of the window.

_Tip: It is advised to turn on automatic refreshing for the _runtime workspace_. The other option is to refresh it manually with F5 after every Gamma command if the generated files do not appear._

## Plugin setup

The plugins can be setup using the plugin in the `setup` folder or manually.

### Using the setup plugin

The setup procedure should be done as follows:

1. Import all Eclipse projects from the `plugins` folder.
1. Run `hu.bme.mit.gamma.setup/src/hu/bme/mit/gamma/setup/GenerateAllModels.mwe2` as a MWE2 Workflow.
1. Run `hu.bme.mit.gamma.setup/src/hu/bme/mit/gamma/setup/GenerateAllLanguages.mwe2` as a MWE2 Workflow.

### Manual setup

The manual plugin setup procedure should be done as follows:
1. Import all Eclipse projects from the `plugins/core` folder.
2. Generate the Model plugin of the Gamma Expression Language: `hu.bme.mit.gamma.expression.model`. The Model plugin can be generated from the ecore file using a genmodel.
3. Generate the Model plugin of the Gamma Action Language: `hu.bme.mit.gamma.action.model`. It can be generated the same way as in the previous step.
3. Generate the Model plugin of the Gamma Statechart Language: `hu.bme.mit.gamma.statechart.model`. It can be generated the same way as in the previous step.
3. Generate the Model plugin of the Gamma Property Language: `hu.bme.mit.gamma.property.model`. It can be generated the same way as in the previous step.
6. Generate the Model plugin of the Gamma Genmodel Language: `hu.bme.mit.gamma.genmodel.model`. Again use the ecore file and the genmodel.
6. Generate the Model plugin of the Gamma Test Language: `hu.bme.mit.gamma.trace.model`. Again use the ecore file and the genmodel.
6. Generate the Model plugin of the UPPAAL metamodel: `de.uni_paderborn.uppaal`. Again use the ecore file and the genmodel.
6. Generate the Model plugin of the traceability projects: `hu.bme.mit.gamma.uppaal.transformation.traceability` and `hu.bme.mit.gamma.yakindu.transformation.traceability`. Again use the ecore file and the genmodel.
7. Run `hu.bme.mit.gamma.expression.language/src/hu/bme/mit/gamma/expression/language/GenerateExpressionLanguage.mwe2` as a MWE2 Workflow.
7. Run `hu.bme.mit.gamma.action.language/src/hu/bme/mit/gamma/action/language/GenerateActionLanguage.mwe2` as a MWE2 Workflow.
8. Run `hu.bme.mit.gamma.statechart.language/src/hu/bme/mit/gamma/statechart/language/GenerateStatechartLanguage.mwe2` as a MWE2 Workflow.
9. Run `hu.bme.mit.gamma.genmodel.language/src/hu/bme/mit/gamma/genmodel/language/GenerateGenModel.mwe2` as a MWE2 Workflow.
10. Run `hu.bme.mit.gamma.trace.language/src/hu/bme/mit/gamma/trace/language/GenerateTraceLanguage.mwe2` as a MWE2 Workflow.
10. Import all Eclipse projects from the `plugins/scenario` folder.
10. Generate the Model plugin of the Gamma Scenario Language: `hu.bme.mit.gamma.scenario.model`. The Model plugin can be generated from the ecore file using a genmodel.
10. Run `hu.bme.mit.gamma.scenario.language/src/hu/bme/mit/gamma/scenario/language/GenerateScenarioLanguage.mwe2` as a MWE2 Workflow.
11. If necessary, create the missing `bin`, `src-gen` and `xtend-gen` folders in the projects indicated in the error log.
12. Clean projects if necessary.

#### Summary

##### Code generation from EMF artifacts:
| Project | Model | Edit | Editor |
|-|:-:|:-:|:-:|
|`de.uni_paderborn.uppaal`| x | | |
|`hu.bme.mit.gamma.expression.model`| x | | |
|`hu.bme.mit.gamma.action.model`| x | | |
|`hu.bme.mit.gamma.statechart.model`| x |  |  |
|`hu.bme.mit.gamma.property.model`| x |  |  |
|`hu.bme.mit.gamma.trace.model`| x | | |
|`hu.bme.mit.gamma.uppaal.transformation.traceability`| x | | |
|`hu.bme.mit.gamma.genmodel.model`| x | | |
|`hu.bme.mit.gamma.yakindu.transformation.traceability`| x | | |
|`hu.bme.mit.gamma.scenario.model`| x | | |

##### Code generation with MWE2 workflows:
| Project | Path |
|-|-|
| `hu.bme.mit.gamma.expression.language` | `/src/hu/bme/mit/gamma/expression/language/GenerateExpressionLanguage.mwe2` |
| `hu.bme.mit.gamma.action.language` | `/src/hu/bme/mit/gamma/action/language/GenerateActionLanguage.mwe2` |
| `hu.bme.mit.gamma.statechart.language` | `/src/hu/bme/mit/gamma/statechart/language/GenerateStatechartLanguage.mwe2` |
| `hu.bme.mit.gamma.property.language` | `/src/hu/bme/mit/gamma/property/language/GeneratePropertyLanguage.mwe2` |
| `hu.bme.mit.gamma.trace.language` | `/src/hu/bme/mit/gamma/trace/language/GenerateTraceLanguage.mwe2` |
| `hu.bme.mit.gamma.genmodel.language` | `/src/hu/bme/mit/gamma/genmodel/language/GenerateGenModel.mwe2` |
| `hu.bme.mit.gamma.scenario.language` | `/src/hu/bme/mit/gamma/scenario/language/GenerateScenarioLanguage.mwe2` |

## Using Gamma functionalities

Hopefully, now you have an Eclipse with the necessary plugins installed and ready to use the Gamma framework.

Now you can use the functionalities of the framework in one of the following ways: you either run a runtime Eclipse and work in that or install the plugins into your host Eclipse.
