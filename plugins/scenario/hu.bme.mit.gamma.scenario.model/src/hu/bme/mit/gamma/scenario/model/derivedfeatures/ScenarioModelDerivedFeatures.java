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
package hu.bme.mit.gamma.scenario.model.derivedfeatures;

import java.util.List;
import java.util.stream.Collectors;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.scenario.model.Delay;
import hu.bme.mit.gamma.scenario.model.DeterministicOccurrence;
import hu.bme.mit.gamma.scenario.model.InteractionDirection;
import hu.bme.mit.gamma.scenario.model.DeterministicOccurrenceSet;
import hu.bme.mit.gamma.scenario.model.ModalityType;
import hu.bme.mit.gamma.scenario.model.NegatedDeterministicOccurrence;
import hu.bme.mit.gamma.scenario.model.Interaction;

public class ScenarioModelDerivedFeatures extends ExpressionModelDerivedFeatures {

	public static InteractionDirection getDirection(DeterministicOccurrenceSet set) {
		boolean isSend = false;
		List<InteractionDirection> directions = javaUtil.filterIntoList(set.getDeterministicOccurrences(), Interaction.class)
				.stream().map(it -> it.getDirection()).collect(Collectors.toList());
		List<NegatedDeterministicOccurrence> negatedInteractions = javaUtil.filterIntoList(set.getDeterministicOccurrences(),
				NegatedDeterministicOccurrence.class);
		directions.addAll(negatedInteractions.stream()
				.filter(it -> it.getDeterministicOccurrence() instanceof Interaction)
				.map(it -> ((Interaction) it.getDeterministicOccurrence())
				.getDirection()).collect(Collectors.toList()));
		if (!directions.isEmpty()) {
			isSend = directions.stream().allMatch(it -> it.equals(InteractionDirection.SEND));
		}
		if (isSend) {
			return InteractionDirection.SEND;
		} else {
			return InteractionDirection.RECEIVE;
		}
	}

	public static ModalityType getModality(DeterministicOccurrenceSet set) {
		List<Interaction> signals = javaUtil.filterIntoList(set.getDeterministicOccurrences(), Interaction.class);

		if (!signals.isEmpty()) {
			return signals.get(0).getModality();
		}
		List<DeterministicOccurrence> negatedSignal = javaUtil
				.filterIntoList(set.getDeterministicOccurrences(), NegatedDeterministicOccurrence.class).stream()
				.map(it -> it.getDeterministicOccurrence()).collect(Collectors.toList());
		if (!negatedSignal.isEmpty()) {
			DeterministicOccurrence interactionDefinition = negatedSignal.get(0);
			if (interactionDefinition instanceof Interaction) {
				Interaction signal = (Interaction) interactionDefinition;
				return signal.getModality();
			}
		}

		List<Delay> delays = javaUtil.filterIntoList(set.getDeterministicOccurrences(), Delay.class);
		if (!delays.isEmpty()) {
			return ModalityType.COLD;
		}
		return ModalityType.COLD;
	}

	public static boolean isAllInteractionsOrBlockNegated(DeterministicOccurrenceSet set) {
		for (DeterministicOccurrence modalInteraction : set.getDeterministicOccurrences()) {
			if (!(modalInteraction instanceof NegatedDeterministicOccurrence)) {
				return false;
			}
		}
		return true;
	}

	public static ModalityType getModality(DeterministicOccurrence interaction) {
		if (interaction instanceof Interaction) {
			return ((Interaction) interaction).getModality();
		}
		if (interaction instanceof Delay) {
			return ModalityType.COLD; //((Delay) interaction).getModality();
		}
		if (interaction instanceof NegatedDeterministicOccurrence) {
			NegatedDeterministicOccurrence negated = (NegatedDeterministicOccurrence) interaction;
			if (negated.getDeterministicOccurrence() instanceof Interaction) {
				return getModality(negated.getDeterministicOccurrence());
			}
		}
		return null;
	}

	public static InteractionDirection getDirection(DeterministicOccurrence interaction) {
		if (interaction instanceof Interaction) {
			return ((Interaction) interaction).getDirection();
		}
		if (interaction instanceof Delay) {
			return InteractionDirection.RECEIVE;
		}
		if (interaction instanceof NegatedDeterministicOccurrence) {
			NegatedDeterministicOccurrence negated = (NegatedDeterministicOccurrence) interaction;
			if (negated.getDeterministicOccurrence() instanceof Interaction) {
				return getDirection(negated.getDeterministicOccurrence());
			}
		}
		return null;
	}

}
