package hu.bme.mit.gamma.scenario.model.reduction;

import java.util.ArrayList;
import java.util.List;

import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator;
import hu.bme.mit.gamma.scenario.model.Delay;
import hu.bme.mit.gamma.scenario.model.Interaction;
import hu.bme.mit.gamma.scenario.model.InteractionDefinition;
import hu.bme.mit.gamma.scenario.model.InteractionFragment;
import hu.bme.mit.gamma.scenario.model.ModalInteractionSet;
import hu.bme.mit.gamma.scenario.model.NegatedModalInteraction;
import hu.bme.mit.gamma.scenario.model.Signal;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.util.JavaUtil;

public class ScenarioReductionUtil {

	private static ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE;
	private static JavaUtil javaUtil = JavaUtil.INSTANCE;
	private static GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;

	public static void createSequences(List<List<FragmentInteractionPair>> listlist, List<List<Integer>> used,
			List<Integer> maximum) {
		boolean ok = false;
		while (!ok) {
			boolean wasAdded = false;
			for (int i = 0; i < used.get(0).size(); i++) {
				if (used.get(0).get(i) < maximum.get(i)) {
					wasAdded = true;
					List<FragmentInteractionPair> tmplist = new ArrayList<FragmentInteractionPair>();
					List<Integer> tmpused = new ArrayList<Integer>();
					for (int j = 0; j < used.get(0).size(); j++) {
						tmpused.add(used.get(0).get(j));
					}
					for (int j = 0; j < listlist.get(0).size(); j++) {
						tmplist.add(listlist.get(0).get(j));
					}
					tmplist.add(new FragmentInteractionPair(i, tmpused.get(i)));
					tmpused.set(i, tmpused.get(i) + 1);

					used.add(tmpused);
					listlist.add(tmplist);
				}
			}
			if (!wasAdded) {
				used.add(used.get(0));
				listlist.add(listlist.get(0));
			}
			used.remove(0);
			listlist.remove(0);
			ok = done(used, maximum);
		}
	}

	private static boolean done(List<List<Integer>> used, List<Integer> maximum) {
		for (List<Integer> l : used) {
			for (int i = 0; i < l.size(); i++) {
				if (l.get(i) != maximum.get(i))
					return false;
			}
		}
		return true;
	}

	// Heap's Algorithm
	public static void generatePermutation(int k, List<Integer> a, List<List<Integer>> l) {
		if (k == 1) {
			l.add(new ArrayList<Integer>(a));
		} else {
			for (int i = 0; i < (k - 1); i++) {
				int tmp;
				generatePermutation(k - 1, a, l);
				if (k % 2 == 0) {
					tmp = a.get(i);
					a.set(i, a.get(k - 1));
					a.set(k - 1, tmp);
				} else {
					tmp = a.get(0);
					a.set(0, a.get(k - 1));
					a.set(k - 1, tmp);
				}
			}
			generatePermutation(k - 1, a, l);
		}
	}
}
