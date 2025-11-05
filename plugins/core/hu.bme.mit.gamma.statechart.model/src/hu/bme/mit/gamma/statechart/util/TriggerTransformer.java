/**
 * Copyright (c) 2025 Contributors to the Gamma project
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * SPDX-License-Identifier: EPL-1.0
 */
package hu.bme.mit.gamma.statechart.util;

import java.util.ArrayList;
import java.util.List;

import hu.bme.mit.gamma.expression.model.AndExpression;
import hu.bme.mit.gamma.expression.model.EqualityExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.ImplyExpression;
import hu.bme.mit.gamma.expression.model.NotExpression;
import hu.bme.mit.gamma.expression.model.OrExpression;
import hu.bme.mit.gamma.expression.model.XorExpression;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.AnyTrigger;
import hu.bme.mit.gamma.statechart.interface_.EventReference;
import hu.bme.mit.gamma.statechart.interface_.EventTrigger;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.interface_.Trigger;
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference;
import hu.bme.mit.gamma.statechart.statechart.BinaryTrigger;
import hu.bme.mit.gamma.statechart.statechart.BinaryType;
import hu.bme.mit.gamma.statechart.statechart.OnCycleTrigger;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory;
import hu.bme.mit.gamma.statechart.statechart.UnaryTrigger;
import hu.bme.mit.gamma.statechart.statechart.UnaryType;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class TriggerTransformer {
	// Singleton
	public static final TriggerTransformer INSTANCE = new TriggerTransformer();
	protected TriggerTransformer() {}
	//

	protected final StatechartModelFactory statechartFactory = StatechartModelFactory.eINSTANCE;
	protected final ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE;
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	
	//
	
	public Expression transformTrigger(Trigger trigger) {
		if (trigger == null) {
			factory.createTrueExpression();
		}
		
		if (trigger instanceof BinaryTrigger _trigger) {
			return transformTrigger(_trigger);
		}
		else if (trigger instanceof UnaryTrigger _trigger) {
			return transformTrigger(_trigger);
		}
		else if (trigger instanceof OnCycleTrigger _trigger) {
			return transformTrigger(_trigger);
		}
		else if (trigger instanceof AnyTrigger _trigger) {
			return transformTrigger(_trigger);
		}
		else if (trigger instanceof EventTrigger _trigger) {
			return transformTrigger(_trigger);
		}
		throw new IllegalArgumentException("Not known trigger: " + trigger);
	}
	
	//
	
	protected Expression transformTrigger(BinaryTrigger trigger) {
		BinaryType type = trigger.getType();
		switch (type) {
			case AND:
				AndExpression expression = factory.createAndExpression();
				expression.getOperands().add(
						transformTrigger(trigger.getLeftOperand()));
				expression.getOperands().add(
						transformTrigger(trigger.getRightOperand()));
				return expression;
			case EQUAL: 
				EqualityExpression expression2 = factory.createEqualityExpression();
				expression2.setLeftOperand(
						transformTrigger(trigger.getLeftOperand()));
				expression2.setRightOperand(
						transformTrigger(trigger.getRightOperand()));
				return expression2;
			case IMPLY:
				ImplyExpression expression3 = factory.createImplyExpression();
				expression3.setLeftOperand(
						transformTrigger(trigger.getLeftOperand()));
				expression3.setRightOperand(
						transformTrigger(trigger.getRightOperand()));
				return expression3;
			case OR:
				OrExpression expression4 = factory.createOrExpression();
				expression4.getOperands().add(
						transformTrigger(trigger.getLeftOperand()));
				expression4.getOperands().add(
						transformTrigger(trigger.getRightOperand()));
				return expression4;
			case XOR:
				XorExpression expression5 = factory.createXorExpression();
				expression5.getOperands().add(
						transformTrigger(trigger.getLeftOperand()));
				expression5.getOperands().add(
						transformTrigger(trigger.getRightOperand()));
				return expression5;
			default:
				throw new IllegalArgumentException("Not known trigger: " + trigger);
		}
	}
	
	protected Expression transformTrigger(UnaryTrigger trigger) {
		UnaryType type = trigger.getType();
		switch (type) {
			case NOT:
				NotExpression expression = factory.createNotExpression();
				expression.setOperand(
						transformTrigger(trigger.getOperand()));
				return expression;
			default:
				throw new IllegalArgumentException("Not known trigger: " + trigger);
		}
	}
	
	protected Expression transformTrigger(OnCycleTrigger trigger) {
		return factory.createTrueExpression();
	}
	
	protected Expression transformTrigger(AnyTrigger trigger) {
		List<Expression> triggerGuards = new ArrayList<Expression>();
		
		StatechartDefinition statechart = StatechartModelDerivedFeatures.getContainingStatechart(trigger);
		
		List<Port> ports = StatechartModelDerivedFeatures.getAllPorts(statechart); // Considering only IN events
		for (Port port : ports) {
			AnyPortEventReference reference = statechartFactory.createAnyPortEventReference();
			reference.setPort(port);
			triggerGuards.add(reference);
		}
		
		if (triggerGuards.isEmpty()) {
			// No possible incoming event
			Expression expression = factory.createFalseExpression();
			return expression;
		}
		if (triggerGuards.size() == 1) {
			// No need for or expression
			Expression expression = triggerGuards.get(0);
			return expression;
		}
		
		OrExpression expression = factory.createOrExpression();
		expression.getOperands().addAll(triggerGuards);
		
		return expression;
	}
	
	protected Expression transformTrigger(EventTrigger trigger) {
		EventReference eventReference = trigger.getEventReference();
		return ecoreUtil.clone(eventReference); // Clone
	}
	
}