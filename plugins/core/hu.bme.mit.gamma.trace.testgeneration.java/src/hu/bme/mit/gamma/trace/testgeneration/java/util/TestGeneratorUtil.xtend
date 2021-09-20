package hu.bme.mit.gamma.trace.testgeneration.java.util

import hu.bme.mit.gamma.statechart.composite.AbstractSynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.AsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.trace.testgeneration.java.ExpressionSerializer
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.uppaal.verification.patterns.InstanceContainer
import hu.bme.mit.gamma.uppaal.verification.patterns.WrapperInstanceContainer
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope

import static com.google.common.base.Preconditions.checkArgument

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class TestGeneratorUtil {

	// Resources
	protected final ViatraQueryEngine engine

	protected final ResourceSet resourceSet
	protected final Component component

	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE

	new(Component _component) {

		this.component = _component
		this.resourceSet = component.eResource.resourceSet
		checkArgument(this.resourceSet !== null)
		this.engine = ViatraQueryEngine.on(new EMFScope(this.resourceSet))
	}

	public def CharSequence getFullContainmentHierarchy(ComponentInstance actual, ComponentInstance child) {
		if (actual === null) {
			// This is the border of the sync components
			if (component instanceof SynchronousComponent) {
				// This is the end
				return ''''''
			}
			if (component instanceof AsynchronousAdapter) {
				// This is the end
				return ''''''
			}
			if (component instanceof AsynchronousCompositeComponent) {
				if (child instanceof SynchronousComponentInstance) {
					// We are on the border of async-sync components
					val wrapperInstance = child.asyncParent
					return '''«wrapperInstance.getFullContainmentHierarchy(child)»getComponent("«child.localName»").'''
				} else {
					// We are on the top of async components
					return ''''''
				}
			}
		} else {
			val parent = actual.parent
			if (child === null) {
				// No dot after the last instance
				// Local names are needed to form parent_actual names
				return '''«parent.getFullContainmentHierarchy(actual)»getComponent("«actual.localName»")'''
			}
			return '''«parent.getFullContainmentHierarchy(actual)»getComponent("«actual.localName»").'''
		}
	}

	protected def getAsyncParent(SynchronousComponentInstance instance) {
		checkArgument(instance !== null, "The instance is a null value.")
		if (instance.isTopInstance) {
			// Needed due to resource set issues: component can be referenced from other composite systems
			return null
		}
		val parents = WrapperInstanceContainer.Matcher.on(engine).getAllValuesOfwrapperInstance(instance)
		if (parents.size > 1) {
			throw new IllegalArgumentException("More than one parent: " + parents)
		}
		return parents.head
	}

	private def isTopInstance(ComponentInstance instance) {
		return component.instances.contains(instance)
	}

	/**
	 * Instance names in the model contain the containment hierarchy from the root.
	 * Instances in the generated do not, therefore the deletion of containment hierarchy is needed during test-generation.
	 */
	protected def getLocalName(ComponentInstance instance) {
		val parent = instance.parent
		var String parentName
		var int startIndex
		if (parent === null) {
			if (instance instanceof SynchronousComponentInstance &&
				component instanceof AsynchronousCompositeComponent) {
				// An async-sync step is needed
				val syncInstance = instance as SynchronousComponentInstance
				val wrapperParent = syncInstance.asyncParent
				parentName = wrapperParent.name
			} else {
				// No parent
				return instance.name
			}
		} else {
			parentName = parent.name
		}
		val instanceName = instance.name
		startIndex = instanceName.lastIndexOf(parentName) + parentName.length + 1 // "_" is counted too
		try {
			val localName = instanceName.substring(startIndex)
			return localName
		} catch (StringIndexOutOfBoundsException e) {
			throw new IllegalArgumentException("Instance " + parentName +
				" has a child with the same name. This makes test generation impossible.")
		}
	}

	/**
	 * Returns whether there are timing specifications in any of the statecharts.
	 */
	public def boolean needTimer(Component component) {
		if (component instanceof StatechartDefinition) {
			return component.timeoutDeclarations.size > 0
		} else if (component instanceof AbstractSynchronousCompositeComponent) {
			return component.components.map[it.type.needTimer].contains(true)
		} else if (component instanceof AsynchronousAdapter) {
			return component.wrappedComponent.type.needTimer
		} else if (component instanceof AsynchronousCompositeComponent) {
			return component.components.map[it.type.needTimer].contains(true)
		} else {
			throw new IllegalArgumentException("Not known component: " + component)
		}
	}

	protected def getParent(ComponentInstance instance) {
		checkArgument(instance !== null, "The instance is a null value.")
		if (instance.isTopInstance) {
			// Needed due to resource set issues: component can be referenced from other composite systems
			return null
		}
		val parents = InstanceContainer.Matcher.on(engine).getAllValuesOfcontainerInstace(instance)
		if (parents.size > 1) {
			throw new IllegalArgumentException("More than one parent: " + parents)
		}
		return parents.head
	}
}
