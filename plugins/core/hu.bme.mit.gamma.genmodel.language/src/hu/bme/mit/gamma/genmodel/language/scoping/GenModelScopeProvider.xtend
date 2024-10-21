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
package hu.bme.mit.gamma.genmodel.language.scoping

import hu.bme.mit.gamma.expression.model.ExpressionModelPackage
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation
import hu.bme.mit.gamma.genmodel.model.ComponentReference
import hu.bme.mit.gamma.genmodel.model.EventMapping
import hu.bme.mit.gamma.genmodel.model.GenModel
import hu.bme.mit.gamma.genmodel.model.GenmodelModelPackage
import hu.bme.mit.gamma.genmodel.model.InterfaceMapping
import hu.bme.mit.gamma.genmodel.model.StatechartContractGeneration
import hu.bme.mit.gamma.genmodel.model.YakinduCompilation
import hu.bme.mit.gamma.statechart.composite.ComponentInstancePortReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceTransitionReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.statechart.composite.CompositeModelPackage
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.TransitionIdAnnotation
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.scoping.Scopes

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class GenModelScopeProvider extends AbstractGenModelScopeProvider {

	override getScope(EObject context, EReference reference) {
//		if (context instanceof YakinduCompilation &&
//				reference == GenmodelModelPackage.Literals.YAKINDU_COMPILATION__STATECHART) {
//			val yakinduCompilation = context as YakinduCompilation
//			val genmodel = yakinduCompilation.eContainer as GenModel
//			return Scopes.scopeFor(genmodel.statechartImports)
//		}
//		if (context instanceof InterfaceMapping &&
//			reference == GenmodelModelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE) {
//			val statechart = ((context as InterfaceMapping).eContainer as YakinduCompilation).statechart
//			if (statechart !== null) {
//				return Scopes.scopeFor(statechart.scopes.filter(InterfaceScope))
//			}
//		}
//		if (context instanceof EventMapping && reference == GenmodelModelPackage.Literals.EVENT_MAPPING__YAKINDU_EVENT) {
//			val yakinduInterface = ((context as EventMapping).eContainer as InterfaceMapping).yakinduInterface
//			val events = yakinduInterface.events
//			return Scopes.scopeFor(events)
//		}
		if (reference == GenmodelModelPackage.Literals.CODE_GENERATION__COMPONENT ||
				reference == GenmodelModelPackage.Literals.COMPONENT_REFERENCE__COMPONENT) {
			val genmodel = ecoreUtil.getSelfOrContainerOfType(context, GenModel)
			val components = genmodel.packageImports.map[it.components].flatten
			return Scopes.scopeFor(components)
		}
		if (reference == GenmodelModelPackage.Literals.EVENT_PRIORITY_TRANSFORMATION__STATECHART) {
			val genmodel = context.eContainer as GenModel
			val components = genmodel.packageImports.map[it.components].flatten.filter(StatechartDefinition)
			return Scopes.scopeFor(components)
		}
		if (reference == GenmodelModelPackage.Literals.PHASE_STATECHART_GENERATION__STATECHART) {
			val genmodel = context.eContainer as GenModel
			val components = genmodel.packageImports.map[it.components].flatten.filter(StatechartDefinition)
			return Scopes.scopeFor(components)
		}
		if (reference == CompositeModelPackage.Literals.COMPONENT_INSTANCE_REFERENCE_EXPRESSION__COMPONENT_INSTANCE) {
			val analysisModel = ecoreUtil.getSelfOrContainerOfType(context, AnalysisModelTransformation)
			// Only if Gamma model is referenced
			val modelReference = analysisModel.model
			if (modelReference instanceof ComponentReference) {
				val component = modelReference.component
				val instanceContainer = ecoreUtil.getSelfOrContainerOfType(
					context, ComponentInstanceReferenceExpression)
				val parent = instanceContainer?.parent
				val instances = (parent === null) ?	component.allInstances :
					parent.getComponentInstance.instances
				return Scopes.scopeFor(instances)
			}
		}
		if (reference == CompositeModelPackage.Literals.COMPONENT_INSTANCE_PORT_REFERENCE_EXPRESSION__PORT) {
			val componentInstanceReference = context as ComponentInstancePortReferenceExpression
			val componentInstance = componentInstanceReference.instance.lastInstance
			if (componentInstance !== null) {
				val ports = componentInstance.derivedType.allPorts
				return Scopes.scopeFor(ports)
			}
		}
		if (reference == CompositeModelPackage.Literals.COMPONENT_INSTANCE_VARIABLE_REFERENCE_EXPRESSION__VARIABLE_DECLARATION) {
			val componentInstanceReference = context as ComponentInstanceVariableReferenceExpression
			val componentInstance = componentInstanceReference.instance.lastInstance
			if (componentInstance !== null) {
				val type = componentInstance.derivedType
				if (type instanceof StatechartDefinition) {
					val variables = type.variableDeclarations
					return Scopes.scopeFor(variables)
				}
			}
		}
		if (reference == CompositeModelPackage.Literals.COMPONENT_INSTANCE_STATE_REFERENCE_EXPRESSION__REGION) {
			val componentInstanceReference = context as ComponentInstanceStateReferenceExpression
			val componentInstance = componentInstanceReference.instance.lastInstance
			if (componentInstance !== null) {
				val component = componentInstance.derivedType
				if (component instanceof StatechartDefinition) {
					return Scopes.scopeFor(component.allRegions)
				}
			}
		}
		if (reference == CompositeModelPackage.Literals.COMPONENT_INSTANCE_STATE_REFERENCE_EXPRESSION__STATE) {
			val componentInstanceReference = context as ComponentInstanceStateReferenceExpression
			val componentInstance = componentInstanceReference.instance.lastInstance
			if (componentInstance !== null) {
				val component = componentInstance.derivedType
				if (component instanceof StatechartDefinition) {
					val region = componentInstanceReference.region
					if (region !== null) {
						return Scopes.scopeFor(region.states)
					}
				}
			}
		}
		if (reference == CompositeModelPackage.Literals.COMPONENT_INSTANCE_TRANSITION_REFERENCE_EXPRESSION__TRANSITION_ID) {
			val componentInstanceReference = context as ComponentInstanceTransitionReferenceExpression
			val componentInstance = componentInstanceReference.instance.lastInstance
			if (componentInstance !== null) {
				val component = componentInstance.derivedType
				if (component instanceof StatechartDefinition) {
					val transitions = component.transitions
					val annotations = transitions.map[it.annotations].flatten
						.filter(TransitionIdAnnotation)
					return Scopes.scopeFor(annotations)
				}
			}
		}
		if (reference == GenmodelModelPackage.Literals.TEST_GENERATION__EXECUTION_TRACE || 
				reference == GenmodelModelPackage.Literals.TRACE_REPLAY_MODEL_GENERATION__EXECUTION_TRACE) {
			val genmodel = context.eContainer as GenModel
			return Scopes.scopeFor(genmodel.traceImports)
		}
		if (context instanceof InterfaceMapping &&
			reference == GenmodelModelPackage.Literals.INTERFACE_MAPPING__GAMMA_INTERFACE) {
			val yakinduCompilation = (context as InterfaceMapping).eContainer as YakinduCompilation
			val genModel = yakinduCompilation.eContainer as GenModel
			val gammaInterfaceRoots = genModel.packageImports
			if (!gammaInterfaceRoots.empty) {
				return Scopes.scopeFor(gammaInterfaceRoots.map[it.interfaces].flatten)
			}
		}
		if (context instanceof EventMapping && reference == GenmodelModelPackage.Literals.EVENT_MAPPING__GAMMA_EVENT) {
			val gammaInterface = ((context as EventMapping).eContainer as InterfaceMapping).gammaInterface
			val events = gammaInterface.allEventDeclarations.map[it.event]
			return Scopes.scopeFor(events)
		}
		if (context instanceof StatechartContractGeneration && reference == GenmodelModelPackage.Literals.STATECHART_CONTRACT_GENERATION__SCENARIO){
			val genmodel = context.eContainer as GenModel
			return Scopes.scopeFor(genmodel.scenarioImports.flatMap[it.scenarios])
		}
		// Expression scoping
		if (reference == ExpressionModelPackage.Literals.DIRECT_REFERENCE_EXPRESSION__DECLARATION) {
			val genmodel = ecoreUtil.getSelfOrContainerOfType(context, GenModel)
			val imports = genmodel.packageImports
			if (!imports.empty) {
				val scopes = newArrayList
				for (^import : imports) {
					scopes += super.getScope(^import, reference)
				}
				return scopes.embedScopes
			}
		}
		
		val scope = super.getScope(context, reference)
		return scope
	}
	
}
