/********************************************************************************
 * Copyright (c) 2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.trace.util;

import java.util.Comparator;
import java.util.List;

import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.OpaqueExpression;
import hu.bme.mit.gamma.expression.model.VariableReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceElementReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.interface_.PortReferenceExpression;
import hu.bme.mit.gamma.statechart.statechart.Region;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.statechart.StateReferenceExpression;
import hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures;
import hu.bme.mit.gamma.trace.model.RaiseEventAct;

public class AssertSorter implements Comparator<Expression> {

	@Override
	public int compare(Expression lhsAssert, Expression rhsAssert) {
		Expression lhs = TraceModelDerivedFeatures.getPrimaryAssert(lhsAssert);
		Expression rhs = TraceModelDerivedFeatures.getPrimaryAssert(rhsAssert);
		if (lhs instanceof OpaqueExpression opaqueLhs && TraceModelDerivedFeatures.isTransitionExecutionExpression(opaqueLhs)) {
			if (rhs instanceof OpaqueExpression opaqueRhs && TraceModelDerivedFeatures.isTransitionExecutionExpression(opaqueRhs)) {
				return opaqueLhs.getExpression().compareTo(opaqueRhs.getExpression());
			}
			return -1;
		}
		if (lhs instanceof RaiseEventAct lhsAct) {
			if (rhs instanceof RaiseEventAct rhsAct) {
				String lhsName = lhsAct.getPort().getName() + lhsAct.getEvent().getName();
				String rhsName = rhsAct.getPort().getName() + rhsAct.getEvent().getName();
				return lhsName.compareTo(rhsName);
			}
			return -1;
		}
		if (rhs instanceof RaiseEventAct) {
			return 1;
		}
		if (lhs instanceof ComponentInstanceElementReferenceExpression lhsInstanceReference &&
				rhs instanceof ComponentInstanceElementReferenceExpression rhsInstanceReference) {
			// Two instance states: first - instance name, second - state level
			List<ComponentInstance> lhsInstances = StatechartModelDerivedFeatures
					.getComponentInstanceChain(lhsInstanceReference.getInstance());
			List<ComponentInstance> rhsInstances = StatechartModelDerivedFeatures
					.getComponentInstanceChain(rhsInstanceReference.getInstance());
			String lhsName = lhsInstances.stream().map(it -> it.getName()).reduce("", (a, b) -> a + b);
			String rhsName = rhsInstances.stream().map(it -> it.getName()).reduce("", (a, b) -> a + b);
			int nameCompare = lhsName.compareTo(rhsName);
			if (nameCompare != 0) {
				return nameCompare;
			}
			if (lhs instanceof StateReferenceExpression lhsInstanceStateConfiguration &&
					rhs instanceof StateReferenceExpression rhsInstanceStateConfiguration) { 
				State lhsState = lhsInstanceStateConfiguration.getState();
				Integer lhsLevel = StatechartModelDerivedFeatures.getLevel(lhsState);
				State rhsState = rhsInstanceStateConfiguration.getState();
				Integer rhsLevel = StatechartModelDerivedFeatures.getLevel(rhsState);
				int regionCompare = lhsLevel.compareTo(rhsLevel);
				if (regionCompare != 0) {
					return regionCompare;
				}
				Region lhsRegion = StatechartModelDerivedFeatures.getParentRegion(lhsState);
				Region rhsRegion = StatechartModelDerivedFeatures.getParentRegion(rhsState);
				return lhsRegion.getName().compareTo(
						rhsRegion.getName());
			}
			else {
				if (lhs instanceof VariableReferenceExpression lhsVariableReference &&
						rhs instanceof VariableReferenceExpression rhsVariableReference &&
						lhs.eClass().equals(rhs.eClass())) {
					// Two instance variable: name
					Declaration lhsVariable = lhsVariableReference.getDeclaration();
					Declaration rhsVariable = rhsVariableReference.getDeclaration();
					if (lhs instanceof PortReferenceExpression lhsPortReference &&
							rhs instanceof PortReferenceExpression rhsPortReference) {
						Port lhsPort = lhsPortReference.getPort();
						Port rhsPort = rhsPortReference.getPort();

						lhsName += lhsPort.getName();
						rhsName += rhsPort.getName();
					}
					lhsName += lhsVariable.getName();
					rhsName += rhsVariable.getName();
					
					return lhsName.compareTo(rhsName);
				}
			}
		}
		if (lhs instanceof StateReferenceExpression && rhs instanceof VariableReferenceExpression) {
			return -1;
		}
		if (lhs instanceof VariableReferenceExpression && rhs instanceof StateReferenceExpression) {
			return 1;
		}
		if (lhs instanceof PortReferenceExpression && rhs instanceof ComponentInstanceVariableReferenceExpression) {
			return -1;
		}
		if (lhs instanceof ComponentInstanceVariableReferenceExpression && rhs instanceof PortReferenceExpression) {
			return 1;
		}
		
		return 0;
	}
}

