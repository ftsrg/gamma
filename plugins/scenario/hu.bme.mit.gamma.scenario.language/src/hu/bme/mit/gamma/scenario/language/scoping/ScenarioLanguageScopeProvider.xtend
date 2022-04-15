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

import com.google.common.collect.Lists
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage
import hu.bme.mit.gamma.scenario.model.ScenarioModelPackage
import hu.bme.mit.gamma.scenario.model.ScenarioPackage
import hu.bme.mit.gamma.scenario.model.Signal
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelPackage
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.util.GammaEcoreUtil
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.Scopes
import org.eclipse.xtext.scoping.impl.SimpleScope

import static com.google.common.base.Preconditions.checkState
import hu.bme.mit.gamma.scenario.model.ScenarioCheckExpression

class ScenarioLanguageScopeProvider extends AbstractScenarioLanguageScopeProvider {

	val util = GammaEcoreUtil.INSTANCE

	override getScope(EObject context, EReference reference) {
		var IScope scope = null
		try {
			switch (context) {
				ScenarioPackage: scope = getScope(context, reference)
				Signal: scope = getScope(context, reference)
				DirectReferenceExpression: scope = getScope(context, reference)
				EventParameterReferenceExpression: scope = getScope(context, reference)
				ScenarioCheckExpression: scope = getScope(context, reference)
			}
		} catch (Exception ex) {
			// left empty on purpose
		} finally {
			scope = if(scope === null) getParentScopeP(context, reference) else scope
		}

		return scope
	}

	private def IScope getScope(DirectReferenceExpression context, EReference reference) {
		if (reference == ExpressionModelPackage.Literals.DIRECT_REFERENCE_EXPRESSION__DECLARATION) {
			// imported
			var scope = IScope.NULLSCOPE;
			val containingScenariopackage = util.getContainerOfType(context, ScenarioPackage);
			val imports = Lists.reverse(containingScenariopackage.imports); // Latter imports are stronger
			for (Package _import : imports) {
				var parent = super.getScope(_import, reference);
				scope = new SimpleScope(parent, scope.getAllElements());
			}
			// params
			scope = new SimpleScope(getParentScope(context, reference), scope.getAllElements());

			return scope;
		}
	}

	private def IScope getScope(ScenarioPackage scenarioPackage, EReference reference) {
		if (reference == ScenarioModelPackage.Literals.SCENARIO_PACKAGE__COMPONENT) {
			val importedPackages = scenarioPackage.imports
			return createScopeFor(importedPackages.flatMap[it.components])
		}
	}
	
	private def IScope getScope(ScenarioCheckExpression check, EReference reference) {
		if (reference == InterfaceModelPackage.Literals.EVENT_PARAMETER_REFERENCE_EXPRESSION__PORT) {
			val package = ecoreUtil.getContainerOfType(check, ScenarioPackage)
			return Scopes.scopeFor(package.component.ports)
		}
	}

	private def IScope getScope(EventParameterReferenceExpression expression, EReference reference) {
		if (reference == InterfaceModelPackage.Literals.EVENT_PARAMETER_REFERENCE_EXPRESSION__PORT) {
			val package = ecoreUtil.getContainerOfType(expression, ScenarioPackage)
			return Scopes.scopeFor(package.component.ports)
		}
		if (reference == InterfaceModelPackage.Literals.EVENT_PARAMETER_REFERENCE_EXPRESSION__EVENT) {
			checkState(expression.port !== null)
			val port = expression.port
			return Scopes.scopeFor(StatechartModelDerivedFeatures.getInputEvents(port))
		}
		if (reference == InterfaceModelPackage.Literals.EVENT_PARAMETER_REFERENCE_EXPRESSION__PARAMETER) {
			checkState(expression.port !== null)
			val event = expression.event
			return Scopes.scopeFor(event.getParameterDeclarations())
		}
		return null
	}

	private def IScope getScope(Signal signal, EReference reference) {
		if (reference == ScenarioModelPackage.Literals.SIGNAL__PORT) {
			val ports = ecoreUtil.getContainerOfType(signal, ScenarioPackage).component.ports
			return createScopeFor(ports)
		} else if (reference == ScenarioModelPackage.Literals.SIGNAL__EVENT) {
			val interface = signal.port.interfaceRealization.interface
			val events = StatechartModelDerivedFeatures.getAllEventDeclarations(interface).map[it.event]
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
