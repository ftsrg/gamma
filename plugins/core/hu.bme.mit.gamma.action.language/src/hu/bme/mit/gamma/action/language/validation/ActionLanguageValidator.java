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

import java.util.Collection;

import org.eclipse.xtext.validation.Check;

import hu.bme.mit.gamma.action.model.Action;
import hu.bme.mit.gamma.action.model.AssignmentStatement;
import hu.bme.mit.gamma.action.model.Branch;
import hu.bme.mit.gamma.action.model.ProcedureDeclaration;
import hu.bme.mit.gamma.action.model.ReturnStatement;
import hu.bme.mit.gamma.action.model.VariableDeclarationStatement;
import hu.bme.mit.gamma.action.util.ActionModelValidator;
import hu.bme.mit.gamma.expression.model.SelectExpression;
import hu.bme.mit.gamma.expression.util.ExpressionModelValidator.ValidationResult;
import hu.bme.mit.gamma.expression.util.ExpressionModelValidator.ValidationResultMessage;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.ValueDeclaration;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionType;

/**
 * This class contains custom validation rules. 
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
public class ActionLanguageValidator extends AbstractActionLanguageValidator {
	
	protected ActionModelValidator actionModelValidator = ActionModelValidator.INSTANCE;
	
	public void handleValidationResultMessage(Collection<ValidationResultMessage> collection) {
		for (ValidationResultMessage element: collection) {
			if (element.getResult() == ValidationResult.ERROR) {
				if (element.getReferenceInfo().hasInteger() && element.getReferenceInfo().hasSource()) {
					error(element.getResultText(), element.getReferenceInfo().getSource(), element.getReferenceInfo().getReference(), element.getReferenceInfo().getIndex());
				} else if (element.getReferenceInfo().hasInteger() && !(element.getReferenceInfo().hasSource())) {
					error(element.getResultText(), element.getReferenceInfo().getReference(), element.getReferenceInfo().getIndex());
				} else if (element.getReferenceInfo().hasSource() && !(element.getReferenceInfo().hasInteger())) {
					error(element.getResultText(), element.getReferenceInfo().getSource(), element.getReferenceInfo().getReference());
				} else {
					error(element.getResultText(), element.getReferenceInfo().getReference());
				}
			}else if (element.getResult() == ValidationResult.WARNING) {
				if (element.getReferenceInfo().hasInteger() && element.getReferenceInfo().hasSource()) {
					warning(element.getResultText(), element.getReferenceInfo().getSource(), element.getReferenceInfo().getReference(), element.getReferenceInfo().getIndex());
				} else if (element.getReferenceInfo().hasInteger() && !(element.getReferenceInfo().hasSource())) {
					warning(element.getResultText(), element.getReferenceInfo().getReference(), element.getReferenceInfo().getIndex());
				} else if (element.getReferenceInfo().hasSource() && !(element.getReferenceInfo().hasInteger())) {
					warning(element.getResultText(), element.getReferenceInfo().getSource(), element.getReferenceInfo().getReference());
				} else {
					warning(element.getResultText(), element.getReferenceInfo().getReference());
				}
			}else if (element.getResult() == ValidationResult.INFO) {
				if (element.getReferenceInfo().hasInteger() && element.getReferenceInfo().hasSource()) {
					info(element.getResultText(), element.getReferenceInfo().getSource(), element.getReferenceInfo().getReference(), element.getReferenceInfo().getIndex());
				} else if (element.getReferenceInfo().hasInteger() && !(element.getReferenceInfo().hasSource())) {
					info(element.getResultText(), element.getReferenceInfo().getReference(), element.getReferenceInfo().getIndex());
				} else if (element.getReferenceInfo().hasSource() && !(element.getReferenceInfo().hasInteger())) {
					info(element.getResultText(), element.getReferenceInfo().getSource(), element.getReferenceInfo().getReference());
				} else {
					info(element.getResultText(), element.getReferenceInfo().getReference());
				}
			}
		}
	}
	
	
	//TODO ???
	@Check
	public void checkUnsupportedActions(Action action) {
		handleValidationResultMessage(actionModelValidator.checkUnsupportedActions(action));
	}
	
	@Check
	public void checkAssignmentActions(AssignmentStatement assignment) {
		handleValidationResultMessage(actionModelValidator.checkAssignmentActions(assignment));
	}
	
	@Check
	public void checkDuplicateVariableDeclarationStatements(VariableDeclarationStatement statement) {
		handleValidationResultMessage(actionModelValidator.checkDuplicateVariableDeclarationStatements(statement));
	}
	
	@Check
	public void checkSelectExpression(SelectExpression expression){
		handleValidationResultMessage(actionModelValidator.checkSelectExpression(expression));
	}

	@Check
	public void CheckReturnStatementType(ReturnStatement rs) {
		handleValidationResultMessage(actionModelValidator.CheckReturnStatementType(rs));
	}
	
	//TODO extract into util-class
	private ProcedureDeclaration getContainingProcedure(Action action) {
		return actionModelValidator.getContainingProcedure(action);
	}
	
	//TODO extract into util-class
	private ProcedureDeclaration getContainingProcedure(Branch branch) {
		return actionModelValidator.getContainingProcedure(branch);
	}
}
