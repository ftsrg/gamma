package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.xsts.model.Action
import java.util.Set

import static com.google.common.base.Preconditions.checkNotNull


class Traceability {
	
	Set<Action> internalEventHandlingActions = newHashSet
	
	//
	
	def putInternalEventHandlingAction(Iterable<? extends Action> actions) {
		for (action : actions) {
			putInternalEventHandlingAction(action)
		}
	}
	
	def putInternalEventHandlingAction(Action action) {
		checkNotNull(action)
		internalEventHandlingActions += action
	}
	
	def getInternalEventHandlingActions() {
		return internalEventHandlingActions
	}
	
	def clearInternalEventHandlingActions() {
		internalEventHandlingActions.clear
	}
	
}