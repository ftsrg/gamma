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

import hu.bme.mit.gamma.scenario.statechart.util.ScenarioStatechartUtil
import hu.bme.mit.gamma.statechart.contract.NotDefinedEventMode
import hu.bme.mit.gamma.statechart.contract.ScenarioContractAnnotation
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.theta.verification.ThetaVerifier
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.trace.util.UnsentEventAssertExtender
import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.transformation.GammaToXstsTransformer
import java.io.File
import java.util.List

class ScenarioStatechartTraceGenerator { 

	val extension TraceModelFactory traceFactory = TraceModelFactory.eINSTANCE
	val extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	val extension FileUtil fileUtil = FileUtil.INSTANCE
	val extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	val extension ScenarioStatechartUtil scenarioStatechartUtil = ScenarioStatechartUtil.INSTANCE
	val extension TraceUtil traceUtil = TraceUtil.INSTANCE

	StatechartDefinition statechart = null

	val boolean testOriginal = true
	
	var int schedulingConstraint=0

	String absoluteParentFolder

	Package _package

	new(StatechartDefinition sd, int schedulingConstraint) {
		this.schedulingConstraint=schedulingConstraint
		this.statechart = sd
		this._package = ecoreUtil.getContainerOfType(statechart, Package)
	}

	def List<ExecutionTrace> execute() {
		var Component c = statechart;
		absoluteParentFolder = (statechart.eResource.file).parentFile.absolutePath
		var result = <ExecutionTrace>newArrayList
		if (statechart.getAnnotation() instanceof ScenarioContractAnnotation && testOriginal) {
			c = ( statechart.getAnnotation() as ScenarioContractAnnotation).getMonitoredComponent();
		}

	var GammaToXstsTransformer gammaToXSTSTransformer =null
	if(schedulingConstraint >0){
		 gammaToXSTSTransformer = new GammaToXstsTransformer(schedulingConstraint,true,true);
	} else {
		 gammaToXSTSTransformer = new GammaToXstsTransformer();
	}
		
		val xStsFile = new File(absoluteParentFolder + File.separator +
			fileNamer.getXtextXStsFileName(statechart.getName()));
		val xStsString = gammaToXSTSTransformer.preprocessAndExecuteAndSerialize(_package, absoluteParentFolder,
			statechart.getName());
		fileUtil.saveString(xStsFile, xStsString);

		val verifier = new ThetaVerifier();
		val modelFile = new File(xStsFile.getAbsolutePath());
		val fileName = modelFile.getName();
		val regionName = statechart.regions.get(0).name
		val statechartName = statechart.name.toFirstUpper
		
		val packageFileName = fileNamer.getUnfoldedPackageFileName(fileName);
		val parameters = "--refinement \"MULTI_SEQ\" --domain \"EXPL\" --initprec \"ALLVARS\"";
		val query = "E<> (("+regionName+"_"+statechartName+" == " + scenarioStatechartUtil.getAccepting() + "))";
		val gammaPackage = ecoreUtil.normalLoad(modelFile.getParent(), packageFileName);

		val r = verifier.verifyQuery(gammaPackage, parameters, modelFile, query, true, true);
		val baseTrace = r.getTrace();

		var derivedTraces = identifySeparateTracesByReset(baseTrace);
		var i = 0;
		val ets = <ExecutionTrace>newArrayList
		for (List<Step> list : derivedTraces) {
			var et = createExecutionTrace
			setupExecutionTrace(et, list, baseTrace.getName() + i++, c, c.eContainer() as Package);
			ets += et
		}

		val backAnnotator = new ExecutionTraceBackAnnotator(ets, c, true, true);
		val filteredTraces = backAnnotator.execute();

		for (et : filteredTraces) {
			val eventAdder = new UnsentEventAssertExtender(et.getSteps(), true);
			if (statechart.getAnnotation() instanceof ScenarioContractAnnotation) {
				if ((statechart.getAnnotation() as ScenarioContractAnnotation).getScenarioType().equals(
					NotDefinedEventMode.STRICT)) {
					eventAdder.execute();
				}
			}
			result += et
		}

		return result
	}

}
