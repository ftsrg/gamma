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

import hu.bme.mit.gamma.statechart.model.composite.AbstractSynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.interface_.Event
import hu.bme.mit.gamma.statechart.model.interface_.Interface
import hu.bme.mit.gamma.yakindu.genmodel.EventMapping
import hu.bme.mit.gamma.yakindu.genmodel.GenModel
import hu.bme.mit.gamma.yakindu.genmodel.GenmodelPackage
import hu.bme.mit.gamma.yakindu.genmodel.InterfaceMapping
import hu.bme.mit.gamma.yakindu.genmodel.YakinduCompilation
import java.util.Collections
import java.util.HashSet
import java.util.Set
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.scoping.Scopes
import org.yakindu.sct.model.stext.stext.InterfaceScope

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
class GenModelScopeProvider extends AbstractGenModelScopeProvider {

	override getScope(EObject context, EReference reference) {
		if (context instanceof YakinduCompilation && reference == GenmodelPackage.Literals.YAKINDU_COMPILATION__STATECHART) {
			val yakinduCompilation = context as YakinduCompilation
			val genmodel = yakinduCompilation.eContainer as GenModel
			return Scopes.scopeFor(genmodel.statechartImports)
		}
		if (reference == GenmodelPackage.Literals.CODE_GENERATION__COMPONENT ||
				reference == GenmodelPackage.Literals.ANALYSIS_MODEL_TRANSFORMATION__COMPONENT) {
			val genmodel = context.eContainer as GenModel
			val components = genmodel.packageImports.map[it.components].flatten
			return Scopes.scopeFor(components)
		}
		if (reference == GenmodelPackage.Literals.COVERAGE__INCLUDE ||
				reference == GenmodelPackage.Literals.COVERAGE__EXCLUDE) {
			val genmodel = context.eContainer.eContainer as GenModel
			val components = genmodel.packageImports.map[it.components].flatten
								.filter(AbstractSynchronousCompositeComponent).map[it.components].flatten
			return Scopes.scopeFor(components)
		}
		if (reference == GenmodelPackage.Literals.TEST_GENERATION__EXECUTION_TRACE) {
			val genmodel = context.eContainer as GenModel
			return Scopes.scopeFor(genmodel.traceImports)
		}
		if (context instanceof InterfaceMapping &&
			reference == GenmodelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE) {
			val statechart = ((context as InterfaceMapping).eContainer as YakinduCompilation).statechart
			if (statechart !== null) {
				return Scopes.scopeFor(statechart.scopes.filter(InterfaceScope))
			}
		}
		if (context instanceof InterfaceMapping &&
			reference == GenmodelPackage.Literals.INTERFACE_MAPPING__GAMMA_INTERFACE) {
			val yakinduCompilation = (context as InterfaceMapping).eContainer as YakinduCompilation
			val genModel = yakinduCompilation.eContainer as GenModel
			val gammaInterfaceRoots = genModel.packageImports
			if (!gammaInterfaceRoots.empty) {
				return Scopes.scopeFor(gammaInterfaceRoots.map[it.interfaces].flatten)
			}
		}
		if (context instanceof EventMapping && reference == GenmodelPackage.Literals.EVENT_MAPPING__YAKINDU_EVENT) {
			val yakinduInterface = ((context as EventMapping).eContainer as InterfaceMapping).yakinduInterface
			val events = yakinduInterface.events
			return Scopes.scopeFor(events)
		}
		if (context instanceof EventMapping && reference == GenmodelPackage.Literals.EVENT_MAPPING__GAMMA_EVENT) {
			val gammaInterface = ((context as EventMapping).eContainer as InterfaceMapping).gammaInterface
			val events = gammaInterface.allEvents
			return Scopes.scopeFor(events)
		}
		val scope = super.getScope(context, reference)
		return scope
	}
	
	/** It returns the events of the parent interfaces as well. */
	private def Set<Event> getAllEvents(Interface anInterface) {
		if (anInterface === null) {
			return Collections.EMPTY_SET
		}
		val eventSet = new HashSet<Event>
		for (parentInterface : anInterface.parents) {
			eventSet.addAll(parentInterface.getAllEvents)
		}
		for (event : anInterface.events.map[it.event]) {
			eventSet.add(event)
		}
		return eventSet
	}

}
