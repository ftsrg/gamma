/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.EventDirection
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.AbstractAssignmentAction
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.Collection

import static com.google.common.base.Preconditions.checkArgument
import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class InternalEventHandler {
	// Singleton
	public static final InternalEventHandler INSTANCE =  new InternalEventHandler
	protected new() {}
	// Auxiliary objects
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	//
	
	def void addInternalEventHandlingActions(XSTS xSts, Component component) {
		if (component.asynchronous || // No signal manipulation for async components and ones with async parents (adapters)
				(!component.top && component.parentComponent.asynchronous)) {
			return
		}
		
		val topInternalPorts = component.allInternalPorts.filter[it.topComponentPort].toList
		xSts.addInternalEventHandlingActions(topInternalPorts)
	}
	
	def void addInternalEventHandlingActions(XSTS xSts, Collection<? extends Port> ports) {
		xSts.addInternalEventHandlingActionsInEntryAction(ports)
		xSts.addInternalEventHandlingActionsInMergedAction(ports)
	}
	
	protected def void addInternalEventHandlingActionsInEntryAction(XSTS xSts, Collection<? extends Port> ports) {
		val xStsEntryEventAction = xSts.entryEventTransition.action
		xStsEntryEventAction.addInternalEventHandlingActions(ports)
	}
	
	protected def void addInternalEventHandlingActionsInMergedAction(XSTS xSts, Collection<? extends Port> ports) {
		val xStsMergedAction = xSts.mergedAction
		xStsMergedAction.addInternalEventHandlingActions(ports)
	}
	
	def void addInternalEventHandlingActions(
			XSTS xSts, Component component, Traceability traceability) {
		xSts.addInternalEventHandlingActionsInEntryAction(component, traceability)
		xSts.addInternalEventHandlingActionsInMergedAction(component, traceability)
	}
	
	protected def void addInternalEventHandlingActionsInEntryAction(
			XSTS xSts, Component component, Traceability traceability) {
		val xStsEntryEventAction = xSts.entryEventTransition.action
		xStsEntryEventAction.addInternalEventHandlingActions(
				component, traceability.internalEventHandlingActionsOfEntryAction)
	}
	
	protected def void addInternalEventHandlingActionsInMergedAction(
			XSTS xSts, Component component, Traceability traceability) {
		val xStsMergedAction = xSts.mergedAction
		xStsMergedAction.addInternalEventHandlingActions(
				component, traceability.internalEventHandlingActionsOfMergedAction)
	}
	
	def void removeInternalEventHandlingActions(
			XSTS xSts, Component component, Traceability traceability) {
		xSts.removeInternalEventHandlingActionsInEntryAction(component, traceability)
		xSts.removeInternalEventHandlingActionsInMergedAction(component, traceability)
	}
	
	protected def void removeInternalEventHandlingActionsInEntryAction(
			XSTS xSts, Component component, Traceability traceability) {
		val xStsEntryEventAction = xSts.entryEventTransition.action
		xStsEntryEventAction.removeInternalEventHandlingActions(
				component, traceability.internalEventHandlingActionsOfEntryAction)
	}
	
	protected def void removeInternalEventHandlingActionsInMergedAction(
			XSTS xSts, Component component, Traceability traceability) {
		val xStsMergedAction = xSts.mergedAction
		xStsMergedAction.removeInternalEventHandlingActions(
				component, traceability.internalEventHandlingActionsOfEntryAction)
	}
	
	def void replaceInternalEventHandlingActions(
			XSTS xSts, Component component, Traceability traceability) {
		xSts.replaceInternalEventHandlingActionsInEntryAction(component, traceability)
		xSts.replaceInternalEventHandlingActionsInMergedAction(component, traceability)
	}
	
	protected def void replaceInternalEventHandlingActionsInEntryAction(
			XSTS xSts, Component component, Traceability traceability) {
		val xStsEntryEventAction = xSts.entryEventTransition.action
		xStsEntryEventAction.replaceInternalEventHandlingActions(
				component, traceability.internalEventHandlingActionsOfEntryAction)
	}
	
	protected def void replaceInternalEventHandlingActionsInMergedAction(
			XSTS xSts, Component component, Traceability traceability) {
		val xStsMergedAction = xSts.mergedAction
		xStsMergedAction.replaceInternalEventHandlingActions(
				component, traceability.internalEventHandlingActionsOfMergedAction)
	}
	
	//
	
	protected def void replaceInternalEventHandlingActions(
			Action action, Component component, Collection<Action> internalEventHandlingActions) {
		action.removeInternalEventHandlingActions(component, internalEventHandlingActions)
		action.addInternalEventHandlingActions(component, internalEventHandlingActions)
	}
	
	protected def void removeInternalEventHandlingActions(
			Action action, Component component, Collection<Action> internalEventHandlingActions) {
		val allInternalEventHandlingActions = action.getInternalEventHandlingActions(component)
		
		allInternalEventHandlingActions.retainAll(internalEventHandlingActions)
		allInternalEventHandlingActions.forEach[it.replaceWithEmptyAction]
		
		internalEventHandlingActions.clear // Clearing the trace set
	}
	
	protected def void addInternalEventHandlingActions(
			Action action, Component component, Collection<Action> internalEventHandlingActions) {
		val xSts = action.containingXsts
		val xStsInternalEventHandlings = xSts.createInternalEventHandlingActions(component)
		action.appendToAction(xStsInternalEventHandlings)
		
		internalEventHandlingActions += xStsInternalEventHandlings // Filling the trace set
	}
	
	protected def void addInternalEventHandlingActions(Action action, Collection<? extends Port> ports) {
		val xSts = action.containingXsts
		val xStsInternalEventHandlings = xSts.createInternalEventHandlingActions(ports)
		action.appendToAction(xStsInternalEventHandlings)
	}
	
	//
	
	protected def createInternalEventHandlingActions(XSTS xSts, Component component) {
		val internalPorts = component.allInternalPorts
		return xSts.createInternalEventHandlingActions(internalPorts)
	}
	
	protected def createInternalEventHandlingActions(XSTS xSts, Collection<? extends Port> internalPorts) {
		val actions = newArrayList
		
		for (internalPort : internalPorts) {
			actions += xSts.createInternalEventHandlingActions(internalPort)
		}
		
		return actions
	}
	
	protected def createInternalEventHandlingActions(XSTS xSts, Port port) {
		checkArgument(port.internal, "Port '" + port.name + "' is not internal")
		
		val actions = newArrayList
		
		val extension ReferenceToXstsVariableMapper mapper = new ReferenceToXstsVariableMapper(xSts)
		
		val internalEvents = port.internalEvents
		for (internalEvent : internalEvents) {
			val xStsInputEventVariable = internalEvent.getInputEventVariable(port)
			val xStsOutputEventVariable = internalEvent.getOutputEventVariable(port)
			
			// If output or input is not used, then there will be no variable for it
			if (xStsInputEventVariable !== null && xStsOutputEventVariable !== null) {
				actions += xStsInputEventVariable.createAssignmentAction(xStsOutputEventVariable)
				actions += xStsOutputEventVariable.createVariableResetAction
				
				for (parameter : internalEvent.parameterDeclarations) {
					val xStsInputParameterVariables = parameter.getInputParameterVariables(port)
					val xStsOutputParameterVariables = parameter.getOutputParameterVariables(port)
					val size = xStsInputParameterVariables.size
					checkState(size == xStsOutputParameterVariables.size)
					
					for (var i = 0; i < size; i++) {
						val xStsInputParameterVariable = xStsInputParameterVariables.get(i)
						val xStsOutputParameterVariable = xStsOutputParameterVariables.get(i)
						
						actions += xStsInputParameterVariable
								.createAssignmentAction(xStsOutputParameterVariable)
						if (parameter.transient) {
							actions += xStsOutputParameterVariable.createVariableResetAction
						}
					}
				}
			}
		}
		
		return actions
	}
	
	//
	
	protected def getInternalEventHandlingActions(Action action, Component component) {
		val xStsVariableAssignments = newArrayList
		
		val internalPorts = component.allInternalPorts
		for (internalPort : internalPorts) {
			xStsVariableAssignments += action.getInternalEventHandlingActions(internalPort)
		}
		
		return xStsVariableAssignments
	}
	
	protected def getInternalEventHandlingActions(Action action, Port port) {
		checkArgument(port.internal, "Port '" + port.name + "' is not internal")
		
		val xSts = action.containingXsts
		val extension ReferenceToXstsVariableMapper mapper = new ReferenceToXstsVariableMapper(xSts)
		
		val xStsVariables = newArrayList
		val xStsVariableAssignments = newArrayList
		
		val internalEvents = port.internalEvents
		for (internalEvent : internalEvents) {
			xStsVariables += internalEvent.getInputEventVariable(port)
			xStsVariables += internalEvent.getOutputEventVariable(port)
			
			for (parameter : internalEvent.parameterDeclarations) {
				xStsVariables += parameter.getInputParameterVariables(port)
				xStsVariables += parameter.getOutputParameterVariables(port)
			}
		}
		
		val xStsAssignments = action.getSelfAndAllContentsOfType(AbstractAssignmentAction)
		for (xStsAssignment : xStsAssignments) {
			val xStsLhsDeclaration = xStsAssignment.lhs.declaration
			if (xStsVariables.contains(xStsLhsDeclaration)) {
				xStsVariableAssignments += xStsAssignment
			}
		}
		
		return xStsVariableAssignments
	}
	
	//
	
	def void addInternalEventResetingActionsInMergedAction(
			XSTS xSts, Component component) {
		val xStsMergedAction = xSts.mergedAction
		
		val xStsOutResets = xSts.createInternalEventResetingActions(component, EventDirection.OUT)
		xStsOutResets.prependToAction(xStsMergedAction)
		val xStsInResets = xSts.createInternalEventResetingActions(component, EventDirection.IN)
		xStsMergedAction.appendToAction(xStsInResets)
	}
	
	protected def createInternalEventResetingActions(
			XSTS xSts, Component component, EventDirection direction) {
		val xStsVariableAssignments = newArrayList
		
		val internalPorts = component.allInternalPorts
		for (internalPort : internalPorts) {
			xStsVariableAssignments += xSts.createInternalEventResetingActions(internalPort, direction)
		}
		
		return xStsVariableAssignments
	}
	
	protected def createInternalEventResetingActions(XSTS xSts, Port port, EventDirection direction) {
		checkArgument(port.internal, "Port '" + port.name + "' is not internal")
		
		val extension ReferenceToXstsVariableMapper mapper = new ReferenceToXstsVariableMapper(xSts)
		
		val xStsVariables = newArrayList
		val xStsVariableAssignments = newArrayList
		
		val internalEvents = port.internalEvents
		for (internalEvent : internalEvents) {
			if (direction == EventDirection.IN) {
				xStsVariables += internalEvent.getInputEventVariable(port)
			}
			else if (direction == EventDirection.OUT) {
				xStsVariables += internalEvent.getOutputEventVariable(port)
			}
			else {
				throw new IllegalArgumentException
			}
			
			if (internalEvent.transient) {
				for (parameter : internalEvent.parameterDeclarations) {
					if (direction == EventDirection.IN) {
						xStsVariables += parameter.getInputParameterVariables(port)
					}
					else if (direction == EventDirection.OUT) {
						xStsVariables += parameter.getOutputParameterVariables(port)
					}
					else {
						throw new IllegalArgumentException("Not known direction: " + direction)
					}
				}
			}
		}
		
		for (xStsVariable : xStsVariables.filterNull) { // If internal events are filtered, there can be nulls
			xStsVariableAssignments += xStsVariable.createVariableResetAction
		}
		
		return xStsVariableAssignments
	}
	
	
//	def void removeInternalEventHandlingActions(XSTS xSts, Component component) {
//		val internalPorts = component.allInternalPorts
//		for (internalPort : internalPorts) {
//			xSts.removeInternalEventHandlingActions(internalPort)
//		}
//	}
//	
//	def void removeInternalEventHandlingActions(XSTS xSts, Port port) {
//		val xStsMergedAction = xSts.mergedAction
//		xStsMergedAction.removeInternalEventHandlingActions(port)
//	}
//	
//	def void removeInternalEventHandlingActions(Action action, Port port) {
//		checkArgument(port.internal, "Port '" + port.name + "' is not internal")
//		
//		val xSts = action.containingXsts
//		val extension ReferenceToXstsVariableMapper mapper = new ReferenceToXstsVariableMapper(xSts)
//		
//		val xStsVariables = newArrayList
//		
//		val internalEvents = port.internalEvents
//		for (internalEvent : internalEvents) {
//			xStsVariables += internalEvent.getInputEventVariable(port)
//			xStsVariables += internalEvent.getOutputEventVariable(port)
//			
//			for (parameter : internalEvent.parameterDeclarations) {
//				xStsVariables += parameter.getInputParameterVariables(port)
//				xStsVariables += parameter.getOutputParameterVariables(port)
//			}
//		}
//		
//		val xStsAssignments = action.getSelfAndAllContentsOfType(AbstractAssignmentAction)
//		for (xStsAssignment : xStsAssignments) {
//			val xStsLhsDeclaration = xStsAssignment.lhs.declaration
//			if (xStsVariables.contains(xStsLhsDeclaration)) {
//				xStsAssignment.remove
//			}
//		}
//	}
	
}