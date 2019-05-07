# Building Gamma

## Eclipse setup

The presented framework has been implemented as a set of Eclipse plugins. To use the
framework, you will need an Eclipse with the following plugins installed:
* Eclipse Modeling Framework SDK 2.17.0.
* Xtext Complete SDK 2.17.0. (It contains Xtend, no need for the additional download
of Xtend.)
* VIATRA SDK 2.1.1.
* Yakindu Statechart Tools 3.5.3.

We recommend to start-up from an Eclipse IDE for Java and DSL Developers as it
contains EMF and Xtext so only VIATRA and Yakindu need to be downloaded.

## Plugin setup

The plugin setup procedure should be done as follows:
1. Import all Eclipse projects from the `plugins` folder.
2. Generate the Model and Edit plugins of the Gamma Constraint language: `hu.bme.mit.gamma.constraint.model`. The Model and Edit plugins can be generated from the ecore file using a genmodel.
3. Generate the Model, Edit and Editor plugins of the Gamma Statechart language: `hu.bme.mit.gamma.statechart.model`. They can be generated the same way as in the previous step.
4. Generate the Model plugin of the traceability projects:
`hu.bme.mit.gamma.uppaal.transformation.traceability` and
`hu.bme.mit.gamma.yakindu.transformation.traceability`. Again use the ecore file and the genmodel.
5. Generate the Model plugin of the UPPAAL metamodel:
`de.uni_paderborn.uppaal`. Again use the ecore file and the genmodel.
6. Generate the Model plugin of the statechart generator model:
`hu.bme.mit.gamma.yakindu.genmodel`. Again use the ecore file and the genmodel.
6. Generate the Model plugin of the trace model:
`hu.bme.mit.gamma.trace.model`. Again use the ecore file and the genmodel.
7. Run `hu.bme.mit.gamma.constraint.language/src/hu/bme/mit/gamma/constraint/language/GenerateConstraintLanguage.mwe2` as a MWE2 Workflow.
8. Run `hu.bme.mit.gamma.statechart.language/src/hu/bme/mit/gamma/statechart/language/GenerateStatechartLanguage.mwe2` as a MWE2 Workflow.
9. Run `hu.bme.mit.gamma.yakindu.genmodel.language/src/hu/bme/mit/gamma/yakindu/genmodel/language/GenerateGenModel.mwe2` as a MWE2 Workflow.
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
|`hu.bme.mit.gamma.constraint.model`| x | x | |
|`hu.bme.mit.gamma.statechart.model`| x | x | x |
|`hu.bme.mit.gamma.trace.model`| x | | |
|`hu.bme.mit.gamma.uppaal.transformation.traceability`| x | | |
|`hu.bme.mit.gamma.yakindu.genmodel`| x | | |
|`hu.bme.mit.gamma.yakindu.transformation.traceability`| x | | |

#### Code generation with MWE2 workflows:
| Project | Path |
|-|-|
| `hu.bme.mit.gamma.constraint.language` | `/src/hu/bme/mit/gamma/constraint/language/GenerateConstraintLanguage.mwe2` |
| `hu.bme.mit.gamma.statechart.language` | `/src/hu/bme/mit/gamma/statechart/language/GenerateStatechartLanguage.mwe2` |
| `hu.bme.mit.gamma.trace.language` | `/src/hu/bme/mit/gamma/yakindu/genmodel/language/GenerateGenModel.mwe2` |
| `hu.bme.mit.gamma.yakindu.genmodel.language` | `/src/hu/bme/mit/gamma/yakindu/genmodel/language/GenerateGenModel.mwe2` |
