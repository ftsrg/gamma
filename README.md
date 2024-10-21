# The Gamma Statechart Composition Framework

*Version 2.11.0* - For the latest version, check out the [dev](https://github.com/ftsrg/gamma/tree/dev) branch.

The Gamma Statechart Composition Framework is a toolset to model, verify and generate code for component-based reactive systems. The framework builds on Yakindu, an open source statechart modeling tool and provides an additional modeling layer to instatiate a communicating network of statecharts. Compositionality is hierarchical, which facilitates the creation of reusable component libraries. Individual statecharts, as well as composite statechart networks can be validated and verified by an automated translation to
- [UPPAAL](http://www.uppaal.org/), a model checker for timed automata,
- [Theta](https://github.com/ftsrg/theta), a generic, modular and configurable model checking framework,
- [Spin](https://spinroot.com/), a tool for the formal verification of multi-threaded software applications,
- [nuXmv](https://nuxmv.fbk.eu/), a symbolic model checker for the analysis of synchronous finite-state and infinite-state systems, or
- [Imandra](https://imandra.ai/), a programming language and an automated reasoning engine to create models/programs and reason about them.

Once a complete model is built, designers can use the code generation functionality of the framework, which can generate Java or C code for the whole system.

Check out http://gamma.inf.mit.bme.hu for more resources about Gamma. A good starting point is our [tool paper](https://inf.mit.bme.hu/sites/default/files/publications/icse18.pdf), [slides](https://www.slideshare.net/VinMol/icse2018-the-gamma-statechart-composition-framework-design-verification-and-code-generation-for-componentbased-reactive-systems) and [demo video](https://youtu.be/ng7lKd1wlDo) presented at [ICSE 2018](https://www.icse2018.org/event/icse-2018-demonstrations-the-gamma-statechart-composition-framework-design-verification-and-code-generation-for-component-based-reactive-systems) as well as our [journal paper](https://link.springer.com/article/10.1007/s10270-020-00806-5).

To cite Gamma, please cite the following paper. You can find additional publications about Gamma [here](http://ftsrg.mit.bme.hu/gamma/publications/#).

```
@inproceedings{molnar2018gamma,
    author = {Vince Moln{\'{a}}r and
              Bence Graics and
              Andr{\'{a}}s V{\"{o}}r{\"{o}}s and
              Istv{\'{a}}n Majzik and
              D{\'{a}}niel Varr{\'{o}}},
    title = {The {Gamma Statechart Composition Framework}: design, verification and code generation for component-based reactive systems},
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
* Eclipse IDE 2024-09, Eclipse IDE for Java and DSL Developers bundle. Note that Yakindu (see below) will not work with the _2023-12_ or newer Eclipse releases due to compatibility reasons.

##### 3rd-party Eclipse components (should be installed separately):
* VIATRA 2.9.1 (https://www.eclipse.org/viatra/),
* PlantUML 1.1.32 (https://plantuml.com/).

##### 3rd-party tools used by Gamma (should be installed separately):
* UPPAAL (Uppsala and Aalborg Universities, http://www.uppaal.org/),
* Spin (Available under the standard BSD 3-Clause open source license, https://spinroot.com/),
* nuXmv (Fondazione Bruno Kessler, https://nuxmv.fbk.eu/),
* Imandra (Imandra, https://imandra.ai/).

### Installation

* Install an Eclipse instance (e.g., Eclipse IDE for Java and DSL Developers) with EMF, Xtext and Java 17.
* Install the required 3rd-party Eclipse components. Detailed instructions can be found in the [`plugins/README.md`](plugins/README.md) file.
    * Alternatively you can use the provided Eclipse Oomph Installer to install the 3rd-party Eclipse components found [here](eclipse-environment/README.md). 
* Exit Eclipse and extract the [Gamma zip file](https://inf.mit.bme.hu/sites/default/files/gamma/2_10_0/gamma-tool-2.10.0.zip) containing the `dropins/plugins` folder (with the Gamma JAR files) into the root folder of Eclipse. This will create the plugins directory in the `dropins` folder of your root Eclipse folder, which should contain all JAR files of Gamma. (If not, make sure you copy all the JAR files contained in the Gamma zip file in the plugins directory of the `dropins` folder of the root folder of Eclipse.)
* When starting Eclipse for the first time, you might need to start it with the `-clean` flag.
* Check if the plugin installed successfully in *Help > About Eclipse* and by clicking Installation Details. On the `Plug-ins tab`, sort the entries by `Plugin-in Id` and look for entries starting with `hu.bme.mit.gamma`.
* For formal verification, download and extract UPPAAL. In order to let Gamma find the UPPAAL executables, add the `bin-Win32` or `bin-Linux` folder to the path environment variable (depending on the operating system being used).
* If you want to use Theta, check out the installation steps [here](plugins/xsts/README.md).
* If you want to use Spin, check out the installation steps [here](plugins/promela/README.md).
* If you want to use nuXmv, check out the installation steps [here](plugins/nuxmv/README.md).
* If you want to use xSAP, check out the installation steps [here](plugins/safety/README.md).
* If you want to use Imandra, check out the installation steps [here](plugins/iml/README.md).

### Tutorials

The tutorials for the framework can be found in the following [folder](tutorial).

## Contact

Contact us by sending an e-mail to `gamma [at] mit.bme.hu`.

## Acknowledgement

Supporters of the Gamma project:

* [MTA-BME Lendület Cyber-Physical Systems Research Group](http://lendulet.inf.mit.bme.hu/),
* [Fault Tolerant Systems Research Group](https://inf.mit.bme.hu/en), [Department of Measurement and Information Systems](https://www.mit.bme.hu/eng/), [Budapest University of Technology and Economics](http://www.bme.hu/?language=en),
* [Új Nemzeti Kiválóság Program (ÚNKP) 2017-2018](http://unkp.gov.hu),
* [Új Nemzeti Kiválóság Program (ÚNKP) 2019-2020](http://unkp.gov.hu),
* [Új Nemzeti Kiválóság Program (ÚNKP) 2020-2021](http://www.unkp.gov.hu/palyazatok/felsooktatasi-doktori-hallgatoi-doktorjelolti-kutatoi-osztondij/felsooktatasi-doktori),
* [Új Nemzeti Kiválóság Program (ÚNKP) 2022-2023](http://www.unkp.gov.hu/palyazatok/felsooktatasi-doktori),
* [Új Nemzeti Kiválóság Program (ÚNKP) 2023-2024](http://www.unkp.gov.hu/palyazatok/tudomannyal-fel),
* [Emberi Erőforrás Fejlesztési Operatív Program (EFOP)](http://www.eit.bme.hu/news/20170927-palyazati-felhivas-szakmai-osztondij?language=en) (EFOP-3.6.2-16-2017-00013),
* [NRDI Fund of Hungary](https://itea3.org/project/embrace.html) (2019-2.1.1-EUREKA-2019-00001 EMBrACE project),
* [EU ECSEL and NRDI Fund of Hungary](https://www.arrowhead.eu/arrowheadtools) (EU ECSEL 826452 and NRDI Fund 2019-2.1.3-NEMZ_ECSEL-2019-00003 Arrowhead Tools project), and
* [Versenyképességi és kiválósági együttműködések program (VKE)](https://prolan.hu/hu/oldal/VKE) (2018-1.3.1-VKE-2018-00040 projekt).

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
