package hu.bme.mit.gamma.ocra.transformation

import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.RealizationMode
import hu.bme.mit.gamma.xsts.transformation.util.Namings

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.transformation.util.Namings.*
import hu.bme.mit.gamma.statechart.interface_.Component

class NamingSerializer extends Namings {

    def static dispatch String customizePortName(Event event, Port port, ComponentInstance instanceName) {
        if (port.interfaceRealization.realizationMode == RealizationMode.PROVIDED) '''«customizeOutputName(event, port, instanceName.customizeComponentName)»'''
        else '''«customizeInputName(event, port, instanceName.customizeComponentName)»'''
    }
    
    def static dispatch String customizePortName(Event event, Port port, ComponentInstanceReferenceExpression instanceName) {
        if (port.interfaceRealization.realizationMode == RealizationMode.PROVIDED) '''«customizeOutputName(event, port, instanceName.customizeComponentName)»'''
        else '''«customizeInputName(event, port, instanceName.customizeComponentName)»'''
    }
    
    def static dispatch String customizePortName(Event event, Port port, String instanceName) {
        if (port.interfaceRealization.realizationMode == RealizationMode.PROVIDED) '''«customizeOutputName(event, port, instanceName.customizeComponentName)»'''
        else '''«customizeInputName(event, port, instanceName.customizeComponentName)»'''
    }
    
    def static dispatch String customizePortName(Event event, Port port, Component instanceName) {
        if (port.interfaceRealization.realizationMode == RealizationMode.PROVIDED) '''«customizeOutputName(event, port, instanceName.customizeComponentName)»'''
        else '''«customizeInputName(event, port, instanceName.customizeComponentName)»'''
    }
    
    static def  String customizeBindinName(Event event, Port leftPort, String leftInstance, Port rightPort, String rightInstance) {
        if (leftPort.interfaceRealization.realizationMode == RealizationMode.PROVIDED) '''
        «customizePortName(event, leftPort, leftInstance)» := «rightInstance».«customizePortName(event, rightPort, rightInstance)»'''
        else '''
        «rightInstance».«customizePortName(event, rightPort, rightInstance)» := «customizePortName(event, leftPort, leftInstance)»'''
    }
    
    static def  String customizeChannelName(Event event, Port leftPort, String leftInstance, Port rightPort, String rightInstance) {
        '''«leftInstance».«customizePortName(event, leftPort, leftInstance)» := «rightInstance».«customizePortName(event, rightPort, rightInstance)»'''
    }
    
    static def  String customizeConstraintName(Event event, Port port, ComponentInstanceReferenceExpression instance) {
		if (port.isInputEvent(event)) {
			return '''«instance.customizeComponentName».«event.customizeInputName(port, instance)»'''
		}
		return '''«instance.customizeComponentName».«event.customizeOutputName(port, instance)»'''
	}
	
	static private def String capitalizeFirstLetter(String input) {
	    if (input === null || input.isEmpty) {
	        return input
	    }
	    return input.substring(0, 1).toUpperCase + input.substring(1)
	}

	
	static def String customizeComponentName(ComponentInstance instance) '''«instance.name.capitalizeFirstLetter»'''
	static def String customizeComponentName(ComponentInstanceReferenceExpression instance) '''«instance.FQN.capitalizeFirstLetter»'''
	static def String customizeComponentName(String instance) '''«instance.capitalizeFirstLetter»'''
	static def String customizeComponentName(Component instance) '''«instance.name.capitalizeFirstLetter»'''
	
}