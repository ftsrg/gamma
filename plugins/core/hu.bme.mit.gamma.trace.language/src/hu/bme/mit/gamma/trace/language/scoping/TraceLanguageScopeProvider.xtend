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

import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.AsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartModelPackage
import hu.bme.mit.gamma.trace.model.Assert
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.InstanceSchedule
import hu.bme.mit.gamma.trace.model.InstanceStateConfiguration
import hu.bme.mit.gamma.trace.model.InstanceVariableState
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.TraceModelPackage
import java.util.HashSet
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.scoping.Scopes

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
class TraceLanguageScopeProvider extends AbstractTraceLanguageScopeProvider {

	override getScope(EObject context, EReference reference) {
		if (context instanceof ExecutionTrace && reference == TraceModelPackage.Literals.EXECUTION_TRACE__COMPONENT) {
			val executionTrace = context as ExecutionTrace
			if (executionTrace.import !== null) {
				return Scopes.scopeFor(executionTrace.import.components)
			}
		}
		if (context instanceof RaiseEventAct && reference == StatechartModelPackage.Literals.RAISE_EVENT_ACTION__PORT) {
			val executionTrace = EcoreUtil2.getRootContainer(context, true) as ExecutionTrace
			val component = executionTrace.component
			val ports = new HashSet<Port>(component.allPorts)
			return Scopes.scopeFor(ports)
		}
		if (context instanceof RaiseEventAct && reference == StatechartModelPackage.Literals.RAISE_EVENT_ACTION__EVENT) {
			val raiseEventAct = context as RaiseEventAct
			if (raiseEventAct.port !== null) {
				val port = raiseEventAct.port
				try {
					val events = port.allEvents
					return Scopes.scopeFor(events);
				} catch (NullPointerException e) {
					// For some reason dirty editor errors emerge
					return super.getScope(context, reference)
				}
			}
		}	
		if (context instanceof InstanceSchedule && reference == TraceModelPackage.Literals.INSTANCE_SCHEDULE__SCHEDULED_INSTANCE) {
			val executionTrace = EcoreUtil2.getRootContainer(context, true) as ExecutionTrace
			val component = executionTrace.component
			if (component instanceof AsynchronousCompositeComponent) {
				val instances = component.allAsynchronousSimpleInstances
				return Scopes.scopeFor(instances)
			}
		}
		if (reference == TraceModelPackage.Literals.INSTANCE_STATE__INSTANCE) {
			val executionTrace = EcoreUtil2.getRootContainer(context, true) as ExecutionTrace
			val component = executionTrace.component
			val simpleSyncInstances = component.allSimpleInstances
			return Scopes.scopeFor(simpleSyncInstances)	
		}
		if (context instanceof InstanceStateConfiguration &&
				reference == TraceModelPackage.Literals.INSTANCE_STATE_CONFIGURATION__STATE) {
			val instanceState = context as InstanceStateConfiguration
			val instance = instanceState.instance
			val instanceType = instance.type
			val executionTrace = EcoreUtil2.getRootContainer(context, true) as ExecutionTrace
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
		if (context instanceof InstanceVariableState && reference == ExpressionModelPackage.Literals.DIRECT_REFERENCE_EXPRESSION__DECLARATION) {
			val instanceVariableState = context as InstanceVariableState
			val instance = instanceVariableState.instance
			val instanceType = instance.type
			if (instanceType === null) {
				return Scopes.scopeFor(#[])
			}
			val variables = EcoreUtil2.getAllContentsOfType(instanceType, VariableDeclaration)
			return Scopes.scopeFor(variables)
		}
		if (context instanceof EnumerationLiteralExpression) {
			var Type enumerationDefinition
			val parent = ecoreUtil.getContainerOfType(context, Assert) // First assert container
			switch parent {
				InstanceVariableState: {
					enumerationDefinition = parent.declaration.type
				}
				RaiseEventAct: {
					val parameterDeclarations = parent.event.parameterDeclarations
					if (!parameterDeclarations.empty) {
						enumerationDefinition = parameterDeclarations.head.type
					}
				}
				default:
					throw new IllegalArgumentException("Not known enumeration use!")
			}
			if (enumerationDefinition instanceof TypeReference) {
				val typeDeclaration = enumerationDefinition.reference
				val typeDefinition = typeDeclaration.type
				if (typeDefinition instanceof EnumerationTypeDefinition) {
					return Scopes.scopeFor(typeDefinition.literals)
				}
			}
			if (enumerationDefinition instanceof EnumerationTypeDefinition) {
				return Scopes.scopeFor(enumerationDefinition.literals)
			}
		}
		super.getScope(context, reference)
	}

}
