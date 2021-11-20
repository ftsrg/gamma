/********************************************************************************
 * Copyright (c) 2020-2021 Contributors to the Gamma project
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scenario.trace.generator

import hu.bme.mit.gamma.lowlevel.xsts.transformation.TransitionMerging
import hu.bme.mit.gamma.scenario.statechart.util.ScenarioStatechartUtil
import hu.bme.mit.gamma.statechart.contract.NotDefinedEventMode
import hu.bme.mit.gamma.statechart.contract.ScenarioAllowedWaitAnnotation
import hu.bme.mit.gamma.statechart.contract.ScenarioContractAnnotation
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.theta.verification.ThetaVerifier
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.trace.util.UnsentEventAssertExtender
import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.transformation.GammaToXstsTransformer
import java.io.File
import java.util.List

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class ScenarioStatechartTraceGenerator {

	val extension TraceModelFactory traceFactory = TraceModelFactory.eINSTANCE
	val extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	val extension FileUtil fileUtil = FileUtil.INSTANCE
	val extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	val extension ScenarioStatechartUtil scenarioStatechartUtil = ScenarioStatechartUtil.INSTANCE
	val extension TraceUtil traceUtil = TraceUtil.INSTANCE

	StatechartDefinition statechart = null

	val boolean testOriginal = true

	var int schedulingConstraint = 0

	String absoluteParentFolder

	Package _package
	
	ScenarioAllowedWaitAnnotation annotation
	
	new(StatechartDefinition statechart, int schedulingConstraint) {
		this(statechart, schedulingConstraint, null);
	}

	new(StatechartDefinition sd, int schedulingConstraint, ScenarioAllowedWaitAnnotation annotation) {
		this.schedulingConstraint = schedulingConstraint
		this.statechart = sd
		this._package = statechart.containingPackage
		this.annotation = annotation
	}

	def List<ExecutionTrace> execute() {
		var Component component = statechart
		absoluteParentFolder = (statechart.eResource.file).parentFile.absolutePath
		var NotDefinedEventMode scenarioContractType = null
		var result = <ExecutionTrace>newArrayList
		val annotations = statechart.annotations
		for (annotation : annotations) {
			if (annotation instanceof ScenarioContractAnnotation) {
				if (testOriginal) {
					component = annotation.monitoredComponent
					scenarioContractType= annotation.scenarioType
				}
			}
		}

		var GammaToXstsTransformer gammaToXSTSTransformer = null
		if (schedulingConstraint > 0) {
			gammaToXSTSTransformer = new GammaToXstsTransformer(
				schedulingConstraint, true, true, TransitionMerging.HIERARCHICAL)
		}
		else {
			gammaToXSTSTransformer = new GammaToXstsTransformer
		}
		
		val name = statechart.name
		val xStsFile = new File(absoluteParentFolder + File.separator +
			fileNamer.getXtextXStsFileName(name))
		val xStsString = gammaToXSTSTransformer.preprocessAndExecuteAndSerialize(
			_package, absoluteParentFolder,	name)
		fileUtil.saveString(xStsFile, xStsString)

		val verifier = new ThetaVerifier
		val modelFile = new File(xStsFile.absolutePath)
		val fileName = modelFile.name
		val regionName = statechart.regions.get(0).name
		val statechartName = statechart.name.toFirstUpper

		val packageFileName = fileNamer.getUnfoldedPackageFileName(fileName)
		val parameters = '''--refinement "MULTI_SEQ" --domain "EXPL" --initprec "ALLVARS" '''
		val query = '''E<> ((«regionName + "_" + statechartName» == «scenarioStatechartUtil.accepting»))'''
		val gammaPackage = ecoreUtil.normalLoad(modelFile.parent, packageFileName)

		val verifierResult = verifier.verifyQuery(gammaPackage, parameters, modelFile, query)
		val baseTrace = verifierResult.trace
		
		if (baseTrace === null){
			throw new IllegalArgumentException('''State «scenarioStatechartUtil.accepting» cannot be reached in the formal model.''')
		}

		var derivedTraces = identifySeparateTracesByReset(baseTrace)
		var i = 0
		val traces = <ExecutionTrace>newArrayList
		for (list : derivedTraces) {
			val containingPackage = component.containingPackage
			val trace = createExecutionTrace
			trace.setupExecutionTrace(list, baseTrace.name + i++, component, containingPackage,
				statechart.scenarioAllowedWaitAnnotation)
			traces += trace
		}

		val backAnnotator = new ExecutionTraceBackAnnotator(traces, component, true, true)
		val filteredTraces = backAnnotator.execute

		for (trace : filteredTraces) {
			val eventAdder = new UnsentEventAssertExtender(trace.steps, true)
			if (scenarioContractType.equals(NotDefinedEventMode.STRICT)) {
				eventAdder.execute
			}
			result += trace
		}

		return result
	}

}
