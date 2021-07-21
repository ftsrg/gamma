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
package hu.bme.mit.gamma.scenario.language.validation

import hu.bme.mit.gamma.scenario.model.CombinedFragment
import hu.bme.mit.gamma.scenario.model.Delay
import hu.bme.mit.gamma.scenario.model.LoopCombinedFragment
import hu.bme.mit.gamma.scenario.model.ModalInteraction
import hu.bme.mit.gamma.scenario.model.ModalInteractionSet
import hu.bme.mit.gamma.scenario.model.NegatedModalInteraction
import hu.bme.mit.gamma.scenario.model.ParallelCombinedFragment
import hu.bme.mit.gamma.scenario.model.Reset
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration
import hu.bme.mit.gamma.scenario.model.ScenarioDefinition
import hu.bme.mit.gamma.scenario.model.Signal
import hu.bme.mit.gamma.scenario.util.ScenarioModelValidator
import org.eclipse.xtext.validation.Check

class ScenarioLanguageValidator extends AbstractScenarioLanguageValidator {

	protected ScenarioModelValidator validator = ScenarioModelValidator.INSTANCE

	@Check(NORMAL)
	def void checkIncompatibleAnnotations(ScenarioDefinition scenario) {
		handleValidationResultMessage(validator.checkIncompatibleAnnotations(scenario))
	}

	@Check
	def void checkScenarioNamesAreUnique(ScenarioDeclaration scenarioDeclaration) {
		handleValidationResultMessage(validator.checkScenarioNamesAreUnique(scenarioDeclaration))
	}

	@Check
	def void checkAtLeastOneHotSignalInChart(ScenarioDefinition scenario) {
		handleValidationResultMessage(validator.checkAtLeastOneHotSignalInChart(scenario))
	}

	@Check
	def void checkModalInteractionSets(ModalInteractionSet modalInteractionSet) {
		handleValidationResultMessage(validator.checkModalInteractionSets(modalInteractionSet))
	}

	@Check
	def void checkModalInteractionsInSynchronousComponents(ModalInteraction interaction) {
		handleValidationResultMessage(validator.checkModalInteractionsInSynchronousComponents(interaction))
	}

	@Check
	def void checkModalInteractionsInSynchronousComponents(Reset reset) {
		handleValidationResultMessage(validator.checkModalInteractionsInSynchronousComponents(reset))
	}

	@Check
	def void checkFirstInteractionsModalityIsTheSame(CombinedFragment combinedFragment) {
		handleValidationResultMessage(validator.checkFirstInteractionsModalityIsTheSame(combinedFragment))
	}

	@Check
	def void checkPortCanSendSignal(Signal signal) {
		handleValidationResultMessage(validator.checkPortCanSendSignal(signal))
	}

	@Check
	def void checkPortCanReceiveSignal(Signal signal) {
		handleValidationResultMessage(validator.checkPortCanReceiveSignal(signal))
	}

	@Check(NORMAL)
	def void negatedReceives(NegatedModalInteraction nmi) {
		handleValidationResultMessage(validator.negatedReceives(nmi))
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

}
