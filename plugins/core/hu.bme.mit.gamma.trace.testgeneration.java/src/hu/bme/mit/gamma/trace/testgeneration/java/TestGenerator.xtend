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

import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.testgeneration.java.util.TestGeneratorUtil
import hu.bme.mit.gamma.trace.util.TraceUtil
import java.util.Collections
import java.util.List
import org.eclipse.emf.ecore.resource.ResourceSet

import static com.google.common.base.Preconditions.checkArgument

import static extension hu.bme.mit.gamma.codegenerator.java.util.Namings.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

class TestGenerator {
	// Constant strings
	protected final String BASE_PACKAGE
	protected final String TIMER_CLASS_NAME = "VirtualTimerService"
	protected final String TIMER_OBJECT_NAME = "timer"
	
	protected final String FINAL_TEST_PREFIX = "final"
	protected final String TEST_ANNOTATION = "@Test"
	protected final String TEST_NAME = "step"
	
	// Value is assigned by the execute methods
	protected final String PACKAGE_NAME
	protected final String CLASS_NAME
	protected final String TEST_CLASS_NAME
	protected final String TEST_INSTANCE_NAME
	
	// Resources
	protected final ResourceSet resourceSet
	
	protected final Package gammaPackage
	protected final Component component
	protected final List<ExecutionTrace> traces // Traces in OR logical relation
	protected final ExecutionTrace firstTrace
	protected final TestGeneratorUtil testGeneratorUtil
	protected final AbstractAssertionHandler waitingHandle 
	protected final ActAndAssertSerializer actAndAssertSerializer	
	// Auxiliary objects
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE
	
	/**
	 * Note that the lists of traces represents a set of behaviors the component must conform to.
	 * Each trace must reference the same component with the same parameter values (arguments).
	 */
	new(List<ExecutionTrace> traces, String basePackage, String className) {
		this.firstTrace = traces.head
		this.component = firstTrace.component
		this.resourceSet = component.eResource.resourceSet
		checkArgument(this.resourceSet !== null)
		this.gammaPackage = component.eContainer as Package
		this.traces = traces
		
		// Initializing the string variables
		this.BASE_PACKAGE = basePackage
		this.PACKAGE_NAME = getPackageName
    	this.CLASS_NAME = className
    	this.TEST_CLASS_NAME = component.reflectiveClassName
    	this.TEST_INSTANCE_NAME = TEST_CLASS_NAME.toFirstLower
    	
    	this.testGeneratorUtil = new TestGeneratorUtil(component)
		this.actAndAssertSerializer = new ActAndAssertSerializer(component,
			TEST_INSTANCE_NAME, TIMER_OBJECT_NAME)
		if (firstTrace.hasAllowedWaitingAnnotation) {
			this.waitingHandle = new WaitingAllowedInFunction(firstTrace, actAndAssertSerializer)
		} 
		else {
			this.waitingHandle = new DefaultAssertionHandler(firstTrace, actAndAssertSerializer)
		}
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
		val suffix = "view"
		var String finalName
		val name = gammaPackage.name.toLowerCase
		if (name.endsWith(suffix)) {
			finalName = name.substring(0, name.length - suffix.length)
		}
		else {
			finalName = name
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
			«IF component.timed»private static «TIMER_CLASS_NAME» «TIMER_OBJECT_NAME»;«ENDIF»
			
			@Before
			public void init() {
				«IF component.timed»
«««					Only if there are timing specis in the model
					«TIMER_OBJECT_NAME» = new «TIMER_CLASS_NAME»();
					«TEST_INSTANCE_NAME» = new «TEST_CLASS_NAME»(«FOR parameter : firstTrace.arguments SEPARATOR ', ' AFTER ', '»«parameter.serialize»«ENDFOR»«TIMER_OBJECT_NAME»);  // Virtual timer is automatically set
				«ELSE»
«««				Each trace must reference the same component with the same parameter values (arguments)!
				«TEST_INSTANCE_NAME» = new «TEST_CLASS_NAME»(«FOR parameter : firstTrace.arguments SEPARATOR ', '»«parameter.serialize»«ENDFOR»);
			«ENDIF»
			}
			
			@After
			public void tearDown() {
				stop();
			}
			
			// Only for override by potential subclasses
			protected void stop() {
				«IF component.timed»
					«TIMER_OBJECT_NAME» = null;
				«ENDIF»
				«TEST_INSTANCE_NAME» = null;				
			}
			
			«traces.generateTestCases»
			
			«IF waitingHandle instanceof WaitingAllowedInFunction»
				«waitingHandle.generateWaitingHandlerFunction(TEST_INSTANCE_NAME)»
			«ENDIF»
		}
	'''
	
	protected def generateImports(Component component) '''
		import «BASE_PACKAGE».*;
		«FOR _package : firstTrace.typeDeclarations.map[it.containingPackage].toSet»
			import «_package.getPackageString(BASE_PACKAGE)».*;
		«ENDFOR»
		
		import static org.junit.Assert.assertTrue;
		
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
							«actAndAssertSerializer.serialize(act)»
						«ENDFOR»
						// Assert
						«val filteredAsserts = testGeneratorUtil.filterAsserts(step)»
						«IF !filteredAsserts.nullOrEmpty»
							«waitingHandle.generateAssertBlock(filteredAsserts)»
						«ENDIF»
					}
					
				'''
				builder.append(testMethod)
			}
		}
		return builder.toString
	}
	
	private def addTabIfNeeded(List<ExecutionTrace> traces, ExecutionTrace trace) '''«IF traces.last !== trace»	«ENDIF»'''
	
}