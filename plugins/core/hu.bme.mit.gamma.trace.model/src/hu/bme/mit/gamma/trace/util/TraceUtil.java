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
package hu.bme.mit.gamma.trace.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.util.EcoreUtil;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.BinaryExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression;
import hu.bme.mit.gamma.statechart.contract.ScenarioAllowedWaitAnnotation;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.interface_.TimeUnit;
import hu.bme.mit.gamma.statechart.util.StatechartUtil;
import hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures;
import hu.bme.mit.gamma.trace.model.Act;
import hu.bme.mit.gamma.trace.model.Cycle;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.trace.model.ExecutionTraceAllowedWaitingAnnotation;
import hu.bme.mit.gamma.trace.model.ExecutionTraceAnnotation;
import hu.bme.mit.gamma.trace.model.ExecutionTraceCommentAnnotation;
import hu.bme.mit.gamma.trace.model.RaiseEventAct;
import hu.bme.mit.gamma.trace.model.Reset;
import hu.bme.mit.gamma.trace.model.Schedule;
import hu.bme.mit.gamma.trace.model.Step;
import hu.bme.mit.gamma.trace.model.TimeUnitAnnotation;
import hu.bme.mit.gamma.trace.model.TraceModelFactory;

public class TraceUtil extends StatechartUtil {
	// Singleton
	public static final TraceUtil INSTANCE = new TraceUtil();
	protected TraceUtil() {}
	//
	
	public static final AssertSorter assertSorter = new AssertSorter();
	protected final TraceModelFactory factory = TraceModelFactory.eINSTANCE;
	
	// Extending super methods
	
	@Override
	public Collection<TypeDeclaration> getTypeDeclarations(EObject context) {
		ExecutionTrace trace = ecoreUtil.getSelfOrContainerOfType(context, ExecutionTrace.class);
		Package _package = trace.getImport();
		Set<TypeDeclaration> typedDeclarations = StatechartModelDerivedFeatures
				.getReferencedTypedDeclarations(_package);
		return typedDeclarations;
	}
	
	public ExecutionTrace createTrace(Component component) {
		ExecutionTrace trace = factory.createExecutionTrace();
		
		String componentName = component.getName();
		
		trace.setImport(
				StatechartModelDerivedFeatures.getContainingPackage(component));
		trace.setComponent(component);
		trace.setName(componentName + "Trace");
		
		addTimeUnitAnnotation(trace);
		
		List<Expression> arguments = StatechartModelDerivedFeatures.getTopComponentArguments(
				trace.getImport());
		trace.getArguments().addAll(
				ecoreUtil.clone(arguments));
		
		return trace;
	}
	
	public void addTimeUnitAnnotation(ExecutionTrace trace) {
		Component component = trace.getComponent();
		Package _package = StatechartModelDerivedFeatures.getContainingPackage(component);
		TimeUnit smallestTimeUnit = StatechartModelDerivedFeatures.getSmallestTimeUnit(_package);
		
		TimeUnitAnnotation timeUnitAnnotation = factory.createTimeUnitAnnotation();
		timeUnitAnnotation.setTimeUnit(smallestTimeUnit);
		
		trace.getAnnotations()
				.add(timeUnitAnnotation);
	}
	
	public Step addStep(ExecutionTrace trace) {
		Step step = factory.createStep();
		
		trace.getSteps()
				.add(step);
		
		return step;
	}
	
	public void sortInstanceStates(ExecutionTrace executionTrace) {
		sortInstanceStates(
				executionTrace.getSteps());
		Cycle cycle = executionTrace.getCycle();
		if (cycle != null) {
			sortInstanceStates(
					cycle.getSteps());
		}
	}
	
	public void sortInstanceStates(List<Step> steps) {
		steps.forEach(it -> sortInstanceStates(it));
	}
	
	public void sortInstanceStates(Step step) {
		List<Expression> instanceStates = step.getAsserts();
		List<Expression> list = new ArrayList<Expression>(instanceStates); // Needed to avoid the 'no duplicates' constraint
		list.sort(assertSorter);
		instanceStates.clear();
		instanceStates.addAll(list);
	}
	
	// Comments
	
	public void addComment(ExecutionTrace trace, String comment) {
		ExecutionTraceCommentAnnotation annotation = null;
		if (TraceModelDerivedFeatures.hasComment(trace)) {
			annotation = TraceModelDerivedFeatures.getCommentAnnotation(trace);
			annotation.setComment(annotation.getComment() + comment);
		}
		else {
			List<ExecutionTraceAnnotation> annotations = trace.getAnnotations();
			annotation = factory.createExecutionTraceCommentAnnotation();
			annotations.add(annotation);
			annotation.setComment(comment);
		}
	}
	
	// Extend
	
	public void extend(ExecutionTrace original, ExecutionTrace extension) {
		List<Step> steps = original.getSteps();
		steps.addAll(
				extension.getSteps());
	}
	
	// Overwriting
	
	public boolean isOverWritten(RaiseEventAct lhs, RaiseEventAct rhs) {
		return lhs.getPort() == rhs.getPort() && lhs.getEvent() == rhs.getEvent();
	}
	
	// Trace coverage
	
	public Collection<ExecutionTrace> removeCoveredExecutionTraces(List<ExecutionTrace> traces) {
		Collection<ExecutionTrace> removedTraces = new ArrayList<ExecutionTrace>(traces);
		
		for (int i = 0; i < traces.size() - 1; ++i) {
			ExecutionTrace lhs = traces.get(i);
			boolean isLhsDeleted = false;
			for (int j = i + 1; j < traces.size() && !isLhsDeleted; ++j) {
				ExecutionTrace rhs = traces.get(j);
				if (isCovered(rhs, lhs)) {
					traces.remove(j);
					--j;
				}
				else if (isCovered(lhs, rhs)) {
					// Else is important, as it is possible that both cover the other one
					isLhsDeleted = true;
					traces.remove(i);
					--i;
				}
			}
		}
		
		removedTraces.removeAll(traces);
		
		return removedTraces;
	}
	
	public void removeCoveredSteps(ExecutionTrace trace) {
		List<List<Step>> separateTracesByReset = identifySeparateTracesByReset(trace);
		removeCoveredStepLists(separateTracesByReset);
	}
	
	public List<List<Step>> identifySeparateTracesByReset(ExecutionTrace trace) {
		List<List<Step>> stepsList = new ArrayList<List<Step>>();
		List<Step> actualSteps = null;
		for (Step step : trace.getSteps()) {
			List<Act> actions = step.getActions();
			if (actions.stream().anyMatch(it -> it instanceof Reset)) {
				if (actualSteps != null) {
					stepsList.add(actualSteps);
				}
				actualSteps = new ArrayList<Step>();
			}
			actualSteps.add(step);
		}
		// Add the last list of steps after the last reset
		if (!stepsList.contains(actualSteps)) {
			stepsList.add(actualSteps);
		}
		return stepsList;
	}
	
	public void removeCoveredStepLists(List<List<Step>> traces) {
		for (int i = 0; i < traces.size() - 1; ++i) {
			List<Step> lhs = traces.get(i);
			boolean isLhsDeleted = false;
			for (int j = i + 1; j < traces.size() && !isLhsDeleted; ++j) {
				List<Step> rhs = traces.get(j);
				if (isCovered(rhs, lhs)) {
					traces.remove(j);
					EcoreUtil.removeAll(rhs);
					--j;
				}
				else if (isCovered(lhs, rhs)) {
					// Else is important, as it is possible that both cover the other one
					isLhsDeleted = true;
					traces.remove(i);
					EcoreUtil.removeAll(lhs);
					--i;
				}
			}
		}
	}
	
	public boolean isCovered(ExecutionTrace covered, List<ExecutionTrace> covering) {
		for (ExecutionTrace coveringTrace : covering) {
			if (isCovered(covered, coveringTrace)) {
				return true;
			}
		}
		return false;
	}
	
	public boolean isCovered(ExecutionTrace covered, ExecutionTrace covering) {
		List<Step> coveredTrace = covered.getSteps();
		List<List<Step>> coveringTraces = identifySeparateTracesByReset(covering);
		for (List<Step> coveringTrace : coveringTraces) {
			if (isCovered(coveredTrace, coveringTrace)) {
				return true;
			}
		}
		return false;
	}
	
	public boolean isCovered(List<Step> covered, List<Step> covering) {
		if (covering.size() < covered.size()) {
			return false;
		}
		for (int i = 0; i < covered.size(); i++) {
			if (!isCovered(covered.get(i), covering.get(i))) {
				return false;
			}
		}
		return true;
	}
	
	public boolean isCovered(Step covered, Step covering) {
		// Only input actions are covered - we expect deterministic behavior
		List<Act> coveredActions = covered.getActions();
		List<Act> coveringActions = covering.getActions();
		if (coveredActions.size() == coveringActions.size()) {
			// Works if there is at most one schedule in the action lists
			// Otherwise, the actions should be split along schedules...
			for (Act act : coveredActions) {
				boolean hasEqual = coveringActions.stream().anyMatch(
						it -> ecoreUtil.helperEquals(act, it));
				if (!hasEqual) {
					return false;
				}
			}
			return true;
		}
		return false;
	}
	
	public void setupExecutionTrace(ExecutionTrace trace, List<Step> steps,
			String name, Component component, Package imports, ScenarioAllowedWaitAnnotation annotation) {
		if (name != null) {
			trace.setName(name);
		}
		if (steps != null) {
			trace.getSteps().clear();
			trace.getSteps().addAll(steps);
		}
		if (component != null) {
			trace.setComponent(component);
		}
		if (imports != null) {
			trace.setImport(imports);
		}
		if (annotation!= null) {
			ExecutionTraceAllowedWaitingAnnotation newAnnotation =
					factory.createExecutionTraceAllowedWaitingAnnotation();
			newAnnotation.setLowerLimit(
					ecoreUtil.clone(annotation.getLowerLimit()));
			newAnnotation.setUpperLimit(
					ecoreUtil.clone(annotation.getUpperLimit()));
			trace.getAnnotations().add(newAnnotation);
		}
	}
	
	public void createCycleIfPossible(ExecutionTrace trace) {
		List<Step> steps = trace.getSteps();
		
		if (steps.size() < 2) {
			return;
		}
		
		Step last = javaUtil.getLastElement(steps);
		Step lastClone = ecoreUtil.clone(last);
		lastClone.getActions().clear();
		for (Step step : steps) {
			Step stepClone = ecoreUtil.clone(step);
			stepClone.getActions().clear();
			if (ecoreUtil.helperEquals(stepClone, lastClone) && step != last) {
				int i = ecoreUtil.getIndex(step) + 1;
				Cycle cycle = factory.createCycle();
				trace.setCycle(cycle);
				List<Step> cycleSteps = cycle.getSteps();
				while (i < steps.size()) {
					Step nextStep = steps.get(i);
					cycleSteps.add(nextStep);
				}
				
				// Removing potential step duplications
				Step previous = null;
				Iterator<Step> iterator = cycleSteps.iterator();
				while (iterator.hasNext()) {
					Step actual = iterator.next();
					if (ecoreUtil.helperEquals(previous, actual)) {
						iterator.remove();
					}
					previous = actual;
				}
				
				return;
			}
		}
	}

	public boolean isCoveredByStates(ExecutionTrace covered, ExecutionTrace covering) {
		List<Step> coveredTrace = covered.getSteps();
		List<Step> coveringTrace = covering.getSteps();
		return isCoveredByStates(coveredTrace, coveringTrace);
	}

	public boolean isCoveredByStates(List<Step> covered, List<Step> covering) {
		if (covering.size() < covered.size()) {
			return false;
		}
		for (int i = 0; i < covered.size(); i++) {
			if (!isCoveredByState(covered.get(i), covering.get(i))) {
				return false;
			}
		}
		return true;
	}

	public boolean isCoveredByState(Step covered, Step covering) {
		List<Expression> coveredAsserts = covered.getAsserts();
		List<Expression> coveringAsserts = covering.getAsserts();
		ComponentInstanceStateReferenceExpression stateCovered = null;
		ComponentInstanceStateReferenceExpression stateCovering = null;
		
		for (Expression asser : coveringAsserts) {
			if (asser instanceof ComponentInstanceStateReferenceExpression exp) {
				stateCovering = exp;
			}
		}
		for (Expression asser : coveredAsserts) {
			if (asser instanceof ComponentInstanceStateReferenceExpression exp) {
				stateCovered = exp;
			}
		}
		if (stateCovered == null || stateCovering == null) {
			return false;
		}
		return ecoreUtil.helperEquals(stateCovered.getState(), stateCovering.getState());
	}
	
	public void clearAsserts(ExecutionTrace trace, Class<?> clazz) {
		for (Step step : trace.getSteps()) {
			List<Expression> asserts = step.getAsserts();
			asserts.removeIf(it -> clazz.isInstance(it));
			for (Expression expression :
						new ArrayList<Expression>(asserts)) {
				if (expression instanceof BinaryExpression binary) {
					if (ExpressionModelDerivedFeatures.hasOperandOfType(binary, clazz)) {
						ecoreUtil.remove(expression);
					}
				}
			}
		}
	}

	public void removeScheduleAndReset(Step step) {
		List<Act> actions = step.getActions();
		actions.removeIf(it -> it instanceof Schedule);
		actions.removeIf(it -> it instanceof Reset);
	}
	
}