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
package hu.bme.mit.gamma.trace.language.scoping

import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceElementReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.composite.CompositeModelPackage
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelPackage
import hu.bme.mit.gamma.statechart.interface_.PortReferenceExpression
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
		val executionTrace = ecoreUtil.getSelfOrContainerOfType(context, ExecutionTrace)
		val component = executionTrace?.component
		if (context instanceof ExecutionTrace && reference == TraceModelPackage.Literals.EXECUTION_TRACE__COMPONENT) {
			if (executionTrace.import !== null) {
				return Scopes.scopeFor(executionTrace.import.components)
			}
		}
		if ((context instanceof RaiseEventAct && reference == StatechartModelPackage.Literals.RAISE_EVENT_ACTION__PORT) ||
			(context instanceof EventParameterReferenceExpression && reference == InterfaceModelPackage.Literals.PORT_REFERENCE_EXPRESSION__PORT)) {
			return Scopes.scopeFor(component.allPorts)
		}
		if ((context instanceof RaiseEventAct && reference == StatechartModelPackage.Literals.RAISE_EVENT_ACTION__EVENT) ||
				(context instanceof EventParameterReferenceExpression && reference == InterfaceModelPackage.Literals.EVENT_REFERENCE_EXPRESSION__EVENT)) {
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
		if (context instanceof EventParameterReferenceExpression &&
				reference == ExpressionModelPackage.Literals.PARAMETER_REFERENCE_EXPRESSION__PARAMETER_DECLARATION) {
			val paramReference = context as EventParameterReferenceExpression
			return Scopes.scopeFor(paramReference.event.parameterDeclarations)
		}
		if (reference == CompositeModelPackage.Literals.COMPONENT_INSTANCE_REFERENCE_EXPRESSION__COMPONENT_INSTANCE) {
			if (context instanceof ComponentInstanceReferenceExpression) {
				val parentInstance = context.parent
				if (parentInstance === null) {
					val instances = component.allInstances // Both atomic and chain references are supported
					return Scopes.scopeFor(instances)
				}
				val instanceType = parentInstance.componentInstance.derivedType
				val instances = instanceType.instances
				return Scopes.scopeFor(instances)
			}
			val instances = component.instances // Only first level
			return Scopes.scopeFor(instances)
		}
		if (context instanceof ComponentInstanceStateReferenceExpression) {
			val instance = context.instance
			val instanceType = (instance === null) ? component : instance.lastInstance.derivedType
			if (reference == StatechartModelPackage.Literals.STATE_REFERENCE_EXPRESSION__REGION) {
				val regions = newLinkedHashSet
				if (instanceType === null) {
					val simpleSyncInstances = component.allSimpleInstances
					for (simpleInstance : simpleSyncInstances) {
						regions += ecoreUtil.getAllContentsOfType(simpleInstance.derivedType, Region)
					}
				}
				else {
					regions += ecoreUtil.getAllContentsOfType(instanceType, Region)
				}
				return Scopes.scopeFor(regions)
			}
			if (reference == StatechartModelPackage.Literals.STATE_REFERENCE_EXPRESSION__STATE) {
				val region = context.region
				if (region !== null) {
					return Scopes.scopeFor(region.states) 
				}
				else {
					val states = newLinkedHashSet
					if (instanceType === null) {
						val simpleSyncInstances = component.allSimpleInstances
						for (simpleInstance : simpleSyncInstances) {
							states += ecoreUtil.getAllContentsOfType(simpleInstance.derivedType, State)
						}
					}
					else {
						states += ecoreUtil.getAllContentsOfType(instanceType, State)
					}
					return Scopes.scopeFor(states)
				}
			}
		}
		
		val instanceVariableState = ecoreUtil.getSelfOrContainerOfType(context, ComponentInstanceElementReferenceExpression)
		val instance = instanceVariableState?.instance
		val instanceType = (instance === null) ? component : instance.lastInstance.derivedType
		
		if (reference == InterfaceModelPackage.Literals.PORT_REFERENCE_EXPRESSION__PORT) {
			val ports = instanceType.allPorts
			return Scopes.scopeFor(ports)
		}
		if (reference == ExpressionModelPackage.Literals.VARIABLE_REFERENCE_EXPRESSION__VARIABLE_DECLARATION) {
			if (instanceType === null) {
				return IScope.NULLSCOPE
			}
			
			val variables = newLinkedHashSet
			if (context instanceof PortReferenceExpression) {
				val port = context.port
				variables += port.allVariableDeclarations
			}
			else {
				variables += ecoreUtil.getAllContentsOfType(instanceType, VariableDeclaration)
				variables += instanceType.allInterfaceVariableDeclarations
				variables.removeIf[it.local]
			}
			
			return Scopes.scopeFor(variables)
		}
		if (reference == ExpressionModelPackage.Literals.ABSTRACT_DIRECT_REFERENCE_EXPRESSION__DECLARATION) {
			val declarations = <Declaration>newLinkedHashSet
			
			declarations += executionTrace.variableDeclarations
			declarations += executionTrace.component
					.containingPackage.constantDeclarations
			
			return Scopes.scopeFor(declarations)
		}
		
		super.getScope(context, reference)
	}

}