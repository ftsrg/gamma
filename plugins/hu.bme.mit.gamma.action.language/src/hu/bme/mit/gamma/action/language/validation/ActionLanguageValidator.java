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
package hu.bme.mit.gamma.action.language.validation;

import java.util.List;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;
import org.eclipse.xtext.validation.Check;

import hu.bme.mit.gamma.action.model.Action;
import hu.bme.mit.gamma.action.model.ActionModelPackage;
import hu.bme.mit.gamma.action.model.AssignmentStatement;
import hu.bme.mit.gamma.action.model.Block;
import hu.bme.mit.gamma.action.model.BreakStatement;
import hu.bme.mit.gamma.action.model.ChoiceStatement;
import hu.bme.mit.gamma.action.model.ConstantDeclarationStatement;
import hu.bme.mit.gamma.action.model.ExpressionStatement;
import hu.bme.mit.gamma.action.model.ForStatement;
import hu.bme.mit.gamma.action.model.IfStatement;
import hu.bme.mit.gamma.action.model.ReturnStatement;
import hu.bme.mit.gamma.action.model.SwitchStatement;
import hu.bme.mit.gamma.action.model.VariableDeclarationStatement;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;

/**
 * This class contains custom validation rules. 
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
public class ActionLanguageValidator extends AbstractActionLanguageValidator {
	
	@Check
	public void checkUnsupportedActions(Action action) {
		if (action instanceof Block ||
				action instanceof BreakStatement ||
				action instanceof ChoiceStatement ||
				action instanceof ConstantDeclarationStatement ||
				action instanceof ExpressionStatement ||
				action instanceof ForStatement ||
				action instanceof IfStatement ||
				action instanceof ReturnStatement ||
				action instanceof SwitchStatement ||
				action instanceof VariableDeclarationStatement) {
			EObject container = action.eContainer();
			EReference eContainmentFeature = action.eContainmentFeature();
			Object object = container.eGet(eContainmentFeature, true);
			if (object instanceof List) {
				@SuppressWarnings("unchecked")
				List<Action> actions = (List<Action>) object;
				int index = actions.indexOf(action);
				error("Not supported action.", container, eContainmentFeature, index);
			}
			else {
				error("Not supported action.", container, eContainmentFeature);
			}
		}
	}
	
	@Check
	public void checkAssignmentActions(AssignmentStatement assignment) {
		ReferenceExpression reference = (ReferenceExpression) assignment.getLhs();
		// Constant
		if (!(reference.getDeclaration() instanceof VariableDeclaration)) {
			error("Values can be assigned only to variables.", ActionModelPackage.Literals.ASSIGNMENT_STATEMENT__LHS);
		}
		// Other assignment type checking
		if (reference.getDeclaration() instanceof VariableDeclaration) {
			VariableDeclaration variableDeclaration = (VariableDeclaration) reference.getDeclaration();
			try {
				Type variableDeclarationType = variableDeclaration.getType();
				ExpressionType rightHandSideExpressionType = typeDeterminator.getType(assignment.getRhs());
				if (!typeDeterminator.equals(variableDeclarationType, rightHandSideExpressionType)) {
					error("The types of the variable declaration and the right hand side expression are not the same: " +
							typeDeterminator.transform(variableDeclarationType).toString().toLowerCase() + " and " +
							rightHandSideExpressionType.toString().toLowerCase() + ".",
							ActionModelPackage.Literals.ASSIGNMENT_STATEMENT__LHS);
				}
				// Additional checks for enumerations
				EnumerationTypeDefinition enumType = null;
				if (variableDeclarationType instanceof EnumerationTypeDefinition) {
					enumType = (EnumerationTypeDefinition) variableDeclarationType;
				}
				else if (variableDeclarationType instanceof TypeReference &&
						((TypeReference) variableDeclarationType).getReference().getType() instanceof EnumerationTypeDefinition) {
					enumType = (EnumerationTypeDefinition) ((TypeReference) variableDeclarationType).getReference().getType();
				}
				if (enumType != null) {
					if (assignment.getRhs() instanceof EnumerationLiteralExpression) {
						EnumerationLiteralExpression rhs = (EnumerationLiteralExpression) assignment.getRhs();
						if (!enumType.getLiterals().contains(rhs.getReference())) {
							error("This is not a valid literal of the enum type: " + rhs.getReference().getName() + ".",
									ActionModelPackage.Literals.ASSIGNMENT_STATEMENT__RHS);
						}
					}
					else {
						error("The right hand side must be of type enumeration literal.", ActionModelPackage.Literals.ASSIGNMENT_STATEMENT__RHS);
					}
				}
			} catch (Exception exception) {
				// There is a type error on a lower level, no need to display the error message on this level too
			}
		}
	}
	
}
