/********************************************************************************
 * Copyright (c) 2018-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.action.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;

import hu.bme.mit.gamma.action.derivedfeatures.ActionModelDerivedFeatures;
import hu.bme.mit.gamma.action.model.Action;
import hu.bme.mit.gamma.action.model.ActionModelPackage;
import hu.bme.mit.gamma.action.model.AssignmentStatement;
import hu.bme.mit.gamma.action.model.Block;
import hu.bme.mit.gamma.action.model.Branch;
import hu.bme.mit.gamma.action.model.BreakStatement;
import hu.bme.mit.gamma.action.model.ChoiceStatement;
import hu.bme.mit.gamma.action.model.ConstantDeclarationStatement;
import hu.bme.mit.gamma.action.model.ExpressionStatement;
import hu.bme.mit.gamma.action.model.ForStatement;
import hu.bme.mit.gamma.action.model.IfStatement;
import hu.bme.mit.gamma.action.model.ProcedureDeclaration;
import hu.bme.mit.gamma.action.model.ReturnStatement;
import hu.bme.mit.gamma.action.model.SwitchStatement;
import hu.bme.mit.gamma.action.model.VariableDeclarationStatement;
import hu.bme.mit.gamma.expression.model.ConstantDeclaration;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionModelValidator;

public class ActionModelValidator extends ExpressionModelValidator {
	// Singleton
	public static final ActionModelValidator INSTANCE = new ActionModelValidator();
	protected ActionModelValidator() {}
	
	public Collection<ValidationResultMessage> checkUnsupportedActions(Action action) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
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
				//validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "Not supported action.",
				// new ReferenceInfo(eContainmentFeature, index, container)));
			}
			else {
				//validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, "Not supported action.",
				//new ReferenceInfo(eContainmentFeature, null, container)));
			}
		}
		return validationResultMessages;
	}
	
	public 	Collection<ValidationResultMessage> checkAssignmentActions(AssignmentStatement assignment) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		ReferenceExpression lhs = assignment.getLhs();
		Declaration declaration = expressionUtil.getDeclaration(lhs);
		if (declaration instanceof ConstantDeclaration) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
				"Constants cannot be assigned new values.",
				new ReferenceInfo(ActionModelPackage.Literals.ASSIGNMENT_STATEMENT__LHS)));
		}
		
		// Other assignment type checking
		if (declaration instanceof VariableDeclaration) {
			VariableDeclaration variableDeclaration = (VariableDeclaration) declaration;
			try {
				Type variableDeclarationType = variableDeclaration.getType();
				validationResultMessages.addAll(checkTypeAndExpressionConformance(variableDeclarationType, 
						assignment.getRhs(), 
						ActionModelPackage.Literals.ASSIGNMENT_STATEMENT__RHS));
			} catch (Exception exception) {
				// There is a type error on a lower level, no need to display the error message on this level too
			}
		}
		
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkDuplicateVariableDeclarationStatements(
			VariableDeclarationStatement statement) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		EObject container = statement.eContainer();
		if (container instanceof Block) {
			Block block = (Block) container;
			String name = statement.getVariableDeclaration().getName();
			List<VariableDeclaration> precedingVariableDeclarations =
					ActionModelDerivedFeatures.getPrecedingVariableDeclarations(block, statement);
			for (VariableDeclaration precedingVariableDeclaration : precedingVariableDeclarations) {
				String newName = precedingVariableDeclaration.getName();
				if (name.equals(newName)) {
					validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"This variable cannot be named " + newName + " as it would enshadow a previous local variable.", 
							new ReferenceInfo(ActionModelPackage.Literals.VARIABLE_DECLARATION_STATEMENT__VARIABLE_DECLARATION)));
				}
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkReturnStatementType(ReturnStatement rs) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		ProcedureDeclaration containingProcedure = ecoreUtil.getContainerOfType(rs, ProcedureDeclaration.class);
		Type containingProcedureType = null;
		if (containingProcedure != null) {
			containingProcedureType = containingProcedure.getType();
		}
		if (!typeDeterminator.equalsType(containingProcedureType, rs.getExpression())) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
				"The type of the return statement (" + typeDeterminator.print(rs.getExpression())
					+ ") does not match the declared type of the procedure (" 
					+ typeDeterminator.print(containingProcedureType) + ")",
					new ReferenceInfo(ActionModelPackage.Literals.RETURN_STATEMENT__EXPRESSION)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkReturnStatementPosition(ReturnStatement statement) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (!ActionModelDerivedFeatures.isRecursivelyFinalAction(statement)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"Currently return statements must be final actions in every possible path.",
					new ReferenceInfo(ActionModelPackage.Literals.PROCEDURE_DECLARATION__BODY)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkReturnStatementPositions(ProcedureDeclaration procedure) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Block block = procedure.getBody();
		for (ReturnStatement statement : ecoreUtil.getAllContentsOfType(block, ReturnStatement.class)) {
			validationResultMessages.addAll(checkReturnStatementPosition(statement));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkBlockIsEmpty(Block block) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		// Block is empty
		if (block.getActions().isEmpty()) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING,
					"The block is empty!",
					new ReferenceInfo(ActionModelPackage.Literals.BLOCK__ACTIONS)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkBranch(Branch branch) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		// Block is empty
		Expression guard = branch.getGuard();
		if (!typeDeterminator.isBoolean(guard)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"Brach conditions must be of type boolean",
					new ReferenceInfo(ActionModelPackage.Literals.BRANCH__GUARD)));
		}
		return validationResultMessages;
	}
	
}
