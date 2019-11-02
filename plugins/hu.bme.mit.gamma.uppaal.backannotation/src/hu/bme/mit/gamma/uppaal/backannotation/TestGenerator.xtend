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
package hu.bme.mit.gamma.uppaal.backannotation

import hu.bme.mit.gamma.statechart.model.Package
import hu.bme.mit.gamma.statechart.model.State
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.composite.AbstractSynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.Component
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponent
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.trace.model.ComponentSchedule
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.InstanceSchedule
import hu.bme.mit.gamma.trace.model.InstanceStateConfiguration
import hu.bme.mit.gamma.trace.model.InstanceVariableState
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.uppaal.backannotation.patterns.InstanceContainer
import hu.bme.mit.gamma.uppaal.backannotation.patterns.WrapperInstanceContainer
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope

import static com.google.common.base.Preconditions.checkArgument

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class TestGenerator {
	// Constant strings
	protected String YAKINDU_PACKAGE_NAME_PREFIX
    protected final String TEST_FOLDER = "test-gen"
	protected final String TIMER_CLASS_NAME = "VirtualTimerService"
	protected final String TIMER_OBJECT_NAME = "timer"
	
	protected final String TEST_ANNOTATION = "@Test"	
	protected final String TEST_NAME = "step"	
	protected final String ASSERT_TRUE = "assertTrue"	
	
	protected final String[] notHandledStateNamePatterns = #['LocalReactionState[0-9]*','FinalState[0-9]*']
	// Value is assigned by the execute methods
    protected final String packageName
	protected final String className
	protected final String componentClassName
	
	protected final ViatraQueryEngine engine
	
	protected final ResourceSet resourceSet
	
	protected final Package gammaPackage
	protected final Component component
	protected final ExecutionTrace trace 
	
	protected final extension ExpressionSerializer expSer = new ExpressionSerializer
	
	/**
	 * Id is needed as a suffix to match the trace file.
	 */
	new(ResourceSet resourceSet, ExecutionTrace trace, String yakinduPackageName, String className) {
		this.resourceSet = resourceSet
		this.component = trace.component // Theoretically, the same thing what loadModels do
		this.gammaPackage = component.eContainer as Package
		this.YAKINDU_PACKAGE_NAME_PREFIX = yakinduPackageName // For some reason, package platform URI does not work
		this.trace = trace
		this.engine = ViatraQueryEngine.on(new EMFScope(this.resourceSet))
		// Initializing the string variables
		this.packageName = getPackageName
    	this.className = className
		this.componentClassName = "Reflective" + component.name.toFirstUpper
	}
	
	/**
	 * Generates the test class.
	 */
	def String execute() {
		return trace.generateTestClass(component, className).toString
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
		return YAKINDU_PACKAGE_NAME_PREFIX + "." + finalName
	}
	
	private def createPackageName() '''package «packageName»;'''
		
	protected def generateTestClass(ExecutionTrace trace, Component component, String className) '''
		«createPackageName»
		
		«component.generateImports»
		
		public class «className» {
			
			private static «componentClassName» «componentClassName.toFirstLower»;
«««			Only if there are timing specifications in the model
			«IF component.needTimer»private static «TIMER_CLASS_NAME» «TIMER_OBJECT_NAME»;«ENDIF»
			
			@Before
			public void init() {
				«IF component.needTimer»
«««					Only if there are timing specs in the model
					«TIMER_OBJECT_NAME» = new «TIMER_CLASS_NAME»();
					«componentClassName.toFirstLower» = new «componentClassName»(«FOR parameter : trace.arguments SEPARATOR ', ' AFTER ', '»«parameter.serialize»«ENDFOR»«TIMER_OBJECT_NAME»);  // Virtual timer is automatically set
				«ELSE»
					«componentClassName.toFirstLower» = new «componentClassName»(«FOR parameter : trace.arguments SEPARATOR ', ' AFTER ', '»«parameter.serialize»«ENDFOR»);
				«ENDIF»
				«componentClassName.toFirstLower».reset();
			}
			
			@After
			public void tearDown() {
				// Only for override by potential subclasses
				«IF component.needTimer»
					«TIMER_OBJECT_NAME» = null;
				«ENDIF»
				«componentClassName.toFirstLower» = null;
			}
			
			«trace.generateTestCases»
		}
	'''
	
	protected def generateImports(Component component) '''
		«IF component.needTimer»
			import «YAKINDU_PACKAGE_NAME_PREFIX».«TIMER_CLASS_NAME»;
		«ENDIF»
		
		import static org.junit.Assert.«ASSERT_TRUE»;
		
		import org.junit.Before;
		import org.junit.After;
		import org.junit.Test;
	'''
	
	protected def CharSequence generateTestCases(ExecutionTrace trace) {
		var testId = 0
		val builder = new StringBuilder
		// Parsing the remaining lines
		for (step : trace.steps) {
			val testMethod = '''
				«TEST_ANNOTATION»
				public void «TEST_NAME + testId++»() {
					«IF testId !== 1»«TEST_NAME + (testId - 2)»();«ENDIF»
					// Act
					«FOR act : step.actions»
						«act.serialize»
					«ENDFOR»
					// Checking out events
					«FOR outEvent : step.outEvents»
						«ASSERT_TRUE»(«componentClassName.toFirstLower».isRaisedEvent("«outEvent.port.name»", "«outEvent.event.name»", new Object[] {«FOR parameter : outEvent.arguments BEFORE " " SEPARATOR ", " AFTER " "»«parameter.serialize»«ENDFOR»}));
					«ENDFOR»
					// Checking variables
					«FOR variableState : step.instanceStates.filter(InstanceVariableState)»
						«ASSERT_TRUE»(«componentClassName.toFirstLower».«variableState.instance.getFullContainmentHierarchy(null)».getValue("«variableState.declaration.name»").equals(«variableState.value.serialize»));
					«ENDFOR»
					// Checking of states
					«FOR instanceState : step.instanceStates.filter(InstanceStateConfiguration).filter[it.state.handled].sortBy[it.instance.name + it.state.name]»
						«ASSERT_TRUE»(«componentClassName.toFirstLower».«instanceState.instance.getFullContainmentHierarchy(null)».isStateActive("«instanceState.state.parentRegion.name»", "«instanceState.state.name»"));
					«ENDFOR»
				}
				
			'''
			builder.append(testMethod)
		}		
		return builder.toString
	}
	
	protected def dispatch serialize(RaiseEventAct raiseEvent) '''
		«componentClassName.toFirstLower».raiseEvent("«raiseEvent.port.name»", "«raiseEvent.event.name»", new Object[] {«FOR param : raiseEvent.arguments BEFORE " " SEPARATOR ", " AFTER " "»«param.serialize»«ENDFOR»});
	'''
	
	protected def dispatch serialize(TimeElapse elapse) '''
		«TIMER_OBJECT_NAME».elapse(«elapse.elapsedTime»);
	'''
	
	protected def dispatch serialize(InstanceSchedule schedule) '''
		«componentClassName.toFirstLower».«schedule.scheduledInstance.getFullContainmentHierarchy(null)».schedule(null);
	'''
	
	protected def dispatch serialize(ComponentSchedule schedule) '''
«««		In theory only asynchronous adapters and synchronous adapters are used
		«componentClassName.toFirstLower».schedule(null);
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
		startIndex = instance.name.lastIndexOf(parentName) + parentName.length + 1 // "_" is counted too
		return instance.name.substring(startIndex)
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
		for (notHandledStateNamePattern: notHandledStateNamePatterns) {
			if (stateName.matches(notHandledStateNamePattern)) {
				return false
			}
		}
		return true
	}
	
	protected def String getYakinduStatePackageName(SynchronousComponentInstance instance) {
		if (!(instance.type instanceof StatechartDefinition)) {
			throw new IllegalArgumentException("Not a statechart instance: " + instance)
		}
		val statechartName = instance.type.name
		return '''«YAKINDU_PACKAGE_NAME_PREFIX».«statechartName.toLowerCase.deleteStatechartSuffix(true)».«statechartName.toFirstUpper.deleteStatechartSuffix(false)»Statemachine.State'''
	}
	
	/**
	 * Gamma uses the suffix Statechart that needs to be deleted when generating test cases.
	 */
	protected def deleteStatechartSuffix(String statechartName, boolean toLower) {
		if (toLower) {
			if (statechartName.endsWith("statechart")) {
				return statechartName.substring(0, statechartName.length - "statechart".length)			
			}
		}
		if (statechartName.endsWith("Statechart")) {
			return statechartName.substring(0, statechartName.length - "Statechart".length)
		}
		return statechartName
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