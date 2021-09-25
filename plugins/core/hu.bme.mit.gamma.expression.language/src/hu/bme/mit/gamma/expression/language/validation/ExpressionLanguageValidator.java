/********************************************************************************
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.expression.language.validation;

import java.util.Collection;
import java.util.List;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.validation.Check;

import hu.bme.mit.gamma.expression.model.ArithmeticExpression;
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression;
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression;
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition;
import hu.bme.mit.gamma.expression.model.BooleanExpression;
import hu.bme.mit.gamma.expression.model.ElseExpression;
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression;
import hu.bme.mit.gamma.expression.model.IfThenElseExpression;
import hu.bme.mit.gamma.expression.model.InitializableElement;
import hu.bme.mit.gamma.expression.model.IntegerRangeLiteralExpression;
import hu.bme.mit.gamma.expression.model.NamedElement;
import hu.bme.mit.gamma.expression.model.PredicateExpression;
import hu.bme.mit.gamma.expression.model.RationalLiteralExpression;
import hu.bme.mit.gamma.expression.model.RecordAccessExpression;
import hu.bme.mit.gamma.expression.model.RecordLiteralExpression;
import hu.bme.mit.gamma.expression.model.SelectExpression;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionModelValidator;
import hu.bme.mit.gamma.expression.util.ExpressionModelValidator.ReferenceInfo;
import hu.bme.mit.gamma.expression.util.ExpressionModelValidator.ValidationResult;
import hu.bme.mit.gamma.expression.util.ExpressionModelValidator.ValidationResultMessage;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ExpressionLanguageValidator extends AbstractExpressionLanguageValidator {

	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected ExpressionModelValidator expressionModelValidator = ExpressionModelValidator.INSTANCE;
	
	protected void handleValidationResultMessage(Collection<ValidationResultMessage> collection) {
		for (ValidationResultMessage element : collection) {
			ValidationResult result = element.getResult();
			ReferenceInfo referenceInfo = element.getReferenceInfo();
			if (result == ValidationResult.ERROR) {
				if (referenceInfo.hasInteger() && referenceInfo.hasSource()) {
					error(element.getResultText(), referenceInfo.getSource(), referenceInfo.getReference(), referenceInfo.getIndex());
				}
				else if (referenceInfo.hasInteger() && !(referenceInfo.hasSource())) {
					error(element.getResultText(), referenceInfo.getReference(), referenceInfo.getIndex());
				}
				else if (referenceInfo.hasSource() && !(referenceInfo.hasInteger())) {
					error(element.getResultText(), referenceInfo.getSource(), referenceInfo.getReference());
				}
				else {
					error(element.getResultText(), referenceInfo.getReference());
				}
			}
			else if (result == ValidationResult.WARNING) {
				if (referenceInfo.hasInteger() && referenceInfo.hasSource()) {
					warning(element.getResultText(), referenceInfo.getSource(), referenceInfo.getReference(), referenceInfo.getIndex());
				}
				else if (referenceInfo.hasInteger() && !(referenceInfo.hasSource())) {
					warning(element.getResultText(), referenceInfo.getReference(), referenceInfo.getIndex());
				}
				else if (referenceInfo.hasSource() && !(referenceInfo.hasInteger())) {
					warning(element.getResultText(), referenceInfo.getSource(), referenceInfo.getReference());
				}
				else {
					warning(element.getResultText(), referenceInfo.getReference());
				}
			}
			else if (result == ValidationResult.INFO) {
				if (referenceInfo.hasInteger() && referenceInfo.hasSource()) {
					info(element.getResultText(), referenceInfo.getSource(), referenceInfo.getReference(), referenceInfo.getIndex());
				}
				else if (referenceInfo.hasInteger() && !(referenceInfo.hasSource())) {
					info(element.getResultText(), referenceInfo.getReference(), referenceInfo.getIndex());
				}
				else if (referenceInfo.hasSource() && !(referenceInfo.hasInteger())) {
					info(element.getResultText(), referenceInfo.getSource(), referenceInfo.getReference());
				}
				else {
					info(element.getResultText(), referenceInfo.getReference());
				}
			}
		}
	}
	
	@Check
	public void checkNameUniqueness(EObject element) {
		List<NamedElement> namedElements = ecoreUtil.getContentsOfType(element, NamedElement.class);
		if (!namedElements.isEmpty()) { // checkNameUniqueness(EObject ) would do this - this way it may be faster
			handleValidationResultMessage(expressionModelValidator.checkNameUniqueness(namedElements));
		}
	}

	@Check
	public void checkTypeDeclaration(TypeDeclaration typeDeclaration) {
		handleValidationResultMessage(expressionModelValidator.checkTypeDeclaration(typeDeclaration));
	}
	
	@Check
	public void checkIfThenElseExpression(IfThenElseExpression expression) {
		handleValidationResultMessage(expressionModelValidator.checkIfThenElseExpression(expression));
	}
	
	@Check
	public void checkArrayLiteralExpression(ArrayLiteralExpression expression) {
		handleValidationResultMessage(expressionModelValidator.checkArrayLiteralExpression(expression));
	}
	
	@Check
	public void checkRecordAccessExpression(RecordAccessExpression recordAccessExpression) {
		handleValidationResultMessage(expressionModelValidator.checkRecordAccessExpression(recordAccessExpression));
	}
	
	@Check
	public void checkFunctionAccessExpression(FunctionAccessExpression functionAccessExpression) {
		handleValidationResultMessage(expressionModelValidator.checkFunctionAccessExpression(functionAccessExpression));
	}
	
	@Check
	public void checkArrayAccessExpression(ArrayAccessExpression expression) {
		handleValidationResultMessage(expressionModelValidator.checkArrayAccessExpression(expression));
	}
	
	@Check
	public void checkSelectExpression(SelectExpression expression){
		handleValidationResultMessage(expressionModelValidator.checkSelectExpression(expression));
	}
	
	@Check
	public void checkElseExpression(ElseExpression expression) {
		handleValidationResultMessage(expressionModelValidator.checkElseExpression(expression));
	}
	
	@Check
	public void checkBooleanExpression(BooleanExpression expression) {
		handleValidationResultMessage(expressionModelValidator.checkBooleanExpression(expression));
	}
	
	@Check
	public void checkPredicateExpression(PredicateExpression expression) {
		handleValidationResultMessage(expressionModelValidator.checkPredicateExpression(expression));
	}
	
	@Check
	public void checkArithmeticExpression(ArithmeticExpression expression) {
		handleValidationResultMessage(expressionModelValidator.checkArithmeticExpression(expression));
	}
	
	@Check
	public void checkInitializableElement(InitializableElement elem) {
		handleValidationResultMessage(expressionModelValidator.checkInitializableElement(elem));
	}
	
	@Check
	public void checkArrayTypeDefinition(ArrayTypeDefinition elem) {
		handleValidationResultMessage(expressionModelValidator.checkArrayTypeDefinition(elem));
	}
	
	@Check
	public void checkSelfComparison(PredicateExpression elem) {
		handleValidationResultMessage(expressionModelValidator.checkSelfComparison(elem));
	}
	
	@Check
	public void checkDivZero(ArithmeticExpression elem) {
		handleValidationResultMessage(expressionModelValidator.checkDivZero(elem));
	}
	
	@Check
	public void checkRecordSelfReference(TypeDeclaration typeDeclaration) {
		handleValidationResultMessage(expressionModelValidator.checkRecordSelfReference(typeDeclaration));
	}
	
	@Check
	public void checkRationalLiteralExpression(RationalLiteralExpression expression) {
		handleValidationResultMessage(expressionModelValidator.checkRationalLiteralExpression(expression));
	}
	
	@Check
	public void checkRecordLiteralExpression(RecordLiteralExpression expression) {
		handleValidationResultMessage(expressionModelValidator.checkRecordLiteralExpression(expression));
	}
	
	@Check
	public void checkIntegerRangeLiteralExpression(IntegerRangeLiteralExpression expression) {
		handleValidationResultMessage(expressionModelValidator.checkIntegerRangeLiteralExpression(expression));
	}
}