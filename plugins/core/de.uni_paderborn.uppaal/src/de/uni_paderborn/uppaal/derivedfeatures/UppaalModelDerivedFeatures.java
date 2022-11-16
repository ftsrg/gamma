/********************************************************************************
 * Copyright (c) 2018-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package de.uni_paderborn.uppaal.derivedfeatures;

import java.util.AbstractMap.SimpleEntry;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.util.JavaUtil;
import uppaal.NTA;
import uppaal.core.NamedElement;
import uppaal.declarations.Declaration;
import uppaal.declarations.Variable;
import uppaal.declarations.VariableContainer;
import uppaal.declarations.VariableDeclaration;
import uppaal.expressions.AssignmentExpression;
import uppaal.expressions.AssignmentOperator;
import uppaal.expressions.Expression;
import uppaal.expressions.IdentifierExpression;
import uppaal.expressions.LiteralExpression;
import uppaal.templates.Edge;
import uppaal.templates.Location;
import uppaal.templates.Template;

public class UppaalModelDerivedFeatures {

	protected static final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected static final JavaUtil javaUtil = JavaUtil.INSTANCE;
	
	//
	
	public static List<VariableDeclaration> getVariableDeclarations(NTA nta) {
		List<Declaration> declarations = nta.getGlobalDeclarations().getDeclaration();
		List<VariableDeclaration> variableDeclarations = javaUtil
				.filterIntoList(declarations, VariableDeclaration.class);
		return variableDeclarations;
	}
	
	public static List<Edge> getOutgoingEdges(Location location) {
		List<Edge> outgoingEdges = new ArrayList<Edge>();
		Template template = location.getParentTemplate();
		for (Edge edge : template.getEdge()) {
			if (edge.getSource() == location) {
				outgoingEdges.add(edge);
			}
		}
		return outgoingEdges;
	}
	
	public static List<Edge> getIncomingEdges(Location location) {
		List<Edge> incomingEdges = new ArrayList<Edge>();
		Template template = location.getParentTemplate();
		for (Edge edge : template.getEdge()) {
			if (edge.getTarget() == location) {
				incomingEdges.add(edge);
			}
		}
		return incomingEdges;
	}
	
	public static boolean isEmpty(Edge edge) {
		return edge.getSelection().isEmpty() && edge.getGuard() == null &&
			edge.getSynchronization() == null && edge.getUpdate().isEmpty();
	}
	
	public static boolean hasOnlyGuard(Edge edge) {
		return edge.getSelection().isEmpty() && edge.getGuard() != null &&
			edge.getSynchronization() == null && edge.getUpdate().isEmpty();
	}
	
	public static boolean hasOnlyUpdate(Edge edge) {
		return edge.getSelection().isEmpty() && edge.getGuard() == null &&
			edge.getSynchronization() == null && !edge.getUpdate().isEmpty();
	}
	
	public static Variable getOnlyVariable(VariableContainer container) {
		List<Variable> variable = container.getVariable();
		if (variable.size() != 1) {
			throw new IllegalArgumentException("Not one variable: " + variable);
		}
		return variable.get(0);
	}
	
	//
	
	public static boolean isBooleanLiteral(LiteralExpression literalExpression) {
		String text = literalExpression.getText();
		return text.equals("true") || text.equals("false");
	}
	
	public static boolean isIntegerLiteral(LiteralExpression literalExpression) {
		String text = literalExpression.getText();
		try {
			Integer.parseInt(text);
			return true;
		} catch (NumberFormatException e) {
			return false;
		}
	}
	
	public static boolean toBoolean(LiteralExpression literalExpression) {
		String text = literalExpression.getText();
		return text.equals("true");
	}
	
	public static Integer toInteger(LiteralExpression literalExpression) {
		String text = literalExpression.getText();
		return Integer.parseInt(text);
	}
	
	//
	
	public static Map<VariableContainer, Entry<Integer, Integer>>
			getIntegerVariableCodomains(NTA nta) {
		List<AssignmentExpression> assignments = ecoreUtil.getAllContentsOfType(
				nta, AssignmentExpression.class);
		
		Map<Variable, List<AssignmentExpression>> assignmentsToVariables =
				new HashMap<Variable, List<AssignmentExpression>>();
		Set<Variable> unhandledVariables = new HashSet<Variable>();
		for (AssignmentExpression assignment : assignments) {
			Expression firstExpr = assignment.getFirstExpr();
			if (firstExpr instanceof IdentifierExpression identifierExpression) {
				NamedElement element = identifierExpression.getIdentifier();
				if (element instanceof Variable variable) {
					AssignmentOperator operator = assignment.getOperator();
					Expression secondExpr = assignment.getSecondExpr();
					if (operator == AssignmentOperator.EQUAL &&
							secondExpr instanceof LiteralExpression literalExpression &&
							isIntegerLiteral(literalExpression)) {
						List<AssignmentExpression> assignmentExpressions =
								javaUtil.getOrCreateList(assignmentsToVariables, variable);
						assignmentExpressions.add(assignment);
					}
					else {
						// Not a simple '=' assignment or not an 'integer literal'
						unhandledVariables.add(variable);
					}
				}
			}
		}
		
		// Deleting unhandleable variables
		Set<Variable> handledVariables = assignmentsToVariables.keySet();
		handledVariables.removeAll(unhandledVariables);
		// Every variable that has only integer value assignments
		
		Map<VariableContainer, Entry<Integer, Integer>> variableMinMax =
				new HashMap<VariableContainer, Entry<Integer, Integer>>();
		for (Variable handledVariable : handledVariables) {
			List<AssignmentExpression> integerAssignments =
					assignmentsToVariables.get(handledVariable);
			// Maping into integers and computing min and max
			Integer max = integerAssignments.stream()
					.map(it -> toInteger((LiteralExpression) it.getSecondExpr()))
					.max((o1, o2) -> o1.compareTo(o2)).get();
			Integer min = integerAssignments.stream()
					.map(it -> toInteger((LiteralExpression) it.getSecondExpr()))
					.min((o1, o2) -> o1.compareTo(o2)).get();
			
			VariableContainer container = handledVariable.getContainer();
			variableMinMax.put(container, new SimpleEntry<Integer, Integer>(min, max));
		}
		
		// TODO check var := var2
		
		return variableMinMax;
	}
	
	
}
