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
package hu.bme.mit.gamma.property.language.scoping

import hu.bme.mit.gamma.property.model.ComponentInstanceEventParameterReference
import hu.bme.mit.gamma.property.model.ComponentInstanceEventReference
import hu.bme.mit.gamma.property.model.ComponentInstanceStateConfigurationReference
import hu.bme.mit.gamma.property.model.ComponentInstanceStateExpression
import hu.bme.mit.gamma.property.model.PropertyModelPackage
import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
import hu.bme.mit.gamma.statechart.composite.CompositeModelPackage
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.scoping.Scopes

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class PropertyLanguageScopeProvider extends AbstractPropertyLanguageScopeProvider {
	
	override getScope(EObject context, EReference reference) {
		if (context instanceof PropertyPackage) {
			if (reference == PropertyModelPackage.Literals.PROPERTY_PACKAGE__COMPONENT) {
				val imports = context.import
				if (!imports.empty) {
					return Scopes.scopeFor(imports.map[it.components].flatten)
				}
			}
		}
		val root = ecoreUtil.getSelfOrContainerOfType(context, PropertyPackage)
		val component = root.component
		if (reference == CompositeModelPackage.Literals.COMPONENT_INSTANCE_REFERENCE__COMPONENT_INSTANCE) {
			val instanceContainer = ecoreUtil.getSelfOrContainerOfType(
					context, ComponentInstanceReference)
			val parent = instanceContainer?.parent
			val instances = (parent === null) ?	component.allInstances :
				parent.componentInstance.instances
			return Scopes.scopeFor(instances)
		}
		if (context instanceof ComponentInstanceStateExpression) {
			// Base
			var instance = context.instance.lastInstance
			val statechart = instance.derivedType
			if (statechart !== null) {
				if (statechart instanceof StatechartDefinition) {
					// State
					if (reference == PropertyModelPackage.Literals.COMPONENT_INSTANCE_STATE_CONFIGURATION_REFERENCE__REGION) {
						return Scopes.scopeFor(statechart.allRegions)
					}
					if (reference == PropertyModelPackage.Literals.COMPONENT_INSTANCE_STATE_CONFIGURATION_REFERENCE__STATE) {
						val stateConfigurationReference = context as ComponentInstanceStateConfigurationReference
						val region = stateConfigurationReference.region
						return Scopes.scopeFor(region.states)
					}
					// Variable
					if (reference == PropertyModelPackage.Literals.COMPONENT_INSTANCE_VARIABLE_REFERENCE__VARIABLE) {
						return Scopes.scopeFor(statechart.variableDeclarations)
					}
					// Port
					if (reference == PropertyModelPackage.Literals.COMPONENT_INSTANCE_EVENT_REFERENCE__PORT ||
							reference == PropertyModelPackage.Literals.COMPONENT_INSTANCE_EVENT_PARAMETER_REFERENCE__PORT) {
						return Scopes.scopeFor(statechart.ports)
					}
					// Event
					if (reference == PropertyModelPackage.Literals.COMPONENT_INSTANCE_EVENT_REFERENCE__EVENT ||
							reference == PropertyModelPackage.Literals.COMPONENT_INSTANCE_EVENT_PARAMETER_REFERENCE__EVENT) {
						if (context instanceof ComponentInstanceEventReference) {
							val port = context.port
							if (!port.eIsProxy) {
								return Scopes.scopeFor(port.outputEvents)
							}
						}
						if (context instanceof ComponentInstanceEventParameterReference) {
							val port = context.port
							if (!port.eIsProxy) {
								return Scopes.scopeFor(port.outputEvents)
							}
						}
					}
					// Parameter
					if (reference == PropertyModelPackage.Literals.COMPONENT_INSTANCE_EVENT_PARAMETER_REFERENCE__PARAMETER) {
						val eventParameterReference = context as ComponentInstanceEventParameterReference
						return Scopes.scopeFor(eventParameterReference.event.parameterDeclarations)
					}
				}
			}
		}
		return super.getScope(context, reference);
	}
	
}
