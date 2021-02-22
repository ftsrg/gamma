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
import org.eclipse.emf.ecore.EStructuralFeature;
import org.eclipse.xtext.validation.Check;

import hu.bme.mit.gamma.expression.model.ArgumentedElement;
import hu.bme.mit.gamma.expression.model.ArithmeticExpression;
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression;
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression;
import hu.bme.mit.gamma.expression.model.BooleanExpression;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.ElseExpression;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage;
import hu.bme.mit.gamma.expression.model.FieldDeclaration;
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression;
import hu.bme.mit.gamma.expression.model.IfThenElseExpression;
import hu.bme.mit.gamma.expression.model.InitializableElement;
import hu.bme.mit.gamma.expression.model.NamedElement;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.PredicateExpression;
import hu.bme.mit.gamma.expression.model.RecordAccessExpression;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.SelectExpression;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.ValueDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator;
import hu.bme.mit.gamma.expression.util.ExpressionLanguageUtil;
import hu.bme.mit.gamma.expression.util.ExpressionModelValidator;
import hu.bme.mit.gamma.expression.util.ExpressionModelValidator.ValidationResult;
import hu.bme.mit.gamma.expression.util.ExpressionModelValidator.ValidationResultMessage;
import hu.bme.mit.gamma.expression.util.ExpressionTypeDeterminator;
import hu.bme.mit.gamma.expression.util.ExpressionUtil;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

/**
 * This class contains custom validation rules. 
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
public class ExpressionLanguageValidator extends AbstractExpressionLanguageValidator {
	
	protected ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE;
	protected ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE;
	protected ExpressionTypeDeterminator typeDeterminator = ExpressionTypeDeterminator.INSTANCE;
	protected GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	
	protected ExpressionModelValidator expressionModelValidator = ExpressionModelValidator.INSTANCE;
	
	public void handleValidationResultMessage(Collection<ValidationResultMessage> collection) {
		for(ValidationResultMessage element: collection) {
			if(element.getResult() == ValidationResult.ERROR) {
				if(element.getReferenceInfo().hasInteger()) {
					error(element.getResultText(),element.getReferenceInfo().getReference(), element.getReferenceInfo().getIndex());
				}else {
					error(element.getResultText(),element.getReferenceInfo().getReference());
				}
			}else if(element.getResult() == ValidationResult.WARNING) {
				if(element.getReferenceInfo().hasInteger()) {
					warning(element.getResultText(),element.getReferenceInfo().getReference(), element.getReferenceInfo().getIndex());
				}else {
					warning(element.getResultText(),element.getReferenceInfo().getReference());
				}
			}else if(element.getResult() == ValidationResult.INFO) {
				if(element.getReferenceInfo().hasInteger()) {
					info(element.getResultText(),element.getReferenceInfo().getReference(), element.getReferenceInfo().getIndex());
				}else {
					info(element.getResultText(),element.getReferenceInfo().getReference());
				}
			}
		}
	}
	
	@Check
	public void checkNameUniqueness(NamedElement element) {
		handleValidationResultMessage(expressionModelValidator.checkNameUniqueness(element));
	}

	protected void checkNames(EObject root,
			Collection<Class<? extends NamedElement>> classes, String name) {
		handleValidationResultMessage(expressionModelValidator.checkNames(root, classes, name));
	}
	
	@Check
	public void checkTypeDeclaration(TypeDeclaration typeDeclaration) {
		handleValidationResultMessage(expressionModelValidator.checkTypeDeclaration(typeDeclaration));
	}
	
	// For derived classes - they have to add the parameterDeclarations
	protected void checkArgumentTypes(ArgumentedElement element, List<ParameterDeclaration> parameterDeclarations) {
		handleValidationResultMessage(expressionModelValidator.checkArgumentTypes(element, parameterDeclarations));
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
		RecordTypeDefinition rtd = (RecordTypeDefinition) ExpressionLanguageUtil.
				findAccessExpressionTypeDefinition(recordAccessExpression);
		// check if the referred declaration is accessible
		Declaration referredDeclaration = 
				ExpressionLanguageUtil.findAccessExpressionInstanceDeclaration(recordAccessExpression);
		if (!(referredDeclaration instanceof ValueDeclaration)) {
			error("The referred declaration is not accessible as a record!",
					ExpressionModelPackage.Literals.ACCESS_EXPRESSION__OPERAND);
			return;
		}
		// check if the referred field exists
		List<FieldDeclaration> fieldDeclarations = rtd.getFieldDeclarations();
		Declaration referredField = recordAccessExpression.getFieldReference().getFieldDeclaration();
		if (!fieldDeclarations.contains(referredField)){
			error("The record type does not contain any fields with the given name.",
					ExpressionModelPackage.Literals.RECORD_ACCESS_EXPRESSION__FIELD_REFERENCE);
			return;
		}
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
	
	protected void checkTypeAndTypeConformance(Type lhs, Type rhs, EStructuralFeature feature) {
		handleValidationResultMessage(expressionModelValidator.checkTypeAndTypeConformance(lhs, rhs, feature));
	}
	
	protected void checkTypeAndExpressionConformance(Type type, Expression rhs, EStructuralFeature feature) {
		handleValidationResultMessage(expressionModelValidator.checkTypeAndExpressionConformance(type, rhs, feature));
	}
	
	protected void checkEnumerationConformance(Type lhs, Type rhs, EStructuralFeature feature) {
		handleValidationResultMessage(expressionModelValidator.checkEnumerationConformance(lhs, rhs, feature));
	}

	protected void checkEnumerationConformance(Type type, Expression rhs, EStructuralFeature feature) {
		handleValidationResultMessage(expressionModelValidator.checkEnumerationConformance(type, rhs, feature));
	}
	
	protected void checkEnumerationConformance(Expression lhs, Expression rhs, EStructuralFeature feature) {
		handleValidationResultMessage(expressionModelValidator.checkEnumerationConformance(lhs, rhs, feature));
	}
	
	protected void checkEnumerationConformance(EnumerationTypeDefinition lhs, EnumerationTypeDefinition rhs,
			EStructuralFeature feature) {
		handleValidationResultMessage(expressionModelValidator.checkEnumerationConformance(lhs, rhs, feature));
	}
	
	@Check
	public void checkArithmeticExpression(ArithmeticExpression expression) {
		handleValidationResultMessage(expressionModelValidator.checkArithmeticExpression(expression));
	}
	
	@Check
	public void checkInitializableElement(InitializableElement elem) {
		handleValidationResultMessage(expressionModelValidator.checkInitializableElement(elem));
	}
	
}