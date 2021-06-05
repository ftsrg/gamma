package hu.bme.mit.gamma.scenario.model.derivedfeatures;

import hu.bme.mit.gamma.scenario.model.Delay;
import hu.bme.mit.gamma.scenario.model.InteractionDefinition;
import hu.bme.mit.gamma.scenario.model.InteractionDirection;
import hu.bme.mit.gamma.scenario.model.ModalInteraction;
import hu.bme.mit.gamma.scenario.model.ModalInteractionSet;
import hu.bme.mit.gamma.scenario.model.ModalityType;
import hu.bme.mit.gamma.scenario.model.NegatedModalInteraction;
import hu.bme.mit.gamma.scenario.model.Signal;

import java.util.List;
import java.util.stream.Collectors;

public class ScenarioModelDerivedFeatures {

	public static InteractionDirection getDirection(ModalInteractionSet set) {
		boolean isSend = false;
		List<InteractionDirection> directions = set.getModalInteractions().stream().filter(it -> it instanceof Signal)
				.map(it -> ((Signal) it).getDirection()).collect(Collectors.toList());
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
		boolean isHot = true;
		for (InteractionDefinition interaction : set.getModalInteractions()) {
			if (interaction instanceof Signal) {
				isHot = isHot && ((Signal) interaction).getModality().equals(ModalityType.HOT);
			} else if (interaction instanceof NegatedModalInteraction) {
				InteractionDefinition inner = ((NegatedModalInteraction) interaction).getModalinteraction();
				if (inner instanceof ModalInteraction) {
					isHot = isHot && ((ModalInteraction) inner).getModality().equals(ModalityType.HOT);
				} else {
					isHot = false;
				}
			}
		}
		if (isHot) {
			return ModalityType.HOT;
		} else {
			return ModalityType.COLD;
		}
	}

}
