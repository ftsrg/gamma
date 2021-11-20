package hu.bme.mit.gamma.trace.testgeneration.java.util

import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.AsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.trace.model.InstanceStateConfiguration
import hu.bme.mit.gamma.trace.model.InstanceVariableState
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.testgeneration.java.ExpressionSerializer
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.transformation.util.annotations.AnnotationNamings
import hu.bme.mit.gamma.uppaal.verification.patterns.InstanceContainer
import hu.bme.mit.gamma.uppaal.verification.patterns.WrapperInstanceContainer
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope

import static com.google.common.base.Preconditions.checkArgument

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

class TestGeneratorUtil {

	// Resources
	protected final ViatraQueryEngine engine

	protected final ResourceSet resourceSet
	protected final Component component
	
	protected final String[] NOT_HANDLED_STATE_NAME_PATTERNS = #['LocalReactionState[0-9]*','FinalState[0-9]*']

	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE

	new(Component _component) {
		this.component = _component
		this.resourceSet = component.eResource.resourceSet
		checkArgument(this.resourceSet !== null)
		this.engine = ViatraQueryEngine.on(new EMFScope(this.resourceSet))
	}
	
	def CharSequence getFullContainmentHierarchy(ComponentInstanceReference instanceReference) {
		if (component.unfolded) {
			return instanceReference.lastInstance.fullContainmentHierarchy
		}
		// Original component instance references
		return '''«FOR instance : instanceReference.componentInstanceChain SEPARATOR '.'»getComponent("«instance.name»")«ENDFOR»'''
	}
	
	def CharSequence getFullContainmentHierarchy(ComponentInstance actual) {
		return actual.getFullContainmentHierarchy(null)
	}

	def CharSequence getFullContainmentHierarchy(ComponentInstance actual, ComponentInstance child) {
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

	def getAsyncParent(SynchronousComponentInstance instance) {
		checkArgument(instance !== null, "The instance is a null value")
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
	def getLocalName(ComponentInstance instance) {
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
				" has a child with the same name, which makes test generation impossible")
		}
	}

	def filterAsserts(Step step) {
		val asserts = newArrayList
		for (assertion : step.asserts) {
			val lowermostAssert = assertion.lowermostAssert
			if (lowermostAssert instanceof InstanceStateConfiguration) {
				if (lowermostAssert.state.handled) {
					asserts += assertion
				}
			}
			else if (lowermostAssert instanceof InstanceVariableState) {
				if (lowermostAssert.declaration.handled) {
					asserts += assertion
				}
			}
			else {
				asserts += assertion
			}
		}
		return asserts
	}
	
	/**
	 * Returns whether the given Gamma State is a state that is not present in Yakindu.
	 */
	def boolean isHandled(State state) {
		val stateName = state.name
		for (notHandledStateNamePattern: NOT_HANDLED_STATE_NAME_PATTERNS) {
			if (stateName.matches(notHandledStateNamePattern)) {
				return false
			}
		}
		return true
	}
	
	protected def boolean isHandled(Declaration declaration) {
		// Not perfect as other variables can be named liked this, but works 99,99% of the time
		val name = declaration.name
		if (name.startsWith(AnnotationNamings.PREFIX) &&
				name.endsWith(AnnotationNamings.POSTFIX) ||
				component.allSimpleInstances.map[it.type].filter(StatechartDefinition)
					.map[it.transitions].flatten.exists[it.id == name] /*Transition id*/) {
			return false
		}
		return true
	}
	
	def getParent(ComponentInstance instance) {
		checkArgument(instance !== null, "The instance is a null value")
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
	
	def String getPortOfAssert(RaiseEventAct assert) '''
		"«assert.port.name»"
	'''
	
	
	def String getEventOfAssert(RaiseEventAct assert) '''
		"«assert.event.name»"
	'''
	
	
	def String getParamsOfAssert(RaiseEventAct assert) '''
		new Object[] {«FOR parameter : assert.arguments BEFORE " " SEPARATOR ", " AFTER " "»«parameter.serialize»«ENDFOR»}
	'''

}
