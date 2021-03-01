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
package hu.bme.mit.gamma.genmodel.language.validation

import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation
import hu.bme.mit.gamma.genmodel.model.AsynchronousInstanceConstraint
import hu.bme.mit.gamma.genmodel.model.CodeGeneration
import hu.bme.mit.gamma.genmodel.model.ComponentReference
import hu.bme.mit.gamma.genmodel.model.EventMapping
import hu.bme.mit.gamma.genmodel.model.GenModel
import hu.bme.mit.gamma.genmodel.model.InterfaceMapping
import hu.bme.mit.gamma.genmodel.model.OrchestratingConstraint
import hu.bme.mit.gamma.genmodel.model.StatechartCompilation
import hu.bme.mit.gamma.genmodel.model.Task
import hu.bme.mit.gamma.genmodel.model.TestGeneration
import hu.bme.mit.gamma.genmodel.model.TestReplayModelGeneration
import hu.bme.mit.gamma.genmodel.model.Verification
import hu.bme.mit.gamma.genmodel.model.YakinduCompilation
import hu.bme.mit.gamma.genmodel.util.GenmodelValidator
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
import hu.bme.mit.gamma.statechart.interface_.EventDeclaration
import hu.bme.mit.gamma.statechart.interface_.RealizationMode
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.FileUtil
import org.eclipse.xtext.validation.Check
import org.yakindu.base.types.Event

/**
 * This class contains custom validation rules. 
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class GenModelValidator extends AbstractGenModelValidator {
	
	protected extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected extension FileUtil fileUtil = FileUtil.INSTANCE
	
	protected GenmodelValidator genmodelValidator = GenmodelValidator.INSTANCE
	// Checking tasks, only one parameter is acceptable
	
	@Check
	def checkTasks(Task task) {
		handleValidationResultMessage(genmodelValidator.checkTasks(task))
	}
	
	@Check
	def checkTasks(YakinduCompilation yakinduCompilation) {
		handleValidationResultMessage(genmodelValidator.checkTasks(yakinduCompilation))
	}
	
	@Check
	def checkTasks(StatechartCompilation statechartCompilation) {
		handleValidationResultMessage(genmodelValidator.checkTasks(statechartCompilation))
	}
	
	@Check
	def checkTasks(AnalysisModelTransformation analysisModelTransformation) {
		handleValidationResultMessage(genmodelValidator.checkTasks(analysisModelTransformation))
	}
	
	@Check
	def checkTasks(Verification verification) {
		handleValidationResultMessage(genmodelValidator.checkTasks(verification))
	}
	
	@Check
	def checkTasks(TestReplayModelGeneration modelGeneration) {
		handleValidationResultMessage(genmodelValidator.checkTasks(modelGeneration))
	}
	
	@Check
	def checkTimeSpecification(TimeSpecification timeSpecification) {
		handleValidationResultMessage(genmodelValidator.checkTimeSpecification(timeSpecification))
	}
	
	@Check
	def checkConstraint(AsynchronousInstanceConstraint constraint) {
		handleValidationResultMessage(genmodelValidator.checkConstraint(constraint))
	}
	
	@Check
	def checkMinimumMaximumOrchestrationPeriodValues(OrchestratingConstraint orchestratingConstraint) {
		handleValidationResultMessage(genmodelValidator.checkMinimumMaximumOrchestrationPeriodValues(orchestratingConstraint))
	}
	
	@Check
	def checkTasks(CodeGeneration codeGeneration) {
		handleValidationResultMessage(genmodelValidator.checkTasks(codeGeneration))
	}
	
	@Check
	def checkTasks(TestGeneration testGeneration) {
		handleValidationResultMessage(genmodelValidator.checkTasks(testGeneration))
	}
	
	// Additional validation rules
	
	@Check
	def checkGammaImports(GenModel genmodel) {
		handleValidationResultMessage(genmodelValidator.checkGammaImports(genmodel))
	}

	@Check
	def checkYakinduImports(GenModel genmodel) {
		handleValidationResultMessage(genmodelValidator.checkYakinduImports(genmodel))
	}
	
	@Check
	def checkTraceImports(GenModel genmodel) {
		handleValidationResultMessage(genmodelValidator.checkTraceImports(genmodel))
	}
	
	@Check
	def checkParameters(ComponentReference componentReference) {
		handleValidationResultMessage(genmodelValidator.checkParameters(componentReference))
	}
	
	@Check
	def checkComponentInstanceArguments(AnalysisModelTransformation analysisModelTransformation) {
		handleValidationResultMessage(genmodelValidator.checkComponentInstanceArguments(analysisModelTransformation))
	}
	
	@Check
	def checkIfAllInterfacesMapped(StatechartCompilation statechartCompilation) {
		handleValidationResultMessage(genmodelValidator.checkIfAllInterfacesMapped(statechartCompilation))
	}
	
	@Check
	def checkInterfaceConformance(InterfaceMapping mapping) {
		handleValidationResultMessage(genmodelValidator.checkInterfaceConformance(mapping))
	}
	
	/** It checks the events of the parent interfaces as well. */
	private def boolean checkConformance(InterfaceMapping mapping) {
		return genmodelValidator.checkConformance(mapping)
	}
	
	@Check
	def checkInterfaceMappingWithoutEventMapping(InterfaceMapping mapping) {
		handleValidationResultMessage(genmodelValidator.checkInterfaceMappingWithoutEventMapping(mapping))
	}
	
	/**
	 * Checks whether the event directions conform to the realization mode.
	 */
	private def areWellDirected(RealizationMode interfaceType, Event yEvent, EventDeclaration gEvent) {
		return genmodelValidator.areWellDirected(interfaceType,yEvent,gEvent)
	}
	
	@Check
	def checkMappingCount(InterfaceMapping mapping) {
		handleValidationResultMessage(genmodelValidator.checkMappingCount(mapping))
	}
	
	@Check
	def checkYakinduInterfaceUniqueness(InterfaceMapping mapping) {
		handleValidationResultMessage(genmodelValidator.checkYakinduInterfaceUniqueness(mapping))
	}
	
	@Check
	def checkEventMappingCount(InterfaceMapping mapping) {
		handleValidationResultMessage(genmodelValidator.checkEventMappingCount(mapping))
	}
	
	@Check
	def checkEventConformance(EventMapping mapping) {		
		handleValidationResultMessage(genmodelValidator.checkEventConformance(mapping))
	}
	
	@Check
	def checkTraces(TestGeneration testGeneration) {
		handleValidationResultMessage(genmodelValidator.checkTraces(testGeneration))
	}
	
	private def boolean checkConformance(EventMapping mapping) {
		return genmodelValidator.checkConformance(mapping)
	}
	
	private def checkEventConformance(Event yEvent, EventDeclaration gEvent, RealizationMode realMode) {
		return genmodelValidator.checkEventConformance(yEvent, gEvent, realMode)
	}
	
	private def checkParameters(Event yEvent, hu.bme.mit.gamma.statechart.interface_.Event gEvent) {
		return genmodelValidator.checkParameters(yEvent, gEvent)
	}
	
	@Check
	def checkComponentInstanceReferences(ComponentInstanceReference reference) {
		genmodelValidator.checkComponentInstanceReferences(reference)
	}
	
}
