package hu.bme.mit.gamma.scenario.model.sorter;

import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator;
import hu.bme.mit.gamma.scenario.model.Delay;
import hu.bme.mit.gamma.scenario.model.InteractionDefinition;
import hu.bme.mit.gamma.scenario.model.ModalInteractionSet;
import hu.bme.mit.gamma.scenario.model.ScenarioDefinition;
import hu.bme.mit.gamma.scenario.model.Signal;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ScenarioContentSorter {

	private static GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	private static ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE;

	public void sort(ScenarioDefinition scenario) {
		List<ModalInteractionSet> sets = ecoreUtil.getAllContentsOfType(scenario, ModalInteractionSet.class);
		for (ModalInteractionSet set : sets) {
			sortInteractionSet(set);
		}
	}

	private void sortInteractionSet(ModalInteractionSet set) {
		List<InteractionDefinition> interactions = set.getModalInteractions();
		Collections.sort(interactions, Comparator
				.comparing((InteractionDefinition interaction) -> getSerializedInteractionDefinition(interaction)));
	}

	private String getSerializedInteractionDefinition(InteractionDefinition interaction) {
		if (interaction instanceof Delay) {
			return getSerializedDelay((Delay) interaction);
		}
		if (interaction instanceof Signal) {
			return getSerializedSignal((Signal) interaction);
		}
		throw new IllegalArgumentException();
	}

	private String getSerializedDelay(Delay delay) {
		return "Delay" + delay.getModality() + evaluator.evaluate(delay.getMaximum())
				+ evaluator.evaluate(delay.getMinimum());
	}

	private String getSerializedSignal(Signal signal) {
		String output = "Signal" + signal.getDirection() + signal.getModality() + signal.getPort().getName()
				+ signal.getEvent().getName();
		for (Expression expr : signal.getArguments()) {
			output += evaluator.evaluate(expr);
		}
		return output;
	}
}
