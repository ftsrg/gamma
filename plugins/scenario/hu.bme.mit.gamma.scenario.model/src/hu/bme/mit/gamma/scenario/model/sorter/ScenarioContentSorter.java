package hu.bme.mit.gamma.scenario.model.sorter;

import java.util.Comparator;
import java.util.List;

import hu.bme.mit.gamma.scenario.model.AlternativeCombinedFragment;
import hu.bme.mit.gamma.scenario.model.InteractionDefinition;
import hu.bme.mit.gamma.scenario.model.InteractionFragment;
import hu.bme.mit.gamma.scenario.model.ModalInteractionSet;
import hu.bme.mit.gamma.scenario.model.ScenarioDefinition;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ScenarioContentSorter {

	private static GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;

	public void sort(ScenarioDefinition scenario) {
		List<ModalInteractionSet> sets = ecoreUtil.getAllContentsOfType(scenario, ModalInteractionSet.class);
		for(ModalInteractionSet set : sets) {
			sortInteractionSet(set);
		}
		
		List<AlternativeCombinedFragment> alts = ecoreUtil.getAllContentsOfType(scenario, AlternativeCombinedFragment.class);
		for(AlternativeCombinedFragment alt : alts) {
			sortAlternativeFragment(alt);
		}
		
	}

	private void sortInteractionSet(ModalInteractionSet set) {
		List<InteractionDefinition> interactions = set.getModalInteractions();
		interactions.sort(Comparator.comparing(InteractionDefinition::toString));		
	}
	
	private void sortAlternativeFragment(AlternativeCombinedFragment alt) {
		List<InteractionFragment> fragments = alt.getFragments();
		fragments.sort(Comparator.comparing(InteractionFragment::toString));		
	}
	
	
}
