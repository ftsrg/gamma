package hu.bme.mit.gamma.scenario.model.sorter;

import java.util.Comparator;
import java.util.List;

import org.eclipse.emf.common.util.ECollections;
import org.eclipse.emf.common.util.EList;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator;
import hu.bme.mit.gamma.scenario.model.Delay;
import hu.bme.mit.gamma.scenario.model.InteractionDefinition;
import hu.bme.mit.gamma.scenario.model.ModalInteractionSet;
import hu.bme.mit.gamma.scenario.model.ScenarioCheckExpression;
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration;
import hu.bme.mit.gamma.scenario.model.Signal;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ScenarioContentSorter {

	private static GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	private static ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE;

	public void sort(ScenarioDeclaration scenario) {
		List<ModalInteractionSet> sets = ecoreUtil.getAllContentsOfType(scenario, ModalInteractionSet.class);
		for (ModalInteractionSet set : sets) {
			sortInteractionSet(set);
		}
	}

	private void sortInteractionSet(ModalInteractionSet set) {
		EList<InteractionDefinition> interactions = set.getModalInteractions();
		ECollections.sort(interactions, Comparator
				.comparing((InteractionDefinition interaction) -> getSerializedInteractionDefinition(interaction)));
	}

	private String getSerializedInteractionDefinition(InteractionDefinition interaction) {
		if (interaction instanceof Delay) {
			return getSerializedDelay((Delay) interaction);
		}
		if (interaction instanceof Signal) {
			return getSerializedSignal((Signal) interaction);
		}
		if (interaction instanceof ScenarioCheckExpression) {
			return "check";
		}
		throw new IllegalArgumentException();
	}

	private String getSerializedDelay(Delay delay) {
		Expression minimum = delay.getMinimum();
		Expression maximum = delay.getMaximum();
		if (maximum == null) {
			maximum = minimum;
		}
		return "Delay" + delay.getModality() + evaluator.evaluate(maximum)
				+ evaluator.evaluate(minimum);
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
