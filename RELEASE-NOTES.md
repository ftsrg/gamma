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

## 2018.12.28. - Version 2.1.0

### What is New

* Components are now parameterizable. Parameterization is supported by both formal verification and code generation functionalities.
* Gamma interfaces, Java code and UPPAAL model (in addition to Gamma statecharts) can be generated using the generator model.

### Improvements

* Bug regarding the linking of packages is fixed.
