/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventDirection
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.RealizationMode
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration
import hu.bme.mit.gamma.statechart.lowlevel.model.StatechartModelFactory
import java.util.List

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.xsts.transformation.util.LowlevelNamings.*

class EventDeclarationTransformer {
// Auxiliary objects
	protected final extension ValueDeclarationTransformer valueDeclarationTransformer
	protected final extension EventAttributeTransformer eventAttributeTransformer = EventAttributeTransformer.INSTANCE
	// Low-level statechart model factory
	protected final extension StatechartModelFactory factory = StatechartModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	// Trace object for storing the mappings
	protected final Trace trace
	
	new(Trace trace) {
		this.trace = trace
		this.valueDeclarationTransformer = new ValueDeclarationTransformer(this.trace)
	}
	
	/**
	 * Returns a list, as an INOUT declaration is mapped to an IN and an OUT declaration.
	 */
	protected def List<EventDeclaration> transform(
			hu.bme.mit.gamma.statechart.interface_.EventDeclaration declaration, Port gammaPort) {
		val gammaDirection = declaration.direction
		val realizationMode = gammaPort.interfaceRealization.realizationMode
		if (gammaDirection == EventDirection.IN &&
				realizationMode == RealizationMode.PROVIDED ||
				gammaDirection == EventDirection.OUT &&
				realizationMode == RealizationMode.REQUIRED) {
			// Event coming in
			val lowlevelEventIn = declaration.event.transform(gammaPort, EventDirection.IN)
			trace.put(gammaPort, declaration, lowlevelEventIn) // Tracing the EventDeclaration
			trace.put(gammaPort, declaration.event, lowlevelEventIn) // Tracing the Event
			return #[lowlevelEventIn]
		}
		else if	(gammaDirection == EventDirection.IN &&
				realizationMode == RealizationMode.REQUIRED ||
				gammaDirection == EventDirection.OUT &&
				realizationMode == RealizationMode.PROVIDED) {
			// Events going out
			val lowlevelEventOut = declaration.event.transform(gammaPort, EventDirection.OUT)
			trace.put(gammaPort, declaration, lowlevelEventOut) // Tracing the EventDeclaration
			trace.put(gammaPort, declaration.event, lowlevelEventOut) // Tracing the Event
			return #[lowlevelEventOut]
		}
		else {
			// In-out events
			// At low-level, INTERNAL events are transformed as INOUT events
			checkState(gammaDirection == EventDirection.INOUT ||
				gammaDirection == EventDirection.INTERNAL)
			val lowlevelEventIn = declaration.event.transform(gammaPort, EventDirection.IN)
			trace.put(gammaPort, declaration, lowlevelEventIn) // Tracing the EventDeclaration
			val lowlevelEventOut = declaration.event.transform(gammaPort, EventDirection.OUT)
			trace.put(gammaPort, declaration, lowlevelEventOut) // Tracing the EventDeclaration
			return #[lowlevelEventIn, lowlevelEventOut]
		}
	}

	protected def EventDeclaration transform(Event gammaEvent, Port gammaPort, EventDirection direction) {
		checkState(direction == EventDirection.IN || direction == EventDirection.OUT)
		
		val lowlevelEvent = createEventDeclaration => [
			it.name = (direction == EventDirection.IN) ?
				gammaEvent.getInputName(gammaPort) : gammaEvent.getOutputName(gammaPort)
			it.persistency = gammaEvent.persistency.transform
			it.direction = direction.transform
			it.isRaised = createVariableDeclaration => [
				it.name = "isRaised"
				it.type = createBooleanTypeDefinition
			]
		]
		trace.put(gammaPort, gammaEvent, lowlevelEvent)
		
		// Transforming the parameters
		for (gammaParameter : gammaEvent.parameterDeclarations) {
			val lowlevelParameters = (direction == EventDirection.IN) ?
				gammaParameter.transformInParameter(gammaPort) : 
				gammaParameter.transformOutParameter(gammaPort)
			lowlevelEvent.parameters += lowlevelParameters
		}
		return lowlevelEvent
	}
	
}