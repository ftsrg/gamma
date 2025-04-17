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
import java.util.function.Function;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.CrossReference;
import org.eclipse.xtext.nodemodel.ICompositeNode;
import org.eclipse.xtext.nodemodel.ILeafNode;
import org.eclipse.xtext.parser.IParseResult;
import org.eclipse.xtext.parser.antlr.AbstractAntlrParser;

import com.google.inject.Injector;

import hu.bme.mit.gamma.expression.language.ExpressionLanguageStandaloneSetup;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.OpaqueExpression;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.util.ExpressionUtil;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.util.JavaUtil;

public class ExpressionLanguageParserAndLinker {
	//
	protected final Injector injector;
	protected final ExpressionUtil util = ExpressionUtil.INSTANCE;
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final JavaUtil javaUtil = JavaUtil.INSTANCE;
	protected final ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE;
	//
	
	public ExpressionLanguageParserAndLinker() {
		injector = getInjector();
	}
	
	// Needs overriding in derived classes
	protected Injector getInjector() {
		return new ExpressionLanguageStandaloneSetup().createInjectorAndDoEMFRegistration();
	}
	
	// Needs overriding in derived classes
	protected Class<? extends AbstractAntlrParser> getParserClass() {
		return CustomExpressionLanguageParser.class;
	}
	
	//

	public Expression preprocessAndParse(String expression, Map<String, String> expressionPreprocess) {
		return preprocessAndParse(expression, Map.of(), expressionPreprocess);
	}
	
	public Expression preprocessAndParse(String expression,
			Map<String, ? extends EObject> scope, Map<String, String> expressionPreprocess) {
		return preprocessAndParse(expression, getScope(scope), expressionPreprocess);
	}
	
	public Expression preprocessAndParse(String expression,
			Function<String, ? extends EObject> scope, Map<String, String> expressionPreprocess) {
		String preprocessedExpression = preprocess(expression, expressionPreprocess);
		return parse(preprocessedExpression, scope);
	}
	
	//
	
	public Expression parse(String expression) {
		return parse(expression, Map.of());
	}
	
	public Expression parse(String expression, Map<String, ? extends EObject> scope) {
		return parse(expression, getScope(scope));
	}
	
	public Expression parse(String expression, Function<String, ? extends EObject> scope) {
		String trimmedExpression = javaUtil.deparenthesize(expression);
		StringReader reader = new StringReader(trimmedExpression);
		
		AbstractAntlrParser parser = injector.getInstance(getParserClass());
		IParseResult result = parser.parse(reader);

		if (result.hasSyntaxErrors()) {
			return util.createOpaqueExpression(expression);
		}

		try {
			String typeReferenceId = null;
			ICompositeNode rootNode = result.getRootNode();
			for (ILeafNode node : rootNode.getLeafNodes()) {
				EObject grammarElement = node.getGrammarElement();
				if (grammarElement instanceof CrossReference) {
					EObject reference = node.getSemanticElement();

					String text = node.getText();
					EObject parsedReference = scope.apply(text);
					if (parsedReference == null) {
						parsedReference = util.createOpaqueExpression(text);
					}
					
					EObject container = reference.eContainer();
					if (container == null) {
						// Replace would not work as it is a single element
						return (Expression) parsedReference;
					}
					
					/// Unparsable enum literals (e.g., state references)
					if (parsedReference instanceof OpaqueExpression) { // I.e., 'parsedReference' was 'null'
						if (reference instanceof TypeReference && container instanceof EnumerationLiteralExpression) {
							typeReferenceId = text;
							continue; // Next node is the literal id
						}
						else if (reference instanceof EnumerationLiteralExpression) {
							String enumId = typeReferenceId + "::" + text;
							parsedReference = util.createOpaqueExpression(enumId);
						}
					}
					///
					
					ecoreUtil.replace(parsedReference, reference);
				}
			}
			
			return (Expression) result.getRootASTElement();
		} catch (Exception e) {
			return util.createOpaqueExpression(expression);
		}
	}
	
	//
	
	protected Function<String, EObject> getScope(Map<String, ? extends EObject> scope) {
		return new Function<String, EObject>() {
			@Override
			public EObject apply(String id) {
				return scope.get(id);
			}
		};
	}
	
	protected String preprocess(String expression, Map<String, String> preprocess) {
		String preprocessedExpression = expression;
		for (String key : preprocess.keySet()) {
			String value = preprocess.get(key);
			preprocessedExpression = preprocessedExpression.replace(key, value);
		}
		return preprocessedExpression;
	}
	
}