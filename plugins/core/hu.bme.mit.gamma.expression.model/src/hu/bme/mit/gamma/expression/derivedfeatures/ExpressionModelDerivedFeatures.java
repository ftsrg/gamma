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
import java.util.stream.Collectors;

import hu.bme.mit.gamma.expression.model.AccessExpression;
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression;
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition;
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition;
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.FieldDeclaration;
import hu.bme.mit.gamma.expression.model.FieldReferenceExpression;
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.ParametricElement;
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition;
import hu.bme.mit.gamma.expression.model.RecordAccessExpression;
import hu.bme.mit.gamma.expression.model.RecordLiteralExpression;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.ResetableVariableDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.SelectExpression;
import hu.bme.mit.gamma.expression.model.TransientVariableDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionUtil;
import hu.bme.mit.gamma.expression.util.FieldHierarchy;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.util.JavaUtil;

public class ExpressionModelDerivedFeatures {
	
	protected static final ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE;
	protected static final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected static final JavaUtil javaUtil = JavaUtil.INSTANCE;
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
	
	public static boolean isRecord(Type type) {
		TypeDefinition typeDefinition = getTypeDefinition(type);
		return typeDefinition instanceof RecordTypeDefinition;
	}
	
	public static boolean isComplex(Type type) {
		TypeDefinition typeDefinition = getTypeDefinition(type);
		return isRecord(typeDefinition) || isArray(typeDefinition);
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
	
	// Record and array handling
	
	public static List<Expression> getFieldValues(RecordLiteralExpression record) {
		TypeDeclaration typeDeclaration = record.getTypeDeclaration();
		RecordTypeDefinition recordType = (RecordTypeDefinition) getTypeDefinition(typeDeclaration.getType());
		List<Expression> values = new ArrayList<Expression>();
		for (FieldDeclaration fieldDeclaration : recordType.getFieldDeclarations()) {
			Expression value = record.getFieldAssignments().stream()
				.filter(it -> it.getReference().getFieldDeclaration() == fieldDeclaration).findFirst().get()
				.getValue();
			values.add(value);
		}
		return values;
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
	
	public static List<FieldHierarchy> getFieldHierarchies(Type type) {
		List<FieldHierarchy> fieldHierarchies = new ArrayList<FieldHierarchy>();
		TypeDefinition typeDefinition = getTypeDefinition(type);
		if (typeDefinition instanceof RecordTypeDefinition) {
			RecordTypeDefinition record = (RecordTypeDefinition) typeDefinition;
			for (FieldDeclaration field : record.getFieldDeclarations()) {
				Type fieldType = field.getType();
				List<FieldHierarchy> hierarchies = getFieldHierarchies(fieldType);
				for (FieldHierarchy hierarchy : hierarchies) {
					hierarchy.prepend(field);
					fieldHierarchies.add(hierarchy);
				}
			}
		}
		else if (typeDefinition instanceof ArrayTypeDefinition) {
			ArrayTypeDefinition array = (ArrayTypeDefinition) typeDefinition;
			Type arrayType = array.getElementType();
			fieldHierarchies.addAll(getFieldHierarchies(arrayType));
		}
		else {
			// Primitive type
			fieldHierarchies.add(new FieldHierarchy());
		}
		return fieldHierarchies;
	}
	
	/**
	 * To every field hierarchy (getFieldHierarchies), a single native type
	 * (possibly a multidimensional array) belongs.
	 */
	public static List<Type> getNativeTypes(Type type) {
		List<Type> nativeTypes = new ArrayList<Type>();
		TypeDefinition typeDefinition = getTypeDefinition(type);
		if (typeDefinition instanceof RecordTypeDefinition) {
			RecordTypeDefinition record = (RecordTypeDefinition) typeDefinition;
			for (FieldDeclaration field : record.getFieldDeclarations()) {
				Type fieldType = field.getType();
				nativeTypes.addAll(getNativeTypes(fieldType));
			}
		}
		else if (typeDefinition instanceof ArrayTypeDefinition) {
			ArrayTypeDefinition array = (ArrayTypeDefinition) typeDefinition;
			Type arrayType = array.getElementType();
			for (Type nativeType : getNativeTypes(arrayType)) {
				ArrayTypeDefinition newArrayType = ecoreUtil.clone(array);
				newArrayType.setElementType(ecoreUtil.clone(nativeType));
				nativeTypes.add(newArrayType);
			}
		}
		else {
			// Primitive types or enum (not type definition, as enum needs a type declaration)
			nativeTypes.add(type);
		}
		return nativeTypes;
	}
	
	public static List<Expression> getAccesses(Expression expression) {
		List<Expression> accesses = new ArrayList<Expression>();
		if (expression instanceof ArrayAccessExpression) {
			ArrayAccessExpression arrayAccessExpression = (ArrayAccessExpression) expression;
			Expression operand = arrayAccessExpression.getOperand();
			if (operand instanceof AccessExpression) {
				accesses.addAll(getAccesses(operand));
			}
			accesses.add(arrayAccessExpression.getIndex());
		}
		else if (expression instanceof RecordAccessExpression) {
			RecordAccessExpression recordAccess = (RecordAccessExpression) expression;
			Expression operand = recordAccess.getOperand();
			if (operand instanceof AccessExpression) {
				accesses.addAll(getAccesses(operand));
			}
			accesses.add(recordAccess.getFieldReference());
		}
		else if (expression instanceof SelectExpression) {
			SelectExpression select = (SelectExpression) expression;
			Expression operand = select.getOperand();
			if (operand instanceof AccessExpression) {
				accesses.addAll(getAccesses(operand));
			}
		}
		return accesses;
	}
	
	public static FieldHierarchy getFieldAccess(Expression expression) {
		List<FieldReferenceExpression> fieldAccesses =
				javaUtil.filter(getAccesses(expression), FieldReferenceExpression.class);
		List<FieldDeclaration> fieldDeclarations = fieldAccesses.stream()
				.map(it -> it.getFieldDeclaration()).collect(Collectors.toList());
		return new FieldHierarchy(fieldDeclarations);
	}
	
	public static List<Expression> getIndexAccess(Expression expression) {
		List<Expression> accesses = getAccesses(expression);
		List<FieldReferenceExpression> recordAccesses =
				javaUtil.filter(accesses, FieldReferenceExpression.class);
		accesses.removeAll(recordAccesses);
		return accesses;
	}
	
	///////////////
	// Deprecated old array and record handling
	///////////////
	
//	public static List<FieldReferenceExpression> collectRecordAccessList(ReferenceExpression exp) {
//		return javaUtil.filter(collectAccessList(exp), FieldReferenceExpression.class);
//	}
//	
//	public static List<FieldHierarchy> getAllFieldHierarchies(RecordTypeDefinition record) {
//		List<FieldHierarchy> fieldHierarchies = new ArrayList<FieldHierarchy>();
//		for (FieldDeclaration field : record.getFieldDeclarations()) {
//			Type type = field.getType();
//			if (type instanceof RecordTypeDefinition) {
//				RecordTypeDefinition subrecord = (RecordTypeDefinition) type;
//				List<FieldHierarchy> hierarchies = getAllFieldHierarchies(subrecord);
//				for (FieldHierarchy hierarchy : hierarchies) {
//					hierarchy.prepend(field);
//					fieldHierarchies.add(hierarchy);
//				}
//			}
//			else {
//				// Primitive type
//				fieldHierarchies.add(new FieldHierarchy(field));
//			}
//		}
//		return fieldHierarchies;
//	}
//	
//	public static List<SimpleEntry<ValueDeclaration, FieldHierarchy>> exploreComplexType(
//			ValueDeclaration original) {
//		List<SimpleEntry<ValueDeclaration, FieldHierarchy>> _xblockexpression = null;
//		final TypeDefinition typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(original);
//		FieldHierarchy _fieldHierarchy = new FieldHierarchy();
//		_xblockexpression = exploreComplexType(original, typeDefinition, _fieldHierarchy);
//		return _xblockexpression;
//	}
//		
//	public static List<SimpleEntry<ValueDeclaration, FieldHierarchy>> exploreComplexType(
//			ValueDeclaration original, TypeDefinition type) {
//		FieldHierarchy _fieldHierarchy = new FieldHierarchy();
//		return exploreComplexType(original, type, _fieldHierarchy);
//	}
//		
//	public static List<SimpleEntry<ValueDeclaration, FieldHierarchy>> exploreComplexType(
//			ValueDeclaration original, TypeDefinition type, FieldHierarchy currentField) {
//		final List<FieldHierarchy> exploredTypes = exploreComplexType2(type, currentField);
//		final List<SimpleEntry<ValueDeclaration, FieldHierarchy>> result = new ArrayList<>();
//		for (FieldHierarchy exploredType : exploredTypes) {
//			SimpleEntry<ValueDeclaration, FieldHierarchy> _pair =
//					new SimpleEntry<ValueDeclaration, FieldHierarchy>(original, exploredType);
//			result.add(_pair);
//		}
//		return result;
//	}
//	
//	public static List<FieldHierarchy> exploreComplexType2(TypeDefinition type) {
//		return exploreComplexType2(type, new FieldHierarchy());
//	}
//		
//	public static List<FieldHierarchy> exploreComplexType2(
//			TypeDefinition type, FieldHierarchy currentField) {
//		final List<FieldHierarchy> result = new ArrayList<FieldHierarchy>();
//		if (type instanceof RecordTypeDefinition) {
//			EList<FieldDeclaration> _fieldDeclarations = ((RecordTypeDefinition)type).getFieldDeclarations();
//			for (FieldDeclaration field : _fieldDeclarations) {
//				final FieldHierarchy newCurrent = new FieldHierarchy();
//				newCurrent.add(currentField);
//				newCurrent.add(field);
//				List<FieldHierarchy> _exploreComplexType2 = exploreComplexType2(
//						ExpressionModelDerivedFeatures.getTypeDefinition(field.getType()), newCurrent);
//				result.addAll(_exploreComplexType2);
//			}
//		}
//		else {
//			if (type instanceof ArrayTypeDefinition) {
//				List<FieldHierarchy> _exploreComplexType2 = exploreComplexType2(
//						ExpressionModelDerivedFeatures.getTypeDefinition(
//								((ArrayTypeDefinition)type).getElementType()), currentField);
//				result.addAll(_exploreComplexType2);
//			}
//			else {
//				result.add(currentField);
//			}
//		}
//		return result;
//	}
//		
//	public static List<Expression> collectAccessList(ReferenceExpression exp) {
//		final List<Expression> result = new ArrayList<Expression>();
//		if (exp instanceof ArrayAccessExpression) {
//			final ArrayAccessExpression arrayAccessExpression = (ArrayAccessExpression) exp;
//			final Expression inner = arrayAccessExpression.getOperand();
//			if (inner instanceof ReferenceExpression) {
//				List<Expression> _collectAccessList = collectAccessList((ReferenceExpression)inner);
//				result.addAll(_collectAccessList);
//			}
//			Expression _onlyElement = javaUtil.getOnlyElement(arrayAccessExpression.getIndexes());
//			result.add(_onlyElement);
//		}
//		else {
//			if (exp instanceof RecordAccessExpression) {
//				RecordAccessExpression recordAccess = (RecordAccessExpression) exp;
//				final Expression inner_1 = recordAccess.getOperand();
//				if (inner_1 instanceof ReferenceExpression) {
//					List<Expression> _collectAccessList_1 = collectAccessList((ReferenceExpression)inner_1);
//					result.addAll(_collectAccessList_1);
//				}
//				FieldReferenceExpression _fieldReference = recordAccess.getFieldReference();
//				result.add(_fieldReference);
//			}
//			else {
//				if (exp instanceof SelectExpression) {
//					final Expression inner_2 = ((SelectExpression)exp).getOperand();
//					if (inner_2 instanceof ReferenceExpression) {
//						List<Expression> _collectAccessList_2 = collectAccessList((ReferenceExpression)inner_2);
//						result.addAll(_collectAccessList_2);
//					}
//				}
//				else {
//					// Simple
//				}
//			}
//		}
//		return result;
//	}
//		
//	public static boolean isSameAccessTree(FieldHierarchy fieldHierarchy,
//			List<FieldReferenceExpression> currentAccessList) {
//		final List<FieldDeclaration> fieldsList = fieldHierarchy.getFields();
//		int _size = fieldsList.size();
//		int _size_1 = currentAccessList.size();
//		if (_size < _size_1) {
//			return false;
//		}
//		for (int i = 0; i < currentAccessList.size(); i++) {
//			final FieldDeclaration access = currentAccessList.get(i).getFieldDeclaration();
//			final FieldDeclaration field = fieldsList.get(i);
//			if (access != field) {
//				return false;
//			}
//		}
//		return true;
//	}
	
}