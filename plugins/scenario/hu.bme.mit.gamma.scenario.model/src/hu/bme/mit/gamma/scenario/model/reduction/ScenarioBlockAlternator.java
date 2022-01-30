package hu.bme.mit.gamma.scenario.model.reduction;

import hu.bme.mit.gamma.scenario.model.AlternativeCombinedFragment;
import hu.bme.mit.gamma.scenario.model.Interaction;
import hu.bme.mit.gamma.scenario.model.InteractionDirection;
import hu.bme.mit.gamma.scenario.model.InteractionFragment;
import hu.bme.mit.gamma.scenario.model.LoopCombinedFragment;
import hu.bme.mit.gamma.scenario.model.ModalInteractionSet;
import hu.bme.mit.gamma.scenario.model.OptionalCombinedFragment;
import hu.bme.mit.gamma.scenario.model.ScenarioModelFactory;

public class ScenarioBlockAlternator {
	
	protected ScenarioModelFactory factory = ScenarioModelFactory.eINSTANCE;
	
	public void transform(InteractionFragment fragment) {
		this.transform(fragment, InteractionDirection.SEND, null);
	}

	protected void transform(InteractionFragment fragment, InteractionDirection previous, InteractionDirection next) {
		InteractionDirection last = previous;
		for (int i= 0; i< fragment.getInteractions().size();i++) {
			Interaction interaction = fragment.getInteractions().get(i);
			if (interaction instanceof ModalInteractionSet) {
//				ModalInteractionSet set= (ModalInteractionSet) interaction;
//				if (last == set.getDirection) {
//					fragment.getInteractions().add(i, getEmptySet());
//					i++;
//				}
//				else {
//					last = getOther(last);
//				}
			}
			else if(interaction instanceof AlternativeCombinedFragment) {
				AlternativeCombinedFragment alt = (AlternativeCombinedFragment) interaction;
				handleAlternativeCombinedFragment(alt,last);
			}
			else if(interaction instanceof OptionalCombinedFragment) {
				
			}
			else if(interaction instanceof LoopCombinedFragment) {
				
			}
		}
		if ( next != null && next == previous) {
			fragment.getInteractions().add(fragment.getInteractions().size()-1, getEmptySet());
		}
		
	}
	


	private void handleAlternativeCombinedFragment(AlternativeCombinedFragment alt, InteractionDirection last) {
		// TODO Auto-generated method stub
		
	}

	protected InteractionDirection getOther(InteractionDirection last) {
		if(last == InteractionDirection.RECEIVE) {
			return InteractionDirection.SEND;
		}
		return InteractionDirection.RECEIVE;
	}

	protected ModalInteractionSet getEmptySet() {
		return factory.createModalInteractionSet();
	}
}
