/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.action.model.Action
import hu.bme.mit.gamma.action.model.ActionModelFactory
import hu.bme.mit.gamma.action.model.ForStatement
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import hu.bme.mit.gamma.expression.model.EnumerableExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.FieldDeclaration
import hu.bme.mit.gamma.expression.model.FunctionDeclaration
import hu.bme.mit.gamma.expression.model.InitializableElement
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression
import hu.bme.mit.gamma.expression.model.IntegerRangeLiteralExpression
import hu.bme.mit.gamma.expression.model.NullaryExpression
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.ValueDeclaration
import java.math.BigInteger
import java.util.ArrayList
import java.util.List

class ForStatementUnroller {
	
	protected final extension ActionModelFactory actionFactory = ActionModelFactory.eINSTANCE;
	protected final extension ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE;
	
	protected final extension ExpressionTransformer expressionTransformer;
	protected final extension ActionTransformer actionTransformer;
	
	protected final Trace trace
	 
	new(Trace trace) {
		this.trace = trace
		this.expressionTransformer = new ExpressionTransformer(this.trace)
		this.actionTransformer = new ActionTransformer(this.trace)
	}
	
	protected def Action unrollForStatement(ForStatement statement)
	{
		var parameterValues = statement.range.getParameterValues;
		
		var unrolledForStatement = actionFactory.createBlock();

		var parameterVariableDeclarationStatement = actionFactory.createVariableDeclarationStatement;
		var parameterVariableDeclaration = expressionFactory.createVariableDeclaration;
		parameterVariableDeclaration.setName(statement.parameter.name);
		parameterVariableDeclaration.setType(statement.parameter.type);
		parameterVariableDeclarationStatement.setVariableDeclaration(parameterVariableDeclaration);
		unrolledForStatement.actions.add(parameterVariableDeclarationStatement);	
		
		for(parameterValue : parameterValues){
			var parameterVariableAssignment = actionFactory.createAssignmentStatement;
			var parameterVariableReference = expressionFactory.createReferenceExpression;
			parameterVariableReference.setDeclaration(parameterVariableDeclaration);
			parameterVariableAssignment.lhs = parameterVariableReference;
			parameterVariableAssignment.rhs = parameterValue;
			unrolledForStatement.actions.add(parameterVariableAssignment);
			
			unrolledForStatement.actions.add(statement.body.transformAction); //clones actions as those are the same on this level afaik
		}
		
		return unrolledForStatement;
	}
	
	//For-statement range values (in general parameter values)
	protected def dispatch List<Expression> getParameterValues(ReferenceExpression expression){
		var parameterValues = new ArrayList<Expression>();
		
		var declaration = expression.declaration;
		var declarationValues = declaration.getDeclarationValues;
		parameterValues.addAll(declarationValues);
		
		return parameterValues;
	}
	protected def dispatch List<Expression> getParameterValues(EnumerableExpression expression){
		var parameterValues = new ArrayList<Expression>();
		parameterValues.addAll(expression.getEnumerableExpressionValues);
		return parameterValues;
	}
	protected def dispatch List<Expression> getParameterValues(Expression expression){
		var parameterValues = new ArrayList<Expression>();
		parameterValues.add(expression);
		return parameterValues;
	}
	
	
	//Declaration values
	protected def dispatch List<Expression> getDeclarationValues(ValueDeclaration declaration){
		var declarationValues = new ArrayList<Expression>();
		
		var valueDeclaration = declaration as ValueDeclaration;
		var valueDeclarationValues = valueDeclaration.getValueDeclarationValues;
		declarationValues.addAll(valueDeclarationValues);
		
		return declarationValues;
	}
	protected def dispatch List<Expression> getDeclarationValues(FunctionDeclaration declaration){
		throw new Exception	//TODO specify exception type
	}
	protected def dispatch List<Expression> getDeclarationValues(TypeDeclaration declaration){
		throw new Exception	//TODO specify exception type
	}
	
	//ValueDeclaration values
	protected def dispatch List<Expression> getValueDeclarationValues(InitializableElement declaration){
		var valueDeclarationValues = new ArrayList<Expression>();
		
		var expression = declaration.expression;
		var expressionValues = expression.getParameterValues;
		valueDeclarationValues.addAll(expressionValues);
		
		return valueDeclarationValues;
	}
	protected def dispatch List<Expression> getValueDeclarationValues(ParameterDeclaration declaration){
		//TODO implement
	}
	protected def dispatch List<Expression> getValueDeclarationValues(FieldDeclaration declaration){
		//TODO implement
	}
	
	//EnumerableExpression values
	protected def dispatch List<Expression> getEnumerableExpressionValues(ArrayLiteralExpression expression){
		var enumerableExpressionValues = new ArrayList<Expression>();
		
		for(operand : expression.operands){
			var operandValues = operand.getParameterValues;
			enumerableExpressionValues.addAll(operandValues);
		}
		
		return enumerableExpressionValues;
	}
	protected def dispatch List<Expression> getEnumerableExpressionValues(IntegerRangeLiteralExpression expression){
		var enumerableExpressionValues = new ArrayList<Expression>();
		
		var left = expression.leftOperand;
		var leftValue = evaluateReferenceOrIntegerLiteralToInteger(left as NullaryExpression);	//Why nullary?
		var right = expression.rightOperand;
		var rightValue = evaluateReferenceOrIntegerLiteralToInteger(right as NullaryExpression); //-same-
		
		for(var int i = if (expression.leftInclusive) leftValue else (leftValue + 1);
			i < (if (expression.rightInclusive) rightValue else (rightValue - 1));
			i++
		){
			//TODO TODO TODO TODO TODO TODO TODO
			var element = expressionFactory.createIntegerLiteralExpression();
			element.setValue(BigInteger.valueOf(i));
			enumerableExpressionValues.add(element);
		}
		
		return enumerableExpressionValues;
	}
	//TODO enumerationLiteral???
	
	//Evaluate ReferenceExpression or IntegerLiteralExpression to Integer
	protected def dispatch int evaluateReferenceOrIntegerLiteralToInteger(ReferenceExpression expression){
		var declaration = expression.declaration;
		return declaration.evaluateReferenceToInteger;
	}
	protected def dispatch int evaluateReferenceOrIntegerLiteralToInteger(IntegerLiteralExpression expression){
		return expression.value.intValue;
	}
	protected def dispatch int evaluateReferenceToInteger(ValueDeclaration declaration){
		return declaration.evaluateValueDeclarationToInteger;
	}
	protected def dispatch int evaluateReferenceToInteger(FunctionDeclaration declaration){
		throw new Exception	//TODO specify exception type
	}
	protected def dispatch int evaluateReferenceToInteger(TypeDeclaration declaration){
		throw new Exception	//TODO specify exception type
	}
	protected def dispatch int evaluateValueDeclarationToInteger(InitializableElement declaration){
		var expression = declaration.expression;
		var value = expression.evaluateExpressionToInteger;
		return value;
	}
	protected def dispatch int evaluateValueDeclarationToInteger(ParameterDeclaration declaration){
		//TODO implement
		return 0;
	}
	protected def dispatch int evaluateValueDeclarationToInteger(FieldDeclaration declaration){
		//TODO implement
		return 0;
	}
	protected def dispatch int evaluateExpressionToInteger(ReferenceExpression expression){
		return expression.evaluateReferenceOrIntegerLiteralToInteger;
	}
	protected def dispatch int evaluateExpressionToInteger(EnumerableExpression expression){
		throw new Exception	//TODO specify exception type
	}
	protected def dispatch int evaluateExpressionToInteger(Expression expression){
		//TODO implement for simple expression (interpreter :) )
		return 0;
	}
	

//	public def List<Expression> getEnumerableElements(EnumerableExpression enumerableExpression){
//		var enumerableElements = new ArrayList<Expression>();
//		if(enumerableExpression instanceof ArrayLiteralExpression){
//			//TODO
//			var arrayLiteralExpression = enumerableExpression as ArrayLiteralExpression; 
//			for(operand : arrayLiteralExpression.operands){
//				if(operand instanceof EnumerableExpression){	//if itself enumerable
//					var enumerableOperand = operand as EnumerableExpression;
//					var innerEnumerableElements = getEnumerableElements(enumerableOperand);
//					enumerableElements.addAll(innerEnumerableElements);
//				}else if(operand instanceof ReferenceExpression){	//if reference 
//					var referenceOperand = operand as ReferenceExpression;
//					var innerEnumerableElements = solveReferenceExpression(referenceOperand);
//					enumerableElements.addAll(innerEnumerableElements);
//				}else{	
//					enumerableElements.add(operand);
//				}
//			}
//		}else if(enumerableExpression instanceof EnumerationLiteralExpression){
//			//rossz
//		}else if(enumerableExpression instanceof IntegerRangeLiteralExpression){
//			//bonyi
//		}
//		return enumerableElements;
//	}
//	
//	public def List<Expression> solveReferenceExpression(ReferenceExpression ref){
//		var enumerableElements = new ArrayList<Expression>();
//		if(ref.declaration instanceof InitializableElement){
//			var referenceOperandDeclaration = ref.declaration as InitializableElement;
//			if(referenceOperandDeclaration.expression instanceof EnumerableExpression){//to enumerable					
//				var innerEnumerableExpression = referenceOperandDeclaration.expression as EnumerableExpression;
//				var innerEnumerableElements = getEnumerableElements(innerEnumerableExpression);
//				enumerableElements.addAll(innerEnumerableElements);
//			}else if(referenceOperandDeclaration.expression instanceof ReferenceExpression){//to normal
//				var innerReferenceExpression = referenceOperandDeclaration.expression as ReferenceExpression;
//				var innerEnumerableElements = solveReferenceExpression(innerReferenceExpression);
//				enumerableElements.addAll(innerEnumerableElements);//FIXME reference to reference?	
//			}
//		}else{
//			//TODO Handle Type and Function declarations
//		}
//		return enumerableElements;
//	}

	
	
	
}