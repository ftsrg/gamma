# Release Notes

## 2018.11.12. - Version 2.0.0

### What is New 

* Gamma now depends on VIATRA 2.0.2 and Yakindu 3.4.3.
* The Gamma Composite Language has a new syntax.
* Gamma supports two synchronous (synchronous composite and cascade composite) and two asynchronous composition modes (asynchronous adapter and asynchronous composite).
* Cascade composite components support the definition of an execution list.
* Gamma statecharts are serialized with a human-readable syntax.
* Imports in .gcd files now must be specified using a workspace URI. 
* The model checking is executed on a background thread.
* The formal verification of both synchronous and asynchronous component models is supported.
* Generate Test Set functionalitiy for deep validation is implemented.
* The results of the verification are serialized with a human-readable syntax.

## 2018.11.14. - Version 2.0.1

### Improvements

* Improvements have been made regarding content assist while editing the models in the Xtext editor.

## 2018.11.15. - Version 2.0.2

### Improvements

* Imports can be defined relatively to the importer file.
* Multiple triggers (in or relation) in Yakindu are transformable.

## 2018.11.23. - Version 2.0.3
	
### Improvements

* Improvements have been made regarding content assist while editing the models in the Xtext editor.
* Icons are added to .gcd, .ggen and .get files.
* Validation rules regarding asynchronous adapters are extended.
* Timing bug regarding asynchronous adapters is fixed.

## 2018.12.27. - Version 2.0.4
	
### Improvements

* Type checking regarding statecharts while editing the models in the Xtext editor is greatly improved.
* Content assist regarding the message queues of the asynchronous adapters is improved.
* Validation rules regarding the priority of message queues of asynchronous adapters are extended.

## 2018.02.28. - Version 2.1.0

### What is New

* Gamma now depends on VIATRA 2.1.0 and Yakindu 3.5.2.
* Components are now parameterizable. Parameterization is supported by both formal verification and code and test generation functionalities.
* Gamma interfaces, Java code, UPPAAL model and JUnit test suites (in addition to Gamma statecharts) can be generated using the generator model.
* Gamma execution traces now must have a name.
* Transition-covering test sets can now be generated.
* Statecharts can be executed in a bottom-up execution mode (subregions are executed first) in addition to the up to now supported top-down execution mode.
* Asynchronous adapters are now defined with the "adapter" keyword and adapt (paramterizable) component instances instead of component types.

### Improvements

* Bug regarding exit events of composite states is fixed.
* Bug regarding the linking of packages is fixed.
* Compatibility issues with the new VIATRA version are resolved.
* Queries generated with the GUI are now appended with an expression specifying activeness (isActive) when referring to states.

## 2018.03.28. - Version 2.1.1

### Improvements

* Validation rules regarding fork and join nodes are added.

## 2018.05.25. - Version 2.1.2

### What is New

* Gamma now depends on VIATRA 2.1.1 and Yakindu 3.5.3.
* A new action language has been introduced (GAL), wich provides new elements in actions, such as cycles and branches.
* The GCL metamodel and grammar have been refactored, they now depend on the GAL.

### Improvements
 
* Validation rules regarding the control specifications of asynchronous adapters are added.
* The Gamma-UPPAAL transformation has been optimized.
