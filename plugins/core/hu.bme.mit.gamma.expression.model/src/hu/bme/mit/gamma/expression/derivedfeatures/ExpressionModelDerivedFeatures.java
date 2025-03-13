/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
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

import hu.bme.mit.gamma.expression.model.AccessExpression;
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression;
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition;
import hu.bme.mit.gamma.expression.model.BinaryExpression;
import hu.bme.mit.gamma.expression.model.BooleanLiteralExpression;
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition;
import hu.bme.mit.gamma.expression.model.ClockVariableDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.ConstantDeclaration;
import hu.bme.mit.gamma.expression.model.DecimalLiteralExpression;
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DeclarationReferenceAnnotation;
import hu.bme.mit.gamma.expression.model.DefaultExpression;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.ElseExpression;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.EnvironmentResettableVariableDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.EqualityExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.ExpressionPackage;
import hu.bme.mit.gamma.expression.model.FieldDeclaration;
import hu.bme.mit.gamma.expression.model.FinalVariableDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.FunctionDeclaration;
import hu.bme.mit.gamma.expression.model.InjectedVariableDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression;
import hu.bme.mit.gamma.expression.model.IntegerRangeLiteralExpression;
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.expression.model.InternalParameterDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.InternalVariableDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.LambdaDeclaration;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.ParameterDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.ParametricElement;
import hu.bme.mit.gamma.expression.model.RationalLiteralExpression;
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
import hu.bme.mit.gamma.expression.util.FieldHierarchy;
import hu.bme.mit.gamma.expression.util.LiteralExpressionCreator;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.util.JavaUtil;

public class ExpressionModelDerivedFeatures {
	
	protected static final ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE;
	protected static final ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE;
	protected static final LiteralExpressionCreator literalCreator = LiteralExpressionCreator.INSTANCE;
	protected static final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected static final JavaUtil javaUtil = JavaUtil.INSTANCE;
	protected static final ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE;
	
	//
	
	public static boolean isContainedByPackage(EObject object) {
		EObject root = ecoreUtil.getRoot(object);
		return root instanceof ExpressionPackage;
	}
	
	//
	
	public static Expression getLeft(IntegerRangeLiteralExpression expression) {
		return getLeft(expression, true);
	}
	
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
	
	public static Expression getRight(IntegerRangeLiteralExpression expression) {
		return getRight(expression, true);
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
	
	public static Expression getOtherOperandIfContainedByEquality(Expression expression) {
		EObject container = expression.eContainer();
		if (container instanceof EqualityExpression equality) {
			Expression leftOperand = equality.getLeftOperand();
			if (leftOperand == expression) {
				Expression rightOperand = equality.getRightOperand();
				return rightOperand;
			}
			else {
				return leftOperand;
			}
		}
		return null; // Not contained by equality (other operand cannot be null: 1..1 multiplicity)
	}
	
	public static boolean hasOperandOfType(BinaryExpression expression, Class<?> clazz) {
		Expression leftOperand = expression.getLeftOperand();
		Expression rightOperand = expression.getRightOperand();
		
		return clazz.isInstance(leftOperand) || clazz.isInstance(rightOperand);
	}
	
	@SuppressWarnings("unchecked")
	public static <T extends Expression> T getOperandOfType(BinaryExpression expression, Class<T> clazz) {
		Expression leftOperand = expression.getLeftOperand();
		Expression rightOperand = expression.getRightOperand();
		
		if (clazz.isInstance(leftOperand)) {
			return (T) leftOperand;
		}
		else if (clazz.isInstance(rightOperand)) {
			return (T) rightOperand;
		}
		return null;
	}
	
	public static Expression getOtherOperandOfType(BinaryExpression expression, Class<?> clazz) {
		Expression leftOperand = expression.getLeftOperand();
		Expression rightOperand = expression.getRightOperand();
		
		if (clazz.isInstance(leftOperand)) {
			return rightOperand;
		}
		else if (clazz.isInstance(rightOperand)) {
			return leftOperand;
		}
		return null;
	}
	
	public static boolean isInternal(ParameterDeclaration parameter) {
		// Not assignable by the environment, only internal components
		return hasAnnotation(parameter, InternalParameterDeclarationAnnotation.class);
	}
	
	public static boolean hasAnnotation(ParameterDeclaration parameter,
			Class<? extends ParameterDeclarationAnnotation> annotation) {
		return parameter.getAnnotations().stream().anyMatch(it -> annotation.isInstance(it));
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
	
	public static boolean isRealClock(VariableDeclaration variable) {
		return isClock(variable) && !isScheduledClock(variable);
	}
	
	public static boolean isInternal(VariableDeclaration variable) {
		// Derived from an internal parameter (not assignable by the environment, only internal components)
		return hasAnnotation(variable, InternalVariableDeclarationAnnotation.class);
	}
	
	public static boolean isInjected(VariableDeclaration variable) {
		// Injected via internal model transformations
		return hasAnnotation(variable, InjectedVariableDeclarationAnnotation.class);
	}
	
	public static boolean hasAnnotation(VariableDeclaration variable,
			Class<? extends VariableDeclarationAnnotation> annotation) {
		return variable.getAnnotations().stream().anyMatch(it -> annotation.isInstance(it));
	}
	
	public static List<DeclarationReferenceAnnotation> getDeclarationReferenceAnnotations(VariableDeclaration variable) {
		List<DeclarationReferenceAnnotation> annotations = new ArrayList<DeclarationReferenceAnnotation>();
		for (VariableDeclarationAnnotation annotation : variable.getAnnotations()) {
			if (annotation instanceof DeclarationReferenceAnnotation referenceAnnotation) {
				annotations.add(referenceAnnotation);
			}
		}
		return annotations;
	}
	
	public static DeclarationReferenceAnnotation getDeclarationReferenceAnnotation(VariableDeclaration variable) {
		List<DeclarationReferenceAnnotation> declarationReferenceAnnotations = getDeclarationReferenceAnnotations(variable);
		return javaUtil.getOnlyElement(declarationReferenceAnnotations);
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
	
	public static boolean isPrimitive(Declaration declaration) {
		Type type = declaration.getType();
		return isPrimitive(type);
	}
	
	public static boolean isPrimitive(Type type) {
		TypeDefinition typeDefinition = getTypeDefinition(type);
		return typeDefinition instanceof BooleanTypeDefinition || typeDefinition instanceof IntegerTypeDefinition ||
				typeDefinition instanceof DecimalTypeDefinition || typeDefinition instanceof RationalTypeDefinition;
	}
	
	public static boolean isNative(Declaration declaration) {
		Type type = declaration.getType();
		return isNative(type);
	}
	
	public static boolean isNative(Type type) {
		TypeDefinition typeDefinition = getTypeDefinition(type);
		return isPrimitive(typeDefinition) || typeDefinition instanceof EnumerationTypeDefinition;
	}
	
	public static boolean isArray(Declaration declaration) {
		Type type = declaration.getType();
		return isArray(type);
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
	
	public static boolean isRecord(Declaration declaration) {
		Type type = declaration.getType();
		return isRecord(type);
	}
	
	public static boolean isRecord(Type type) {
		TypeDefinition typeDefinition = getTypeDefinition(type);
		return typeDefinition instanceof RecordTypeDefinition;
	}
	
	public static boolean isComplex(Declaration declaration) {
		Type type = declaration.getType();
		return isComplex(type);
	}
	
	public static boolean isComplex(Type type) {
		TypeDefinition typeDefinition = getTypeDefinition(type);
		return isRecord(typeDefinition) || isArray(typeDefinition);
	}
	
	public static boolean isElseOrDefault(Expression expression) {
		return expression instanceof ElseExpression || expression instanceof DefaultExpression;
	}
	
	public static TypeDefinition getElementTypeDefinition(Declaration declaration) {
		Type type = declaration.getType();
		TypeDefinition typeDefinition = getTypeDefinition(type);
		if (typeDefinition instanceof ArrayTypeDefinition arrayTypeDefinition) {
			return getTypeDefinition(
					arrayTypeDefinition.getElementType());
		}
		return typeDefinition;
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
	
	public static boolean isUnused(EnumerationLiteralDefinition literal) {
		String name = literal.getName();
		return name.equals(
				getUnusedEnumerationLiteralName());
	}
	
	public static String getUnusedEnumerationLiteralName() {
		return "__UnusedLiteral__";
	}
	
	public static List<Expression> getIndexes(Expression expression) {
		List<Expression> indexes = new ArrayList<Expression>();
		
		if (expression instanceof AccessExpression accessExpression) {
			Expression operand = accessExpression.getOperand();
			indexes.addAll(
					getIndexes(operand)); // Recursion, including records
		}
		if (expression instanceof ArrayAccessExpression arrayAccessExpression) {
			indexes.add(arrayAccessExpression.getIndex()); // Index adding
		}
		
		return indexes;
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
	
	public static int getDimension(Declaration declaration) {
		return getDimension(declaration, new FieldHierarchy());
	}
	
	public static int getDimension(Type type) {
		return getDimension(type, new FieldHierarchy());
	}
	
	public static int getDimension(Declaration declaration, FieldHierarchy fieldHierarchy) {
		Type type = declaration.getType();
		return getDimension(type, fieldHierarchy);
	}
	
	public static int getDimension(Type type, FieldHierarchy fieldHierarchy) {
		TypeDefinition typeDefinition = getTypeDefinition(type);
		if (typeDefinition instanceof ArrayTypeDefinition) {
			Type arrayElementType = getArrayElementType(typeDefinition);
			return getDimension(arrayElementType, fieldHierarchy) + 1;
		}
		else if (typeDefinition instanceof RecordTypeDefinition) {
			if (fieldHierarchy.isEmpty()) {
				throw new IllegalArgumentException("No specified field: " + fieldHierarchy);
			}
			FieldDeclaration field = fieldHierarchy.getFirst();
			FieldHierarchy remainingHierarchy = fieldHierarchy.cloneAndRemoveFirst();
			return getDimension(field, remainingHierarchy);
		}
		else {
			return 0;
		}
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
	
	public static Declaration getContainingDeclaration(Type type) {
		return ecoreUtil.getContainerOfType(type, Declaration.class);
	}
	
	public static VariableDeclaration getContainingVariable(Type type) {
		return ecoreUtil.getContainerOfType(type, VariableDeclaration.class);
	}
	
	public static int getIndex(ParameterDeclaration parameter) {
		ParametricElement container = (ParametricElement) parameter.eContainer();
		return container.getParameterDeclarations().indexOf(parameter);
	}
	
	public static boolean isEvaluable(Expression expression) {
		List<ReferenceExpression> references = ecoreUtil.getSelfAndAllContentsOfType(
				expression, ReferenceExpression.class);
		for (ReferenceExpression reference : new ArrayList<ReferenceExpression>(references)) {
			if (reference instanceof DirectReferenceExpression directReference) {
				Declaration declaration = directReference.getDeclaration();
				if (declaration instanceof ConstantDeclaration) {
					references.remove(reference);
				}
			}
		}
		return references.isEmpty();
	}
	
	public static boolean isNativeLiteral(Expression expression) {
		return expression instanceof BooleanLiteralExpression ||
				expression instanceof IntegerLiteralExpression ||
				expression instanceof RationalLiteralExpression ||
				expression instanceof DecimalLiteralExpression ||
				expression instanceof EnumerationLiteralExpression;
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
		if (type instanceof TypeReference typeReference) {
			TypeDeclaration typeDeclaration = typeReference.getReference();
			typeDeclarations.add(typeDeclaration);
			Type typeDefinition = typeDeclaration.getType();
			typeDeclarations.addAll(
					getAllTypeDeclarations(typeDefinition));
		}
		else if (type instanceof RecordTypeDefinition record) {
			for (FieldDeclaration fieldDeclaration : record.getFieldDeclarations()) {
				Type fieldType = fieldDeclaration.getType();
				typeDeclarations.addAll(
						getAllTypeDeclarations(fieldType));
			}
		}
		else if (type instanceof ArrayTypeDefinition array) {
			Type elementType = array.getElementType();
			typeDeclarations.addAll(
					getAllTypeDeclarations(elementType));
		}
		return typeDeclarations;
	}
	
}