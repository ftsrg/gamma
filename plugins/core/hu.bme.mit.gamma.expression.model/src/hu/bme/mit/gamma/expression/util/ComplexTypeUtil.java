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
package hu.bme.mit.gamma.expression.util;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.AccessExpression;
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression;
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression;
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.FieldAssignment;
import hu.bme.mit.gamma.expression.model.FieldDeclaration;
import hu.bme.mit.gamma.expression.model.FieldReferenceExpression;
import hu.bme.mit.gamma.expression.model.RecordAccessExpression;
import hu.bme.mit.gamma.expression.model.RecordLiteralExpression;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.SelectExpression;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.util.JavaUtil;

public class ComplexTypeUtil {
	// Singleton - maybe the 1D-multidimensional array handling setting will make this non-singleton
	public static final ComplexTypeUtil INSTANCE = new ComplexTypeUtil();
	protected ComplexTypeUtil() {}
	//
	
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final JavaUtil javaUtil = JavaUtil.INSTANCE;
	protected final ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE;
	
	protected final ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE;
	
	protected final boolean TRANSFORM_INTO_1D_ARRAY = false;

	// Record and array handling - high-level expression and action transformers should build on these
	
	public List<FieldHierarchy> getFieldHierarchies(Declaration declaration) {
		TypeDefinition type = ExpressionModelDerivedFeatures.getTypeDefinition(declaration);
		return getFieldHierarchies(type);
	}
	
	public List<FieldHierarchy> getFieldHierarchies(Type type) {
		List<FieldHierarchy> fieldHierarchies = new ArrayList<FieldHierarchy>();
		TypeDefinition typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(type);
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
	
	public List<Type> getNativeTypes(Declaration declaration) {
		TypeDefinition type = ExpressionModelDerivedFeatures.getTypeDefinition(declaration);
		return getNativeTypes(type);
	}
	
	public List<Type> getNativeTypes(Type type) {
		if (TRANSFORM_INTO_1D_ARRAY) {
			return get1DNativeTypes(type);
		}
		else {
			return getMultiDNativeTypes(type);
		}
	}
	
	/**
	 * To every field hierarchy (getFieldHierarchies), a single native type
	 * (possibly a multidimensional array) belongs.
	 */
	public List<Type> getMultiDNativeTypes(Type type) {
		List<Type> nativeTypes = new ArrayList<Type>();
		TypeDefinition typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(type);
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
				newArrayType.setElementType(
						ecoreUtil.clone(nativeType));
				nativeTypes.add(newArrayType);
			}
		}
		else {
			// Primitive types or enum (not type definition, as enum needs a type declaration)
			nativeTypes.add(type);
		}
		return nativeTypes;
	}
	
	/**
	 * To every field hierarchy (getFieldHierarchies), a single native type
	 * (possibly a 1D array) belongs.
	 */
	public List<Type> get1DNativeTypes(Type type) {
		List<Type> nativeTypes = getNativeTypes(type);
		return to1DArrays(nativeTypes);
	}
	
	public List<Type> to1DArrays(List<Type> types) {
		List<Type> _1DArrays = new ArrayList<Type>();
		for (Type type : types) {
			_1DArrays.add(type);
		}
		return _1DArrays;
	}
	
	public Type to1DArray(Type type) {
		Type clonedType = ecoreUtil.clone(type);
		if (clonedType instanceof ArrayTypeDefinition) {
			ArrayTypeDefinition arrayTypeDefinition = (ArrayTypeDefinition) clonedType;
			Expression size = arrayTypeDefinition.getSize();
			Type innerType = arrayTypeDefinition.getElementType();
			if (innerType instanceof ArrayTypeDefinition) {
				ArrayTypeDefinition _1DArray = (ArrayTypeDefinition) to1DArray(innerType);
				Expression innerSize = _1DArray.getSize();
				Expression newSize = expressionUtil.wrapIntoMultiaryExpression(
						size, innerSize, factory.createMultiplyExpression());
				_1DArray.setSize(newSize);
				return _1DArray;
			}
			return arrayTypeDefinition;
		}
		return clonedType;
	}
	
	public List<Expression> getDSizes(ArrayTypeDefinition type) {
		Type elementType = type.getElementType();
		Expression size = ecoreUtil.clone(type.getSize());
		List<Expression> dimensions = new ArrayList<Expression>();
		dimensions.add(size);
		if (elementType instanceof ArrayTypeDefinition) {
			ArrayTypeDefinition innerArrayType = (ArrayTypeDefinition) elementType;
			dimensions.addAll(
					getDSizes(innerArrayType));
		}
		return dimensions;
	}
	
	public List<Expression> getFieldValues(RecordLiteralExpression record) {
		TypeDeclaration typeDeclaration = record.getTypeDeclaration();
		RecordTypeDefinition recordType = (RecordTypeDefinition)
				ExpressionModelDerivedFeatures.getTypeDefinition(typeDeclaration.getType());
		List<Expression> values = new ArrayList<Expression>();
		for (FieldDeclaration fieldDeclaration : recordType.getFieldDeclarations()) {
			Expression value = record.getFieldAssignments().stream()
				.filter(it -> it.getReference().getFieldDeclaration() == fieldDeclaration).findFirst().get()
				.getValue();
			values.add(value);
		}
		return values;
	}
	
	public FieldAssignment getFieldAssignment(
			RecordLiteralExpression literal, FieldHierarchy fieldHierarchy) {
		List<FieldAssignment> fieldAssignments = literal.getFieldAssignments();
		FieldAssignment fieldAssignment = null;
		for (FieldDeclaration field : fieldHierarchy.getFields()) {
			fieldAssignment = fieldAssignments.stream().filter(it -> 
				it.getReference().getFieldDeclaration() == field).findFirst().get();
			Expression fieldValue = fieldAssignment.getValue();
			if (fieldValue instanceof RecordLiteralExpression) {
				RecordLiteralExpression subrecord = (RecordLiteralExpression) fieldValue;
				fieldAssignments = subrecord.getFieldAssignments();
			}
		}
		return fieldAssignment;
	}
	
	public Expression getValue(Expression literal /* Has to contain valid expression in each field or index */, 
			FieldHierarchy fieldHierarchy, IndexHierarchy indexHierarchy) {
		if (literal instanceof RecordLiteralExpression) {
			RecordLiteralExpression record = (RecordLiteralExpression) literal;
			FieldHierarchy clonedHierarchy = fieldHierarchy.clone();
			FieldDeclaration field = clonedHierarchy.removeFirst();
			Expression value = record.getFieldAssignments().stream().filter(it -> 
				it.getReference().getFieldDeclaration() == field).findFirst().get().getValue();
			return getValue(value, clonedHierarchy, indexHierarchy);
		}
		else if (literal instanceof ArrayLiteralExpression) {
			ArrayLiteralExpression array = (ArrayLiteralExpression) literal;
			IndexHierarchy clonedIndexHierarchy = indexHierarchy.clone();
			int index = clonedIndexHierarchy.removeFirst();
			Expression value = array.getOperands().get(index);
			return getValue(value, fieldHierarchy, clonedIndexHierarchy);
		}
		else {
			return literal;
		}
	}
	
	public List<Expression> getAccesses(Expression expression) {
		List<Expression> accesses = new ArrayList<Expression>();
		if (expression instanceof ArrayAccessExpression) {
			ArrayAccessExpression arrayAccessExpression = (ArrayAccessExpression) expression;
			Expression operand = arrayAccessExpression.getOperand();
			if (operand instanceof AccessExpression) {
				accesses.addAll(
						getAccesses(operand));
			}
			accesses.add(arrayAccessExpression.getIndex());
		}
		else if (expression instanceof RecordAccessExpression) {
			RecordAccessExpression recordAccess = (RecordAccessExpression) expression;
			Expression operand = recordAccess.getOperand();
			if (operand instanceof AccessExpression) {
				accesses.addAll(
						getAccesses(operand));
			}
			accesses.add(recordAccess.getFieldReference());
		}
		else if (expression instanceof SelectExpression) {
			SelectExpression select = (SelectExpression) expression;
			Expression operand = select.getOperand();
			if (operand instanceof AccessExpression) {
				accesses.addAll(
						getAccesses(operand));
			}
		}
		return accesses;
	}
	
	public FieldHierarchy getFieldAccess(Expression expression) {
		List<FieldReferenceExpression> fieldAccesses =
				javaUtil.filterIntoList(getAccesses(expression), FieldReferenceExpression.class);
		List<FieldDeclaration> fieldDeclarations = fieldAccesses.stream()
				.map(it -> it.getFieldDeclaration()).collect(Collectors.toList());
		return new FieldHierarchy(fieldDeclarations);
	}
	
	public List<Expression> getIndexAccess(Expression expression) {
		return getMultiDIndexAccess(expression);
	}
	
	public List<Expression> getMultiDIndexAccess(Expression expression) {
		List<Expression> accesses = getAccesses(expression);
		List<FieldReferenceExpression> recordAccesses =
				javaUtil.filterIntoList(accesses, FieldReferenceExpression.class);
		accesses.removeAll(recordAccesses);
		return accesses;
	}
	
	public List<Expression> get1DIndexAccess(Expression expression) {
		throw new UnsupportedOperationException();
	}
	
}