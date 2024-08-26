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

import org.eclipse.xtext.validation.Check;

import hu.bme.mit.gamma.action.model.AbstractAssignmentStatement;
import hu.bme.mit.gamma.action.model.AssertionStatement;
import hu.bme.mit.gamma.action.model.Block;
import hu.bme.mit.gamma.action.model.Branch;
import hu.bme.mit.gamma.action.model.ExpressionStatement;
import hu.bme.mit.gamma.action.model.ForStatement;
import hu.bme.mit.gamma.action.model.ProcedureDeclaration;
import hu.bme.mit.gamma.action.model.ReturnStatement;
import hu.bme.mit.gamma.action.model.SwitchStatement;
import hu.bme.mit.gamma.action.model.VariableDeclarationStatement;
import hu.bme.mit.gamma.action.util.ActionModelValidator;

public class ActionLanguageValidator extends AbstractActionLanguageValidator {
	
	protected ActionModelValidator actionModelValidator = ActionModelValidator.INSTANCE;

	public ActionLanguageValidator() {
		super.expressionModelValidator = actionModelValidator;
	}
	
	@Check
	public void checkAssignmentActions(AbstractAssignmentStatement assignment) {
		handleValidationResultMessage(actionModelValidator.checkAssignmentActions(assignment));
	}
	
	@Check
	public void checkDuplicateVariableDeclarationStatements(VariableDeclarationStatement statement) {
		handleValidationResultMessage(actionModelValidator.checkDuplicateVariableDeclarationStatements(statement));
	}

	@Check
	public void checkReturnStatementType(ReturnStatement rs) {
		handleValidationResultMessage(actionModelValidator.checkReturnStatementType(rs));
	}
	
	@Check
	public void checkReturnStatementPositions(ProcedureDeclaration procedure) {
		handleValidationResultMessage(actionModelValidator.checkReturnStatementPositions(procedure));
	}
	
	@Check
	public void checkExecutionPathsForReturn(ProcedureDeclaration procedure) {
		handleValidationResultMessage(actionModelValidator.checkExecutionPathsForReturn(procedure));
	}
	
	@Check
	public void checkBlockIsEmpty(Block block) {
		handleValidationResultMessage(actionModelValidator.checkBlockIsEmpty(block));
	}
	
	@Check
	public void checkBranch(Branch branch) {
		handleValidationResultMessage(actionModelValidator.checkBranch(branch));
	}
	
	@Check
	public void checkForStatement(ForStatement forStatement) {
		handleValidationResultMessage(actionModelValidator.checkForStatement(forStatement));
	}
	
	@Check
	public void checkSwitchStatement(SwitchStatement switchStatement) {
		handleValidationResultMessage(actionModelValidator.checkSwitchStatement(switchStatement));
	}
	
	@Check
	public void checkAssertionStatement(AssertionStatement assertStatement) {
		handleValidationResultMessage(actionModelValidator.checkAssertionStatement(assertStatement));
	}
	
	@Check
	public void checkExpressionStatement(ExpressionStatement expressionStatement) {
		handleValidationResultMessage(actionModelValidator.checkExpressionStatement(expressionStatement));
	}
	
}