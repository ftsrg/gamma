# The Gamma Statechart Composition Framework

*Version 2.4.0* - For the latest version, check out the [dev](https://github.com/ftsrg/gamma/tree/dev) branch.

The Gamma Statechart Composition Framework is a toolset to model, verify and generate code for component-based reactive systems. The framework builds on Yakindu, an open source statechart modeling tool and provides an additional modeling layer to instatiate a communicating network of statecharts. Compositionality is hierarchical, which facilitates the creation of reusable component libraries. Individual statecharts, as well as composite statechart networks can be validated and verified by an automated translation to UPPAAL, a model checker for timed automata, or [Theta](https://github.com/ftsrg/theta), a generic, modular and configurable model checking framework. Once a complete model is built, designers can use the code generation functionality of the framework, which can generate Java code for the whole system.

Check out http://gamma.inf.mit.bme.hu for more resources about Gamma. A good starting point is our [tool paper](https://inf.mit.bme.hu/sites/default/files/publications/icse18.pdf), [slides](https://www.slideshare.net/VinMol/icse2018-the-gamma-statechart-composition-framework-design-verification-and-code-generation-for-componentbased-reactive-systems) and [demo video](https://youtu.be/ng7lKd1wlDo) presented at [ICSE 2018](https://www.icse2018.org/event/icse-2018-demonstrations-the-gamma-statechart-composition-framework-design-verification-and-code-generation-for-component-based-reactive-systems).

To cite Gamma, please cite the following paper. You can find additional publications about Gamma [here](http://ftsrg.mit.bme.hu/gamma/publications/#).

```
@inproceedings{molnar2018gamma,
    author = {Vince Moln{\'{a}}r and
              Bence Graics and
              Andr{\'{a}}s V{\"{o}}r{\"{o}}s and
              Istv{\'{a}}n Majzik and
              D{\'{a}}niel Varr{\'{o}}},
    title = {The {G}amma statechart composition framework: design, verification and code generation for component-based reactive systems},
    booktitle = {Proceedings of the 40th International Conference on Software Engineering: Companion Proceeedings},
    pages = {113--116},
    year = {2018},
    publisher = {ACM},
    doi = {10.1145/3183440.3183489}
}
```

## Using Gamma

### Dependencies

##### Recommended Eclipse version and bundle:
* Eclipse IDE 2020-09, Eclipse IDE for Java and DSL Developers bundle.

##### 3rd-party Eclipse components (should be installed separately):
* Xtext 2.23.0 (https://www.eclipse.org/Xtext/, included in Eclipse bundle),
* VIATRA 2.4.1 (https://www.eclipse.org/viatra/),
* Yakindu Statechart Tools 3.5.13 (https://www.itemis.com/en/yakindu/state-machine/).

##### 3rd-party tools used by Gamma (should be installed separately):
* UPPAAL (Uppsala and Aalborg Universities, http://www.uppaal.org/).

### Installation

* Have an Eclipse instance (Eclipse IDE for Java and DSL Developers) with EMF, Xtext and Java 11.
* Install VIATRA 2.4.1 and the Yakindu Statechart Tools 3.5.13.
* Exit Eclipse and extract the Gamma zip file containing the `dropins/plugins` folder (with the Gamma JAR files) into the root folder of Eclipse. This will create the plugins directory in the dropins folder of your root Eclipse folder, which should contain all JAR files of Gamma. (If not, make sure you copy all the JAR files contained in the Gamma zip file in the plugins directory of the dropins folder of the root folder of Eclipse.)
* When starting Eclipse for the first time, you might need to start it with the -clean flag.
* Check if the plugin installed successfully in Help > About Eclipse and by clicking Installation Details. On the Plug-ins tab, sort the entries by Plugin-in Id and look for entries starting with hu.bme.mit.gamma. 
* For formal verification, download and extract UPPAAL. In order to let Gamma find the UPPAAL executables, add the bin-Win32 or bin-Linux folder to the path environment variable (depending on the operating system being used).
* If you want to use Theta, check out the installation steps [here](https://github.com/ftsrg/gamma/blob/master/plugins/xsts/README.md).

### Tutorials

The tutorials for the framework can be found in the following [folder](https://github.com/FTSRG/gamma/blob/master/tutorial).

## Contact

Contact us by sending an e-mail to `gamma [at] mit.bme.hu`.
 
## Acknowledgement

Supporters of the Gamma project:

* [MTA-BME Lendület Cyber-Physical Systems Research Group](http://lendulet.inf.mit.bme.hu/),
* [Fault Tolerant Systems Research Group](https://inf.mit.bme.hu/en), [Department of Measurement and Information Systems](https://www.mit.bme.hu/eng/), [Budapest University of Technology and Economics](http://www.bme.hu/?language=en),
* [Új Nemzeti Kiválóság Program (ÚNKP) 2017-2018](http://unkp.gov.hu),
* [Új Nemzeti Kiválóság Program (ÚNKP) 2019-2020](http://unkp.gov.hu),
* [Új Nemzeti Kiválóság Program (ÚNKP) 2020-2021](http://www.unkp.gov.hu/palyazatok/felsooktatasi-doktori-hallgatoi-doktorjelolti-kutatoi-osztondij/felsooktatasi-doktori),
* [Emberi Erőforrás Fejlesztési Operatív Program (EFOP)](http://www.eit.bme.hu/news/20170927-palyazati-felhivas-szakmai-osztondij?language=en) (EFOP-3.6.2-16-2017-00013),
* [EMBrACE](https://itea3.org/project/embrace.html) - Environment for model-based rigorous adaptive co-design and operation of CPS.

Special thanks to: 

* András Vörös,
* Oszkár Semeráth,
* Kristóf Marussy,
* Ákos Hajdu,
* Dániel Varró,
* István Ráth,
* Zoltán Micskei,
* István Majzik,
* IncQuery Labs Ltd.
