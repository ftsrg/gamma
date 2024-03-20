/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.trace.language.scoping

import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.statechart.composite.CompositeModelPackage
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelPackage
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartModelPackage
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.TraceModelPackage
import hu.bme.mit.gamma.trace.util.TraceUtil
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.Scopes

import static extension hu.bme.mit.gamma.action.derivedfeatures.ActionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class TraceLanguageScopeProvider extends AbstractTraceLanguageScopeProvider {

	new() {
		super.util = TraceUtil.INSTANCE
	}

	override getScope(EObject context, EReference reference) {
		if (context instanceof ExecutionTrace && reference == TraceModelPackage.Literals.EXECUTION_TRACE__COMPONENT) {
			val executionTrace = context as ExecutionTrace
			if (executionTrace.import !== null) {
				return Scopes.scopeFor(executionTrace.import.components)
			}
		}
		if ((context instanceof RaiseEventAct && reference == StatechartModelPackage.Literals.RAISE_EVENT_ACTION__PORT) ||
			(context instanceof EventParameterReferenceExpression && reference == InterfaceModelPackage.Literals.EVENT_PARAMETER_REFERENCE_EXPRESSION__PORT)) {
			val executionTrace = ecoreUtil.getContainerOfType(context, ExecutionTrace)
			val component = executionTrace.component
			return Scopes.scopeFor(component.allPorts)
		}
		if ((context instanceof RaiseEventAct && reference == StatechartModelPackage.Literals.RAISE_EVENT_ACTION__EVENT) ||
				(context instanceof EventParameterReferenceExpression && reference == InterfaceModelPackage.Literals.EVENT_PARAMETER_REFERENCE_EXPRESSION__EVENT)) {
			val port = if (context instanceof RaiseEventAct) {
				context.port
			} else if (context instanceof EventParameterReferenceExpression) {
				context.port
			}
			if (port !== null) {
				try {
					val events = port.allEvents
					return Scopes.scopeFor(events)
				} catch (NullPointerException e) {
					// For some reason dirty editor errors emerge
					return super.getScope(context, reference)
				}
			}
		}
		if (context instanceof EventParameterReferenceExpression && reference == InterfaceModelPackage.Literals.EVENT_PARAMETER_REFERENCE_EXPRESSION__PARAMETER) {
			val paramReference = context as EventParameterReferenceExpression
			return Scopes.scopeFor(paramReference.event.parameterDeclarations)
		}
		if (reference == CompositeModelPackage.Literals.COMPONENT_INSTANCE_REFERENCE_EXPRESSION__COMPONENT_INSTANCE) {
			val executionTrace = ecoreUtil.getContainerOfType(context, ExecutionTrace)
			val component = executionTrace.component
			if (!(context instanceof ComponentInstanceReferenceExpression)) {
				val instances = component.instances // Only first level
				return Scopes.scopeFor(instances)
			}
			val instances = component.allInstances // Both atomic and chain references are supported
			return Scopes.scopeFor(instances)
		}
		if (context instanceof ComponentInstanceStateReferenceExpression) {
			val instance = context.instance
			val executionTrace = ecoreUtil.getContainerOfType(context, ExecutionTrace)
			val component = executionTrace.component
			val instanceType = (instance === null) ? component : instance.lastInstance.derivedType
			if (reference == CompositeModelPackage.Literals.COMPONENT_INSTANCE_STATE_REFERENCE_EXPRESSION__REGION) {
				val regions = newLinkedHashSet
				if (instanceType === null) {
					val simpleSyncInstances = component.allSimpleInstances
					for (simpleInstance : simpleSyncInstances) {
						regions += ecoreUtil.getAllContentsOfType(simpleInstance.type, Region)
					}
				}
				else {
					regions += ecoreUtil.getAllContentsOfType(instanceType, Region)
				}
				return Scopes.scopeFor(regions)
			}
			if (reference == CompositeModelPackage.Literals.COMPONENT_INSTANCE_STATE_REFERENCE_EXPRESSION__STATE) {
				val region = context.region
				if (region !== null) {
					return Scopes.scopeFor(region.states) 
				}
				else {
					val states = newLinkedHashSet
					if (instanceType === null) {
						val simpleSyncInstances = component.allSimpleInstances
						for (simpleInstance : simpleSyncInstances) {
							states += ecoreUtil.getAllContentsOfType(simpleInstance.type, State)
						}
					}
					else {
						states += ecoreUtil.getAllContentsOfType(instanceType, State)
					}
					return Scopes.scopeFor(states)
				}
			}
		}
		if (reference == CompositeModelPackage.Literals.
				COMPONENT_INSTANCE_VARIABLE_REFERENCE_EXPRESSION__VARIABLE_DECLARATION) {
			val instanceVariableState = ecoreUtil.getSelfOrContainerOfType(
					context, ComponentInstanceVariableReferenceExpression)
			val instance = instanceVariableState.instance
			val executionTrace = ecoreUtil.getContainerOfType(context, ExecutionTrace)
			val component = executionTrace.component
			val instanceType = (instance === null) ? component : instance.lastInstance.derivedType
			if (instanceType === null) {
				return IScope.NULLSCOPE
			}
			val variables = ecoreUtil.getAllContentsOfType(instanceType, VariableDeclaration)
			variables.removeIf[it.local]
			return Scopes.scopeFor(variables)
		}
		if (reference == ExpressionModelPackage.Literals.DIRECT_REFERENCE_EXPRESSION__DECLARATION) {
			val executionTrace = ecoreUtil.getContainerOfType(context, ExecutionTrace)
			val declarations = <Declaration>newLinkedHashSet
			
			declarations += executionTrace.variableDeclarations
			declarations += executionTrace.component
					.containingPackage.constantDeclarations
			
			return Scopes.scopeFor(declarations)
		}
		super.getScope(context, reference)
	}

}