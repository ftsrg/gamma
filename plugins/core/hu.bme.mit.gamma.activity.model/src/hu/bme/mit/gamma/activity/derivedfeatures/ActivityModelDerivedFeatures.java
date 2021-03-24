package hu.bme.mit.gamma.activity.derivedfeatures;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.action.derivedfeatures.ActionModelDerivedFeatures;
import hu.bme.mit.gamma.activity.model.ActivityDeclaration;
import hu.bme.mit.gamma.activity.model.ActivityDeclarationReference;
import hu.bme.mit.gamma.activity.model.ActivityDefinition;
import hu.bme.mit.gamma.activity.model.InlineActivityDeclaration;
import hu.bme.mit.gamma.activity.model.NamedActivityDeclarationReference;
import hu.bme.mit.gamma.activity.model.OutsidePinReference;

public class ActivityModelDerivedFeatures extends ActionModelDerivedFeatures {

	public static ActivityDeclaration getContainingActivityDeclaration(EObject element) {
		if (element instanceof ActivityDeclaration) {
			return (ActivityDeclaration)element;
		}
		
		return getContainingActivityDeclaration(element.eContainer());
	}
	
	public static ActivityDefinition getContainingActivityDefinition(EObject element) {
		if (element instanceof ActivityDefinition) {
			return (ActivityDefinition)element;
		}
		
		return getContainingActivityDefinition(element.eContainer());
	}
	
	public static ActivityDeclaration getReferencedActivityDeclaration(OutsidePinReference reference) {
		ActivityDeclarationReference declReference = reference.getActionNode().getActivityDeclarationReference();

		if (declReference instanceof InlineActivityDeclaration) {
			return (InlineActivityDeclaration)declReference;
		}
		if (declReference instanceof NamedActivityDeclarationReference) {
			return ((NamedActivityDeclarationReference)declReference).getNamedActivityDeclaration();
		}
		
		return null;
	}
	
}
