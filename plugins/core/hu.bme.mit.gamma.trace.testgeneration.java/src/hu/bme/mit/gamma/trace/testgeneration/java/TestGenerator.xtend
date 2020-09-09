/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.trace.testgeneration.java

import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.statechart.composite.AbstractSynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.AsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.trace.model.ComponentSchedule
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.InstanceSchedule
import hu.bme.mit.gamma.trace.model.InstanceStateConfiguration
import hu.bme.mit.gamma.trace.model.InstanceVariableState
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Reset
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.transformation.util.AnnotationNamings
import hu.bme.mit.gamma.uppaal.verification.patterns.InstanceContainer
import hu.bme.mit.gamma.uppaal.verification.patterns.WrapperInstanceContainer
import java.util.Collections
import java.util.List
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope

import static com.google.common.base.Preconditions.checkArgument

import static extension hu.bme.mit.gamma.codegenerator.java.util.Namings.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class TestGenerator {
	// Constant strings
	protected final String BASE_PACKAGE
	protected final String TEST_FOLDER = "test-gen"
	protected final String TIMER_CLASS_NAME = "VirtualTimerService"
	protected final String TIMER_OBJECT_NAME = "timer"
	
	protected final String FINAL_TEST_PREFIX = "final"	
	protected final String TEST_ANNOTATION = "@Test"	
	protected final String TEST_NAME = "step"	
	protected final String ASSERT_TRUE = "assertTrue"	
	
	protected final String[] NOT_HANDLED_STATE_NAME_PATTERNS = #['LocalReactionState[0-9]*','FinalState[0-9]*']
	
	// Value is assigned by the execute methods
	protected final String PACKAGE_NAME
	protected final String CLASS_NAME
	protected final String TEST_CLASS_NAME
	protected final String TEST_INSTANCE_NAME
	
	// Resources
	protected final ViatraQueryEngine engine
	
	protected final ResourceSet resourceSet
	
	protected final Package gammaPackage
	protected final Component component
	protected final List<ExecutionTrace> traces // Traces in OR logical relation
	
	// Auxiliary objects
	protected final extension ExpressionSerializer expressionSerializer = new ExpressionSerializer
	
	/**
	 * Note that the lists of traces represents a set of behaviors the component must conform to.
	 * Each trace must reference the same component with the same parameter values (arguments).
	 */
	new(List<ExecutionTrace> traces, String basePackage, String className) {
		this.component = traces.head.component // Theoretically, the same thing what loadModels do
		this.resourceSet = component.eResource.resourceSet
		checkArgument(this.resourceSet !== null)
		this.gammaPackage = component.eContainer as Package
		this.BASE_PACKAGE = basePackage // For some reason, package platform URI does not work
		this.traces = traces
		this.engine = ViatraQueryEngine.on(new EMFScope(this.resourceSet))
		// Initializing the string variables
		this.PACKAGE_NAME = getPackageName
    	this.CLASS_NAME = className
    	this.TEST_CLASS_NAME = component.reflectiveClassName
    	this.TEST_INSTANCE_NAME = TEST_CLASS_NAME.toFirstLower
	}
	
	new(ExecutionTrace trace, String yakinduPackageName, String className) {
		this(Collections.singletonList(trace), yakinduPackageName, className)
	}
	
	/**
	 * Generates the test class.
	 */
	def String execute() {
		return traces.generateTestClass(component, CLASS_NAME).toString
	}
	
	def getPackageName() {
		val suffix = "view";
		var String finalName
		val name = gammaPackage.getName().toLowerCase();
		if (name.endsWith(suffix)) {
			finalName = name.substring(0, name.length() - suffix.length());
		} else {
			finalName = name;
		}
		return BASE_PACKAGE + "." + finalName
	}
	
	private def createPackageName() '''package «PACKAGE_NAME»;'''
		
	protected def generateTestClass(List<ExecutionTrace> traces, Component component, String className) '''
		«createPackageName»
		
		«component.generateImports»
		
		public class «className» {
			
			private static «TEST_CLASS_NAME» «TEST_INSTANCE_NAME»;
«««			Only if there are timing specis in the model
			«IF component.needTimer»private static «TIMER_CLASS_NAME» «TIMER_OBJECT_NAME»;«ENDIF»
			
			@Before
			public void init() {
				«IF component.needTimer»
«««					Only if there are timing specis in the model
					«TIMER_OBJECT_NAME» = new «TIMER_CLASS_NAME»();
					«TEST_INSTANCE_NAME» = new «TEST_CLASS_NAME»(«FOR parameter : traces.head.arguments SEPARATOR ', ' AFTER ', '»«parameter.serialize»«ENDFOR»«TIMER_OBJECT_NAME»);  // Virtual timer is automatically set
				«ELSE»
«««				Each trace must reference the same component with the same parameter values (arguments)!
				«TEST_INSTANCE_NAME» = new «TEST_CLASS_NAME»(«FOR parameter : traces.head.arguments SEPARATOR ', '»«parameter.serialize»«ENDFOR»);
			«ENDIF»
			}
			
			@After
			public void tearDown() {
				stop();
			}
			
			// Only for override by potential subclasses
			protected void stop() {
				«IF component.needTimer»
					«TIMER_OBJECT_NAME» = null;
				«ENDIF»
				«TEST_INSTANCE_NAME» = null;				
			}
			
			«traces.generateTestCases»
		}
	'''
	
	protected def generateImports(Component component) '''
		import «BASE_PACKAGE».*;
		
		import static org.junit.Assert.«ASSERT_TRUE»;
		
		import org.junit.Before;
		import org.junit.After;
		import org.junit.Test;
	'''
	
	protected def CharSequence generateTestCases(List<ExecutionTrace> traces) {
		var stepId = 0
		var traceId = 0
		val builder = new StringBuilder
		// The traces are in an OR-relation
		builder.append('''
			«TEST_ANNOTATION»
			public void test() {
				«FOR trace : traces»
					«IF traces.last !== trace»try {«ENDIF»
					«traces.addTabIfNeeded(trace)»«FINAL_TEST_PREFIX»«TEST_NAME.toFirstUpper»«traceId++»();
					«traces.addTabIfNeeded(trace)»return;
					«IF traces.last !== trace»} catch(AssertionError e) {}«ENDIF»
				«ENDFOR»
			}
		''')
		traceId = 0
		// Parsing the remaining lines
		for (trace : traces) {
			val steps = newArrayList
			steps += trace.steps
			if (trace.cycle !== null) {
				// Cycle steps are not handled differently
				steps += trace.cycle.steps
			}
			for (step : steps) {
				val testMethod = '''
					public void «IF steps.indexOf(step) == steps.size - 1»«FINAL_TEST_PREFIX»«TEST_NAME.toFirstUpper»«traceId++»()«ELSE»«TEST_NAME + stepId++»()«ENDIF» {
						«IF step !== steps.head»«TEST_NAME»«IF step === steps.last»«stepId - 1»«ELSE»«stepId - 2»«ENDIF»();«ENDIF»
						// Act
						«FOR act : step.actions»
							«act.serialize»
						«ENDFOR»
						// Checking out events
						«FOR outEvent : step.outEvents»
							«ASSERT_TRUE»(«TEST_INSTANCE_NAME».isRaisedEvent("«outEvent.port.name»", "«outEvent.event.name»", new Object[] {«FOR parameter : outEvent.arguments BEFORE " " SEPARATOR ", " AFTER " "»«parameter.serialize»«ENDFOR»}));
						«ENDFOR»
						// Checking variables
						«FOR variableState : step.instanceStates.filter(InstanceVariableState).filter[it.declaration.isHandled]»
							«ASSERT_TRUE»(«TEST_INSTANCE_NAME».«variableState.instance.getFullContainmentHierarchy(null)».checkVariableValue("«variableState.declaration.name»", «variableState.value.serialize»));
						«ENDFOR»
						// Checking of states
						«FOR instanceState : step.instanceStates.filter(InstanceStateConfiguration).filter[it.state.handled].sortBy[it.instance.name + it.state.name]»
							«ASSERT_TRUE»(«TEST_INSTANCE_NAME».«instanceState.instance.getFullContainmentHierarchy(null)».isStateActive("«instanceState.state.parentRegion.name»", "«instanceState.state.name»"));
						«ENDFOR»
					}
					
				'''
				builder.append(testMethod)
			}
		}
		return builder.toString
	}
	
	private def addTabIfNeeded(List<ExecutionTrace> traces, ExecutionTrace trace) '''«IF traces.last !== trace»	«ENDIF»'''
	
	protected def dispatch serialize(Reset reset) '''
		«IF component.needTimer»«TIMER_OBJECT_NAME».reset(); // Timer before the system«ENDIF»
		«TEST_INSTANCE_NAME».reset();
	'''
	
	protected def dispatch serialize(RaiseEventAct raiseEvent) '''
		«TEST_INSTANCE_NAME».raiseEvent("«raiseEvent.port.name»", "«raiseEvent.event.name»", new Object[] {«FOR param : raiseEvent.arguments BEFORE " " SEPARATOR ", " AFTER " "»«param.serialize»«ENDFOR»});
	'''
	
	protected def dispatch serialize(TimeElapse elapse) '''
		«TIMER_OBJECT_NAME».elapse(«elapse.elapsedTime»);
	'''
	
	protected def dispatch serialize(InstanceSchedule schedule) '''
		«TEST_INSTANCE_NAME».«schedule.scheduledInstance.getFullContainmentHierarchy(null)».schedule(null);
	'''
	
	protected def dispatch serialize(ComponentSchedule schedule) '''
«««		In theory only asynchronous adapters and synchronous adapters are used
		«TEST_INSTANCE_NAME».schedule(null);
	'''
	
	protected def getParent(ComponentInstance instance) {
		checkArgument(instance !== null, "The instance is a null value.")
		val parents = InstanceContainer.Matcher.on(engine).getAllValuesOfcontainerInstace(instance)
		if (parents.size > 1) {
			throw new IllegalArgumentException("More than one parent: " + parents)
		}
		return parents.head
	}
	
	protected def getAsyncParent(SynchronousComponentInstance instance) {
		checkArgument(instance !== null, "The instance is a null value.")
		val parents = WrapperInstanceContainer.Matcher.on(engine).getAllValuesOfwrapperInstance(instance)
		if (parents.size > 1) {
			throw new IllegalArgumentException("More than one parent: " + parents)
		}
		return parents.head
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
			if (instance instanceof SynchronousComponentInstance && component instanceof AsynchronousCompositeComponent) {
				// An async-sync step is needed
				val syncInstance = instance as SynchronousComponentInstance
				val wrapperParent = syncInstance.asyncParent
				parentName = wrapperParent.name
			}
			else {
				// No parent
				return instance.name
			}
		}
		else {
			parentName = parent.name
		}
		val instanceName = instance.name
		startIndex = instanceName.lastIndexOf(parentName) + parentName.length + 1 // "_" is counted too
		try {
			val localName = instanceName.substring(startIndex)
			return localName
		} catch (StringIndexOutOfBoundsException e) {
			throw new IllegalStateException("Instance " + parentName + " has a child with the same name. This makes test generation impossible.")
		}
	}
	
	protected def CharSequence getFullContainmentHierarchy(ComponentInstance actual, ComponentInstance child) {
		if (actual === null) {
			// This is the border of the sync components
			if (component instanceof SynchronousComponent) {
				// This is the end
				return ''''''
			}
			if (component instanceof AsynchronousAdapter) {
				// This is the end
				return '''getComponent("«component.wrappedComponent.name»").'''
			}
			if  (component instanceof AsynchronousCompositeComponent) {
				if (child instanceof SynchronousComponentInstance) {
					// We are on the border of async-sync components
					val wrapperInstance = child.asyncParent
					return '''«wrapperInstance.getFullContainmentHierarchy(child)»getComponent("«child.localName»").'''
				}
				else {
					// We are on the top of async components
					return ''''''
				}
			}
		}
		else {
			val parent = actual.parent
			if (child === null) {
				// No dot after the last instance
				// Local names are needed to form parent_actual names
				return '''«parent.getFullContainmentHierarchy(actual)»getComponent("«actual.localName»")'''	
			}
			return '''«parent.getFullContainmentHierarchy(actual)»getComponent("«actual.localName»").'''
		}	
	}
	
	/**
	 * Returns whether the given Gamma State is a state that is not present in Yakindu.
	 */
	protected def boolean isHandled(State state) {
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
	
	/**
     * Returns whether there are timing specifications in any of the statecharts.
     */
    protected def boolean needTimer(Component component) {
    	if (component instanceof StatechartDefinition) {
    		return component.timeoutDeclarations.size > 0
    	}
    	else if (component instanceof AbstractSynchronousCompositeComponent) {
    		return component.components.map[it.type.needTimer].contains(true)
    	}
    	else if (component instanceof AsynchronousAdapter) {
    		return component.wrappedComponent.type.needTimer
    	}
    	else if (component instanceof AsynchronousCompositeComponent) {
    		return component.components.map[it.type.needTimer].contains(true)
    	}
    	else {
    		throw new IllegalArgumentException("Not known component: " + component)
    	}
    }
	
}
