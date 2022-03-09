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
import hu.bme.mit.gamma.scenario.model.Interaction;
import hu.bme.mit.gamma.scenario.model.InteractionFragment;
import hu.bme.mit.gamma.scenario.model.ScenarioDefinition;
import hu.bme.mit.gamma.scenario.model.ScenarioDefinitionReference;
import hu.bme.mit.gamma.scenario.model.ScenarioModelFactory;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ScenarioReferenceResolver {
	private GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;

	public void resolveReferences(ScenarioDefinition scenario) {
		if(!containsAnyReferences(scenario)) {
			return;
		}

		List<Interaction> newInteractions = resolveReferencesFromFragment(scenario.getChart().getFragment());
		scenario.getChart().getFragment().getInteractions().clear();
		scenario.getChart().getFragment().getInteractions().addAll(newInteractions);

		resolveReferences(scenario);
	}

	private List<Interaction> resolveReferencesFromFragment(InteractionFragment fragment) {
		List<Interaction> newInteractions = new ArrayList<>();
		for (Interaction interaction : fragment.getInteractions()) {
			if (interaction instanceof ScenarioDefinitionReference) {
				ScenarioDefinitionReference ref = (ScenarioDefinitionReference) interaction;
				List<Interaction> clonedInteractions = ecoreUtil.clone(ref.getScenarioDefinition().getChart().getFragment()).getInteractions();
				checkReferencesToInline(clonedInteractions, ref);
				newInteractions.addAll(clonedInteractions);
			} 
			else if (interaction instanceof CombinedFragment) {
				boolean isTransformationNeeded = containsAnyReferences(interaction);
				if (isTransformationNeeded) {
					CombinedFragment combinedFragmen = (CombinedFragment) interaction;
					List<InteractionFragment> newFargments = new ArrayList<>();
					for (InteractionFragment subFragment : combinedFragmen.getFragments()) {
						InteractionFragment newFragment = ScenarioModelFactory.eINSTANCE.createInteractionFragment();
						newFragment.getInteractions().addAll(resolveReferencesFromFragment(subFragment));
						newFargments.add(newFragment);
					}
					combinedFragmen.getFragments().clear();
					combinedFragmen.getFragments().addAll(newFargments);
					newInteractions.add(combinedFragmen);
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
		return !ecoreUtil.getAllContentsOfType(object,
				ScenarioDefinitionReference.class).isEmpty();
	}
	
	private void checkReferencesToInline(List<Interaction> clonedInteractions, ScenarioDefinitionReference ref) {
		for (Interaction interaction : clonedInteractions) {
			List<DirectReferenceExpression> references = ecoreUtil.getAllContentsOfType(interaction, DirectReferenceExpression.class);
			for (DirectReferenceExpression direct : references) {
				Declaration decl = direct.getDeclaration();
				if (decl instanceof ConstantDeclaration) {
					ConstantDeclaration _const = (ConstantDeclaration) decl;
					Expression cloned = ecoreUtil.clone(_const.getExpression());
					ecoreUtil.change(cloned, direct, direct.eContainer());
					ecoreUtil.replace(cloned, direct);
				}
				if(decl instanceof ParameterDeclaration)
				{
					ParameterDeclaration param = (ParameterDeclaration) decl;					
					for(ParameterDeclaration paramD: ref.getScenarioDefinition().getParameterDeclarations()) {
						if(paramD.getName() == param.getName()) {
							int index = ref.getScenarioDefinition().getParameterDeclarations().indexOf(paramD);
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
