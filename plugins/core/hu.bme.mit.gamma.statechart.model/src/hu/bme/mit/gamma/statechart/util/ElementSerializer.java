/********************************************************************************
 * Copyright (c) 2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.statechart.util;

import java.util.List;

import hu.bme.mit.gamma.action.model.Action;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.statechart.interface_.Trigger;
import hu.bme.mit.gamma.statechart.statechart.Transition;

public class ElementSerializer {
	// Singleton
	public static final ElementSerializer INSTANCE = new ElementSerializer();
	protected ElementSerializer() {}
	//
	protected final TriggerSerializer triggerSerializer = TriggerSerializer.INSTANCE;
	protected final ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE;
	protected final ActionSerializer actionSerializer = ActionSerializer.INSTANCE;
	//
	
	public String serialize(Transition transition) {
		String stateNodes = "from " + transition.getSourceState().getName() + " to " + transition.getTargetState();
		
		Trigger trigger = transition.getTrigger();
		String triggerString = "when " + triggerSerializer.serialize(trigger);
		
		Expression guard = transition.getGuard();
		String guardString = (guard == null) ? "" : expressionSerializer.serialize(guard);
		
		List<Action> effects = transition.getEffects();
		String effectString = (effects.isEmpty()) ? "" : "/ " + effects.stream()
				.map(it -> actionSerializer.serialize(it))
				.reduce((t, u) -> t + "; " + u);
		
		return stateNodes + " " + triggerString + " " + guardString + " " + effectString;
	}
	
}
