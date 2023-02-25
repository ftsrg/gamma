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
package hu.bme.mit.gamma.scenario.model.sorter;

import java.util.Comparator;
import java.util.List;

import org.eclipse.emf.common.util.ECollections;
import org.eclipse.emf.common.util.EList;

import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator;
import hu.bme.mit.gamma.scenario.model.Delay;
import hu.bme.mit.gamma.scenario.model.DeterministicOccurrence;
import hu.bme.mit.gamma.scenario.model.DeterministicOccurrenceSet;
import hu.bme.mit.gamma.scenario.model.Interaction;
import hu.bme.mit.gamma.scenario.model.NegatedDeterministicOccurrence;
import hu.bme.mit.gamma.scenario.model.ScenarioAssignmentStatement;
import hu.bme.mit.gamma.scenario.model.ScenarioCheckExpression;
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration;
import hu.bme.mit.gamma.scenario.util.ExpressionSerializer;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ScenarioContentSorter {

	private static GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	private static ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE;
	private static ExpressionSerializer serializer = ExpressionSerializer.INSTANCE;

	public void sort(ScenarioDeclaration scenario) {
		List<DeterministicOccurrenceSet> sets = ecoreUtil.getAllContentsOfType(scenario,
				DeterministicOccurrenceSet.class);
		for (DeterministicOccurrenceSet set : sets) {
			sortInteractionSet(set);
		}
	}

	private void sortInteractionSet(DeterministicOccurrenceSet set) {
		EList<DeterministicOccurrence> interactions = set.getDeterministicOccurrences();
		ECollections.sort(interactions, Comparator
				.comparing((DeterministicOccurrence interaction) -> getSerializedInteractionDefinition(interaction)));
	}

	private String getSerializedInteractionDefinition(DeterministicOccurrence interaction) {
		if (interaction instanceof Delay) {
			return getSerializedDelay((Delay) interaction);
		}
		if (interaction instanceof NegatedDeterministicOccurrence) {
			return getSerializedNegation((NegatedDeterministicOccurrence) interaction);
		}
		if (interaction instanceof Interaction) {
			return getSerializedSignal((Interaction) interaction);
		}
		if (interaction instanceof ScenarioCheckExpression) {
			return getSerializedCheck((ScenarioCheckExpression) interaction);
		}
		if (interaction instanceof ScenarioAssignmentStatement) {
			return getSerializedAssignment((ScenarioAssignmentStatement) interaction);
		}
		throw new IllegalArgumentException("Not supported interaction: " + interaction);
	}

	private String getSerializedDelay(Delay delay) {
		Expression minimum = delay.getMinimum();
		Expression maximum = delay.getMaximum();
		if (maximum == null) {
			maximum = minimum;
		}
		return "Delay" + evaluator.evaluate(maximum) + evaluator.evaluate(minimum);
	}

	private String getSerializedNegation(NegatedDeterministicOccurrence negation) {
		return "Negate" + getSerializedInteractionDefinition(negation.getDeterministicOccurrence());
	}

	private String getSerializedSignal(Interaction signal) {
		String output = "Interaction" + signal.getDirection() + signal.getModality() + signal.getPort().getName()
				+ signal.getEvent().getName();
		for (Expression expression : signal.getArguments()) {
			output += serializer.serialize(expression);
		}
		return output;
	}

	private String getSerializedAssignment(ScenarioAssignmentStatement assignment) {
		return "Assign" + serializer.serialize(assignment.getLhs()) + serializer.serialize(assignment.getRhs());
	}

	private String getSerializedCheck(ScenarioCheckExpression check) {
		return "Check" + serializer.serialize(check.getExpression());
	}
}
