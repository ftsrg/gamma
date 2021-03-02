package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.FieldDeclaration
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression
import hu.bme.mit.gamma.expression.model.InitializableElement
import hu.bme.mit.gamma.expression.model.RecordLiteralExpression
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition
import hu.bme.mit.gamma.expression.model.TypeDefinition
import hu.bme.mit.gamma.expression.model.ValueDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import java.util.List

import static extension com.google.common.collect.Iterables.getOnlyElement

class ValueDeclarationTransformer {
	// Auxiliary object
	protected final extension TypeTransformer typeTransformer
	protected final extension ExpressionTransformer expressionTransformer
	// Expression factory
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	// Trace needed for variable mappings
	protected final Trace trace
	
	new(Trace trace) {
		this.trace = trace
		this.typeTransformer = new TypeTransformer(trace)
		this.expressionTransformer = new ExpressionTransformer(trace)
	}
	
	def List<VariableDeclaration> transformValue(ValueDeclaration variable) {
		val List<VariableDeclaration> transformed = newArrayList
		val TypeDefinition variableType = getTypeDefinitionFromType(variable.type)
		// Records are broken up into separate variables
		if (variableType instanceof RecordTypeDefinition) {
			for (field : variableType.fieldDeclarations) {
				val innerField = <FieldDeclaration>newArrayList
				innerField += field
				transformed += transformValueField(variable, innerField, newArrayList)
			}
			return transformed
		}
		else if (variableType instanceof ArrayTypeDefinition) {
			val arrayStack = <ArrayTypeDefinition>newArrayList
			arrayStack += variableType
			transformed += transformValueArray(variable, variableType, arrayStack)
			return transformed
		}
		else {	//Simple variables and arrays of simple types are simply transformed
			val newVariable = createVariableDeclaration => [
				it.name = variable.name
				it.type = variable.type.transformType
				if (variable instanceof InitializableElement) {
					it.expression = variable.expression?.transformExpression?.getOnlyElement
				}
				if (variable instanceof VariableDeclaration) {
					for (annotation : variable.annotations) {
						it.annotations += annotation.transformAnnotation
					}
				}
			]
			transformed += newVariable
			trace.put(variable, transformed.head)
			return transformed
		}
	}
	
	private def List<VariableDeclaration> transformValueField(ValueDeclaration variable,
			List<FieldDeclaration> currentField, List<ArrayTypeDefinition> arrayStack) {
		val List<VariableDeclaration> transformed = newArrayList
		
		val typeDef = getTypeDefinitionFromType(currentField.last.type)
		if (typeDef instanceof RecordTypeDefinition) { // if another record
			for (field : typeDef.fieldDeclarations) {
				val innerField = <FieldDeclaration>newArrayList
				innerField += currentField
				innerField += field
				val innerStack = <ArrayTypeDefinition>newArrayList
				innerStack += arrayStack
				transformed += transformValueField(variable, innerField, innerStack)
			}
		}
		else {	//if simple type
			val transformedField = createVariableDeclaration => [
				it.name = variable.name + "_" + currentField.last.name	//TODO name provider
				it.type = createTransformedRecordType(arrayStack, currentField.last.type)
				if (variable instanceof InitializableElement) {
					val initial = variable.expression
					if (initial !== null) {
						if (initial instanceof RecordLiteralExpression) {
							it.expression = getExpressionFromRecordLiteral(
								initial, currentField).transformExpression.getOnlyElement
						} 
						else if (initial instanceof ArrayLiteralExpression) {
							it.expression = constraintFactory.createArrayLiteralExpression
							for (op : initial.operands) {
								if (op instanceof RecordLiteralExpression) {
									(it.expression as ArrayLiteralExpression).operands += 
										getExpressionFromRecordLiteral(op, currentField).transformExpression.getOnlyElement
								}
							}
						} 
						else if (initial instanceof FunctionAccessExpression) {
							if (trace.isMapped(initial)) {
								var possibleValues = trace.get(initial)
								var VariableDeclaration currentValue = null
								for (value : possibleValues) {
									if (value.name.contains(currentField.last.name)) { // TODO nameprovider
										currentValue = value
									}
								}
								if (currentValue !== null) {
									val currentValueConst = currentValue
									it.expression = createDirectReferenceExpression => [
										it.declaration = currentValueConst
									]
								}
							}
							else {
								throw new IllegalArgumentException("Error when transforming function access expression: " +
									initial + " was not yet transformed.")
							}
						} 
						else {
							throw new IllegalArgumentException("Cannot transform initial value: " + initial)
						}
					}
				}
				if (variable instanceof VariableDeclaration) {
					for (annotation : variable.annotations) {
						it.annotations += annotation.transformAnnotation
					}
				}
			]
			transformed += transformedField
			trace.put(new Pair(variable, currentField), transformedField)
		}
		
		return transformed	
	}
	
	private def List<VariableDeclaration> transformValueArray(ValueDeclaration variable,
			ArrayTypeDefinition currentType, List<ArrayTypeDefinition> arrayStack) {
		val List<VariableDeclaration> transformed = newArrayList
		
		val TypeDefinition innerType = getTypeDefinitionFromType(currentType.elementType)
		if (innerType instanceof ArrayTypeDefinition) {
			val innerStack = <ArrayTypeDefinition>newArrayList
			innerStack += arrayStack
			innerStack += innerType
			transformed += transformValueArray(variable, innerType, innerStack)
		}
		else if (innerType instanceof RecordTypeDefinition) {
			for (field : innerType.fieldDeclarations) {
				val innerField = <FieldDeclaration>newArrayList
				innerField += field
				val innerStack = <ArrayTypeDefinition>newArrayList
				innerStack += arrayStack
				transformed += transformValueField(variable, innerField, innerStack)
			}
			return transformed
		}
		else {	// Simple
			transformed += createVariableDeclaration => [
				it.name = variable.name
				it.type = variable.type.transformType
				if (variable instanceof InitializableElement) {
					it.expression = variable.expression?.transformExpression?.getOnlyElement
				}
				if (variable instanceof VariableDeclaration) {
					for (annotation : variable.annotations) {
						it.annotations += annotation.transformAnnotation
					}
				}
			]
			trace.put(variable, transformed.head)
		}
		return transformed
	}
	
	private def Expression getExpressionFromRecordLiteral(RecordLiteralExpression initial,
			List<FieldDeclaration> currentField) {
		for (assignment : initial.fieldAssignments) {
			val value = assignment.value
			if (currentField.head.name == assignment.reference) {
				if (currentField.size == 1) {
					return value
				}
				else {
					if (assignment.value instanceof RecordLiteralExpression) {
						val innerField = <FieldDeclaration>newArrayList
						innerField += currentField.subList(1, currentField.size)
						return getExpressionFromRecordLiteral(
							value as RecordLiteralExpression, innerField)
					}
					else {
						throw new IllegalArgumentException("Invalid expression!")
					}
				}
			}
		}
	}
	
}