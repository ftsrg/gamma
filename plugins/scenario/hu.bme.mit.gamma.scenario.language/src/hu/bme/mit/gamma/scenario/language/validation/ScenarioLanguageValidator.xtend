/********************************************************************************
 * Copyright (c) 2020-2022 Contributors to the Gamma project
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scenario.language.validation

import hu.bme.mit.gamma.scenario.model.AlternativeCombinedFragment
import hu.bme.mit.gamma.scenario.model.CombinedFragment
import hu.bme.mit.gamma.scenario.model.Delay
import hu.bme.mit.gamma.scenario.model.LoopCombinedFragment
import hu.bme.mit.gamma.scenario.model.DeterministicOccurrenceSet
import hu.bme.mit.gamma.scenario.model.NegatedDeterministicOccurrence
import hu.bme.mit.gamma.scenario.model.ParallelCombinedFragment
import hu.bme.mit.gamma.scenario.model.ScenarioCheckExpression
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration
import hu.bme.mit.gamma.scenario.model.ScenarioDefinitionReference
import hu.bme.mit.gamma.scenario.model.ScenarioPackage
import hu.bme.mit.gamma.scenario.util.ScenarioModelValidator
import org.eclipse.xtext.validation.Check
import hu.bme.mit.gamma.scenario.model.Interaction

class ScenarioLanguageValidator extends AbstractScenarioLanguageValidator {

	protected ScenarioModelValidator validator = ScenarioModelValidator.INSTANCE

	new() {
		super.expressionModelValidator = validator
	}

	@Check(NORMAL)
	def void checkIncompatibleAnnotations(ScenarioDeclaration scenario) {
		handleValidationResultMessage(validator.checkIncompatibleAnnotations(scenario))
	}

	@Check
	def void checkScenarioNamesAreUnique(ScenarioPackage _package) {
		handleValidationResultMessage(validator.checkScenarioNamesAreUnique(_package))
	}

	@Check
	def void checkAtLeastOneHotSignalInChart(ScenarioDeclaration scenario) {
		handleValidationResultMessage(validator.checkAtLeastOneHotSignalInChart(scenario))
	}

	@Check
	def void checkDeterministicOccurrenceSets(DeterministicOccurrenceSet modalInteractionSet) {
		handleValidationResultMessage(validator.checkDeterministicOccurrenceSets(modalInteractionSet))
	}


	@Check
	def void checkFirstInteractionsModalityIsTheSame(CombinedFragment combinedFragment) {
		handleValidationResultMessage(validator.checkFirstInteractionsModalityIsTheSame(combinedFragment))
	}

	@Check
	def void checkPortCanSendSignal(Interaction signal) {
		handleValidationResultMessage(validator.checkPortCanSendSignal(signal))
	}

	@Check
	def void checkPortCanReceiveSignal(Interaction signal) {
		handleValidationResultMessage(validator.checkPortCanReceiveSignal(signal))
	}

	@Check(NORMAL)
	def void negatedReceives(NegatedDeterministicOccurrence negatedModalInteraction) {
		handleValidationResultMessage(validator.negatedReceives(negatedModalInteraction))
	}

	@Check
	def void checkParallelCombinedFragmentExists(ParallelCombinedFragment fragment) {
		handleValidationResultMessage(validator.checkParallelCombinedFragmentExists(fragment))
	}

	@Check
	def void checkIntervals(LoopCombinedFragment loop) {
		handleValidationResultMessage(validator.checkIntervals(loop))
	}

	@Check
	def void checkIntervals(Delay delay) {
		handleValidationResultMessage(validator.checkIntervals(delay))
	}

	@Check
	def void checkScenarioReferenceParamCount(ScenarioDefinitionReference scenarioReference) {
		handleValidationResultMessage(validator.checkScenarioReferenceParamCount(scenarioReference))
	}

	@Check
	def void checkScenarioCheck(ScenarioCheckExpression check) {
		handleValidationResultMessage(validator.checkScenarioCheck(check))
	}

	@Check
	def void checkRecursiveScenraioReference(ScenarioDefinitionReference scenarioReference) {
		handleValidationResultMessage(validator.checkRecursiveScenraioReference(scenarioReference))
	}

	@Check
	def void checkScenraioReferenceInitialBlock(ScenarioDefinitionReference scenarioReference) {
		handleValidationResultMessage(validator.checkScenraioReferenceInitialBlock(scenarioReference))
	}

	@Check
	def void checkScenraioBlockOrder(DeterministicOccurrenceSet set) {
		handleValidationResultMessage(validator.checkScenraioBlockOrder(set))
	}

	@Check
	def void checkAlternativeWithCheckInteraction(AlternativeCombinedFragment alternative) {
		handleValidationResultMessage(validator.checkAlternativeWithCheckInteraction(alternative))
	}

	@Check
	def void checkDelayAndNegateInSameBlock(DeterministicOccurrenceSet set) {
		handleValidationResultMessage(validator.checkDelayAndNegateInSameBlock(set))
	}
}
