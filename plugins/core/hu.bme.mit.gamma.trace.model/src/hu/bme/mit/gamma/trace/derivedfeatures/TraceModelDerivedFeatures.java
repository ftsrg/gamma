/********************************************************************************
 * Copyright (c) 2018-2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.trace.derivedfeatures;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.ArgumentedElement;
import hu.bme.mit.gamma.expression.model.BinaryExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.NotExpression;
import hu.bme.mit.gamma.expression.model.OpaqueExpression;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.UnaryExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceElementReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression;
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.util.ExpressionSerializer;
import hu.bme.mit.gamma.trace.model.Act;
import hu.bme.mit.gamma.trace.model.Cycle;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.trace.model.ExecutionTraceAllowedWaitingAnnotation;
import hu.bme.mit.gamma.trace.model.ExecutionTraceAnnotation;
import hu.bme.mit.gamma.trace.model.ExecutionTraceCommentAnnotation;
import hu.bme.mit.gamma.trace.model.NegativeTestAnnotation;
import hu.bme.mit.gamma.trace.model.RaiseEventAct;
import hu.bme.mit.gamma.trace.model.Step;
import hu.bme.mit.gamma.trace.model.TimeElapse;
import hu.bme.mit.gamma.trace.model.TimeUnitAnnotation;

public class TraceModelDerivedFeatures extends ExpressionModelDerivedFeatures {
	//
	public static final String TRANSITION_EXEC_PREFIX = "Transition executed: ";
	//
	protected static final ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE;
	//
	
	public static boolean isUnfolded(ExecutionTrace trace) {
		Component component = trace.getComponent();
		return StatechartModelDerivedFeatures.isUnfolded(component);
	}
	
	public static List<ParameterDeclaration> getParameterDeclarations(ArgumentedElement element) {
		if (element instanceof RaiseEventAction raiseEventAction) {
			Event event = raiseEventAction.getEvent();
			return event.getParameterDeclarations();
		}
		if (element instanceof ExecutionTrace trace) {
			Component component = trace.getComponent();
			return component.getParameterDeclarations();
		}
		throw new IllegalArgumentException("Not supported element: " + element);
	}
	
	public static ExecutionTrace getContainingExecutionTrace(EObject object) {
		ExecutionTrace trace = ecoreUtil.getContainerOfType(object, ExecutionTrace.class);
		return trace;
	}
	
	public static boolean isTopmostAssert(Expression expression) {
		EObject container = expression.eContainer();
		return !(container instanceof Expression);
	}
	
	public static Step getContainingStep(EObject object) {
		Step step = ecoreUtil.getContainerOfType(object, Step.class);
		return step;
	}
	
	public static Step getPreviousStep(Step step) {
		return (Step) ecoreUtil.getPrevious(step);
	}
	
	// Annotations
	
	public static boolean hasAssertInFirstStep(ExecutionTrace trace) {
		List<Step> steps = trace.getSteps();
		Step firstStep = steps.get(0);
		return !firstStep.getAsserts().isEmpty();
	}
	
	public static boolean hasAllowedWaitingAnnotation(ExecutionTrace trace) {
		return hasAnnotation(trace, ExecutionTraceAllowedWaitingAnnotation.class);
	}
	
	public static boolean hasAnnotation(ExecutionTrace trace,
			Class<? extends ExecutionTraceAnnotation> annotation) {
		return trace.getAnnotations().stream().anyMatch(it -> annotation.isInstance(it));
	}
	
	public static <T extends ExecutionTraceAnnotation> T getAnnotation(
			ExecutionTrace trace, Class<T> annotation) {
		List<ExecutionTraceAnnotation> annotations = trace.getAnnotations();
		List<T> filteredAnnotations = javaUtil.filterIntoList(annotations, annotation);
		T filteredAnnotation = filteredAnnotations.get(0);
		return filteredAnnotation;
	}
	
	public static ExecutionTraceAllowedWaitingAnnotation getAllowedWaitingAnnotation(
				ExecutionTrace trace) {
		List<ExecutionTraceAnnotation> annotations = trace.getAnnotations();
		List<ExecutionTraceAllowedWaitingAnnotation> waitingAnnotations = javaUtil.filterIntoList(annotations,
				ExecutionTraceAllowedWaitingAnnotation.class);
		ExecutionTraceAllowedWaitingAnnotation annotation = waitingAnnotations.get(0);
		return annotation;
	}
	
	public static TimeUnitAnnotation getTimeUnitAnnotation(ExecutionTrace trace) {
		List<ExecutionTraceAnnotation> annotations = trace.getAnnotations();
		List<TimeUnitAnnotation> timeUnitAnnotations = javaUtil.filterIntoList(annotations, TimeUnitAnnotation.class);
		TimeUnitAnnotation timeUnitAnnotation = timeUnitAnnotations.get(0);
		return timeUnitAnnotation;
	}
	
	public static boolean isNegativeTest(ExecutionTrace trace) {
		return hasAnnotation(trace, NegativeTestAnnotation.class);
	}
	
	public static boolean hasComment(ExecutionTrace trace) {
		return hasAnnotation(trace, ExecutionTraceCommentAnnotation.class);
	}
	
	public static ExecutionTraceCommentAnnotation getCommentAnnotation(ExecutionTrace trace) {
		return getAnnotation(trace, ExecutionTraceCommentAnnotation.class);
	}
	
	public static String getComment(ExecutionTrace trace) {
		ExecutionTraceCommentAnnotation annotation = getCommentAnnotation(trace);
		return annotation.getComment();
	}
	
	public static Component getComponent(EObject object) {
		ExecutionTrace trace = ecoreUtil.getSelfOrContainerOfType(object, ExecutionTrace.class);
		Component component = trace.getComponent();
		return component;
	}
	
	//
	
	public static Expression getSchedulingTime(ExecutionTrace trace) {
		List<Step> steps = trace.getSteps();
		List<Step> notFirstSteps = new ArrayList<Step>(steps);
		
		if (notFirstSteps.size() <= 1) {
			return null;
		}
		
		notFirstSteps.remove(0);
		TimeElapse schedulingTimeElapse = null;
		for (Step step : notFirstSteps) {
			List<Act> actions = step.getActions();
			List<TimeElapse> timeElapses = javaUtil.filterIntoList(actions, TimeElapse.class);
			if (timeElapses.isEmpty()) {
				return null;
			}
			
			TimeElapse timeElapse = javaUtil.getOnlyElement(timeElapses);
			if (schedulingTimeElapse == null) {
				schedulingTimeElapse = timeElapse;
			}
			else {
				Expression generalElapsedTime = schedulingTimeElapse.getElapsedTime();
				Expression actualElapsedTime = timeElapse.getElapsedTime();
				if (evaluator.evaluateInteger(generalElapsedTime) !=
						evaluator.evaluateInteger(actualElapsedTime)) {
					return null;
				}
			}
		}
		
		Expression generalElapsedTime = schedulingTimeElapse.getElapsedTime();
		return ecoreUtil.clone(generalElapsedTime);
	}
	
	public static boolean isTransitionExecutionExpression(OpaqueExpression expression) {
		String TRANSITION_EXEC_PREFIX = "Transition executed: ";
		String text = expression.getExpression();
		return text.startsWith(TRANSITION_EXEC_PREFIX);
	}
	
	public static Expression getLowermostAssert(Expression assertion) {
		if (assertion instanceof NotExpression negatedAssert) {
			return getLowermostAssert(negatedAssert.getOperand());
		}
		return assertion;
	}
	
	public static Expression getPrimaryAssert(Expression assertion) {
		List<ComponentInstanceVariableReferenceExpression> variableReferences =
				ecoreUtil.getSelfAndAllContentsOfType(assertion, ComponentInstanceVariableReferenceExpression.class);
		if (variableReferences.size() == 1) {
			return variableReferences.get(0);
		}
		
		List<ComponentInstanceStateReferenceExpression> stateReferences =
				ecoreUtil.getSelfAndAllContentsOfType(assertion, ComponentInstanceStateReferenceExpression.class);
		if (stateReferences.size() == 1) {
			return stateReferences.get(0);
		}
		
		List<RaiseEventAct> raiseReferences =
				ecoreUtil.getSelfAndAllContentsOfType(assertion, RaiseEventAct.class);
		if (raiseReferences.size() == 1) {
			return raiseReferences.get(0);
		}
		
		return assertion;
	}
	
	public static ComponentInstanceReferenceExpression getInstanceReference(Expression expression) {
		if (expression instanceof ComponentInstanceElementReferenceExpression element) {
			return element.getInstance();
		}
		else if (expression instanceof UnaryExpression unaryExpression) {
			Expression operand = unaryExpression.getOperand();
			return getInstanceReference(operand);
		}
		else if (expression instanceof BinaryExpression binaryExpression) {
			Expression leftOperand = binaryExpression.getLeftOperand();
			try {
				return getInstanceReference(leftOperand);
			} catch (IllegalArgumentException e) {
				Expression rightOperand = binaryExpression.getRightOperand();
				return getInstanceReference(rightOperand);
			}
//			ComponentInstanceElementReferenceExpression elementReference =
//					getOperandOfType(binaryExpression, ComponentInstanceElementReferenceExpression.class);
//			return getInstanceReference(elementReference);
		}
		throw new IllegalArgumentException("Not known instance state: " + expression);
	}

	
	// Views
	
	public static List<Step> getAllSteps(ExecutionTrace trace) {
		List<Step> steps = new ArrayList<Step>(
				trace.getSteps());
		
		Cycle cycle = trace.getCycle();
		if (cycle != null) {
			steps.addAll(
					cycle.getSteps());
		}
		
		return steps;
	}
	
	public static Step getLastStep(ExecutionTrace trace) {
		List<Step> steps = trace.getSteps();
		int size = steps.size();
		return steps.get(size - 1); 
	}

	public static List<RaiseEventAct> getOutEvents(Step step) {
		List<RaiseEventAct> outEvents = new ArrayList<RaiseEventAct>();
		for (Expression assertion : step.getAsserts()) {
			if (assertion instanceof RaiseEventAct act) {
				outEvents.add(act);
			}
		}
		return outEvents;
	}
	
	public static List<EventParameterReferenceExpression> getEventParameterReferences(Step step) {
		return ecoreUtil.getAllContentsOfType(step, EventParameterReferenceExpression.class);
	}

	public static List<ComponentInstanceStateReferenceExpression> getInstanceStateConfigurations(Step step) {
		List<ComponentInstanceStateReferenceExpression> states = new ArrayList<ComponentInstanceStateReferenceExpression>();
		for (Expression assertion : step.getAsserts()) {
			if (assertion instanceof ComponentInstanceStateReferenceExpression exp) {
				states.add(exp);
			}
		}
		return states;
	}
	
	public static Map<SynchronousComponentInstance, Set<State>> groupInstanceStateConfigurations(Step step) {
		Map<SynchronousComponentInstance, Set<State>> instanceStates =
				new HashMap<SynchronousComponentInstance, Set<State>>();
		List<ComponentInstanceStateReferenceExpression> stateConfigurations = getInstanceStateConfigurations(step);
		for (ComponentInstanceStateReferenceExpression stateConfiguration : stateConfigurations) {
			SynchronousComponentInstance instance = (SynchronousComponentInstance)
					StatechartModelDerivedFeatures.getLastInstance(stateConfiguration.getInstance());
			State state = stateConfiguration.getState();
			if (!instanceStates.containsKey(instance)) {
				instanceStates.put(instance, new HashSet<State>());
			}
			Set<State> states = instanceStates.get(instance);
			states.add(state);
		}
		return instanceStates;
	}
	
	public static List<ComponentInstanceVariableReferenceExpression> getInstanceVariableStates(Step step) {
		return ecoreUtil.getAllContentsOfType(step, ComponentInstanceVariableReferenceExpression.class);
	}
	
	public static List<ComponentInstanceVariableReferenceExpression> getUniqueInstanceVariableStates(Step step) {
		List<ComponentInstanceVariableReferenceExpression> instanceVariableStates = getInstanceVariableStates(step);
		
		Set<Expression> topExpressions = new HashSet<Expression>();
		Iterator<ComponentInstanceVariableReferenceExpression> iterator = instanceVariableStates.iterator();
		while (iterator.hasNext()) {
			ComponentInstanceVariableReferenceExpression next = iterator.next();
			Expression top = ecoreUtil.getSelfOrLastContainerOfType(next, Expression.class);
			if (topExpressions.contains(top)) {
				iterator.remove();
			}
			else {
				topExpressions.add(top);
			}
		}
		return instanceVariableStates;
	}
	
	public static List<ComponentInstanceReferenceExpression> getFirstComponentInstanceReferenceExpressions(ExecutionTrace trace) {
		return ecoreUtil.getAllContentsOfType(trace, ComponentInstanceReferenceExpression.class)
				.stream()
				.filter(it -> !(it.eContainer() instanceof ComponentInstanceReferenceExpression))
				.toList();
	}
	
	//
	
	public static boolean areAssertsEquivalent(ExecutionTrace lhs, ExecutionTrace rhs) {
		return areAssertsEquivalent(lhs, rhs, true, true);
	}
	
	public static boolean areAssertsEquivalent(ExecutionTrace lhs, ExecutionTrace rhs,
				boolean considerInstanceNames, boolean considerInjectedVariables) {
		List<Step> lhsSteps = lhs.getSteps();
		List<Step> rhsSteps = rhs.getSteps();
		
		return areAssertsEquivalent(lhsSteps, rhsSteps, considerInstanceNames, considerInjectedVariables);
	}
	
	public static boolean areAssertsEquivalent(List<Step> lhs, List<Step> rhs,
				boolean considerInstanceNames, boolean considerInjectedVariables) {
		int size = lhs.size();
		if (size != rhs.size()) {
			return false;
		}
		
		for (int i = 0; i < size; ++i) {
			Step lhsStep = lhs.get(i);
			Step rhsStep = rhs.get(i);
			
			if (!areAssertsEquivalent(lhsStep, rhsStep,
					considerInstanceNames, considerInjectedVariables)) {
				return false;
			}
		}
		
		return true;
	}
	
	public static boolean areAssertsEquivalent(Step lhs, Step rhs,
				boolean considerInstanceNames, boolean considerInjectedVariables) {
		List<Expression> lhsAsserts = new ArrayList<Expression>(lhs.getAsserts());
		List<Expression> rhsAsserts = new ArrayList<Expression>(rhs.getAsserts());
		
		if (!considerInjectedVariables) {
			lhsAsserts.removeIf(it -> ecoreUtil.getSelfAndAllContentsOfType(it,	ComponentInstanceVariableReferenceExpression.class)
					.stream().anyMatch(ref -> isInjected(ref.getVariableDeclaration())));
			rhsAsserts.removeIf(it -> ecoreUtil.getSelfAndAllContentsOfType(it,	ComponentInstanceVariableReferenceExpression.class)
					.stream().anyMatch(ref -> isInjected(ref.getVariableDeclaration())));
		}
		
		int size = lhsAsserts.size();
		if (size != rhsAsserts.size()) {
			return false;
		}
		
		for (int i = 0; i < size; ++i) {
			Expression lhsAssert = lhsAsserts.get(i);
			Expression rhsAssert = rhsAsserts.get(i);
			
			if (!considerInstanceNames) {
				lhsAssert = ecoreUtil.clone(lhsAssert);
				rhsAssert = ecoreUtil.clone(rhsAssert);
				
				List<ComponentInstanceElementReferenceExpression> references = new ArrayList<ComponentInstanceElementReferenceExpression>(
						ecoreUtil.getSelfAndAllContentsOfType(lhsAssert, ComponentInstanceElementReferenceExpression.class));
				references.addAll(
						ecoreUtil.getSelfAndAllContentsOfType(rhsAssert, ComponentInstanceElementReferenceExpression.class));
				
				for (ComponentInstanceElementReferenceExpression reference : references) {
					reference.setInstance(null);
				}
			}
			
			String lhsSerial = expressionSerializer.serialize(lhsAssert);
			String rhsSerial = expressionSerializer.serialize(rhsAssert);
			
			if (!lhsSerial.equals(rhsSerial)) {
				return false;
			}
		}
		
		return true;
	}
	
}
