package hu.bme.mit.gamma.action.model.util;

import java.util.Collection;

import hu.bme.mit.gamma.action.model.Action;
import hu.bme.mit.gamma.action.model.ActionModelFactory;
import hu.bme.mit.gamma.action.model.Block;

public class ActionUtil {

	private ActionModelFactory factory = ActionModelFactory.eINSTANCE;
	
	public Action extend(Action originalAction, Action newAction) {
		if (originalAction == null) {
			return newAction;
		}
		else if (newAction == null) {
			return originalAction;
		}
		else if (originalAction instanceof Block) {
			Block block = (Block) originalAction;
			block.getActions().add(newAction);
			return block;
		}
		else {
			Block block = factory.createBlock();
			block.getActions().add(originalAction);
			block.getActions().add(newAction);
			return block;
		}
	}
	
	public Action extend(Action originalAction, Collection<? extends Action> newActions) {
		Action extensibleAction = originalAction;
		for (Action newAction : newActions) {
			extensibleAction = extend(extensibleAction, newAction);
		}
		return extensibleAction;
	}
	
}
