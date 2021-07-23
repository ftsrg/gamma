package hu.bme.mit.gamma.trace.environment.transformation

import hu.bme.mit.gamma.statechart.composite.CascadeCompositeComponent
import hu.bme.mit.gamma.statechart.composite.CompositeModelFactory
import hu.bme.mit.gamma.statechart.composite.InstancePortReference
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import org.eclipse.xtend.lib.annotations.Data

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.environment.transformation.TraceReplayModelGenerator.Namings.*

class TraceReplayModelGenerator {
	
	protected final ExecutionTrace executionTrace
	protected final String systemName
	protected final String envrionmentModelName
	protected final EnvironmentModel environmentModel
	
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension InterfaceModelFactory interfaceModelFactory = InterfaceModelFactory.eINSTANCE
	protected final extension CompositeModelFactory statechartModelFactory = CompositeModelFactory.eINSTANCE
	
	new(ExecutionTrace executionTrace, String systemName,
			String envrionmentModelName, EnvironmentModel environmentModel) {
		this.executionTrace = executionTrace
		this.systemName = systemName
		this.envrionmentModelName = envrionmentModelName
		this.environmentModel = environmentModel
	}
	
	/**
	 * Returns the resulting environment model and system model wrapped into Packages.
	 * Both have to be serialized.
	 */
	def execute() {
		val transformer = new TraceToEnvironmentModelTransformer(
				envrionmentModelName, executionTrace, environmentModel)
		val result = transformer.execute
		val environmentModel = result.statechart
		val lastState = result.lastState
		val trace = transformer.getTrace
		
		val testModel = executionTrace.component as SynchronousComponent
		val testModelPackage = testModel.containingPackage
		val systemModel = testModel.wrapSynchronousComponent => [
			it.name = systemName
		]
		val componentInstance = systemModel.components.head => [
			it.name = systemModel.instanceName
		]
		
		val environmentInstance = environmentModel.instantiateSynchronousComponent
		systemModel.components.add(0, environmentInstance)
		
		// Tending to the system and proxy ports
		if (this.environmentModel === EnvironmentModel.OFF) {
			systemModel.ports.clear
			systemModel.portBindings.clear
		}
		else {
			for (portBinding : systemModel.portBindings) {
				val instancePortReference = portBinding.instancePortReference
				
				val componentPort = instancePortReference.port
				val proxyPort = trace.getComponentProxyPort(componentPort)
				
				instancePortReference.instance = environmentInstance
				instancePortReference.port = proxyPort
			}
		}
		
		// Tending to the environment and component ports
		for (portPair : trace.componentEnvironmentPortPairs) {
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
		systemPackage.name = testModelPackage.name // So test generation remains simple
		
		environmentPackage.imports += testModel.importableInterfacePackages // E.g., interfaces
		systemPackage.imports += environmentPackage
		systemPackage.imports += testModelPackage
				
		return new Result(environmentInstance, systemModel, lastState)
	}
	
	///
	
	static class Namings {
	
		def static String getInstanceName(Component system) '''_«system.name.toFirstLower»'''
		
	}
	
	@Data
	static class Result {
		SynchronousComponentInstance environmentModelIntance
		CascadeCompositeComponent systemModel
		State lastState
	}
	
}