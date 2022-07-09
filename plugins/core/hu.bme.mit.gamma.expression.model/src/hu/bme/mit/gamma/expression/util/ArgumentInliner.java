/********************************************************************************
 * Copyright (c) 2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.expression.util;

import java.util.List;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression;
import hu.bme.mit.gamma.expression.model.FunctionDeclaration;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ArgumentInliner {
	// Singleton
	public static final ArgumentInliner INSTANCE = new ArgumentInliner();
	protected ArgumentInliner() {}
	//

	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	
	//
	
	public void inlineParamaters(List<? extends ParameterDeclaration> parameters,
			List<? extends Expression> arguments) {
		for (int i = 0; i < arguments.size(); i++) {
			ParameterDeclaration parameter = parameters.get(i);
			Expression argument = arguments.get(i);
			EObject root = parameter.eContainer();
			// Precondition: here parameters can be referenced only via DirectReferenceExpressions
			for (DirectReferenceExpression reference : ecoreUtil.getSelfAndAllContentsOfType(
					root, DirectReferenceExpression.class).stream()
						.filter(it -> it.getDeclaration() == parameter)
						.collect(Collectors.toList())) {
				Expression clonedArgument = ecoreUtil.clone(argument);
				ecoreUtil.replace(clonedArgument, reference);
			}
		}
	}
	
	//
	
	public Expression createInlinedExpression(Expression root,
			List<? extends ParameterDeclaration> parameters, List<? extends Expression> arguments) {
		Expression result = ecoreUtil.clone(root);
		
		for (int i = 0; i < arguments.size(); i++) {
			Expression argument = arguments.get(i);
			ParameterDeclaration parameter = parameters.get(i);
			// Precondition: here parameters can be referenced only via DirectReferenceExpressions
			for (DirectReferenceExpression directReference : ecoreUtil.getSelfAndAllContentsOfType(
					result, DirectReferenceExpression.class).stream()
					.filter(it -> it.getDeclaration() == parameter)
					.collect(Collectors.toList())) {
				Expression clonedArgument = ecoreUtil.clone(argument);
				if (directReference == result) {
					return clonedArgument; // A single direct reference to the parameter
				}
				else {
					ecoreUtil.replace(clonedArgument, directReference);
				}
			}
		}
		
		return result;
	}
	
	public Expression createInlinedLambaExpression(FunctionAccessExpression expression) {
		DirectReferenceExpression operand = (DirectReferenceExpression) expression.getOperand();
		Declaration lamdaDeclaration = operand.getDeclaration();
		FunctionDeclaration function = (FunctionDeclaration) lamdaDeclaration;
		
		List<Expression> arguments = expression.getArguments();
		List<ParameterDeclaration> parameters = function.getParameterDeclarations();
		if (arguments.size() != parameters.size()) {
			throw new IllegalArgumentException("Incorrect number of arguments");
		}
		
		Expression clonedBody = ExpressionModelDerivedFeatures.getLambdaExpression(function);
		// createInlinedExpression clones the body
		return createInlinedExpression(clonedBody, parameters, arguments);
	}
	
}
