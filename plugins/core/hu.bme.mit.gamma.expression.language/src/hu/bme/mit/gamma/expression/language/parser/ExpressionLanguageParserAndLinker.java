/********************************************************************************
 * Copyright (c) 2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.expression.language.parser;

import java.io.StringReader;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.function.Function;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.CrossReference;
import org.eclipse.xtext.nodemodel.ICompositeNode;
import org.eclipse.xtext.nodemodel.INode;
import org.eclipse.xtext.parser.IParseResult;

import com.google.inject.Injector;

import hu.bme.mit.gamma.expression.language.ExpressionLanguageStandaloneSetup;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionUtil;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ExpressionLanguageParserAndLinker {
	//
	protected final Injector injector = new ExpressionLanguageStandaloneSetup().createInjectorAndDoEMFRegistration();
	protected final ExpressionUtil util = ExpressionUtil.INSTANCE;
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE;
	//

	// TODO preprocessing
	
	public Expression parse(String expression) {
		return parse(expression, Map.of());
	}
	
	public Expression parse(String expression, Map<String, VariableDeclaration> scope) {
		return parse(expression,
			new Function<String, VariableDeclaration>() {
				@Override
				public VariableDeclaration apply(String t) {
					return scope.get(t);
				}
			}
		);
	}
	
	public Expression parse(String expression, Function<String, ? extends Declaration> scope) {
		CustomExpressionLanguageParser parser = injector.getInstance(CustomExpressionLanguageParser.class);
		StringReader reader = new StringReader(expression);
		IParseResult result = parser.parse(reader);

		if (result.hasSyntaxErrors()) {
			return util.createOpaqueExpression(expression);
		}

		try {
			ICompositeNode rootNode = result.getRootNode();
			for (INode node : rootNode.getLeafNodes()) {
				EObject grammarElement = node.getGrammarElement();
				if (grammarElement instanceof CrossReference) {
					DirectReferenceExpression reference = (DirectReferenceExpression) node.getSemanticElement();

					String text = node.getText();
					Declaration declaration = scope.apply(text);
					if (declaration != null) {
						reference.setDeclaration(declaration);
					}
					else {
						Expression opaque = util.createOpaqueExpression(text);
						ecoreUtil.replace(opaque, reference);
//						throw new NoSuchElementException();
					}
				}
			}
			return (Expression) result.getRootASTElement();
		} catch (NoSuchElementException e) {}

		return util.createOpaqueExpression(expression);
	}
	
}