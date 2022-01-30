package hu.bme.mit.gamma.scenario.model.reduction;

import hu.bme.mit.gamma.scenario.model.AlternativeCombinedFragment;
import hu.bme.mit.gamma.scenario.model.CombinedFragment;
import hu.bme.mit.gamma.scenario.model.LoopCombinedFragment;
import hu.bme.mit.gamma.scenario.model.OptionalCombinedFragment;

public class CombinedFragmentDeterminizator {
	
	public static void execute(CombinedFragment combinedFragment) {
		if(combinedFragment instanceof AlternativeCombinedFragment) {
			handleAlternative((AlternativeCombinedFragment) combinedFragment);
		}
		if(combinedFragment instanceof OptionalCombinedFragment) {
			handleOptional((OptionalCombinedFragment) combinedFragment);
		}
		if(combinedFragment instanceof LoopCombinedFragment) {
			handleLoop((LoopCombinedFragment) combinedFragment);
		}
	}

	private static void handleLoop(LoopCombinedFragment combinedFragment) {
		
	}

	private static void handleOptional(OptionalCombinedFragment combinedFragment) {
		throw new UnsupportedOperationException();
	}

	private static void handleAlternative(AlternativeCombinedFragment alternative) {
		throw new UnsupportedOperationException();
	}
	

}
