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
package hu.bme.mit.gamma.expression.derivedfeatures;

import java.util.ArrayList;
import java.util.List;

import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition;
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.FieldDeclaration;
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.ParametricElement;
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.ResetableVariableDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.TransientVariableDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionUtil;
import hu.bme.mit.gamma.expression.util.FieldHierarchy;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ExpressionModelDerivedFeatures {
	
	protected static final ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE;
	protected static final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected static final ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE;

	public static boolean isTransient(VariableDeclaration variable) {
		return variable.getAnnotations().stream()
				.anyMatch(it -> it instanceof TransientVariableDeclarationAnnotation);
	}
	
	public static boolean isResetable(VariableDeclaration variable) {
		return variable.getAnnotations().stream()
				.anyMatch(it -> it instanceof ResetableVariableDeclarationAnnotation);
	}
	
	public static boolean isPrimitive(Type type) {
		if (type instanceof BooleanTypeDefinition || type instanceof IntegerTypeDefinition ||
				type instanceof DecimalTypeDefinition || type instanceof RationalTypeDefinition) {
			return true;
		}
		return false;
	}
	
	public static TypeDefinition getTypeDefinition(Declaration declaration) {
		Type type = declaration.getType();
		return getTypeDefinition(type);
	}
	
	public static TypeDefinition getTypeDefinition(Type type) {
		if (type instanceof TypeDefinition) {
			return (TypeDefinition) type;
		}
		if (type instanceof TypeReference) {
			TypeReference typeReference = (TypeReference) type;
			return (TypeDefinition) typeReference.getReference().getType();
		}
		throw new IllegalArgumentException("Not known type: " + type);
	}
	
	public static List<FieldHierarchy> getAllFieldHierarchies(RecordTypeDefinition record) {
		List<FieldHierarchy> fieldHierarchies = new ArrayList<FieldHierarchy>();
		for (FieldDeclaration field : record.getFieldDeclarations()) {
			Type type = field.getType();
			if (type instanceof RecordTypeDefinition) {
				RecordTypeDefinition subrecord = (RecordTypeDefinition) type;
				List<FieldHierarchy> hierarchies = getAllFieldHierarchies(subrecord);
				for (FieldHierarchy hierarchy : hierarchies) {
					hierarchy.prepend(field);
					fieldHierarchies.add(hierarchy);
				}
			}
			else {
				// Primitive type
				fieldHierarchies.add(new FieldHierarchy(field));
			}
		}
		return fieldHierarchies;
	}
	
	public static Expression getDefaultExpression(Type type) {
		return expressionUtil.getInitialValueOfType(type);
	}
	
	public static int getIndex(ParameterDeclaration parameter) {
		ParametricElement container = (ParametricElement) parameter.eContainer();
		return container.getParameterDeclarations().indexOf(parameter);
	}
	
	public static boolean isEvaluable(Expression expression) {
		return ecoreUtil.getSelfAndAllContentsOfType(
				expression, ReferenceExpression.class).isEmpty();
	}
	
}
