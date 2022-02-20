package hu.bme.mit.gamma.scenario.model.reduction;

import java.util.ArrayList;
import java.util.List;

import hu.bme.mit.gamma.scenario.model.AlternativeCombinedFragment;
import hu.bme.mit.gamma.scenario.model.Interaction;
import hu.bme.mit.gamma.scenario.model.InteractionFragment;
import hu.bme.mit.gamma.scenario.model.OptionalCombinedFragment;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class EmbededCombinedFragmentRemover {

	private static GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;

	public void transform(AlternativeCombinedFragment alternative) {

		for (InteractionFragment fragment : alternative.getFragments()) {
			for (Interaction interaction : fragment.getInteractions()) {
				if (interaction instanceof AlternativeCombinedFragment) {
					handleAlternative((AlternativeCombinedFragment) interaction, fragment, alternative);
				} else if (interaction instanceof OptionalCombinedFragment) {
					handleOptional((OptionalCombinedFragment) interaction, fragment, alternative);
				}
			}
		}

	}

	private void handleOptional(OptionalCombinedFragment optional, InteractionFragment fragment,
			AlternativeCombinedFragment outer) {
		int index = fragment.getInteractions().indexOf(optional);
		InteractionFragment newfragment = ecoreUtil.clone(fragment);
		ecoreUtil.replace(ecoreUtil.clone(optional.getFragments().get(0)), newfragment.getInteractions().get(index));
		outer.getFragments().add(newfragment);
		fragment.getInteractions().remove(optional);
	}

	private void handleAlternative(AlternativeCombinedFragment alternative, InteractionFragment fragment,
			AlternativeCombinedFragment outer) {
		List<InteractionFragment> newFragments = new ArrayList<>();
		int index = fragment.getInteractions().indexOf(alternative);
		for (InteractionFragment innerFragment : alternative.getFragments()) {
			InteractionFragment newfragment = ecoreUtil.clone(fragment);
			ecoreUtil.replace(ecoreUtil.clone(innerFragment), newfragment.getInteractions().get(index));
			newFragments.add(newfragment);
		}
		outer.getFragments().remove(fragment);
		outer.getFragments().addAll(newFragments);
	}

}
