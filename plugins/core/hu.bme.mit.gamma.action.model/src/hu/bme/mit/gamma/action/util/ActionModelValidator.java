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

import hu.bme.mit.gamma.action.derivedfeatures.ActionModelDerivedFeatures;
import hu.bme.mit.gamma.action.model.AbstractAssignmentStatement;
import hu.bme.mit.gamma.action.model.ActionModelPackage;
import hu.bme.mit.gamma.action.model.AssertionStatement;
import hu.bme.mit.gamma.action.model.AssignmentStatement;
import hu.bme.mit.gamma.action.model.Block;
import hu.bme.mit.gamma.action.model.Branch;
import hu.bme.mit.gamma.action.model.ExpressionStatement;
import hu.bme.mit.gamma.action.model.ForStatement;
import hu.bme.mit.gamma.action.model.HavocStatement;
import hu.bme.mit.gamma.action.model.ProcedureDeclaration;
import hu.bme.mit.gamma.action.model.ReturnStatement;
import hu.bme.mit.gamma.action.model.Statement;
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
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression;
import hu.bme.mit.gamma.expression.model.IntegerRangeTypeDefinition;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.model.VoidTypeDefinition;
import hu.bme.mit.gamma.expression.util.ExpressionModelValidator;

public class ActionModelValidator extends ExpressionModelValidator {
	// Singleton
	public static final ActionModelValidator INSTANCE = new ActionModelValidator();
	protected ActionModelValidator() {}
	
	public Collection<ValidationResultMessage> checkAssignmentActions(AbstractAssignmentStatement assignment) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		ReferenceExpression lhs = assignment.getLhs();
		Declaration declaration = expressionUtil.getDeclaration(lhs);
		if (declaration instanceof ConstantDeclaration) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
				"Constants cannot be assigned new values",
					new ReferenceInfo(ActionModelPackage.Literals.ABSTRACT_ASSIGNMENT_STATEMENT__LHS)));
			return validationResultMessages;
		}
		// Other assignment type checking
		if (assignment instanceof AssignmentStatement assignmentStatement) {
			try {
				Expression rhs = assignmentStatement.getRhs();
				validationResultMessages.addAll(checkExpressionConformance(lhs, rhs,
					new ReferenceInfo(ActionModelPackage.Literals.ASSIGNMENT_STATEMENT__RHS)));
			} catch (Exception exception) {
				// There is a type error on a lower level, no need to display the error message on this level too
			}
		}
		else if (assignment instanceof HavocStatement havoc) {
			Expression constraint = havoc.getConstraint();
			if (constraint != null && !typeDeterminator.isBoolean(constraint)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
					"This constraint is not a boolean expression",
						new ReferenceInfo(ActionModelPackage.Literals.HAVOC_STATEMENT__CONSTRAINT)));
				return validationResultMessages;
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
							"This variable cannot be named " + newName + " as it would enshadow a previous local variable", 
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
		if (!ecoreUtil.isLast(statement)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
				"A return statement must be the final statement in a block",
					new ReferenceInfo(ActionModelPackage.Literals.RETURN_STATEMENT__EXPRESSION, statement)));
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
	
	public Collection<ValidationResultMessage> checkExecutionPathsForReturn(ProcedureDeclaration procedure) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();

		Type type = procedure.getType();
		if (ExpressionModelDerivedFeatures.getTypeDefinition(type) instanceof VoidTypeDefinition) {
			return validationResultMessages;
		}
		
		Block block = procedure.getBody();
		
		List<Statement> containersOfReturns = new ArrayList<>();
		List<ReturnStatement> listOfReturnStatements = ecoreUtil.getAllContentsOfType(block, ReturnStatement.class);
		List<Branch> listOfBranch = ecoreUtil.getAllContentsOfType(block, Branch.class);
		
		boolean hasRootReturn = false;
		
		if (listOfReturnStatements.size() != 0) {
			// procedure has a root return statement
			for (ReturnStatement rs : listOfReturnStatements) {
				if (rs.eContainer().equals(block)) {
					hasRootReturn = true;
				}
			}
		
			if (listOfBranch.size() != 0) {
				for (Branch branch : listOfBranch) {
					// containers of branches
					Statement statement = ecoreUtil.getContainerOfType(branch, Statement.class);
					if (!containersOfReturns.contains(statement)) {
						containersOfReturns.add(statement);
					}
				}
				
				for (Statement statement : containersOfReturns) {
					boolean eachPathContainReturn = true;
					// all branch of statements
					for (Branch branch : ecoreUtil.getAllContentsOfType(statement, Branch.class)) {
						if (ecoreUtil.getAllContentsOfType(branch, ReturnStatement.class).size() == 0) {
							eachPathContainReturn = false;
						}
					}
					
					// some branch dosen't contain return statement
					if (!eachPathContainReturn) {
						// check the upper levels
						Statement content = ecoreUtil.clone(statement);
						Statement container = ecoreUtil.getContainerOfType(content, Statement.class);
						
						while (container != null || eachPathContainReturn) {
							// check the upper statement has more return statement, then the lower statement
							if (ecoreUtil.getAllContentsOfType(container, ReturnStatement.class).size() > ecoreUtil.getAllContentsOfType(content, ReturnStatement.class).size()) {
								eachPathContainReturn = true;
							}
							container = ecoreUtil.getContainerOfType(container, Statement.class);
							content = ecoreUtil.getContainerOfType(content, Statement.class);
						}
						
						// no root return statement and some branch doesn't contain return statement
						if (!eachPathContainReturn && !hasRootReturn) {
							validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
									"Each execution path must have a return statement",
									new ReferenceInfo(ActionModelPackage.Literals.PROCEDURE_DECLARATION__BODY, procedure)));							
						}
					}
				}
			}
		}
		else {
			// procedure doesn't contain return statement, but it's return type doesn't void
			if (!(procedure.getType() instanceof VoidTypeDefinition)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"Each procedure must have a return statement unless the return type of procedure is void",
						new ReferenceInfo(ActionModelPackage.Literals.PROCEDURE_DECLARATION__BODY, procedure)));
			}
		}
		
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkBlockIsEmpty(Block block) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		// Block is empty
		if (block.getActions().isEmpty()) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING,
					"The block is empty",
					new ReferenceInfo(ActionModelPackage.Literals.BLOCK__ACTIONS)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkBranch(Branch branch) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Expression guard = branch.getGuard();
		EObject container = branch.eContainer();
		// Check if container is a SwitchStatement
		if (container instanceof SwitchStatement) {
			SwitchStatement switchStatement = (SwitchStatement) container;
			if (!typeDeterminator.equalsType(switchStatement.getControlExpression(), guard) &&
					!(guard instanceof DefaultExpression)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"The guard must have the same type as the control expression",
						new ReferenceInfo(ActionModelPackage.Literals.BRANCH__GUARD)));
			}
		}
		else {
			if (!typeDeterminator.isBoolean(guard)) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"Branch conditions must be of type boolean",
						new ReferenceInfo(ActionModelPackage.Literals.BRANCH__GUARD)));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkForStatement(ForStatement forStatement) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		// Parameter check
		if (!typeDeterminator.isInteger(forStatement.getParameter().getType())) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The type of parameter must be integer",
					new ReferenceInfo(ActionModelPackage.Literals.FOR_STATEMENT__PARAMETER)));
		}
		// Range check 
		if (!(typeDeterminator.getType(forStatement.getRange()) instanceof IntegerRangeTypeDefinition)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
					"The type of range must be integer range",
					new ReferenceInfo(ActionModelPackage.Literals.FOR_STATEMENT__RANGE)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkSwitchStatement(SwitchStatement switchStatement) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		// if controlExpression is an enum, no need the DefaultBranch
		Type typeDef = typeDeterminator.getTypeDefinition(switchStatement.getControlExpression());
		if (typeDef instanceof EnumerationTypeDefinition) {
			EnumerationTypeDefinition enumerationTypeDefinition = (EnumerationTypeDefinition) typeDef;
			List<EnumerationLiteralDefinition> literals = new ArrayList<EnumerationLiteralDefinition>(
					enumerationTypeDefinition.getLiterals());
			List<Branch> cases = switchStatement.getCases();
			boolean hasDefaultBranch = false;
			for (Branch currentCase : cases) {
				Expression guard = currentCase.getGuard();
				if (guard instanceof EnumerationLiteralExpression) {
					EnumerationLiteralExpression literalExpression = (EnumerationLiteralExpression) guard;
					literals.remove(literalExpression.getReference());
				}
				// check DefaultBranch
				if (currentCase.getGuard() instanceof DefaultExpression) {
					hasDefaultBranch = true;
				}
			}
			if (literals.size() > 0 && !hasDefaultBranch) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
						"The following enumeration literals are not covered in any of the branches: " +
								literals.stream().map(it -> it.getName()).reduce((a, b) -> a + ", " + b).get(),
						new ReferenceInfo(ActionModelPackage.Literals.SWITCH_STATEMENT__CONTROL_EXPRESSION)));
			}
			else if (literals.size() == 0 && hasDefaultBranch) {
				validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING,
					"If a switch statement covers all literals of an enumeration, the default branch is not needed",
						new ReferenceInfo(ActionModelPackage.Literals.SWITCH_STATEMENT__CONTROL_EXPRESSION)));
			}
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkAssertionStatement(AssertionStatement assertStatement) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		if (!typeDeterminator.isBoolean(assertStatement.getAssertion())) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
				"The expressions of assertion statements must be of type boolean",
					new ReferenceInfo(ActionModelPackage.Literals.ASSERTION_STATEMENT__ASSERTION)));
		}
		return validationResultMessages;
	}
	
	public Collection<ValidationResultMessage> checkExpressionStatement(ExpressionStatement expressionStatement) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		Expression expression = expressionStatement.getExpression();
		if (!(expression instanceof FunctionAccessExpression)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.WARNING,
				"This expression statement has no effect here",
					new ReferenceInfo(ActionModelPackage.Literals.EXPRESSION_STATEMENT__EXPRESSION)));
		}
		return validationResultMessages;
	}
	
}