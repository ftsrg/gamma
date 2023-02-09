/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.XSTS
import java.util.Set

import static com.google.common.base.Preconditions.checkNotNull

class Traceability {
	
	XSTS xSts
	
	Set<Action> internalEventHandlingActionsOfMergedAction = newHashSet
	Set<Action> internalEventHandlingActionsOfEntryAction = newHashSet
	
	//
	
	def setXSts(XSTS xSts) {
		this.xSts = xSts
	}
	
	def getXSts() {
		return xSts
	}
	
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