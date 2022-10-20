package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.xsts.model.Action
import java.util.Set

import static com.google.common.base.Preconditions.checkNotNull

class Traceability {
	
//	Map<Component, MultiaryAction> asynchronousCompositeActions = newHashMap
	//
	Set<Action> internalEventHandlingActionsOfMergedAction = newHashSet
	Set<Action> internalEventHandlingActionsOfEntryAction = newHashSet
	
//	//
//	
//	def putAsynchronousCompositeAction(
//			AbstractAsynchronousCompositeComponent component, MultiaryAction action) {
//		checkNotNull(component)
//		checkNotNull(action)
//		asynchronousCompositeActions += component -> action
//	}
//	
//	def hasAsynchronousCompositeAction(AbstractAsynchronousCompositeComponent component) {
//		checkNotNull(component)
//		return asynchronousCompositeActions.containsKey(component)
//	}
//	
//	def getAsynchronousCompositeAction(
//			AbstractAsynchronousCompositeComponent component) {
//		checkState(component.hasAsynchronousCompositeAction)
//		val action = asynchronousCompositeActions.get(component)
//		return action
//	}
//	
//	//
	
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