package hu.bme.mit.gamma.trace.environment.transformation

import hu.bme.mit.gamma.statechart.composite.CompositeModelFactory
import hu.bme.mit.gamma.statechart.composite.InstancePortReference
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent
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
		val environmentModel = transformer.execute
		val trace = transformer.getTrace
		
		val testModel = executionTrace.component as SynchronousComponent
		val systemModel = testModel.wrapSynchronousComponent
		val componentInstance = systemModel.components.head
		
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
		
		systemPackage.imports += environmentPackage
		systemPackage.imports += systemModel.containingPackage
				
		return new SimpleEntry(environmentModel, systemModel)
	}
	
}