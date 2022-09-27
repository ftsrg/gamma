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
package hu.bme.mit.gamma.expression.derivedfeatures;

import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition;
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition;
import hu.bme.mit.gamma.expression.model.ClockVariableDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.ConstantDeclaration;
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DefaultExpression;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.ElseExpression;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.EnvironmentResettableVariableDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.ExpressionPackage;
import hu.bme.mit.gamma.expression.model.FieldDeclaration;
import hu.bme.mit.gamma.expression.model.FinalVariableDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.FunctionDeclaration;
import hu.bme.mit.gamma.expression.model.IntegerRangeLiteralExpression;
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.expression.model.LambdaDeclaration;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.ParametricElement;
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.ResettableVariableDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.ScheduledClockVariableDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.TransientVariableDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.model.VariableDeclarationAnnotation;
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator;
import hu.bme.mit.gamma.expression.util.ExpressionUtil;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.util.JavaUtil;

public class ExpressionModelDerivedFeatures {
	
	protected static final ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE;
	protected static final ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE;
	protected static final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected static final JavaUtil javaUtil = JavaUtil.INSTANCE;
	protected static final ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE;
	
	//
	
	public static boolean isContainedByPackage(EObject object) {
		EObject root = ecoreUtil.getRoot(object);
		return root instanceof ExpressionPackage;
	}
	
	//
	
	public static Expression getLeft(IntegerRangeLiteralExpression expression, boolean isInclusive) {
		Expression leftOperand = expression.getLeftOperand();
		boolean isLeftInclusive = expression.isLeftInclusive();
		if (isInclusive == isLeftInclusive) {
			return leftOperand;
		}
		if (isLeftInclusive) { // Literal is inclusive, but caller wants exclusive
			return expressionUtil.wrapIntoSubtract(
					ecoreUtil.clone(leftOperand), 1);
		}
		return expressionUtil.wrapIntoAdd(
				ecoreUtil.clone(leftOperand), 1); // Literal is exclusive, but caller wants inclusive
	}
	
	public static Expression getRight(IntegerRangeLiteralExpression expression, boolean isInclusive) {
		Expression rightOperand = expression.getRightOperand();
		boolean isRightInclusive = expression.isRightInclusive();
		if (isInclusive == isRightInclusive) {
			return rightOperand;
		}
		if (isRightInclusive) { // Literal is inclusive, but caller wants exclusive
			return expressionUtil.wrapIntoAdd(
					ecoreUtil.clone(rightOperand), 1);
		}
		return expressionUtil.wrapIntoSubtract(
				ecoreUtil.clone(rightOperand), 1); // Literal is exclusive, but caller wants inclusive
	}
	
	public static boolean isTransient(VariableDeclaration variable) {
		// Can be reset as the last action of the component (before entering a stable state)
		return hasAnnotation(variable, TransientVariableDeclarationAnnotation.class);
	}
	
	public static boolean isResettable(VariableDeclaration variable) {
		// Can be reset as the first action of the component (after leaving a stable state)
		return hasAnnotation(variable, ResettableVariableDeclarationAnnotation.class);
	}
	
	public static boolean isEnvironmentResettable(VariableDeclaration variable) {
		// Can be reset by the environment
		return hasAnnotation(variable, EnvironmentResettableVariableDeclarationAnnotation.class);
	}
	
	public static boolean isFinal(VariableDeclaration variable) {
		return hasAnnotation(variable, FinalVariableDeclarationAnnotation.class);
	}
	
	public static boolean isClock(VariableDeclaration variable) {
		return hasAnnotation(variable, ClockVariableDeclarationAnnotation.class);
	}
	
	public static boolean isScheduledClock(VariableDeclaration variable) {
		return hasAnnotation(variable, ScheduledClockVariableDeclarationAnnotation.class);
	}
	
	public static boolean hasAnnotation(VariableDeclaration variable,
			Class<? extends VariableDeclarationAnnotation> annotation) {
		return variable.getAnnotations().stream().anyMatch(it -> annotation.isInstance(it));
	}
	
	public static List<VariableDeclaration> filterVariablesByAnnotation(
			Collection<? extends VariableDeclaration> variables,
			Class<? extends VariableDeclarationAnnotation> annotation) {
		return variables.stream().filter(it -> hasAnnotation(it, annotation))
				.collect(Collectors.toList());
	}
	
	// Imports
	
	public static Set<ExpressionPackage> getImportableDeclarationPackages(EObject object) {
		Set<ExpressionPackage> importablePackages = new LinkedHashSet<ExpressionPackage>();
		
		for (DirectReferenceExpression reference :
				ecoreUtil.getSelfAndAllContentsOfType(object, DirectReferenceExpression.class)) {
			Declaration declaration = reference.getDeclaration();
			if (declaration instanceof FunctionDeclaration ||
					declaration instanceof TypeDeclaration ||
					declaration instanceof ConstantDeclaration) {
				ExpressionPackage constantPackage = ecoreUtil.getContainerOfType(
						declaration, ExpressionPackage.class);
				importablePackages.add(constantPackage);
			}
		}
		
		return importablePackages;
	}
	
	// Types
	
	public static boolean isPrimitive(Type type) {
		TypeDefinition typeDefinition = getTypeDefinition(type);
		return typeDefinition instanceof BooleanTypeDefinition || typeDefinition instanceof IntegerTypeDefinition ||
				typeDefinition instanceof DecimalTypeDefinition || typeDefinition instanceof RationalTypeDefinition;
	}
	
	public static boolean isNative(Type type) {
		TypeDefinition typeDefinition = getTypeDefinition(type);
		return isPrimitive(typeDefinition) || typeDefinition instanceof EnumerationTypeDefinition;
	}
	
	public static boolean isArray(Type type) {
		TypeDefinition typeDefinition = getTypeDefinition(type);
		return typeDefinition instanceof ArrayTypeDefinition;
	}
	
	public static boolean isOneCapacityArray(Type type) {
		TypeDefinition typeDefinition = getTypeDefinition(type);
		if (typeDefinition instanceof ArrayTypeDefinition) {
			ArrayTypeDefinition arrayTypeDefinition = (ArrayTypeDefinition) typeDefinition;
			Expression size = arrayTypeDefinition.getSize();
			int evaluatedSize = evaluator.evaluate(size);
			return evaluatedSize == 1;
		}
		return false;
	}
	
	public static boolean isRecord(Type type) {
		TypeDefinition typeDefinition = getTypeDefinition(type);
		return typeDefinition instanceof RecordTypeDefinition;
	}
	
	public static boolean isComplex(Type type) {
		TypeDefinition typeDefinition = getTypeDefinition(type);
		return isRecord(typeDefinition) || isArray(typeDefinition);
	}
	
	public static boolean isElseOrDefault(Expression expression) {
		return expression instanceof ElseExpression || expression instanceof DefaultExpression;
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
			return getTypeDefinition(typeReference.getReference().getType());
		}
		throw new IllegalArgumentException("Not known type: " + type);
	}
	
	public static TypeDeclaration getTypeDeclaration(Type type) {
		TypeDeclaration declaration = ecoreUtil.getContainerOfType(type, TypeDeclaration.class);
		if (declaration == null) {
			throw new IllegalArgumentException("No type declaration: " + type);
		}
		return declaration;
	}
	
	public static TypeDeclaration getTypeDeclaration(EnumerationLiteralDefinition literal) {
		TypeDeclaration declaration = ecoreUtil.getContainerOfType(literal, TypeDeclaration.class);
		if (declaration == null) {
			throw new IllegalArgumentException("No type declaration: " + literal);
		}
		return declaration;
	}
	
	public static Type getArrayElementType(Declaration declaration) {
		Type type = declaration.getType();
		return getArrayElementType(type);
	}
	
	public static Type getArrayElementType(Type type) {
		TypeDefinition typeDefinition = getTypeDefinition(type);
		if (typeDefinition instanceof ArrayTypeDefinition) {
			ArrayTypeDefinition arrayTypeDefinition = (ArrayTypeDefinition) typeDefinition;
			return arrayTypeDefinition.getElementType();
		}
		throw new IllegalArgumentException("Not array type: " + type);
	}
	
	// Type references
	
	public static boolean refersToAnAlias(TypeReference typeReference) {
		TypeDeclaration typeDeclaration = typeReference.getReference();
		Type type = typeDeclaration.getType();
		return type instanceof TypeReference;
	}
	
	public static TypeReference getFinalTypeReference(TypeReference typeReference) {
		if (refersToAnAlias(typeReference)) {
			TypeDeclaration typeDeclaration = typeReference.getReference();
			Type type = typeDeclaration.getType();
			TypeReference aliasReference = (TypeReference) type;
			return getFinalTypeReference(aliasReference);
		}
		return typeReference;
	}
	
	// Functions
	
	public static Expression getLambdaExpression(FunctionDeclaration function) {
		if (function instanceof LambdaDeclaration) {
			LambdaDeclaration lambda = (LambdaDeclaration) function;
			return lambda.getExpression();
		}
		// ProcedureDeclaration
		List<EObject> contents = new ArrayList<EObject>(
				function.eContents());
		contents.remove(
				function.getType());
		contents.removeAll(
				function.getParameterDeclarations());
		EObject block = javaUtil.getOnlyElement(contents);
		EObject returnStatement = javaUtil.getOnlyElement(block.eContents());
		EObject expression = javaUtil.getOnlyElement(returnStatement.eContents());
		return (Expression) expression;
	}
	
	//
	
	public static Expression getDefaultExpression(Declaration declaration) {
		Type type = declaration.getType();
		return getDefaultExpression(type);
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
	
	public static List<TypeDeclaration> getSelfAndAllTypeDeclarations(Type type) {
		List<TypeDeclaration> typeDeclarations = getAllTypeDeclarations(type);
		if (type instanceof TypeDefinition) {
			TypeDeclaration typeDeclaration = ecoreUtil.getContainerOfType(type, TypeDeclaration.class);
			typeDeclarations.add(0, typeDeclaration);
		}
		return typeDeclarations;
	}
	
	public static List<TypeDeclaration> getAllTypeDeclarations(Type type) {
		List<TypeDeclaration> typeDeclarations = new ArrayList<TypeDeclaration>();
		if (type instanceof TypeReference) {
			TypeReference typeReference = (TypeReference) type;
			TypeDeclaration typeDeclaration = typeReference.getReference();
			typeDeclarations.add(typeDeclaration);
			Type typeDefinition = typeDeclaration.getType();
			if (typeDefinition instanceof RecordTypeDefinition) {
				RecordTypeDefinition subrecord = (RecordTypeDefinition) typeDefinition;
				for (FieldDeclaration field : subrecord.getFieldDeclarations()) {
					Type fieldType = field.getType();
					typeDeclarations.addAll(getAllTypeDeclarations(fieldType));
				}
			}
			else if (typeDefinition instanceof ArrayTypeDefinition) {
				ArrayTypeDefinition array = (ArrayTypeDefinition) typeDefinition;
				Type elementType = array.getElementType();
				typeDeclarations.addAll(getAllTypeDeclarations(elementType));
			}
		}
		return typeDeclarations;
	}
	
}