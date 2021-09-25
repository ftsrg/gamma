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

	// TODO use javaUtil.filterInto list instead of these casts
	
	public static InteractionDirection getDirection(ModalInteractionSet set) {
		boolean isSend = false;
		List<InteractionDirection> directions = set.getModalInteractions().stream().filter(it -> it instanceof Signal)
				.map(it -> ((Signal) it).getDirection()).collect(Collectors.toList());
		directions.addAll(set.getModalInteractions().stream().filter(it -> it instanceof NegatedModalInteraction)
				.filter(it -> ((NegatedModalInteraction) it).getModalinteraction() instanceof Signal)
				.map(it -> ((Signal) ((NegatedModalInteraction) it).getModalinteraction()).getDirection())
				.collect(Collectors.toList()));
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
		List<Signal> signals = set.getModalInteractions().stream().filter(it -> it instanceof Signal)
				.map(it -> (Signal) it).collect(Collectors.toList());

		if (!signals.isEmpty()) {
			return signals.get(0).getModality();
		}
		List<InteractionDefinition> negatedSignal = set.getModalInteractions().stream()
				.filter(it -> it instanceof NegatedModalInteraction)
				.map(it -> ((NegatedModalInteraction) it).getModalinteraction()).collect(Collectors.toList());
		if (!negatedSignal.isEmpty()) {
			InteractionDefinition interactionDefinition = negatedSignal.get(0);
			if (interactionDefinition instanceof Signal) {
				Signal signal = (Signal) interactionDefinition;
				return signal.getModality();
			}
		}
		List<InteractionDefinition> delays = set.getModalInteractions().stream().filter(it -> it instanceof Delay)
				.map(it -> ((Delay) it)).collect(Collectors.toList());
		if (!delays.isEmpty()) {
			InteractionDefinition interactionDefinition = delays.get(0);
			if (interactionDefinition instanceof Signal) {
				Signal signal = (Signal) interactionDefinition;
				return signal.getModality();
			}
		}
		return ModalityType.COLD;
	}

}
