/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
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
import hu.bme.mit.gamma.util.Triple;
import uppaal.NTA;
import uppaal.core.NamedElement;
import uppaal.declarations.ClockVariableDeclaration;
import uppaal.declarations.Declaration;
import uppaal.declarations.GlobalDeclarations;
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
import uppaal.types.BuiltInType;
import uppaal.types.PredefinedType;
import uppaal.types.Type;
import uppaal.types.TypeDefinition;
import uppaal.types.TypeReference;

public class UppaalModelDerivedFeatures {

	protected static final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected static final JavaUtil javaUtil = JavaUtil.INSTANCE;
	
	//
	
	public static boolean isGlobal(Declaration declaration) {
		NTA nta = ecoreUtil.getContainerOfType(declaration, NTA.class);
		GlobalDeclarations globalDeclarations = nta.getGlobalDeclarations();
		List<Declaration> declarations = globalDeclarations.getDeclaration();
		
		return declarations.contains(declaration);
	}
	
	public static List<VariableDeclaration> getGlobalVariableDeclarations(NTA nta) {
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
	
	public static boolean isClock(NamedElement element) {
		if (element instanceof Variable variable) {
			VariableContainer container = variable.getContainer();
			return isClock(container);
		}
		return false;
	}
	
	public static boolean isClock(VariableContainer container) {
		TypeDefinition type = container.getTypeDefinition();
		if (type instanceof TypeReference typeReference) {
			Type referredType = typeReference.getReferredType();
			if (referredType instanceof PredefinedType predefinedType) {
				return predefinedType.getType() == BuiltInType.CLOCK;
			}
		}
		return container instanceof ClockVariableDeclaration;
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
		
		Triple<Map<Variable, List<LiteralExpression>>, Map<Variable, List<Variable>>,
			Set<Variable>> variableAssignmentGroups = getVariableAssignmentGroups(nta);
		
		Map<Variable, List<LiteralExpression>> integerVariableAssignments = variableAssignmentGroups.getFirst();
		Map<Variable, List<Variable>> variableVariableAssignments = variableAssignmentGroups.getSecond();
		Set<Variable> notIntegerLiteralVariables = variableAssignmentGroups.getThird();
		
		Map<Variable, List<LiteralExpression>> integerLiteralVariableAssignments =
				new HashMap<Variable, List<LiteralExpression>>(integerVariableAssignments);
		Set<Variable> integerLiteralVariables = integerLiteralVariableAssignments.keySet();
		Set<Variable> variableVariables = variableVariableAssignments.keySet();
		integerLiteralVariables.removeAll(variableVariables);
		integerLiteralVariables.removeAll(notIntegerLiteralVariables);
		// Every variable in this collection now has only integer value assignments
		
		// 1: Calculating precise domains based on these values
		Map<VariableContainer, Entry<Integer, Integer>> integerVariableMinMax = calculatePresiceCodomains(
				integerLiteralVariableAssignments, integerLiteralVariables);
		
		// 2: Extending min/max values for variables that need to hold low/large values
		// e.g., a := 70.000
		extendCodomainsForLiteralAssignments(integerVariableAssignments, integerVariableMinMax);
		
		// 3: Checking 'var := var2' assignments - note that this is done after the 'extension'
		extendCodomainsForVariableAssignments(integerVariableAssignments, variableVariableAssignments,
				notIntegerLiteralVariables, variableVariables, integerVariableMinMax);
		
		return integerVariableMinMax;
	}

	public static void extendCodomainsForVariableAssignments(
			Map<Variable, List<LiteralExpression>> integerVariableAssignments,
			Map<Variable, List<Variable>> variableVariableAssignments, Set<Variable> notIntegerLiteralVariables,
			Set<Variable> variableVariables, Map<VariableContainer, Entry<Integer, Integer>> integerVariableMinMax) {
		variableVariables.removeAll(notIntegerLiteralVariables);
		// Every variable in this collection now has only integer value assignments
		// or 'var := var2' assignments
		int size = 0;
		while (size != variableVariableAssignments.size()) {
			size = variableVariableAssignments.size(); // While we can remove vars from here
			
			for (Variable assignedVariable :
						new ArrayList<Variable>(variableVariables)) {
				List<Variable> rhsVariables = variableVariableAssignments.get(assignedVariable);
				if (rhsVariables.stream()
						.allMatch(it ->
							integerVariableMinMax.keySet().contains(it.getContainer()))) {
					List<Integer> mins = new ArrayList<Integer>();
					List<Integer> maxs = new ArrayList<Integer>();
					
					// Rhs variables
					for (Variable rhsVariable : rhsVariables) {
						VariableContainer container = rhsVariable.getContainer();
						Entry<Integer, Integer> minMax = integerVariableMinMax.get(container);
						mins.add(minMax.getKey());
						maxs.add(minMax.getValue());
					}
					
					// Rhs integer literals
					if (integerVariableAssignments.containsKey(assignedVariable)) {
						for (LiteralExpression integerLiteral :
								integerVariableAssignments.get(assignedVariable)) {
							mins.add(
									toInteger(integerLiteral));
							maxs.add(
									toInteger(integerLiteral));
						}
					}
					
					int min = mins.stream()
							.min((o1, o2) -> o1.compareTo(o2)).get();
					int max = maxs.stream()
							.max((o1, o2) -> o1.compareTo(o2)).get();
					
					// Now the codomain of the assigned variable is "known"
					variableVariables.remove(assignedVariable);
					// So we move it to the other map
					VariableContainer container = assignedVariable.getContainer();
					integerVariableMinMax.put(container,
							new SimpleEntry<Integer, Integer>(min, max));
				}
			}
		}
	}

	public static void extendCodomainsForLiteralAssignments(Map<Variable, List<LiteralExpression>> integerVariableAssignments,
			Map<VariableContainer, Entry<Integer, Integer>> integerVariableMinMax) {
		List<Variable> additionalIntegerVariables =
				new ArrayList<Variable>(integerVariableAssignments.keySet());
		additionalIntegerVariables.removeIf(
				it -> integerVariableMinMax.containsKey(it.getContainer()));
		for (Variable integerVariable : additionalIntegerVariables) {
			List<LiteralExpression> integerLiterals =
					integerVariableAssignments.get(integerVariable);
			Integer min = integerLiterals.stream()
					.map(it -> toInteger(it))
					.min((o1, o2) -> o1.compareTo(o2)).get();
			Integer max = integerLiterals.stream()
					.map(it -> toInteger(it))
					.max((o1, o2) -> o1.compareTo(o2)).get();
			
			VariableContainer container = integerVariable.getContainer();
			min = Integer.min(Short.MIN_VALUE, min);
			max = Integer.max(Short.MAX_VALUE, max);
			
			if (min < Short.MIN_VALUE || Short.MAX_VALUE < max) {
				integerVariableMinMax.put(container,
						new SimpleEntry<Integer, Integer>(min, max));
			}
		}
	}

	public static Map<VariableContainer, Entry<Integer, Integer>> calculatePresiceCodomains(
			Map<Variable, List<LiteralExpression>> integerLiteralVariableAssignments,
			Set<Variable> integerLiteralVariables) {
		Map<VariableContainer, Entry<Integer, Integer>> integerVariableMinMax =
				new HashMap<VariableContainer, Entry<Integer, Integer>>();
		for (Variable integerLiteralVariable : integerLiteralVariables) {
			List<LiteralExpression> integerLiterals =
					integerLiteralVariableAssignments.get(integerLiteralVariable);
			// Mapping into integers and computing min and max
			Integer min = integerLiterals.stream()
					.map(it -> toInteger(it))
					.min((o1, o2) -> o1.compareTo(o2)).get();
			Integer max = integerLiterals.stream()
					.map(it -> toInteger(it))
					.max((o1, o2) -> o1.compareTo(o2)).get();
			
			VariableContainer container = integerLiteralVariable.getContainer();
			integerVariableMinMax.put(container,
					new SimpleEntry<Integer, Integer>(min, max));
		}
		return integerVariableMinMax;
	}
	
	public static Triple<
			Map<Variable, List<LiteralExpression>>,	Map<Variable, List<Variable>>, Set<Variable>>
				getVariableAssignmentGroups(NTA nta) {
		List<AssignmentExpression> assignments = ecoreUtil.getAllContentsOfType(
				nta, AssignmentExpression.class);
		
		Map<Variable, List<LiteralExpression>> integerVariableAssignments =
				new HashMap<Variable, List<LiteralExpression>>();
		Map<Variable, List<Variable>> variableVariableAssignments =
				new HashMap<Variable, List<Variable>>();
		Set<Variable> notIntegerLiteralVariables = new HashSet<Variable>();
		for (AssignmentExpression assignment : assignments) {
			Expression firstExpr = assignment.getFirstExpr();
			if (firstExpr instanceof IdentifierExpression identifierExpression) {
				NamedElement element = identifierExpression.getIdentifier();
				if (element instanceof Variable variable) {
					AssignmentOperator operator = assignment.getOperator();
					Expression secondExpr = assignment.getSecondExpr();
					if (UppaalModelDerivedFeatures.isClock(variable)) {
						// Clock variable, we do not mess with it
						notIntegerLiteralVariables.add(variable);
					}
					else if (operator == AssignmentOperator.EQUAL &&
							secondExpr instanceof LiteralExpression literalExpression &&
							isIntegerLiteral(literalExpression)) {
						List<LiteralExpression> integerLiterals =
								javaUtil.getOrCreateList(integerVariableAssignments, variable);
						integerLiterals.add(literalExpression);
					}
					// TODO if secondExpr is evaluable...
					else if (operator == AssignmentOperator.EQUAL &&
								secondExpr instanceof IdentifierExpression rhsIdentifierExpression) {
						NamedElement rhsNamedElement = rhsIdentifierExpression.getIdentifier();
						if (rhsNamedElement instanceof Variable rhsVariable) {
							List<Variable> variables = javaUtil
									.getOrCreateList(variableVariableAssignments, variable);
							variables.add(rhsVariable);
						}
					}
					else {
						// Not a simple '=' assignment or not an 'integer literal' or 'var = var2'
						notIntegerLiteralVariables.add(variable);
					}
				}
			}
		}
		
		// Variable initialization are transformed into assignments, so they are already handled
		
		return new Triple<Map<Variable, List<LiteralExpression>>, Map<Variable, List<Variable>>, Set<Variable>>(
				integerVariableAssignments, variableVariableAssignments, notIntegerLiteralVariables);
	}
	
}
