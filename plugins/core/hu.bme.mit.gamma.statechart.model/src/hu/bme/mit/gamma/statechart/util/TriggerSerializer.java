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

import hu.bme.mit.gamma.statechart.interface_.AnyTrigger;
import hu.bme.mit.gamma.statechart.interface_.EventTrigger;
import hu.bme.mit.gamma.statechart.interface_.OccurrenceReferenceExpression;
import hu.bme.mit.gamma.statechart.interface_.Trigger;
import hu.bme.mit.gamma.statechart.statechart.BinaryTrigger;
import hu.bme.mit.gamma.statechart.statechart.BinaryType;
import hu.bme.mit.gamma.statechart.statechart.OnCycleTrigger;
import hu.bme.mit.gamma.statechart.statechart.OpaqueTrigger;
import hu.bme.mit.gamma.statechart.statechart.UnaryTrigger;
import hu.bme.mit.gamma.statechart.statechart.UnaryType;

public class TriggerSerializer {
	// Singleton
	public static final TriggerSerializer INSTANCE = new TriggerSerializer();
	protected TriggerSerializer() {}
	//
	protected final ExpressionSerializer serializer = new ExpressionSerializer();
	//
	
	protected String _serialize(AnyTrigger trigger) {
		return "any";
	}
	
	protected String _serialize(OnCycleTrigger trigger) {
		return "cycle";
	}
	
	protected String _serialize(OpaqueTrigger trigger) {
		return trigger.getTrigger();
	}
	
	protected String _serialize(EventTrigger trigger) {
		OccurrenceReferenceExpression eventReference = trigger.getEventReference();
		return serializer.serialize(eventReference);
	}
	
	protected String _serialize(UnaryTrigger trigger) {
		UnaryType type = trigger.getType();
		Trigger operand = trigger.getOperand();
		assert type == UnaryType.NOT;
		
		return "not " + serialize(operand);
	}
	
	protected String _serialize(BinaryTrigger trigger) {
		BinaryType type = trigger.getType();
		Trigger lhs = trigger.getLeftOperand();
		Trigger rhs = trigger.getRightOperand();
		
		return  serialize(lhs) + " " + _serialize(type) + " " + serialize(rhs);
	}
	
	protected String _serialize(BinaryType type) {
		switch (type) {
			case AND: return "&&";
			case EQUAL: return "==";
			case IMPLY: return "=>";
			case OR: return "||";
			case XOR: return "^";
			default:
				throw new IllegalArgumentException("Not known type: " + type);
		}
	}
	
	///
	public String serialize(Trigger trigger) {
		if (trigger instanceof AnyTrigger _trigger) {
			return _serialize(_trigger);
		}
		if (trigger instanceof OnCycleTrigger _trigger) {
			return _serialize(_trigger);
		}
		if (trigger instanceof OpaqueTrigger _trigger) {
			return _serialize(_trigger);
		}
		if (trigger instanceof EventTrigger _trigger) {
			return _serialize(_trigger);
		}
		if (trigger instanceof UnaryTrigger _trigger) {
			return _serialize(_trigger);
		}
		if (trigger instanceof BinaryTrigger _trigger) {
			return _serialize(_trigger);
		}
		
		throw new IllegalArgumentException("Not known trigger: " + trigger);
	}
	
}
