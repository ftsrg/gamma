package hu.bme.mit.gamma.activity.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;

import hu.bme.mit.gamma.action.model.AssignmentStatement;
import hu.bme.mit.gamma.action.util.ActionModelValidator;
import hu.bme.mit.gamma.activity.model.PinReference;
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage;
import hu.bme.mit.gamma.expression.model.NamedElement;

public class ActivityModelValidator extends ActionModelValidator {
	// Singleton
	public static final ActivityModelValidator INSTANCE = new ActivityModelValidator();
	protected ActivityModelValidator() {
		super.typeDeterminator = ActivityExpressionTypeDeterminator.INSTANCE; // PinReference
	}
	//
	
	public Collection<ValidationResultMessage> checkNameUniqueness(NamedElement element) {
		String name = element.getName();
		
		/*if (element instanceof NamedActivityDeclaration) {
			ActivityPackage activityPackage = ecoreUtil.getContainerOfType(element, ActivityPackage.class);
			
			return checkDirectNames(activityPackage.getNamedActivityDeclarations(), name);
		}*/
		
		return super.checkNameUniqueness(element);
	}
	
	public <T> Collection<ValidationResultMessage> checkDirectNames(Collection<T> elements, String name) {
		int nameCount = 0;
		
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();

		for (T element : elements) {
			if (element instanceof NamedElement) {
				if (name.equals(((NamedElement)element).getName())) {
					++nameCount;
				}
				if (nameCount > 1) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
							"In a Gamma model, these identifiers must be unique in the same context.",
							new ReferenceInfo(ExpressionModelPackage.Literals.NAMED_ELEMENT__NAME)));
				}
			}
		}
		return validationResultMessages;
	}
	
	@Override
	public 	Collection<ValidationResultMessage> checkAssignmentActions(AssignmentStatement assignment) {
		if (assignment.getLhs() instanceof PinReference) {
			return Collections.emptyList();
		}
		
		return super.checkAssignmentActions(assignment);
	}
	
}