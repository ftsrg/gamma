/********************************************************************************
 * Copyright (c) 2020-2023 Contributors to the Gamma project
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scenario.trace.generator

import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.lowlevel.xsts.transformation.TransitionMerging
import hu.bme.mit.gamma.scenario.statechart.util.ScenarioStatechartUtil
import hu.bme.mit.gamma.scenario.trace.generator.util.ExecutionTraceBackAnnotator
import hu.bme.mit.gamma.scenario.trace.generator.util.TraceGenUtil
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.contract.NotDefinedEventMode
import hu.bme.mit.gamma.statechart.contract.ScenarioContractAnnotation
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.theta.verification.ThetaTraceGenerator
import hu.bme.mit.gamma.theta.verification.ThetaVerifier
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.trace.util.UnsentEventAssertExtender
import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.transformation.util.annotations.AnnotatablePreprocessableElements
import hu.bme.mit.gamma.transformation.util.annotations.ComponentInstanceReferences
import hu.bme.mit.gamma.transformation.util.annotations.DataflowCoverageCriterion
import hu.bme.mit.gamma.transformation.util.annotations.InteractionCoverageCriterion
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.transformation.api.Gamma2XstsTransformerSerializer
import java.io.File
import java.util.ArrayList
import java.util.List

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class ScenarioStatechartTraceGenerator {

	val extension TraceModelFactory traceFactory = TraceModelFactory.eINSTANCE
	val extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	val extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	val extension ScenarioStatechartUtil scenarioStatechartUtil = ScenarioStatechartUtil.INSTANCE
	val extension TraceUtil traceUtil = TraceUtil.INSTANCE
	val extension TraceGenUtil traceGenUtil = TraceGenUtil.INSTANCE

	protected final boolean TEST_ORIGINAL = true
	val boolean USE_OWN_TRAVERSAL = false

	StatechartDefinition statechart = null
	List<Expression> arguments = newArrayList
	var Integer schedulingConstraint = 0

	protected String absoluteParentFolder

	new(StatechartDefinition statechart, List<? extends Expression> arguments, Integer schedulingConstraint) {
		this.statechart = statechart
		this.arguments += arguments
		this.schedulingConstraint = schedulingConstraint
	}
	
	def List<ExecutionTrace> execute() {
		var Component component = statechart
		absoluteParentFolder = statechart.eResource.file
				.parentFile.absolutePath
		var NotDefinedEventMode scenarioContractType = null
		val result = <ExecutionTrace>newArrayList
		val annotations = statechart.annotations
		val isNegativeTest = statechart.hasNegatedContractStatechartAnnotation
		for (annotation : annotations) {
			if (annotation instanceof ScenarioContractAnnotation) {
				if (TEST_ORIGINAL) {
					component = annotation.monitoredComponent
					scenarioContractType = annotation.scenarioType
				}
			}
		}
		if (schedulingConstraint <= 0) {
			schedulingConstraint = null
		}
		val name = statechart.name
		val compInstanceRef = new ComponentInstanceReferences(newArrayList,newArrayList)
		val transformator = new Gamma2XstsTransformerSerializer(statechart, arguments, absoluteParentFolder, name, schedulingConstraint, schedulingConstraint,
			true, false, false, true, TransitionMerging.HIERARCHICAL, null, 
			new AnnotatablePreprocessableElements(null, null, null, null, null, compInstanceRef, null, null, null,
				InteractionCoverageCriterion.EVERY_INTERACTION, InteractionCoverageCriterion.EVERY_INTERACTION, null,
				DataflowCoverageCriterion.ALL_USE, null, DataflowCoverageCriterion.ALL_USE), null, null)
		transformator.execute
		
		val xStsFile = new File(absoluteParentFolder + File.separator + fileNamer.getXtextXStsFileName(name))
		
		val targetStateName = isNegativeTest ? 
			scenarioStatechartUtil.hotViolation : 
			scenarioStatechartUtil.accepting
		val traces = 
		if (USE_OWN_TRAVERSAL) {
			deriveTracesWithOwn(targetStateName, component, xStsFile)
		} else {
			deriveTracesWithBuiltIn(targetStateName, component, xStsFile)
		}
		
		val backAnnotator = new ExecutionTraceBackAnnotator(traces, component, true, true, isNegativeTest)
		val filteredTraces = backAnnotator.execute
		
		for (trace : filteredTraces) {
			trace.variableDeclarations += statechart.variableDeclarations.clone.filter[!it.name.startsWith("__id_")]
			backAnnotateNegsChecksAndAssigns(component, trace)
			val refs = getAllContentsOfType(trace, DirectReferenceExpression).filter[it.declaration instanceof VariableDeclaration]
			for (oldRef : refs) {
				val newRef = oldRef.clone
				newRef.declaration = trace.variableDeclarations.findFirst[it.name == oldRef.declaration.name]
				ecoreUtil.changeAndReplace(newRef, oldRef,trace)
			}
			trace.steps.forEach[it.asserts.removeIf([it instanceof ComponentInstanceStateReferenceExpression])]
		}

		for (trace : filteredTraces) {
			val eventAdder = new UnsentEventAssertExtender(trace.steps, true)
			if (scenarioContractType == NotDefinedEventMode.STRICT) {
				eventAdder.execute
			}
			result += trace
		}

		if (isNegativeTest) {
			val mergedTraces = <ExecutionTrace>newArrayList
			val similarTracesSet = <List<ExecutionTrace>>newArrayList
			similarTracesSet += <ExecutionTrace>newArrayList
			
			for (trace : result) {
				var added = false
				for (similarSet : similarTracesSet) {// traces should be at least 2 step long
					val steps = trace.steps.subList(0,trace.steps.size-2)
					if (!added && similarSet.exists[steps.isCovered(it.steps.subList(0, it.steps.size - 2)) 
						&& it.steps.subList(0, it.steps.size - 2).isCovered(steps)]) {
						similarSet += trace
						added = true
					}
				}
				if (!added) {
					similarTracesSet += <ExecutionTrace>newArrayList
					similarTracesSet.lastOrNull += trace
				}
			}
			
			for (set : similarTracesSet.filter[!it.empty]) {
				mergedTraces += mergeLastStepOfTraces(set)
			}	

			for (trace : mergedTraces) {
				trace.annotations += createNegativeTestAnnotation
			}
			result.clear
			result.addAll(mergedTraces)
		}
		return result
	}	
	
	def List<ExecutionTrace> deriveTracesWithBuiltIn(String targetStateName, Component component, File xStsFile){
		val derivedTraces = new ArrayList<ExecutionTrace>
		val ttg = new ThetaTraceGenerator
		derivedTraces += ttg.execute(xStsFile, true, <String>newArrayList, false, false)
		val traces = <ExecutionTrace>newArrayList	
		var i = 0
		val containingPackage = component.containingPackage
		for (trace : derivedTraces) {
			val lastStep = trace.steps.lastOrNull
			val stateAssert = lastStep.asserts.filter(ComponentInstanceStateReferenceExpression).head // this filter is sufficient due to the simple assertions used in the tests
			if(stateAssert !== null && stateAssert.state.name.contains(targetStateName)) {
				trace.setupExecutionTrace(null, trace.name + i++, component, containingPackage, statechart.scenarioAllowedWaitAnnotation.clone)
				traces += trace
			}
		}
		return traces
	}
	
	def List<ExecutionTrace> deriveTracesWithOwn(String targetStateName, Component component, File xStsFile){
		val verifier = new ThetaVerifier
		val modelFile = new File(xStsFile.absolutePath)
		val fileName = modelFile.name
		val regionName = statechart.regions.get(0).name
		val statechartName = statechart.name.toFirstUpper
		val packageFileName = fileNamer.getUnfoldedPackageFileName(fileName)
		val parameters = '''--refinement "MULTI_SEQ" --domain "EXPL" --initprec "ALLVARS" --allpaths'''
		val query = '''E<> ((«regionName + "_" + statechartName» == «targetStateName»))'''
		val gammaPackage = ecoreUtil.normalLoad(modelFile.parent, packageFileName)
		val verifierResult = verifier.verifyQuery(gammaPackage, parameters, modelFile, query)
		val baseTrace = verifierResult.trace

		if (baseTrace === null) {
			throw new IllegalArgumentException('''State «scenarioStatechartUtil.accepting» cannot be reached in the formal model''')
		}

		var derivedTraces = identifySeparateTracesByReset(baseTrace)
		var i = 0
		val traces = <ExecutionTrace>newArrayList
		for (list : derivedTraces) {
			val containingPackage = component.containingPackage
			val trace = createExecutionTrace
			trace.arguments += arguments.clone
			trace.setupExecutionTrace(list, baseTrace.name + i++, component, containingPackage,
				statechart.scenarioAllowedWaitAnnotation.clone)
			traces += trace
		}
		return traces
	}
}
