/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.genmodel.language.validation

import hu.bme.mit.gamma.expression.model.ArgumentedElement
import hu.bme.mit.gamma.genmodel.model.AbstractComplementaryTestGeneration
import hu.bme.mit.gamma.genmodel.model.AdaptiveContractTestGeneration
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation
import hu.bme.mit.gamma.genmodel.model.AsynchronousInstanceConstraint
import hu.bme.mit.gamma.genmodel.model.CodeGeneration
import hu.bme.mit.gamma.genmodel.model.EventMapping
import hu.bme.mit.gamma.genmodel.model.FmeaTableGeneration
import hu.bme.mit.gamma.genmodel.model.GenModel
import hu.bme.mit.gamma.genmodel.model.InterfaceMapping
import hu.bme.mit.gamma.genmodel.model.OrchestratingConstraint
import hu.bme.mit.gamma.genmodel.model.SafetyAssessment
import hu.bme.mit.gamma.genmodel.model.SemanticDiff
import hu.bme.mit.gamma.genmodel.model.StatechartCompilation
import hu.bme.mit.gamma.genmodel.model.StatechartContractGeneration
import hu.bme.mit.gamma.genmodel.model.Task
import hu.bme.mit.gamma.genmodel.model.TestGeneration
import hu.bme.mit.gamma.genmodel.model.TraceReplayModelGeneration
import hu.bme.mit.gamma.genmodel.model.Verification
import hu.bme.mit.gamma.genmodel.model.YakinduCompilation
import hu.bme.mit.gamma.genmodel.util.GenmodelValidator
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification
import org.eclipse.xtext.validation.Check

class GenModelValidator extends AbstractGenModelValidator {
	
	protected final GenmodelValidator genmodelValidator = GenmodelValidator.INSTANCE
	
	new() {
		super.expressionModelValidator = genmodelValidator
	}
	
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
	def checkTasks(AbstractComplementaryTestGeneration testGeneration) {
		handleValidationResultMessage(genmodelValidator.checkTasks(testGeneration))
	}
	
	@Check
	def checkTasks(TraceReplayModelGeneration modelGeneration) {
		handleValidationResultMessage(genmodelValidator.checkTasks(modelGeneration))
	}
	
	@Check
	def checkTasks(SemanticDiff semanticDiff) {
		handleValidationResultMessage(genmodelValidator.checkTasks(semanticDiff))
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
	
	@Check
	def checkReferredComponentTasks(AdaptiveContractTestGeneration testGeneration) {
		handleValidationResultMessage(genmodelValidator.checkReferredComponentTasks(testGeneration))
	}
	
	@Check
	def checkTasks(SafetyAssessment safetyAssessment) {
		handleValidationResultMessage(genmodelValidator.checkTasks(safetyAssessment))
	}
	
	// Additional validation rules
	
	@Check
	def checkArgumentTypes(ArgumentedElement argumentedElement) {
		handleValidationResultMessage(genmodelValidator.checkArgumentTypes(argumentedElement))
	}
	
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
	
	@Check
	def checkInterfaceMappingWithoutEventMapping(InterfaceMapping mapping) {
		handleValidationResultMessage(genmodelValidator.checkInterfaceMappingWithoutEventMapping(mapping))
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
	
	@Check
	def checkComponentInstanceReferences(ComponentInstanceReferenceExpression reference) {
		handleValidationResultMessage(genmodelValidator.checkComponentInstanceReferences(reference))
	}
	
	@Check
	def checkNegatedInteractionInTestAutomatonGeneration(StatechartContractGeneration statechartContractGeneration) {
		handleValidationResultMessage(genmodelValidator.checkNegatedInteractionInTestAutomatonGeneration(statechartContractGeneration))
	}
	
	@Check
	def checkSafetyAssessment(SafetyAssessment safetyAssessment) {
		handleValidationResultMessage(genmodelValidator.checkSafetyAssessment(safetyAssessment))
	}
	
	@Check
	def checkCardinality(FmeaTableGeneration fmeaTableGeneration) {
		handleValidationResultMessage(genmodelValidator.checkFmeaTableGeneration(fmeaTableGeneration))
	}
	
}