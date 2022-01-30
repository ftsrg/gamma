package hu.bme.mit.gamma.scenario.model.reduction;

import java.util.ArrayList;
import java.util.List;

import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator;
import hu.bme.mit.gamma.scenario.model.Delay;
import hu.bme.mit.gamma.scenario.model.Interaction;
import hu.bme.mit.gamma.scenario.model.InteractionDefinition;
import hu.bme.mit.gamma.scenario.model.InteractionFragment;
import hu.bme.mit.gamma.scenario.model.ModalInteraction;
import hu.bme.mit.gamma.scenario.model.ModalInteractionSet;
import hu.bme.mit.gamma.scenario.model.NegatedModalInteraction;
import hu.bme.mit.gamma.scenario.model.Signal;
import hu.bme.mit.gamma.util.JavaUtil;

public class ScenarioReductionUtil {

	private static ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE;
	private static JavaUtil javaUtil = JavaUtil.INSTANCE;

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

	public static List<Interaction> getLongestMatchingPrefix(InteractionFragment fragment1,
			InteractionFragment fragment2) {
		List<Interaction> content1 = fragment1.getInteractions();
		List<Interaction> content2 = fragment2.getInteractions();
		List<Interaction> matching = new ArrayList<>();
		for (int i = 0; i < content1.size(); i++) {
			Interaction interaction1 = content1.get(i);
			Interaction interaction2 = content2.get(i);
			if (areInteractionDefinitionsEqual(interaction1, interaction2)) {
				matching.add(interaction1);
			} else {
				return matching;
			}
		}
		return matching;
	}

	private static boolean areInteractionDefinitionsEqual(Interaction interaction1, Interaction interaction2) {
		if (interaction1 instanceof NegatedModalInteraction) {
			return areNegatedEqual((NegatedModalInteraction) interaction1, (NegatedModalInteraction) interaction2);
		}
		if (interaction1 instanceof Signal) {
			return areSignalsEqual((Signal) interaction1, (Signal) interaction2);
		}
		if (interaction1 instanceof Delay) {
			return areDelaysEqual((Delay) interaction1, (Delay) interaction2);
		}
		return false;
	}

	private static boolean areSignalsEqual(Signal signal1, Signal signal2) {
		boolean direction = signal1.getDirection() == signal2.getDirection();
		boolean modality = signal1.getModality() == signal2.getModality();
		boolean port = signal1.getPort().equals(signal2.getPort());
		boolean event = signal1.getEvent().equals(signal2.getEvent());
		boolean arguments = true;
		for (int i = 0; i < signal1.getArguments().size(); i++) {
			Expression arg1 = signal1.getArguments().get(i);
			Expression arg2 = signal2.getArguments().get(i);
			if (evaluator.evaluate(arg2) != evaluator.evaluate(arg1)) {
				arguments = false;
			}
		}
		return direction && modality && port && event && arguments;
	}

	private static boolean areDelaysEqual(Delay delay1, Delay delay2) {
		boolean modality = delay1.getModality() == delay2.getModality();
		boolean minimum = evaluator.evaluate(delay1.getMinimum()) != evaluator.evaluate(delay2.getMinimum());
		boolean maximum = evaluator.evaluate(delay1.getMaximum()) != evaluator.evaluate(delay2.getMaximum());
		return maximum && modality && minimum;
	}

	private static boolean areNegatedEqual(NegatedModalInteraction negated1, NegatedModalInteraction negated2) {
		InteractionDefinition inner1 = negated1.getModalinteraction();
		InteractionDefinition inner2 = negated2.getModalinteraction();
		if (inner1 instanceof Signal && inner2 instanceof Signal) {
			return areSignalsEqual((Signal) inner1, (Signal) inner2);
		}
		if (inner1 instanceof ModalInteractionSet && inner2 instanceof ModalInteractionSet) {
			return areInteractionSetsEqual((ModalInteractionSet) inner1, (ModalInteractionSet) inner2);
		}
		return false;
	}

	private static boolean areInteractionSetsEqual(ModalInteractionSet inner1, ModalInteractionSet inner2) {
		List<InteractionDefinition> content1 = inner1.getModalInteractions();
		List<InteractionDefinition> content2 = inner2.getModalInteractions();
		List<Signal> signals1 = javaUtil.filterIntoList(content1, Signal.class);
		List<Signal> signals2 = javaUtil.filterIntoList(content2, Signal.class);
		List<Delay> delays1 = javaUtil.filterIntoList(content1, Delay.class);
		List<Delay> delays2 = javaUtil.filterIntoList(content2, Delay.class);
		List<NegatedModalInteraction> negated1 = javaUtil.filterIntoList(content1, NegatedModalInteraction.class);
		List<NegatedModalInteraction> negated2 = javaUtil.filterIntoList(content2, NegatedModalInteraction.class);
		areInteractionDefinitionListsEqual(signals1, signals2);
		areInteractionDefinitionListsEqual(delays1, delays2);
		areInteractionDefinitionListsEqual(negated1, negated2);
		return signals2.isEmpty() && negated2.isEmpty() && delays2.isEmpty();
	}

	private static void areInteractionDefinitionListsEqual(List<? extends InteractionDefinition> list1,
			List<? extends InteractionDefinition> list2) {
		for (InteractionDefinition interaction : list1) {
			boolean found = false;
			for (int i = 0; i < list2.size() && !found; i++) {
				if (interaction instanceof NegatedModalInteraction) {
					NegatedModalInteraction negated1 = (NegatedModalInteraction) interaction;
					NegatedModalInteraction negated2 = (NegatedModalInteraction) list2.get(i);
					if (areNegatedEqual(negated1, negated2)) {
						found = true;
						list2.remove(i);
					}
				}
				if (interaction instanceof Signal) {
					Signal signal1 = (Signal) interaction;
					Signal signal2 = (Signal) list2.get(i);
					if (areSignalsEqual(signal1, signal2)) {
						found = true;
						list2.remove(i);
					}
				}
				if (interaction instanceof Delay) {
					Delay delay1 = (Delay) interaction;
					Delay delay2 = (Delay) list2.get(i);
					if (areDelaysEqual(delay1, delay2)) {
						found = true;
						list2.remove(i);
					}
				}
			}
		}
	}

}
