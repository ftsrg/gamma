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

import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;

import hu.bme.mit.gamma.action.derivedfeatures.ActionModelDerivedFeatures;
import hu.bme.mit.gamma.action.model.Action;
import hu.bme.mit.gamma.action.model.ActionModelPackage;
import hu.bme.mit.gamma.action.model.AssertionStatement;
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
import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.ConstantDeclaration;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DefaultExpression;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.IntegerRangeTypeDefinition;
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.model.impl.DefaultExpressionImpl;
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
		Expression guard = branch.getGuard();
		EObject container = branch.eContainer();
		// check if container is a SwitchStatement
		if (container instanceof SwitchStatement) {
			SwitchStatement switchStatement = (SwitchStatement) container;
			if (!typeDeterminator.equalsType(switchStatement.getControlExpression(), guard) && !(branch.getGuard() instanceof DefaultExpression)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"SwitchBrach type of control expression must be same type of guard!",
						new ReferenceInfo(ActionModelPackage.Literals.BRANCH__GUARD)));
			}
		}
		else {
			if (!typeDeterminator.isBoolean(guard)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"Branch conditions must be of type boolean!",
						new ReferenceInfo(ActionModelPackage.Literals.BRANCH__GUARD)));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkForStatement(ForStatement forStatement) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		// parameter check
		if (!typeDeterminator.isInteger(forStatement.getParameter().getType())) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The type of parameter must be integer!",
					new ReferenceInfo(ActionModelPackage.Literals.FOR_STATEMENT__PARAMETER)));
		}
		// range check 
		if (!(typeDeterminator.getType(forStatement.getRange()) instanceof IntegerRangeTypeDefinition)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The type of range must be integer range!",
					new ReferenceInfo(ActionModelPackage.Literals.FOR_STATEMENT__RANGE)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkSwitchStatement(SwitchStatement switchStatement) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		// if controlExpression is an enum, no need the DefaultBranch
		Type typeDef = typeDeterminator.getTypeDefinition(switchStatement.getControlExpression());
		if (typeDef instanceof EnumerationTypeDefinition) {
			List<EnumerationLiteralDefinition> cloneLiterals = ecoreUtil.clone(((EnumerationTypeDefinition) typeDef).getLiterals());
			List<EnumerationLiteralDefinition> literals = ecoreUtil.clone(((EnumerationTypeDefinition) typeDef).getLiterals());
			List<Branch> cases = switchStatement.getCases();
			boolean hasDefaultBranch = false;
			for (Branch currentCase : cases) {
				if (typeDeterminator.equalsType(switchStatement.getControlExpression(), currentCase.getGuard())) {
					for (EnumerationLiteralDefinition literal : literals) {
						if (ecoreUtil.helperEquals(literal, ((EnumerationLiteralExpression) currentCase.getGuard()).getReference())) {
							int idx = literals.indexOf(literal);
							cloneLiterals.remove(idx);
						}
					}
				}
				// check DefaultBranch
				if (currentCase.getGuard() instanceof DefaultExpression) {
					hasDefaultBranch = true;
				}
			}
			if (cloneLiterals.size() == 0 && hasDefaultBranch) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.INFO,
						"If a switch statement checks all literals of an enumeration, the default branch is not needed!",
						new ReferenceInfo(ActionModelPackage.Literals.SWITCH_STATEMENT__CONTROL_EXPRESSION)));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkAssertionStatement(AssertionStatement assertStatement) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		if (!typeDeterminator.isBoolean(assertStatement.getAssertion())) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The expression of assertion statement must be boolean!",
					new ReferenceInfo(ActionModelPackage.Literals.ASSERTION_STATEMENT__ASSERTION)));
		}
		
		return validationResultMessages;
	}
}
