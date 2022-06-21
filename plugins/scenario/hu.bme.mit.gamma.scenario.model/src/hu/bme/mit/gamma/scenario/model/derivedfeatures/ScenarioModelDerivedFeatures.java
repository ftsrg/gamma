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
import hu.bme.mit.gamma.scenario.model.InteractionDefinition;
import hu.bme.mit.gamma.scenario.model.InteractionDirection;
import hu.bme.mit.gamma.scenario.model.ModalInteractionSet;
import hu.bme.mit.gamma.scenario.model.ModalityType;
import hu.bme.mit.gamma.scenario.model.NegatedModalInteraction;
import hu.bme.mit.gamma.scenario.model.Signal;

public class ScenarioModelDerivedFeatures extends ExpressionModelDerivedFeatures {

	public static InteractionDirection getDirection(ModalInteractionSet set) {
		boolean isSend = false;
		List<InteractionDirection> directions = javaUtil.filterIntoList(set.getModalInteractions(), Signal.class)
				.stream().map(it -> it.getDirection()).collect(Collectors.toList());
		List<NegatedModalInteraction> negatedInteractions = javaUtil.filterIntoList(set.getModalInteractions(),
				NegatedModalInteraction.class);
		directions.addAll(negatedInteractions.stream()
				.filter(it -> it.getModalinteraction() instanceof Signal)
				.map(it -> ((Signal) it.getModalinteraction())
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

	public static ModalityType getModality(ModalInteractionSet set) {
		List<Signal> signals = javaUtil.filterIntoList(set.getModalInteractions(), Signal.class);

		if (!signals.isEmpty()) {
			return signals.get(0).getModality();
		}
		List<InteractionDefinition> negatedSignal = javaUtil
				.filterIntoList(set.getModalInteractions(), NegatedModalInteraction.class).stream()
				.map(it -> it.getModalinteraction()).collect(Collectors.toList());
		if (!negatedSignal.isEmpty()) {
			InteractionDefinition interactionDefinition = negatedSignal.get(0);
			if (interactionDefinition instanceof Signal) {
				Signal signal = (Signal) interactionDefinition;
				return signal.getModality();
			}
		}

		List<Delay> delays = javaUtil.filterIntoList(set.getModalInteractions(), Delay.class);
		if (!delays.isEmpty()) {
			return delays.get(0).getModality();
		}
		return ModalityType.COLD;
	}

	public static boolean isAllInteractionsOrBlockNegated(ModalInteractionSet set) {
		for (InteractionDefinition modalInteraction : set.getModalInteractions()) {
			if (!(modalInteraction instanceof NegatedModalInteraction)) {
				return false;
			}
		}
		return true;
	}

	public static ModalityType getModality(InteractionDefinition interaction) {
		if (interaction instanceof Signal) {
			return ((Signal) interaction).getModality();
		}
		if (interaction instanceof Delay) {
			return ((Delay) interaction).getModality();
		}
		if (interaction instanceof NegatedModalInteraction) {
			NegatedModalInteraction negated = (NegatedModalInteraction) interaction;
			if (negated.getModalinteraction() instanceof Signal) {
				return getModality(negated.getModalinteraction());
			}
		}
		return null;
	}

	public static InteractionDirection getDirection(InteractionDefinition interaction) {
		if (interaction instanceof Signal) {
			return ((Signal) interaction).getDirection();
		}
		if (interaction instanceof Delay) {
			return InteractionDirection.RECEIVE;
		}
		if (interaction instanceof NegatedModalInteraction) {
			NegatedModalInteraction negated = (NegatedModalInteraction) interaction;
			if (negated.getModalinteraction() instanceof Signal) {
				return getDirection(negated.getModalinteraction());
			}
		}
		return null;
	}

}
