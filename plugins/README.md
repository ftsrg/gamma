# Building Gamma

## Eclipse setup

You will need Java 17 to setup Gamma.

Gamma has been implemented as a set of Eclipse plugins. To use the framework, you will need an Eclipse with the following plugins installed:
* Eclipse Modeling Framework SDK 2.39.0,
* Xtext Complete SDK 2.36.0 (it contains Xtend, there is no need for the additional download of Xtend),
* VIATRA SDK 2.9.1,
* PlantUML 1.1.32,
* (Optional) Ecore Diagram Tools/Sirius (if you want to have a graphical representation of the EMF metamodels of Gamma).

We recommend starting from an Eclipse IDE for Java and DSL Developers as it contains EMF and Xtext so only VIATRA, Yakindu and PlantUML need to be downloaded.

- Download a new Eclipse IDE for [Java and DSL Developers package](https://www.eclipse.org/downloads/packages/release/2024-09/r/eclipse-ide-java-and-dsl-developers). Note that Yakindu (see below) will not work with the _2023-12_ or newer Eclipse releases due to compatibility reasons.
- Run Eclipse. If an error message is thrown about the unavailability of Java (this happens if Java is not added to your path), you have to specifiy the path to your Java installation (`javaw.exe` in the `bin` folder) for Eclipse. Open the `eclipse.ini` file in the root folder of your Eclipse with a text editor and add the following two lines right above the `-vmargs` line:
```
-vm
path_to_your_java_insallation/Java/jdk-version/bin/javaw.exe
```
- Install the following packages. The _Install_ window can be opened via the _Help > Install New Software..._ menu item. In the _Install_ window click _Add..._, and paste the necessary URL in the _Location_ text field. 
   - Install VIATRA 2.9.1 from update site: http://download.eclipse.org/viatra/updates/release/2.9.1.
     - Choose the whole _VIATRA Query and Transformation SDK_ package.
   - Furthermore, it is *necessary* to setup the environment for the *PlantUML* visualization plugins located in the [`vis`](vis) folder. The instructions are described in the [`README`](vis/README.md) file of the folder.

Make sure to set the text file encoding of your Eclipse workspace to **UTF-8**: _Window > Preferences..._ Start typing `workspace` in the left upper textfield (in the place of `type filter text`). Select _General > Workspace_ from the filtered item list and check the `Text file encoding` setting at the bottom of the window.

Make sure to set the Java compiler compliance level to **17**: _Window > Preferences..._ Start typing `compiler` in the left upper textfield (in the place of `type filter text`). Select _Java > Compiler_ from the filtered item list and set the `Compiler compliance level` to **17** at the top of the window.

_Tip: It is advised to turn on automatic refreshing for the _runtime workspace_: _Window > Preferences..._ Start typing `hooks` in the left upper textfield (in the place of `type filter text`). Select _General > Workspace_ from the filtered item list and check the `Refresh using native hooks and polling` setting at the top of the window. The other option is to refresh it manually with F5 after every Gamma command if the generated files do not appear._

## Verification backends

If you want to use the *XSTS* formalism for formal verification (via *Theta*) and code generation for standalone statecharts, you will have to setup the plugins located in the [`xsts`](xsts) folder. The instructions are described in the [`README`](xsts/README.md) file of the folder.

If you want to use *UPPAAL* for formal verification, download and extract *UPPAAL 5.0.0*. In order to let Gamma find the UPPAAL executables, add the `bin-Win32` or `bin-Linux` folder to the path environment variable (depending on the operating system being used).
- If you are on more recent Linux distributions *UPPAAL* has issues with the newer `libc`. In [this discussion](https://groups.google.com/g/uppaal/c/B_Fml7_z0IE) you will find a solution to this problem.

If you want to use *Spin* for formal verification, download and extract *Spin 6.5.1* or higher version. In order to let Gamma find the Spin executable, add the `spin.exe` or `spin` to the path environment variable (depending on the operating system being used). The instructions are described in the [`README`](promela/README.md) file of the folder.

If you want to use *nuXmv* for formal verification, download and extract *nuXmv 2.0.0* or higher version. In order to let Gamma find the nuXmv executable, add the `nuXmv.exe` or `nuXmv` to the path environment variable (depending on the operating system being used). The instructions are described in the [`README`](nuxmv/README.md) file of the folder.

If you want to use *xSAP* for safety assessment, download and extract *xSAP 1.4.0* or higher version. In order to let Gamma find the xSAP executable, create an environment variable named `XSAP_HOME` that points to the extracted xSAP root folder (absolute path) and add the `xSAP/bin` folder to the PATH environment or default search path (depending on your OS). The instructions are described in the [`README`](safety/README.md) file of the folder.

If you want to use *Imandra* for formal verification, download Python 3, install Imandra using *pip*, and use the corresponding script to download *imandra-cli* and authenticate yourself to the Imandra server. The instructions are described in the [`README`](iml/README.md) file of the folder.

## Plugin setup

If you have Git installed, it is recommended to clone the [Gamma repository](https://github.com/ftsrg/gamma) to your local machine by clicking on the green `Code` button of the front page and using the appearing URL: open a command line and navigate into the folder where you want to clone the repository, then run the `git clone https://github.com/ftsrg/gamma.git` command. After this, make sure to checkout the branch of your choice, e.g., `master` if you want to use the latest release, or `dev` if you want to use also the functionalities implemented since the latest release.

Otherwise, you can download the zip file containing the content of the repository (`Download ZIP` button) and extract it.

The plugins can be setup using the plugin in the `setup` folder or manually.

### Using the setup plugin

The setup procedure should be done as follows:

1. Import all Eclipse projects from the `plugins` folder.
1. Run `hu.bme.mit.gamma.setup/src/hu/bme/mit/gamma/setup/GenerateAllModels.mwe2` as a MWE2 Workflow.
1. Run `hu.bme.mit.gamma.setup/src/hu/bme/mit/gamma/setup/GenerateAllLanguages.mwe2` as a MWE2 Workflow.
1. Clean all the projects if any error remains in the workaspace (common in the case of projects using VIATRA patterns): _Project > Clean..._.

When running the workflows for the first time, a pop-up window may appear stating that there are errors in the workspace (e.g., missing folders that are generated after the execution of the workflows). Proceed with the running anyway.

### Manual setup

The manual plugin setup procedure should be done as follows:
1. Import all Eclipse projects from the `plugins` folder.
2. Generate the Model plugin of the Gamma Expression Language: `hu.bme.mit.gamma.expression.model`. The Model plugin can be generated from the ecore file using a genmodel.
3. Generate the Model plugin of the Gamma Action Language: `hu.bme.mit.gamma.action.model`. It can be generated the same way as in the previous step.
3. Generate the Model plugin of the Gamma Statechart Language: `hu.bme.mit.gamma.statechart.model`. It can be generated the same way as in the previous step.
3. Generate the Model plugin of the Gamma Property Language: `hu.bme.mit.gamma.property.model`. It can be generated the same way as in the previous step.
6. Generate the Model plugin of the Gamma Genmodel Language: `hu.bme.mit.gamma.genmodel.model`. Again use the ecore file and the genmodel.
6. Generate the Model plugin of the Gamma Test Language: `hu.bme.mit.gamma.trace.model`. Again use the ecore file and the genmodel.
6. Generate the Model plugin of the Gamma Scenario Language: `hu.bme.mit.gamma.scenario.model`. Again use the ecore file and the genmodel.
6. Generate the Model plugin of the Gamma Fault Extension Language: `hu.bme.mit.gamma.fei.model`. Again use the ecore file and the genmodel.
6. Generate the Model plugin of the UPPAAL metamodel: `de.uni_paderborn.uppaal`. Again use the ecore file and the genmodel.
6. Generate the Model plugin of the traceability projects: `hu.bme.mit.gamma.uppaal.transformation.traceability` and `hu.bme.mit.gamma.yakindu.transformation.traceability`. Again use the ecore file and the genmodel.
7. Run `hu.bme.mit.gamma.expression.language/src/hu/bme/mit/gamma/expression/language/GenerateExpressionLanguage.mwe2` as a MWE2 Workflow.
7. Run `hu.bme.mit.gamma.action.language/src/hu/bme/mit/gamma/action/language/GenerateActionLanguage.mwe2` as a MWE2 Workflow.
8. Run `hu.bme.mit.gamma.statechart.language/src/hu/bme/mit/gamma/statechart/language/GenerateStatechartLanguage.mwe2` as a MWE2 Workflow.
9. Run `hu.bme.mit.gamma.genmodel.language/src/hu/bme/mit/gamma/genmodel/language/GenerateGenModel.mwe2` as a MWE2 Workflow.
10. Run `hu.bme.mit.gamma.trace.language/src/hu/bme/mit/gamma/trace/language/GenerateTraceLanguage.mwe2` as a MWE2 Workflow.
10. Run `hu.bme.mit.gamma.scenario.language/src/hu/bme/mit/gamma/scenario/language/GenerateScenarioLanguage.mwe2` as a MWE2 Workflow.
10. Run `hu.bme.mit.gamma.fei.language/src/hu/bme/mit/gamma/fei/language/GenerateFaultExtensionLanguage.mwe2` as a MWE2 Workflow.
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
|`hu.bme.mit.gamma.fei.model`| x | | |

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
| `hu.bme.mit.gamma.fei.language` | `/src/hu/bme/mit/gamma/fei/language/GenerateFaultExtensionLanguage.mwe2` |

## Using Gamma functionalities

Hopefully, now you have an Eclipse with the necessary plugins installed and ready to use the Gamma framework.

Now you can use the functionalities of the framework in one of the following ways: you either run a runtime Eclipse and work in that or install the plugins into your host Eclipse.
