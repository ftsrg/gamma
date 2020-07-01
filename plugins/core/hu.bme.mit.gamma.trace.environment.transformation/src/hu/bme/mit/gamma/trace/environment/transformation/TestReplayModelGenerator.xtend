package hu.bme.mit.gamma.trace.environment.transformation

import hu.bme.mit.gamma.statechart.composite.CompositeModelFactory
import hu.bme.mit.gamma.statechart.composite.InstancePortReference
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import java.util.AbstractMap.SimpleEntry

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class TestReplayModelGenerator {
	
	protected final ExecutionTrace executionTrace
	
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension InterfaceModelFactory interfaceModelFactory = InterfaceModelFactory.eINSTANCE
	protected final extension CompositeModelFactory statechartModelFactory = CompositeModelFactory.eINSTANCE
	
	new(ExecutionTrace executionTrace) {
		this.executionTrace = executionTrace
	}
	
	/**
	 * Returns the resulting environment model and system model wrapped into Packages.
	 * Both have to be serialized.
	 */
	def execute() {
		val transformer = new TraceToEnvironmentModelTransformer(executionTrace)
		val result = transformer.execute
		val environmentModel = result.key
		val trace = transformer.getTrace
		
		val testModel = executionTrace.component as SynchronousComponent
		val systemModel = testModel.wrapSynchronousComponent => [
			it.name = getSystemModelName(environmentModel, testModel)
		]
		val componentInstance = systemModel.components.head => [
			it.name = it.name.toFirstLower
		]
		
		val environmentInstance = environmentModel.instantiateSynchronousComponent
		systemModel.components.add(0, environmentInstance)
		
		systemModel.ports.clear
		systemModel.portBindings.clear
		
		for (portPair : trace.portPairs) {
			val componentPort = portPair.key
			val environmentPort = portPair.value
			
			var InstancePortReference providedReference = createInstancePortReference
			var InstancePortReference requiredReference = createInstancePortReference
			
			val channel = createSimpleChannel
			channel.providedPort = providedReference
			channel.requiredPort = requiredReference
			systemModel.channels += channel
			
			if (componentPort.isProvided) {
				providedReference.instance = componentInstance
				providedReference.port = componentPort
				requiredReference.instance = environmentInstance
				requiredReference.port = environmentPort
			}
			else {
				providedReference.instance = environmentInstance
				providedReference.port = environmentPort
				requiredReference.instance = componentInstance
				requiredReference.port = componentPort
			}
		}
		
		// Wrapping the resulting packages
		val environmentPackage = environmentModel.wrapIntoPackage
		val systemPackage = systemModel.wrapIntoPackage
		
		environmentPackage.imports += testModel.interfaceImports // E.g., interfaces
		systemPackage.imports += environmentPackage
		systemPackage.imports += testModel.containingPackage
				
		return new SimpleEntry(environmentModel, systemModel)
	}
	
	protected def getInterfaceImports(Component component) {
		return component.allPorts.map[it.interface.containingPackage].toList 
	}
	
	protected def String getSystemModelName(Component environmentModel, Component testModel) '''«environmentModel.name»On«testModel.name»'''
	
}