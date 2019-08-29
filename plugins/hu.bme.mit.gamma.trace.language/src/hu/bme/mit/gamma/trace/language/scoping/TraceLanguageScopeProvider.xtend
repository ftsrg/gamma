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
import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.State
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.StatechartModelPackage
import hu.bme.mit.gamma.statechart.model.composite.AbstractSynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.Component
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.InstanceSchedule
import hu.bme.mit.gamma.trace.model.InstanceState
import hu.bme.mit.gamma.trace.model.InstanceStateConfiguration
import hu.bme.mit.gamma.trace.model.InstanceVariableState
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.model.TracePackage
import java.util.Collection
import java.util.Collections
import java.util.HashSet
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.scoping.Scopes

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
class TraceLanguageScopeProvider extends AbstractTraceLanguageScopeProvider {

	override getScope(EObject context, EReference reference) {
		if (context instanceof ExecutionTrace && reference == TracePackage.Literals.EXECUTION_TRACE__COMPONENT) {
			val executionTrace = context as ExecutionTrace
			if (executionTrace.import !== null) {
				return Scopes.scopeFor(executionTrace.import.components)
			}
		}
		if (context instanceof RaiseEventAct && reference == StatechartModelPackage.Literals.RAISE_EVENT_ACTION__PORT) {
			val executionTrace = (context as RaiseEventAct).eContainer.eContainer as ExecutionTrace
			val component = executionTrace.component
			val ports = new HashSet<Port>(component.ports)
			if (component instanceof AsynchronousAdapter) {
				// Wrappers need the wrapped components as well
				ports += component.wrappedComponent.type.ports
			}
			return Scopes.scopeFor(ports)
		}
		if (context instanceof RaiseEventAct && reference == StatechartModelPackage.Literals.RAISE_EVENT_ACTION__EVENT) {
			val raiseEventAct = context as RaiseEventAct
			if (raiseEventAct.port !== null) {
				val port = raiseEventAct.port
				try {
					val events = port.interfaceRealization.interface.events.map[it.event]
					return Scopes.scopeFor(events);
				} catch (NullPointerException e) {
					// For some reason dirty editor errors emerge
					return super.getScope(context, reference)
				}
			}
		}	
		if (context instanceof InstanceSchedule && reference == TracePackage.Literals.INSTANCE_SCHEDULE__SCHEDULED_INSTANCE) {
			val executionTrace = (context as InstanceSchedule).eContainer.eContainer as ExecutionTrace
			val component = executionTrace.component
			if (component instanceof AsynchronousCompositeComponent) {
				val instances = component.asynchronousInstances
				return Scopes.scopeFor(instances)
			}
		}
		if (reference == TracePackage.Literals.INSTANCE_STATE__INSTANCE) {
			val executionTrace = if (context instanceof InstanceState) {
				context.eContainer.eContainer as ExecutionTrace
			}
			else if (context instanceof Step) {
				context.eContainer as ExecutionTrace
			}
			val component = executionTrace.component
			val simpleSyncInstances = component.synchronousInstances
			return Scopes.scopeFor(simpleSyncInstances)	
		}
		if (context instanceof InstanceStateConfiguration && reference == TracePackage.Literals.INSTANCE_STATE_CONFIGURATION__STATE) {
			val instanceState = context as InstanceStateConfiguration
			val instance = instanceState.instance
			val instanceType = instance.type
			val executionTrace = context.eContainer.eContainer as ExecutionTrace
			val states = new HashSet<State>
			if (instanceType === null) {
				val component = executionTrace.component
				val simpleSyncInstances = component.synchronousInstances
				for (simpleInstance : simpleSyncInstances) {
					states += EcoreUtil2.getAllContentsOfType(simpleInstance.type, State)
				}
			}
			else {
				states += EcoreUtil2.getAllContentsOfType(instanceType, State)
			}
			return Scopes.scopeFor(states)
		}
		if (context instanceof InstanceVariableState && reference == ExpressionModelPackage.Literals.REFERENCE_EXPRESSION__DECLARATION) {
			val instanceVariableState = context as InstanceVariableState
			val instance = instanceVariableState.instance
			val instanceType = instance.type
			if (instanceType === null) {
				return Scopes.scopeFor(#[])
			}
			val variables = EcoreUtil2.getAllContentsOfType(instanceType, VariableDeclaration)
			return Scopes.scopeFor(variables)
		}
		super.getScope(context, reference)
	}

	private def Collection<AsynchronousComponentInstance> getAsynchronousInstances(AsynchronousCompositeComponent component) {
		val simpleInstances = component.components.filter[it.type instanceof AsynchronousAdapter].toSet
		for (compositeComponent : component.components.filter[it.type instanceof AsynchronousCompositeComponent]) {
			simpleInstances += (compositeComponent.type as AsynchronousCompositeComponent).asynchronousInstances
		}
		return simpleInstances
	}
	
	private def dispatch Collection<SynchronousComponentInstance> getSynchronousInstances(Component component) {
		return Collections.emptySet
	}
	
	private def dispatch Collection<SynchronousComponentInstance> getSynchronousInstances(AsynchronousCompositeComponent component) {
		val simpleInstances = new HashSet<SynchronousComponentInstance>
		for (instance : component.components) {
			simpleInstances += instance.type.synchronousInstances
		}
		return simpleInstances
	}
	
	private def dispatch Collection<SynchronousComponentInstance> getSynchronousInstances(AsynchronousAdapter component) {
		return #[component.wrappedComponent]
	}
	
	private def dispatch Collection<SynchronousComponentInstance> getSynchronousInstances(AbstractSynchronousCompositeComponent component) {
		val simpleInstances = component.components.filter[it.type instanceof StatechartDefinition].toSet
		for (instance : component.components.filter[it.type instanceof AbstractSynchronousCompositeComponent]) {
			simpleInstances += instance.type.synchronousInstances
		}
		return simpleInstances
	}

}
