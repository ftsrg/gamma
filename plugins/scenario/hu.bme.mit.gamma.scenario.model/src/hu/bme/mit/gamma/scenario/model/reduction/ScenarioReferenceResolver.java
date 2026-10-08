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
package hu.bme.mit.gamma.scenario.model.reduction;

import java.util.ArrayList;
import java.util.List;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.model.ConstantDeclaration;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.scenario.model.CombinedFragment;
import hu.bme.mit.gamma.scenario.model.Fragment;
import hu.bme.mit.gamma.scenario.model.Occurrence;
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration;
import hu.bme.mit.gamma.scenario.model.ScenarioDefinitionReference;
import hu.bme.mit.gamma.scenario.model.ScenarioModelFactory;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ScenarioReferenceResolver {
	//
	private GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	//
	
	public void resolveReferences(ScenarioDeclaration scenario) {
		if (!containsAnyReferences(scenario)) {
			return;
		}
		Fragment fragment = scenario.getFragment();
		List<Occurrence> interactions = fragment.getInteractions();
		List<Occurrence> newInteractions = resolveReferencesFromFragment(fragment);
		interactions.clear();
		interactions.addAll(newInteractions);

		resolveReferences(scenario);
	}

	private List<Occurrence> resolveReferencesFromFragment(Fragment fragment) {
		List<Occurrence> newInteractions = new ArrayList<>();
		for (Occurrence interaction : fragment.getInteractions()) {
			if (interaction instanceof ScenarioDefinitionReference ref) {
				ScenarioDeclaration scenario = ref.getScenarioDefinition();
				Fragment fragment2 = scenario.getFragment();
				List<Occurrence> clonedInteractions = ecoreUtil
						.clone(fragment2).getInteractions();
				checkReferencesToInline(clonedInteractions, ref);
				newInteractions.addAll(clonedInteractions);
			}
			else if (interaction instanceof CombinedFragment combinedFragment) {
				List<Fragment> fragments = combinedFragment.getFragments();
				boolean isTransformationNeeded = containsAnyReferences(interaction);
				if (isTransformationNeeded) {
					List<Fragment> newFargments = new ArrayList<>();
					for (Fragment subFragment : fragments) {
						Fragment newFragment = ScenarioModelFactory.eINSTANCE.createFragment();
						newFragment.getInteractions().addAll(
								resolveReferencesFromFragment(subFragment));
						newFargments.add(newFragment);
					}
					fragments.clear();
					fragments.addAll(newFargments);
					newInteractions.add(combinedFragment);
				}
				else {
					newInteractions.add(interaction);
				}
			}
			else {
				newInteractions.add(interaction);
			}
		}
		return newInteractions;
	}

	private boolean containsAnyReferences(EObject object) {
		return !ecoreUtil.getAllContentsOfType(object, ScenarioDefinitionReference.class).isEmpty();
	}

	private void checkReferencesToInline(List<Occurrence> clonedInteractions, ScenarioDefinitionReference ref) {
		for (Occurrence interaction : clonedInteractions) {
			List<DirectReferenceExpression> references = ecoreUtil.getAllContentsOfType(interaction,
					DirectReferenceExpression.class);
			for (DirectReferenceExpression direct : references) {
				Declaration decl = direct.getDeclaration();
				if (decl instanceof ConstantDeclaration _const) {
					Expression cloned = ecoreUtil.clone(_const.getExpression());
					ecoreUtil.change(cloned, direct, direct.eContainer());
					ecoreUtil.replace(cloned, direct);
				}
				if (decl instanceof ParameterDeclaration param) {
					ScenarioDeclaration scenario = ref.getScenarioDefinition();
					List<ParameterDeclaration> parameterDeclarations = scenario.getParameterDeclarations();
					for (ParameterDeclaration paramD : parameterDeclarations) {
						if (paramD.getName() == param.getName()) {
							int index = parameterDeclarations.indexOf(paramD);
							Expression _new = ref.getArguments().get(index);
							Expression cloned = ecoreUtil.clone(_new);
							ecoreUtil.change(cloned, direct, direct.eContainer());
							ecoreUtil.replace(cloned, direct);
						}
					}
				}
			}
		}
	}
}
