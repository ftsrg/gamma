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
package hu.bme.mit.gamma.trace.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;

import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.util.EcoreUtil;
import org.eclipse.emf.ecore.util.EcoreUtil.EqualityHelper;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.util.ExpressionUtil;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Interface;
import hu.bme.mit.gamma.statechart.interface_.InterfaceRealization;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures;
import hu.bme.mit.gamma.trace.model.Act;
import hu.bme.mit.gamma.trace.model.Assert;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.trace.model.InstanceStateConfiguration;
import hu.bme.mit.gamma.trace.model.InstanceVariableState;
import hu.bme.mit.gamma.trace.model.RaiseEventAct;
import hu.bme.mit.gamma.trace.model.Reset;
import hu.bme.mit.gamma.trace.model.Step;

public class TraceUtil extends ExpressionUtil {
	// Singleton
	public static final TraceUtil INSTANCE = new TraceUtil();
	protected TraceUtil() {}
	//
	
	public static final AssertSorter assertSorter = new AssertSorter();
	
	// Extending super methods
	
	@Override
	public Collection<TypeDeclaration> getTypeDeclarations(EObject context) {
		Collection<TypeDeclaration> types = new HashSet<TypeDeclaration>();
		ExecutionTrace trace = ecoreUtil.getSelfOrContainerOfType(context, ExecutionTrace.class);
		Package _package = trace.getImport();
		// Explicit imports
		for (Package importedPackage : StatechartModelDerivedFeatures.getAllImports(_package)) {
			types.addAll(importedPackage.getTypeDeclarations());
		}
		// Native references in the case the unfolded packages
		Collection<TypeReference> references = new ArrayList<TypeReference>();
		references.addAll(ecoreUtil.getAllContentsOfType(_package, TypeReference.class));
		// Events and parameters
		for (InterfaceRealization realization :
				ecoreUtil.getAllContentsOfType(_package, InterfaceRealization.class)) {
			Interface _interface = realization.getInterface();
			references.addAll(ecoreUtil.getAllContentsOfType(_interface, TypeReference.class));
		}
		// Collecting the type declarations
		for (TypeReference reference : references) {
			TypeDeclaration typeDeclaration = reference.getReference();
			types.add(typeDeclaration);
			Type type = ExpressionModelDerivedFeatures.getTypeDefinition(typeDeclaration.getType());
			if (type instanceof RecordTypeDefinition) {
				RecordTypeDefinition recordType = (RecordTypeDefinition) type;
				Collection<TypeDeclaration> containedTypeDeclarations =
						TraceModelDerivedFeatures.getAllTypeDeclarations(recordType);
				types.addAll(containedTypeDeclarations);
			}
		}
		return types;
	}
	
	// Step sorter
	
	public static class AssertSorter implements Comparator<Assert> {

		@Override
		public int compare(Assert lhsAssert, Assert rhsAssert) {
			Assert lhs = TraceModelDerivedFeatures.getLowermostAssert(lhsAssert);
			Assert rhs = TraceModelDerivedFeatures.getLowermostAssert(rhsAssert);
			if (lhs instanceof RaiseEventAct) {
				if (rhs instanceof RaiseEventAct) {
					return 0;
				}
				return -1;
			}
			if (rhs instanceof RaiseEventAct) {
				return 1;
			}
			if (lhs instanceof InstanceStateConfiguration && rhs instanceof InstanceStateConfiguration) {
				// Two instance states: first - instance name, second - state level
				InstanceStateConfiguration lhsInstanceStateConfiguration = (InstanceStateConfiguration) lhs;
				InstanceStateConfiguration rhsInstanceStateConfiguration = (InstanceStateConfiguration) rhs;
				ComponentInstance lhsInstance = StatechartModelDerivedFeatures.getLastInstance(
						lhsInstanceStateConfiguration.getInstance());
				ComponentInstance rhsInstance = StatechartModelDerivedFeatures.getLastInstance(
						rhsInstanceStateConfiguration.getInstance());
				int nameCompare = lhsInstance.getName().compareTo(rhsInstance.getName());
				if (nameCompare != 0) {
					return nameCompare;
				}
				Integer lhsLevel = StatechartModelDerivedFeatures.getLevel(lhsInstanceStateConfiguration.getState());
				Integer rhsLevel = StatechartModelDerivedFeatures.getLevel(rhsInstanceStateConfiguration.getState());
				return lhsLevel.compareTo(rhsLevel);
			}
			else if (lhs instanceof InstanceVariableState && rhs instanceof InstanceVariableState) {
				// Two instance variable: name
				InstanceVariableState lhsInstanceVariableState = (InstanceVariableState) lhs;
				InstanceVariableState rhsInstanceVariableState = (InstanceVariableState) rhs;
				ComponentInstance lhsInstance = StatechartModelDerivedFeatures.getLastInstance(
						lhsInstanceVariableState.getInstance());
				ComponentInstance rhsInstance = StatechartModelDerivedFeatures.getLastInstance(
						rhsInstanceVariableState.getInstance());
				String lhsName = lhsInstance.getName() +
						lhsInstanceVariableState.getDeclaration().getName();
				String rhsName = rhsInstance.getName() +
						rhsInstanceVariableState.getDeclaration().getName();
				return lhsName.compareTo(rhsName);
			}
			else if (lhs instanceof InstanceStateConfiguration && rhs instanceof InstanceVariableState) {
				// First - instance state, second - instance variable
				return -1;
			}
			else if (lhs instanceof InstanceVariableState && rhs instanceof InstanceStateConfiguration) {
				// First - instance state, second - instance variable
				return 1;
			}
			return 0;
		}
		
	}
	
	public void sortInstanceStates(ExecutionTrace executionTrace) {
		sortInstanceStates(executionTrace.getSteps());
	}
	
	public void sortInstanceStates(List<Step> steps) {
		steps.forEach(it -> sortInstanceStates(it));
	}
	
	public void sortInstanceStates(Step step) {
		List<Assert> instanceStates = step.getAsserts();
		List<Assert> list = new ArrayList<Assert>(instanceStates); // Needed to avoid the 'no duplicates' constraint
		list.sort(assertSorter);
		instanceStates.clear();
		instanceStates.addAll(list);
	}
	
	// Extend
	
	public void extend(ExecutionTrace original, ExecutionTrace extension) {
		original.getSteps().addAll(extension.getSteps());
	}
	
	// Overwriting
	
	public boolean isOverWritten(RaiseEventAct lhs, RaiseEventAct rhs) {
		return lhs.getPort() == rhs.getPort() && lhs.getEvent() == rhs.getEvent();
	}
	
	// Trace coverage
	
	public void removeCoveredExecutionTraces(List<ExecutionTrace> traces) {
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
	}
	
	public void removeCoveredSteps(ExecutionTrace trace) {
		List<List<Step>> separateTracesByReset = identifySeparateTracesByReset(trace);
		removeCoveredStepLists(separateTracesByReset);
	}
	
	public List<List<Step>> identifySeparateTracesByReset(ExecutionTrace trace) {
		List<List<Step>> stepsList = new ArrayList<List<Step>>();
		List<Step> actualSteps = null;
		for (Step step : trace.getSteps()) {
			if (step.getActions().stream().anyMatch(it -> it instanceof Reset)) {
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
		// Only input actions are covered
		EList<Act> coveredActions = covered.getActions();
		EList<Act> coveringActions = covering.getActions();
		if (coveredActions.size() == coveringActions.size()) {
			for (Act act : coveredActions) {
				boolean hasEqual = coveringActions.stream().anyMatch(it -> equalsTo(act, it));
				if (!hasEqual) {
					return false;
				}
			}
			return true;
		}
		return false;
	}
	
	public void setupExecutionTrace(ExecutionTrace trace, List<Step> steps,
			String name, Component component, Package imports) {
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
	}

	public boolean isCoveredByStates(ExecutionTrace covered, ExecutionTrace covering) {
		List<Step> coveredTrace = covered.getSteps();
		List<Step> coveringTrace = covering.getSteps();
		if (isCoveredByStates(coveredTrace, coveringTrace)) {
			return true;
		}
		return false;
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
		EList<Assert> coveredAsserts = covered.getAsserts();
		EList<Assert> coveringAsserts = covering.getAsserts();
		InstanceStateConfiguration stateCovered = null;
		InstanceStateConfiguration stateCovering = null;
		for (Assert asser : coveringAsserts) {
			if (asser instanceof InstanceStateConfiguration) {
				stateCovering = (InstanceStateConfiguration) asser;
			}
		}
		for (Assert asser : coveredAsserts) {
			if (asser instanceof InstanceStateConfiguration) {
				stateCovered = (InstanceStateConfiguration) asser;
			}
		}
		if (stateCovered == null || stateCovering == null) {
			return false;
		}
		if (ecoreUtil.helperEquals(stateCovered.getState(), stateCovering.getState())) {
			return true;
		}
		return false;
	}
	
	public void clearAsserts(ExecutionTrace trace, Class<?> clazz) {
		for (Step step : trace.getSteps()) {
			step.getAsserts().removeIf(it -> clazz.isInstance(it));
		}
	}
	
	public boolean equalsTo(EObject lhs, EObject rhs) {
		EqualityHelper helper = new EqualityHelper();
		return helper.equals(lhs, rhs);
	}
	
}