/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.property.language.scoping

import hu.bme.mit.gamma.property.model.PropertyModelPackage
import hu.bme.mit.gamma.property.model.PropertyPackage
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.scoping.Scopes

class PropertyLanguageScopeProvider extends AbstractPropertyLanguageScopeProvider {
	
	override getScope(EObject context, EReference reference) {
		if (context instanceof PropertyPackage) {
			if (reference == PropertyModelPackage.Literals.PROPERTY_PACKAGE__COMPONENT) {
				val imports = context.imports
				if (!imports.empty) {
					return Scopes.scopeFor(imports.map[it.components].flatten)
				}
			}
		}
		val root = ecoreUtil.getSelfOrContainerOfType(context, PropertyPackage)
		val packages = root.imports
		val component = root.component
		
		val scope = context.handleTypeDeclarationAndComponentInstanceElementReferences(reference, packages, component)
		if (scope !== null) {
			return scope
		}
		
		return super.getScope(context, reference);
	}
	
//	protected def handleTypeDeclarationAndComponentInstanceElementReferences(EObject context, EReference reference,
//			Collection<? extends Package> packages, Component component) {
//		val typeScope = context.handleTypeDeclarationReferences(reference, packages)
//		if (typeScope !== null) {
//			return typeScope
//		}
//		
//		val componentInstanceElementScope = context.handleComponentInstanceElementReferences(reference, component)
//		if (componentInstanceElementScope !== null) {
//			return componentInstanceElementScope
//		}
//		
//		return null
//	}
//	
//	protected def handleTypeDeclarationReferences(EObject context, EReference reference,
//			Collection<? extends Package> packages) {
//		if (reference == ExpressionModelPackage.Literals.TYPE_REFERENCE__REFERENCE) {
//			// Util override is crucial because of this
//			val typeDeclarations = packages.map[it.typeDeclarations].flatten
//			return Scopes.scopeFor(typeDeclarations)
//		}
//		
//		return null
//	}
//	
//	protected def handleComponentInstanceElementReferences(EObject context, EReference reference,
//			Component component) {
//		if (reference == CompositeModelPackage.Literals.COMPONENT_INSTANCE_REFERENCE_EXPRESSION__COMPONENT_INSTANCE) {
//			val instanceContainer = ecoreUtil.getSelfOrContainerOfType(
//					context, ComponentInstanceReferenceExpression)
//			val parent = instanceContainer?.parent
//			val instances = (parent === null) ?	component.allInstances :
//				parent.getComponentInstance.instances
//			
//			return Scopes.scopeFor(instances)
//		}
//		if (context instanceof ComponentInstanceElementReferenceExpression) {
//			// Base
//			var instance = context.instance.lastInstance
//			val statechart = instance.derivedType
//			if (statechart !== null) {
//				if (statechart instanceof StatechartDefinition) {
//					// State
//					if (reference == CompositeModelPackage.Literals.COMPONENT_INSTANCE_STATE_REFERENCE_EXPRESSION__REGION) {
//						return Scopes.scopeFor(statechart.allRegions)
//					}
//					if (reference == CompositeModelPackage.Literals.COMPONENT_INSTANCE_STATE_REFERENCE_EXPRESSION__STATE) {
//						val stateConfigurationReference = context as ComponentInstanceStateReferenceExpression
//						val region = stateConfigurationReference.region
//						return Scopes.scopeFor(region.states)
//					}
//					// Variable
//					if (reference == CompositeModelPackage.Literals.COMPONENT_INSTANCE_VARIABLE_REFERENCE_EXPRESSION__VARIABLE_DECLARATION) {
//						return Scopes.scopeFor(statechart.variableDeclarations)
//					}
//					// Port
//					if (reference == CompositeModelPackage.Literals.COMPONENT_INSTANCE_EVENT_REFERENCE_EXPRESSION__PORT ||
//							reference == CompositeModelPackage.Literals.COMPONENT_INSTANCE_EVENT_PARAMETER_REFERENCE_EXPRESSION__PORT) {
//						return Scopes.scopeFor(statechart.ports)
//					}
//					// Event
//					if (reference == CompositeModelPackage.Literals.COMPONENT_INSTANCE_EVENT_REFERENCE_EXPRESSION__EVENT ||
//							reference == CompositeModelPackage.Literals.COMPONENT_INSTANCE_EVENT_PARAMETER_REFERENCE_EXPRESSION__EVENT) {
//						if (context instanceof ComponentInstanceEventReferenceExpression) {
//							val port = context.port
//							if (!port.eIsProxy) {
//								return Scopes.scopeFor(port.outputEvents)
//							}
//						}
//						if (context instanceof ComponentInstanceEventParameterReferenceExpression) {
//							val port = context.port
//							if (!port.eIsProxy) {
//								return Scopes.scopeFor(port.outputEvents)
//							}
//						}
//					}
//					// Parameter
//					if (reference == CompositeModelPackage.Literals.COMPONENT_INSTANCE_EVENT_PARAMETER_REFERENCE_EXPRESSION__PARAMETER_DECLARATION) {
//						val eventParameterReference = context as ComponentInstanceEventParameterReferenceExpression
//						return Scopes.scopeFor(eventParameterReference.event.parameterDeclarations)
//					}
//				}
//			}
//		}
//		
//		return null
//	}
	
}
