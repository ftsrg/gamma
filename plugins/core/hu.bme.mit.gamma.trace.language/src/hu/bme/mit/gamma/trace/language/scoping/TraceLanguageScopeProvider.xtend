/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.trace.language.scoping

import hu.bme.mit.gamma.expression.model.ExpressionModelPackage
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.AsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.CompositeModelPackage
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartModelPackage
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.InstanceSchedule
import hu.bme.mit.gamma.trace.model.InstanceStateConfiguration
import hu.bme.mit.gamma.trace.model.InstanceVariableState
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.TraceModelPackage
import hu.bme.mit.gamma.trace.util.TraceUtil
import java.util.HashSet
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.Scopes

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
		if (context instanceof RaiseEventAct && reference == StatechartModelPackage.Literals.RAISE_EVENT_ACTION__PORT) {
			val executionTrace = ecoreUtil.getContainerOfType(context, ExecutionTrace)
			val component = executionTrace.component
			return Scopes.scopeFor(component.allPorts)
		}
		if (context instanceof RaiseEventAct && reference == StatechartModelPackage.Literals.RAISE_EVENT_ACTION__EVENT) {
			val raiseEventAct = context as RaiseEventAct
			if (raiseEventAct.port !== null) {
				val port = raiseEventAct.port
				try {
					val events = port.allEvents
					return Scopes.scopeFor(events)
				} catch (NullPointerException e) {
					// For some reason dirty editor errors emerge
					return super.getScope(context, reference)
				}
			}
		}	
		if (context instanceof InstanceSchedule &&
				reference == TraceModelPackage.Literals.INSTANCE_SCHEDULE__SCHEDULED_INSTANCE) {
			val executionTrace = ecoreUtil.getContainerOfType(context, ExecutionTrace)
			val component = executionTrace.component
			if (component instanceof AsynchronousCompositeComponent) {
				val instances = component.allAsynchronousSimpleInstances
				return Scopes.scopeFor(instances)
			}
		}
		if (reference == CompositeModelPackage.Literals.COMPONENT_INSTANCE_REFERENCE__COMPONENT_INSTANCE) {
			val executionTrace = ecoreUtil.getContainerOfType(context, ExecutionTrace)
			val component = executionTrace.component
			val instances = component.allInstances // Both atomic and chain references are supported
			return Scopes.scopeFor(instances)
		}
		if (context instanceof InstanceStateConfiguration &&
				reference == TraceModelPackage.Literals.INSTANCE_STATE_CONFIGURATION__STATE) {
			val instanceState = context as InstanceStateConfiguration
			val instance = instanceState.instance
			val instanceType = instance.lastInstance.derivedType
			val executionTrace = ecoreUtil.getContainerOfType(context, ExecutionTrace)
			val states = new HashSet<State>
			if (instanceType === null) {
				val component = executionTrace.component
				val simpleSyncInstances = component.allSimpleInstances
				for (simpleInstance : simpleSyncInstances) {
					states += EcoreUtil2.getAllContentsOfType(simpleInstance.type, State)
				}
			}
			else {
				states += EcoreUtil2.getAllContentsOfType(instanceType, State)
			}
			return Scopes.scopeFor(states)
		}
		if (context instanceof InstanceVariableState &&
				reference == ExpressionModelPackage.Literals.DIRECT_REFERENCE_EXPRESSION__DECLARATION) {
			val instanceVariableState = context as InstanceVariableState
			val instance = instanceVariableState.instance
			val instanceType = instance.lastInstance.derivedType
			if (instanceType === null) {
				return IScope.NULLSCOPE
			}
			val variables = EcoreUtil2.getAllContentsOfType(instanceType, VariableDeclaration)
			return Scopes.scopeFor(variables)
		}
		super.getScope(context, reference)
	}

}