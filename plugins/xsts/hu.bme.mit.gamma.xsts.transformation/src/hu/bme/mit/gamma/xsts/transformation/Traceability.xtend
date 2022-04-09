package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.xsts.model.Action
import java.util.Set

import static com.google.common.base.Preconditions.checkNotNull


class Traceability {
	
	Set<Action> internalEventHandlingActionsOfMergedAction = newHashSet
	Set<Action> internalEventHandlingActionsOfEntryAction = newHashSet
	
	//
	
	def putInternalEventHandlingActionsOfMergedAction(Iterable<? extends Action> actions) {
		for (action : actions) {
			putInternalEventHandlingActionsOfMergedAction(action)
		}
	}
	
	def putInternalEventHandlingActionsOfMergedAction(Action action) {
		checkNotNull(action)
		internalEventHandlingActionsOfMergedAction += action
	}
	
	def getInternalEventHandlingActionsOfMergedAction() {
		return internalEventHandlingActionsOfMergedAction
	}
	
	def clearInternalEventHandlingActionsOfMergedAction() {
		internalEventHandlingActionsOfMergedAction.clear
	}
	
	//
	
	def putInternalEventHandlingActionsOfEntryAction(Iterable<? extends Action> actions) {
		for (action : actions) {
			putInternalEventHandlingActionsOfEntryAction(action)
		}
	}
	
	def putInternalEventHandlingActionsOfEntryAction(Action action) {
		checkNotNull(action)
		internalEventHandlingActionsOfEntryAction += action
	}
	
	def getInternalEventHandlingActionsOfEntryAction() {
		return internalEventHandlingActionsOfEntryAction
	}
	
	def clearInternalEventHandlingActionsOfEntryAction() {
		internalEventHandlingActionsOfEntryAction.clear
	}
	
}