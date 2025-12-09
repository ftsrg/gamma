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
	protected final AbstractAntlrParser parser;
	//
	protected final ExpressionUtil util = ExpressionUtil.INSTANCE;
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final JavaUtil javaUtil = JavaUtil.INSTANCE;
	protected final ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE;
	//
	
	public ExpressionLanguageParserAndLinker() {
		Injector injector = getInjector();
		Class<? extends AbstractAntlrParser> parserClass = getParserClass();
		this.parser = injector.getInstance(parserClass);
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
		return preprocessAndParse2(expression, wrapScope(scope), expressionPreprocess);
	}
	
	public Expression preprocessAndParse(String expression,
			Function<String, ? extends EObject> scope, Map<String, String> expressionPreprocess) {
		return preprocessAndParse2(expression, wrapScope(scope), expressionPreprocess);
	}
	
	public Expression preprocessAndParse2(String expression,
			Function<ILeafNode, ? extends EObject> scope, Map<String, String> expressionPreprocess) {
		String preprocessedExpression = preprocess(expression, expressionPreprocess);
		return parse2(preprocessedExpression, scope);
	}
	
	//
	
	public Expression parse(String expression) {
		return parse(expression, Map.of());
	}
	
	public Expression parse(String expression, Map<String, ? extends EObject> scope) {
		return parse2(expression, wrapScope(scope));
	}
	
	public Expression parse(String expression, Function<String, ? extends EObject> scope) {
		return parse2(expression, wrapScope(scope));
	}
	
	public Expression parse2(String expression, Function<ILeafNode, ? extends EObject> scope) {
		String trimmedExpression = javaUtil.deparenthesize(expression);
		StringReader reader = new StringReader(trimmedExpression);
		
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
					EObject referenceContainer = node.getSemanticElement();

					String text = node.getText();
					EObject parsedObject = scope.apply(node);
					if (parsedObject == null) {
						parsedObject = util.createOpaqueExpression(text);
					}
					
					EObject grandparentContainer = referenceContainer.eContainer();
					if (grandparentContainer == null) {
						// Replace would not work as it is a single element
						return (Expression) parsedObject;
					}
					
					/// Unparsable enum literals (e.g., state references)
					if (parsedObject instanceof OpaqueExpression) { // I.e., 'parsedReference' was 'null'
						if (referenceContainer instanceof TypeReference && grandparentContainer instanceof EnumerationLiteralExpression) {
							typeReferenceId = text;
							continue; // Next node is the literal id
						}
						else if (referenceContainer instanceof EnumerationLiteralExpression) {
							String enumId = typeReferenceId + "::" + text;
							parsedObject = util.createOpaqueExpression(enumId);
						}
					}
					///
					
					ecoreUtil.replace(parsedObject, referenceContainer);
				}
			}
			
			return (Expression) result.getRootASTElement();
		} catch (Exception e) {
			return util.createOpaqueExpression(expression);
		}
	}
	
	//
	
	protected Function<ILeafNode, EObject> wrapScope(Map<String, ? extends EObject> scope) {
		return new Function<ILeafNode, EObject>() {
			@Override
			public EObject apply(ILeafNode node) {
				String id = node.getText();
				return scope.get(id);
			}
		};
	}
	
	protected Function<ILeafNode, EObject> wrapScope(Function<String, ? extends EObject> scope) {
		return new Function<ILeafNode, EObject>() {
			@Override
			public EObject apply(ILeafNode node) {
				String id = node.getText();
				return scope.apply(id);
			}
		};
	}
	
	//
	
	protected String preprocess(String expression, Map<String, String> preprocess) {
		String preprocessedExpression = expression;
		for (String key : preprocess.keySet()) {
			String value = preprocess.get(key);
			preprocessedExpression = preprocessedExpression.replace(key, value);
		}
		return preprocessedExpression;
	}
	
}