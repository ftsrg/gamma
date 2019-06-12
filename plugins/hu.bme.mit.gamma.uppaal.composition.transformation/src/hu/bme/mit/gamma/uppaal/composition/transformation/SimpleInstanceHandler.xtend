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
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil.EqualityHelper

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
			if (instance.type instanceof StatechartDefinition) {
				// Atomic component
				return newArrayList(instance)
			}
			else {
				// Composite component
				return instance.type.simpleInstances
			}
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
	
	def boolean contains(SynchronousComponentInstance container, SynchronousComponentInstance instance) {
		if (container.helperEquals(instance)) {
			// Sometimes not working due to the M2M transformation: different references (instances) for component instances
			// Works for transition tests and not for state tests for some reason
			return true
		}
		val containerType = container.type
		if (containerType instanceof AbstractSynchronousCompositeComponent) {
			for (containedInstance : containerType.components) {
				val result = containedInstance.contains(instance) 
				if (result) {
					return true
				}
			}
		}
		return false
	}
	
	private def boolean helperEquals(EObject lhs, EObject rhs) {
		val helper = new EqualityHelper();
		return helper.equals(lhs, rhs);
	}
	
}