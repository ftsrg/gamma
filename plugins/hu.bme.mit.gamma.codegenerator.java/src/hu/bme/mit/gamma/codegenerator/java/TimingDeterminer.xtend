package hu.bme.mit.gamma.codegenerator.java

import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.model.composite.Component
import hu.bme.mit.gamma.statechart.model.composite.CompositeComponent

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class TimingDeterminer {
	
	/**
	 * Returns whether there is a timing specification in any of the statecharts.
	 */
	protected def boolean needTimer(StatechartDefinition statechart) {
		return statechart.timeoutDeclarations.size > 0
	}
	
	/**
	 * Returns whether there is a time specification inside the given component.
	 */
	protected def boolean needTimer(Component component) {
		if (component instanceof StatechartDefinition) {
			return component.needTimer
		}
		else if (component instanceof CompositeComponent) {
			val composite = component as CompositeComponent
			return composite.derivedComponents.map[it.derivedType.needTimer].contains(true)
		}
		else if (component instanceof AsynchronousAdapter) {
			val wrapper = component as AsynchronousAdapter
			return !wrapper.clocks.empty || wrapper.wrappedComponent.type.needTimer
		}
		else {
			throw new IllegalArgumentException("No such component: " + component)
		}
	}
	
}