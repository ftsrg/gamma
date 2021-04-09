package hu.bme.mit.gamma.expression.util;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.AccessExpression;
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression;
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.Expression;
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
	
	protected final boolean TRANSFORM_INTO_1D_ARRAY = true;

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
	
	/**
	 * To every field hierarchy (getFieldHierarchies), a single native type
	 * (possibly a multidimensional array) belongs.
	 */
	public List<Type> getNativeTypes(Type type) {
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
	
	public List<Expression> getAccesses(Expression expression) {
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
	
	public FieldHierarchy getFieldAccess(Expression expression) {
		List<FieldReferenceExpression> fieldAccesses =
				javaUtil.filter(getAccesses(expression), FieldReferenceExpression.class);
		List<FieldDeclaration> fieldDeclarations = fieldAccesses.stream()
				.map(it -> it.getFieldDeclaration()).collect(Collectors.toList());
		return new FieldHierarchy(fieldDeclarations);
	}
	
	public List<Expression> getIndexAccess(Expression expression) {
		List<Expression> accesses = getAccesses(expression);
		List<FieldReferenceExpression> recordAccesses =
				javaUtil.filter(accesses, FieldReferenceExpression.class);
		accesses.removeAll(recordAccesses);
		return accesses;
	}
	
}