/********************************************************************************
 * Copyright (c) 2020-2022 Contributors to the Gamma project
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
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage
import hu.bme.mit.gamma.scenario.model.Interaction
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration
import hu.bme.mit.gamma.scenario.model.ScenarioModelPackage
import hu.bme.mit.gamma.scenario.model.ScenarioPackage
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

class ScenarioLanguageScopeProvider extends AbstractScenarioLanguageScopeProvider {

	val ecoreUtil = GammaEcoreUtil.INSTANCE

	override getScope(EObject context, EReference reference) {
		var IScope scope = null
		try {
			if (reference == ExpressionModelPackage.Literals.DIRECT_REFERENCE_EXPRESSION__DECLARATION) {
				// imported
				var _scope = IScope.NULLSCOPE;
				val containingScenarioPackage = ecoreUtil.getContainerOfType(context, ScenarioPackage);
				val imports = Lists.reverse(containingScenarioPackage.imports); // Latter imports are stronger
				for (Package _import : imports) {
					var parent = super.getScope(_import, reference);
					_scope = new SimpleScope(parent, _scope.getAllElements());
				}
				// params
				val containingScenarioDecl = ecoreUtil.getContainerOfType(context, ScenarioDeclaration);
				val variables = containingScenarioDecl.variableDeclarations
				_scope = new SimpleScope(getParentScope(context, reference), _scope.getAllElements());
				scope = Scopes.scopeFor(variables, _scope)
			} else if (context instanceof ScenarioPackage &&
				reference == ScenarioModelPackage.Literals.SCENARIO_PACKAGE__COMPONENT) {
				val scenarioPackage = context as ScenarioPackage
				val importedPackages = scenarioPackage.imports
				scope = createScopeFor(importedPackages.flatMap[it.components])
			} else if (reference == InterfaceModelPackage.Literals.EVENT_PARAMETER_REFERENCE_EXPRESSION__PORT) {
				val package = ecoreUtil.getContainerOfType(context, ScenarioPackage)
				return Scopes.scopeFor(package.component.ports)
			} else if (context instanceof EventParameterReferenceExpression && reference ==
				InterfaceModelPackage.Literals.EVENT_PARAMETER_REFERENCE_EXPRESSION__EVENT) {
				val expression = context as EventParameterReferenceExpression
				checkState(expression.port !== null)
				val port = expression.port
				return Scopes.scopeFor(StatechartModelDerivedFeatures.getAllEvents(port))
			} else if (context instanceof EventParameterReferenceExpression && reference ==
				InterfaceModelPackage.Literals.EVENT_PARAMETER_REFERENCE_EXPRESSION__PARAMETER) {
				val expression = context as EventParameterReferenceExpression
				checkState(expression.port !== null)
				val event = expression.event
				return Scopes.scopeFor(event.parameterDeclarations)
			} else if (context instanceof Interaction && reference == ScenarioModelPackage.Literals.INTERACTION__PORT) { 
				val ports = ecoreUtil.getContainerOfType(context, ScenarioPackage).component.ports
				return createScopeFor(ports)
			} else if (context instanceof Interaction && reference == ScenarioModelPackage.Literals.INTERACTION__EVENT) {
				val signal = context as Interaction
				val interface = signal.getPort.interfaceRealization.interface
				val events = StatechartModelDerivedFeatures.getAllEventDeclarations(interface).map[it.event]
				return createScopeFor(events)
			}
		} catch (Exception ex) {
			// left empty on purpose
		} finally {
			scope = if (scope === null) getParentScopeP(context, reference) else scope
		}

		return scope
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
