/********************************************************************************
 * Copyright (c) 2020-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scenario.language.scoping

import hu.bme.mit.gamma.scenario.language.util.ScenarioLanguageUtil
import hu.bme.mit.gamma.scenario.language.util.StatechartLanguageUtil
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration
import hu.bme.mit.gamma.scenario.model.ScenarioModelPackage
import hu.bme.mit.gamma.scenario.model.Signal
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.Scopes

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
class ScenarioLanguageScopeProvider extends AbstractScenarioLanguageScopeProvider {

	override getScope(EObject context, EReference reference) {
		var IScope scope = null

		try {
			switch (context) {
				ScenarioDeclaration: scope = getScope(context, reference)
				Signal: scope = getScope(context, reference)
			}
		} catch (Exception ex) {
			// left empty on purpose
		} finally {
			scope = if(scope === null) getParentScopeP(context, reference) else scope
		}

		return scope
	}

	private def IScope getScope(ScenarioDeclaration declaration, EReference reference) {
		if(reference == ScenarioModelPackage.Literals.SCENARIO_DECLARATION__COMPONENT) {
			val importedPackage = declaration.package
			return createScopeFor(importedPackage.components)
		}
	}
	
	private def IScope getScope(Signal signal, EReference reference) {
		if(reference == ScenarioModelPackage.Literals.SIGNAL__PORT) {
			val ports = ScenarioLanguageUtil::getScenarioDeclaration(signal).component.ports
			return createScopeFor(ports)

		} else if(reference == ScenarioModelPackage.Literals.SIGNAL__EVENT) {
			val interface = signal.port.interfaceRealization.interface
			val events = StatechartLanguageUtil::collectInterfaceEvents(interface)
			return createScopeFor(events)
		}
	}

	private def getParentScopeP(EObject object, EReference reference) {
		return super.getScope(object, reference)
	}

	private def createScopeFor(Iterable<? extends EObject> iterable) {
		switch (iterable) {
			case null: null
			default: Scopes.scopeFor(iterable)
		}
	}
}
