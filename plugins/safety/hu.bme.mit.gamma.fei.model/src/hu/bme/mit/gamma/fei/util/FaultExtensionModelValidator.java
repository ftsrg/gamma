/********************************************************************************
 * Copyright (c) 2023-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.fei.util;

import java.util.AbstractMap.SimpleEntry;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map.Entry;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.fei.model.CommonCauseMode;
import hu.bme.mit.gamma.fei.model.CommonCauseProbability;
import hu.bme.mit.gamma.fei.model.CommonCauseRange;
import hu.bme.mit.gamma.fei.model.Effect;
import hu.bme.mit.gamma.fei.model.FaultEvent;
import hu.bme.mit.gamma.fei.model.FaultMode;
import hu.bme.mit.gamma.fei.model.FaultModeState;
import hu.bme.mit.gamma.fei.model.FaultModeStateReference;
import hu.bme.mit.gamma.fei.model.FaultSlice;
import hu.bme.mit.gamma.fei.model.FaultTransition;
import hu.bme.mit.gamma.fei.model.FaultTransitionTrigger;
import hu.bme.mit.gamma.fei.model.FeiModelPackage;
import hu.bme.mit.gamma.fei.model.GlobalDynamics;
import hu.bme.mit.gamma.fei.model.LocalDynamics;
import hu.bme.mit.gamma.fei.model.SelfFixTemplate;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventReferenceExpression;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.statechart.util.StatechartModelValidator;

public class FaultExtensionModelValidator extends StatechartModelValidator {
	// Singleton
	public static final FaultExtensionModelValidator INSTANCE = new FaultExtensionModelValidator();
	protected FaultExtensionModelValidator() {
		// TODO add ExpressionTypeValidator
	}
	//
	
	public Collection<ValidationResultMessage> checkFaultModes(FaultMode faultMode) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		LocalDynamics localDynamics = faultMode.getLocalDynamics();
		Effect effect = faultMode.getEffect();
		boolean containsSelfFix = ecoreUtil.containsTypeTransitively(effect, SelfFixTemplate.class);
		if (localDynamics == LocalDynamics.TRANSIENT && !containsSelfFix) {
			validationResultMessages.add(new ValidationResultMessage(
				ValidationResult.ERROR,
					"If the local dynamics is set to 'transient', then the self-fix template must be instantiated",
						new ReferenceInfo(FeiModelPackage.Literals.FAULT_MODE__LOCAL_DYNAMICS)));
		}
		else if (localDynamics == LocalDynamics.PERMANENT && containsSelfFix) {
			validationResultMessages.add(new ValidationResultMessage(
				ValidationResult.ERROR,
					"If the local dynamics is set to 'permanent', then the self-fix template must not be instantiated",
						new ReferenceInfo(FeiModelPackage.Literals.FAULT_MODE__LOCAL_DYNAMICS)));
		}
	
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkGlobalDynamics(FaultSlice faultSlice) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		List<FaultMode> faultModes = faultSlice.getFaultModes();
		GlobalDynamics globalDynamics = faultSlice.getGlobalDynamics();
		if (faultModes.size() > 1 && globalDynamics == null) {
			validationResultMessages.add(new ValidationResultMessage(
				ValidationResult.ERROR,
					"If multiple fault effects are specified, then global dynamics must also be defined",
						new ReferenceInfo(FeiModelPackage.Literals.FAULT_SLICE__FAULT_MODES)));
		}
		
		if (globalDynamics != null && faultModes.size() < 2) {
			validationResultMessages.add(new ValidationResultMessage(
				ValidationResult.ERROR,
					"Global dynamics must also be defined in the case of multiple fault effects",
						new ReferenceInfo(FeiModelPackage.Literals.FAULT_SLICE__GLOBAL_DYNAMICS)));
		}
	
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkEffect(Effect effect) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		ComponentInstanceEventReferenceExpression failureEvent = effect.getFailureEvent();
		if (failureEvent != null) {
			Port port = failureEvent.getPort();
			Event event = failureEvent.getEvent();
			
			StatechartDefinition statechart = StatechartModelDerivedFeatures.getContainingStatechart(port);
			if (statechart != null) {
				List<Entry<Port, Event>> triggeringInputEvents = StatechartModelDerivedFeatures.getTriggeringInputEvents(statechart);
				if (!triggeringInputEvents.contains(new SimpleEntry<Port, Event>(port, event))) {
					validationResultMessages.add(new ValidationResultMessage(
							ValidationResult.ERROR,
								"The referenced event is not used in the model",
									new ReferenceInfo(FeiModelPackage.Literals.EFFECT__FAILURE_EVENT)));
				}
			}
		}
		
		return validationResultMessages;
	}
			
	public Collection<ValidationResultMessage> checkFaultTransitions(FaultTransition faultTransition) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		FaultTransitionTrigger trigger = faultTransition.getTrigger();
		if (trigger != null) {
			FaultMode triggerFaultMode = trigger.getFaultMode();
			FaultEvent triggerEvent = trigger.getEvent();
			
			FaultModeStateReference source = faultTransition.getSource();
			FaultMode sourceFaultMode = source.getFaultMode();
			FaultModeState sourceState = source.getState();
			
			FaultModeStateReference target = faultTransition.getTarget();
			FaultMode targetFaultMode = target.getFaultMode();
			FaultModeState targetState = target.getState();
			
			if (triggerEvent == FaultEvent.FAILURE) {
				if (!(targetFaultMode == triggerFaultMode && targetState == FaultModeState.FAULTY)) {
					validationResultMessages.add(new ValidationResultMessage(
						ValidationResult.WARNING,
							"In case of a failure trigger, the target fault mode should be the trigger fault mode in a faulty state",
								new ReferenceInfo(FeiModelPackage.Literals.FAULT_TRANSITION__TRIGGER)));
				}
			}
			else if (triggerEvent == FaultEvent.SELF_FIX) {
				if (!(sourceFaultMode == triggerFaultMode && sourceState == FaultModeState.FAULTY)) {
					validationResultMessages.add(new ValidationResultMessage(
						ValidationResult.WARNING,
							"In case of a self-fix trigger, the source fault mode should be the trigger fault mode",
								new ReferenceInfo(FeiModelPackage.Literals.FAULT_TRANSITION__TRIGGER)));
				}
				if (triggerFaultMode.getLocalDynamics() != LocalDynamics.TRANSIENT) {
					validationResultMessages.add(new ValidationResultMessage(
						ValidationResult.ERROR,
							"The trigger fault mode does not have transient local dynamics so a self-fix event cannot occur",
								new ReferenceInfo(FeiModelPackage.Literals.FAULT_TRANSITION__TRIGGER)));
				}
			}
			
			if (triggerFaultMode != targetFaultMode && triggerFaultMode != sourceFaultMode) {
				validationResultMessages.add(new ValidationResultMessage(
					ValidationResult.WARNING,
						"The trigger fault mode should either be the source or target trigger fault mode",
							new ReferenceInfo(FeiModelPackage.Literals.FAULT_TRANSITION__TRIGGER)));
			}
			
			Expression guard = faultTransition.getGuard();
			if (guard != null && !typeDeterminator.isBoolean(guard)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"This guard is not a boolean expression",
						new ReferenceInfo(FeiModelPackage.Literals.FAULT_TRANSITION__GUARD)));
			}
		}
	
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkCommonCauseModes(CommonCauseMode commonCauseMode) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		FaultSlice faultSlice = commonCauseMode.getFaultSlice();
		FaultMode faultMode = commonCauseMode.getFaultMode();
		
		FaultSlice containingFaultSlice = ecoreUtil.getContainerOfType(faultMode, FaultSlice.class);
		if (faultSlice != containingFaultSlice) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"This fault mode is not defined in the referenced fault slice",
					new ReferenceInfo(FeiModelPackage.Literals.COMMON_CAUSE_MODE__FAULT_MODE)));
		}
		
		CommonCauseRange range = commonCauseMode.getRange();
		if (range != null) {
			Expression lowerBound = range.getLowerBound();
			Expression higherBound = range.getHigherBound();
			if (lowerBound != null) {
				if (!ExpressionModelDerivedFeatures.isEvaluable(lowerBound)) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"This value is not an evaluable integer value",
							new ReferenceInfo(FeiModelPackage.Literals.COMMON_CAUSE_RANGE__LOWER_BOUND, range)));
				}
			}
			if (higherBound != null) {
				if (!ExpressionModelDerivedFeatures.isEvaluable(higherBound)) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"This value is not an evaluable integer value",
							new ReferenceInfo(FeiModelPackage.Literals.COMMON_CAUSE_RANGE__HIGHER_BOUND, range)));
				}
			}
			if (lowerBound != null && higherBound != null) {
				int lower = expressionEvaluator.evaluate(lowerBound);
				int higher = expressionEvaluator.evaluate(higherBound);
				
				if (0 > lower) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"This value is not a positive integer value",
							new ReferenceInfo(FeiModelPackage.Literals.COMMON_CAUSE_RANGE__LOWER_BOUND, range)));
				}
				if (0 > higher) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"This value is not a positive integer value",
							new ReferenceInfo(FeiModelPackage.Literals.COMMON_CAUSE_RANGE__HIGHER_BOUND, range)));
				}
				if (lower > higher) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"The higher bound must be greater than or equal to the lower bound",
							new ReferenceInfo(FeiModelPackage.Literals.COMMON_CAUSE_RANGE__HIGHER_BOUND, range)));
				}
			}
		}
		
		if (faultSlice != containingFaultSlice) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"This fault mode is not defined in the referenced fault slice",
					new ReferenceInfo(FeiModelPackage.Literals.COMMON_CAUSE_MODE__FAULT_MODE)));
		}
		
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkCommonCauseProbabilities(CommonCauseProbability commonCauseProbability) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		Expression value = commonCauseProbability.getValue();
		if (value != null) {
			if (!ExpressionModelDerivedFeatures.isEvaluable(value)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"This value is not evaluable",
						new ReferenceInfo(FeiModelPackage.Literals.COMMON_CAUSE_PROBABILITY__VALUE)));
			}
			else {
				double evaluatedValue = expressionEvaluator.evaluateDecimal(value);
				if (evaluatedValue < 0 || 1 < evaluatedValue) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
						"A decimal value between 0 and 1 is expected",
							new ReferenceInfo(FeiModelPackage.Literals.COMMON_CAUSE_PROBABILITY__VALUE)));
				}
			}
		}

		return validationResultMessages;
	}
	
	
}
