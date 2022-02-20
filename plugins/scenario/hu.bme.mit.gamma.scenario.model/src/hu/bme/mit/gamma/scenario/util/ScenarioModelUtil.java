package hu.bme.mit.gamma.scenario.util;

import java.util.ArrayList;
import java.util.List;

import hu.bme.mit.gamma.expression.util.ExpressionEvaluator;
import hu.bme.mit.gamma.scenario.model.AlternativeCombinedFragment;
import hu.bme.mit.gamma.scenario.model.Interaction;
import hu.bme.mit.gamma.scenario.model.InteractionFragment;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.util.JavaUtil;

public class ScenarioModelUtil {

	private static ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE;
	private static JavaUtil javaUtil = JavaUtil.INSTANCE;
	private static GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;

	public static List<Interaction> getLongestMatchingPrefix(InteractionFragment fragment1,
			InteractionFragment fragment2) {
		List<Interaction> content1 = fragment1.getInteractions();
		List<Interaction> content2 = fragment2.getInteractions();
		List<Interaction> matching = new ArrayList<>();
		for (int i = 0; i < content1.size(); i++) {
			Interaction interaction1 = content1.get(i);
			Interaction interaction2 = content2.get(i);
			if (ecoreUtil.helperEquals(interaction1, interaction2)) { // TODO sort fragments and interactions
				matching.add(interaction1);
			} else {
				return matching;
			}
		}
		return matching;
	}

	public static boolean areInteractionsEqual(Interaction interaction1, Interaction interaction2) {
		return ecoreUtil.helperEquals(interaction1, interaction2);
	}

	public static boolean isAlternativeFragmentDeterministic(AlternativeCombinedFragment alternative) {
		// Assumes, that there are no inner combined fragments
		for (int i = 0; i < alternative.getFragments().size(); i++) {
			InteractionFragment fragment1 = alternative.getFragments().get(i);
			for (int j = 0; j < alternative.getFragments().size(); j++) {
				if (i != j) {
					InteractionFragment fragment2 = alternative.getFragments().get(j);
					if (areInteractionsEqual(fragment1.getInteractions().get(0), fragment2.getInteractions().get(0))) {
						return false;
					}
				}
			}
		}
		return true;
	}

}
