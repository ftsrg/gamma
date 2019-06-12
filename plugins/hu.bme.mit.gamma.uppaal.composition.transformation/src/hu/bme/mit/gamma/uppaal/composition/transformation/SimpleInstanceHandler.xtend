package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.statechart.model.Component
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.composite.AbstractSynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance
import java.util.Collection
import java.util.List

import static com.google.common.base.Preconditions.checkArgument

class SimpleInstanceHandler {
	
	def List<SynchronousComponentInstance> getSimpleInstances(Collection<? extends ComponentInstance> instances) {
		val List<SynchronousComponentInstance> simpleInstances = newArrayList
		for (instance : instances) {
			simpleInstances += instance.simpleInstances
		}
		return simpleInstances
	}
	
	def List<SynchronousComponentInstance> getSimpleInstances(ComponentInstance instance) {
		checkArgument(instance instanceof SynchronousComponentInstance ||
			instance instanceof AsynchronousComponentInstance)
		if (instance instanceof SynchronousComponentInstance) {
			return instance.type.simpleInstances
		}
		if (instance instanceof AsynchronousComponentInstance) {
			return instance.type.simpleInstances
		}
	}
	
	def List<SynchronousComponentInstance> getSimpleInstances(Component component) {
		val List<SynchronousComponentInstance> simpleInstances = newArrayList
		if (component instanceof AsynchronousCompositeComponent) {
			for (AsynchronousComponentInstance instance : component.getComponents()) {
				val type = instance.getType()
				simpleInstances.addAll(getSimpleInstances(type))
			}
		}
		else if (component instanceof AsynchronousAdapter) {
			simpleInstances.addAll(getSimpleInstances(component.getWrappedComponent().getType()))
		}
		else if (component instanceof AbstractSynchronousCompositeComponent) {
			for (SynchronousComponentInstance instance : component.getComponents()) {
				val type = instance.getType()
				if (type instanceof StatechartDefinition) {
					simpleInstances.add(instance)
				}
				else {
					simpleInstances.addAll(getSimpleInstances(type))
				}
			}
		}
		return simpleInstances
	}
	
}