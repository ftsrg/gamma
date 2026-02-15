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
package hu.bme.mit.gamma.scxml.transformation.parse;

import static java.util.Map.entry;

import java.io.StringReader;
import java.util.Map;
import java.util.function.Function;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.CrossReference;
import org.eclipse.xtext.nodemodel.ICompositeNode;
import org.eclipse.xtext.nodemodel.ILeafNode;
import org.eclipse.xtext.parser.IParseResult;

import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.OpaqueExpression;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.language.parser.StatechartExpressionLanguageParserAndLinker;

public class ScxmlGammaExpressionLanguageParser extends StatechartExpressionLanguageParserAndLinker {

	private static final Map<String, String> defaultScxmlPreprocessRules = Map.ofEntries(
			entry("!", "not"),
			entry("&&", "and"),
			entry("||", "or"));

	public Expression preprocessAndParse(String expression, Function<ILeafNode, ? extends EObject> scope) {
		return super.preprocessAndParse2(expression, scope, defaultScxmlPreprocessRules);
	}

	@Override
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
				System.out.println("ScxmlGammaExpressionParser: " + node.getText());
				if (grammarElement instanceof CrossReference) {
					EObject reference = node.getSemanticElement();

					String text = node.getText();
					// TODO grammarElement.type.classifier
					EObject parsedReference = scope.apply(node);
					if (parsedReference == null) {
						parsedReference = util.createOpaqueExpression(text);
					}

					// TODO
					// grammarelement.eContainer().getFeature() // e.g. "port"
					// parsedReference.eClass().getEStructuralFeature(featureName);

					EObject container = reference.eContainer();

					/*
					 * TODO Save EObject (scope) list, define matchable sequences e.g.
					 * port.event::param, port.event, port.any, variable, parameter etc. If match,
					 * then resolve with correct types
					 * 
					 * TODO Implement scoping, inject scope provider
					 */

					/// Direct reference expressions (variable, parameter)
					if (reference instanceof DirectReferenceExpression ref) {
						if (parsedReference instanceof DirectReferenceExpression ref2) {
							ref.setDeclaration(ref2.getDeclaration());
						}
					}
					///

					/// Event parameter reference expressions
					if (reference instanceof EventParameterReferenceExpression ref) {
						if (parsedReference instanceof Port port) {
							ref.setPort(port);
						}
						if (parsedReference instanceof Event event) {
							ref.setEvent(event);
						}
						if (parsedReference instanceof ParameterDeclaration eventParameter) {
							ref.setParameter(eventParameter);
						}
					}
					///

					/* TODO Fix commented section if needed
					 * if (container == null) { // Replace would not work as it is a single element
					 * return (Expression) parsedReference; }
					 */

					/// Unparsable enum literals (e.g., state references)
					if (parsedReference instanceof OpaqueExpression) { // I.e., 'parsedReference' was 'null'
						if (reference instanceof TypeReference && container instanceof EnumerationLiteralExpression) {
							typeReferenceId = text;
							continue; // Next node is the literal id
						} else if (reference instanceof EnumerationLiteralExpression) {
							String enumId = typeReferenceId + "::" + text;
							parsedReference = util.createOpaqueExpression(enumId);
							
							if (container == null) {
								// Replace would not work as it is a single element
								return (Expression) parsedReference;
							} else {
								ecoreUtil.replace(parsedReference, reference);
							}
						}
					}
					///

					// TODO Fix commented section if needed
					// ecoreUtil.replace(parsedReference, reference);
				}
			}

			return (Expression) result.getRootASTElement();
		} catch (Exception e) {
			return util.createOpaqueExpression(expression);
		}
	}

}
