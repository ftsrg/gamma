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
package hu.bme.mit.gamma.genmodel.language.scoping

import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation
import hu.bme.mit.gamma.genmodel.model.Coverage
import hu.bme.mit.gamma.genmodel.model.EventMapping
import hu.bme.mit.gamma.genmodel.model.GenModel
import hu.bme.mit.gamma.genmodel.model.GenmodelModelPackage
import hu.bme.mit.gamma.genmodel.model.InterfaceMapping
import hu.bme.mit.gamma.genmodel.model.YakinduCompilation
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponent
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.scoping.Scopes
import org.yakindu.sct.model.stext.stext.InterfaceScope

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
class GenModelScopeProvider extends AbstractGenModelScopeProvider {

	override getScope(EObject context, EReference reference) {
		if (context instanceof YakinduCompilation &&
				reference == GenmodelModelPackage.Literals.YAKINDU_COMPILATION__STATECHART) {
			val yakinduCompilation = context as YakinduCompilation
			val genmodel = yakinduCompilation.eContainer as GenModel
			return Scopes.scopeFor(genmodel.statechartImports)
		}
		if (reference == GenmodelModelPackage.Literals.CODE_GENERATION__COMPONENT ||
				reference == GenmodelModelPackage.Literals.ANALYSIS_MODEL_TRANSFORMATION__COMPONENT) {
			val genmodel = context.eContainer as GenModel
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
		if (context instanceof Coverage &&
				reference == GenmodelModelPackage.Literals.COVERAGE__INCLUDE ||
				reference == GenmodelModelPackage.Literals.COVERAGE__EXCLUDE) {
			val analysisModelTransformation = context.eContainer as AnalysisModelTransformation
			val component = analysisModelTransformation.component
			return Scopes.scopeFor(component.allInstances)
		}
		if (reference == GenmodelModelPackage.Literals.ASYNCHRONOUS_INSTANCE_CONSTRAINT__INSTANCE) {
			val genmodel = EcoreUtil2.getContainerOfType(context, AnalysisModelTransformation)
			val component = genmodel.component
			if (component instanceof AsynchronousComponent) {
				return Scopes.scopeFor(component.allAsynchronousSimpleInstances)
			}
		}
		if (reference == GenmodelModelPackage.Literals.TEST_GENERATION__EXECUTION_TRACE || 
				reference == GenmodelModelPackage.Literals.TEST_REPLAY_MODEL_GENERATION__EXECUTION_TRACE) {
			val genmodel = context.eContainer as GenModel
			return Scopes.scopeFor(genmodel.traceImports)
		}
		if (reference == GenmodelModelPackage.Literals.ADAPTIVE_CONTRACT_TEST_GENERATION__STATECHART_CONTRACT) {
			val genModel = EcoreUtil2.getRootContainer(context) as GenModel
			return Scopes.scopeFor(genModel.packageImports.map[it.components.filter(StatechartDefinition)].flatten)
		}
		if (context instanceof InterfaceMapping &&
			reference == GenmodelModelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE) {
			val statechart = ((context as InterfaceMapping).eContainer as YakinduCompilation).statechart
			if (statechart !== null) {
				return Scopes.scopeFor(statechart.scopes.filter(InterfaceScope))
			}
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
		if (context instanceof EventMapping && reference == GenmodelModelPackage.Literals.EVENT_MAPPING__YAKINDU_EVENT) {
			val yakinduInterface = ((context as EventMapping).eContainer as InterfaceMapping).yakinduInterface
			val events = yakinduInterface.events
			return Scopes.scopeFor(events)
		}
		if (context instanceof EventMapping && reference == GenmodelModelPackage.Literals.EVENT_MAPPING__GAMMA_EVENT) {
			val gammaInterface = ((context as EventMapping).eContainer as InterfaceMapping).gammaInterface
			val events = gammaInterface.allEventDeclarations.map[it.event]
			return Scopes.scopeFor(events)
		}
		val scope = super.getScope(context, reference)
		return scope
	}
	
}
