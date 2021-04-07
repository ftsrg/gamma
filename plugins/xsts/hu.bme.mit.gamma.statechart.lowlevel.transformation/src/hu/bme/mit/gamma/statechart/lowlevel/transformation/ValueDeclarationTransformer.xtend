package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.expression.model.ConstantDeclaration
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.InitializableElement
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.ValueDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.FieldHierarchy
import hu.bme.mit.gamma.statechart.interface_.Port
import java.util.List

import static com.google.common.base.Preconditions.checkState

import static extension com.google.common.collect.Iterables.getOnlyElement
import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.LowlevelNamings.*

class ValueDeclarationTransformer {
	// Auxiliary object
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension TypeTransformer typeTransformer
	// Expression factory
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	// Trace needed for variable mappings
	protected final Trace trace
	
	new(Trace trace) {
		this.trace = trace
		this.expressionTransformer = new ExpressionTransformer(trace)
		this.typeTransformer = new TypeTransformer(trace)
	}
	
	def List<VariableDeclaration> transformComponentParameter(ParameterDeclaration gammaParameter) {
		val lowlevelVariableNames = gammaParameter.componentParameterNames
		return gammaParameter.transform(lowlevelVariableNames,
			new Tracer {
				override trace(ValueDeclaration value, FieldHierarchy fieldHierarchy,
						VariableDeclaration lowlevelVariable) {
					trace.put(value -> fieldHierarchy, lowlevelVariable)
				}
			}
		)
	}
	
	def List<VariableDeclaration> transformFunctionParameter(ParameterDeclaration gammaParameter) {
		val lowlevelVariableNames = gammaParameter.componentParameterNames
		return gammaParameter.transform(lowlevelVariableNames,
			new Tracer {
				override trace(ValueDeclaration value, FieldHierarchy fieldHierarchy,
						VariableDeclaration lowlevelVariable) {
					trace.put(value -> fieldHierarchy, lowlevelVariable)
				}
			}
		)
	}
	
	def List<VariableDeclaration> transformInParameter(ParameterDeclaration gammaParameter, Port gammaPort) {
		val lowlevelVariableNames = gammaParameter.getInNames(gammaPort)
		return gammaParameter.transform(lowlevelVariableNames, 
			new Tracer {
				override trace(ValueDeclaration value, FieldHierarchy fieldHierarchy,
						VariableDeclaration lowlevelVariable) {
					trace.putInParameter(gammaPort, gammaParameter.containingEvent,
						gammaParameter -> fieldHierarchy, lowlevelVariable)
				}
			}
		)
	}
	
	def List<VariableDeclaration> transformOutParameter(ParameterDeclaration gammaParameter, Port gammaPort) {
		val lowlevelVariableNames = gammaParameter.getOutNames(gammaPort)
		return gammaParameter.transform(lowlevelVariableNames, 
			new Tracer {
				override trace(ValueDeclaration value, FieldHierarchy fieldHierarchy,
						VariableDeclaration lowlevelVariable) {
					trace.putOutParameter(gammaPort, gammaParameter.containingEvent,
						gammaParameter -> fieldHierarchy, lowlevelVariable)
				}
			}
		)
	}
	
	private def List<VariableDeclaration> transform(ParameterDeclaration gammaParameter,
			List<String> lowlevelVariableNames, Tracer tracer) {
		val lowlevelVariables = gammaParameter.transformValue(tracer)
		lowlevelVariables.nameLowlevelVariables(lowlevelVariableNames)
		return lowlevelVariables
	}

	def List<VariableDeclaration> transform(ConstantDeclaration gammaConstant) {
		val lowlevelVariables = gammaConstant.transformValue(
			new Tracer {
				override trace(ValueDeclaration value, FieldHierarchy fieldHierarchy,
						VariableDeclaration lowlevelVariable) {
					trace.put(value -> fieldHierarchy, lowlevelVariable)
				}
			}
		)
		// Constant variable names do not really matter in terms of traceability
		val lowlevelVariableNames = gammaConstant.names
		lowlevelVariables.nameLowlevelVariables(lowlevelVariableNames)
		return lowlevelVariables
	}
	
	def List<VariableDeclaration> transform(VariableDeclaration gammaVariable) {
		val lowlevelVariables = gammaVariable.transformValue(
			new Tracer {
				override trace(ValueDeclaration value, FieldHierarchy fieldHierarchy,
						VariableDeclaration lowlevelVariable) {
					trace.put(value -> fieldHierarchy, lowlevelVariable)
				}
			}
		)
		val lowlevelVariableNames = gammaVariable.names
		lowlevelVariables.nameLowlevelVariables(lowlevelVariableNames)
		return lowlevelVariables
	}
	
	private def nameLowlevelVariables(List<VariableDeclaration> lowlevelVariables,
			List<String> lowlevelVariableNames) {
		checkState(lowlevelVariables.size == lowlevelVariableNames.size)
		val size = lowlevelVariables.size
		for (var i = 0; i < size; i++) {
			val lowlevelVariable = lowlevelVariables.get(i)
			val lowlevelVariableName = lowlevelVariableNames.get(i)
			lowlevelVariable.name = lowlevelVariableName
		}
	}
	
	def List<VariableDeclaration> transform(ValueDeclaration gammaValue) {
		if (gammaValue instanceof VariableDeclaration) {
			return gammaValue.transform
		}
		if (gammaValue instanceof ConstantDeclaration) {
			return gammaValue.transform
		}
		throw new IllegalArgumentException("Not known: " + gammaValue)
	}
	
	private def List<VariableDeclaration> transformValue(ValueDeclaration variable, Tracer tracer) {
		val type = variable.type
		val fieldHierarchies = type.fieldHierarchies
		val nativeTypes = type.nativeTypes
		checkState(fieldHierarchies.size == nativeTypes.size)
		val size = fieldHierarchies.size
		val lowlevelVariables = newArrayList
		for (var i = 0; i < size; i++) {
			val fieldHierarchy = fieldHierarchies.get(i)
			val nativeType = nativeTypes.get(i).transformType
			val lowlevelVariable = createVariableDeclaration => [
				// Name added later
				it.type = nativeType
				if (variable instanceof InitializableElement) {
					it.expression = variable.expression?.transformExpression?.onlyElement
				}
				if (variable instanceof VariableDeclaration) {
					for (annotation : variable.annotations) {
						it.annotations += annotation.transformAnnotation
					}
				}
			]
			lowlevelVariables += lowlevelVariable
			// Abstract tracing
			tracer.trace(variable, fieldHierarchy, lowlevelVariable)
		}
		return lowlevelVariables
	}
	
	interface Tracer {
		// Maybe it could contain the namings too
		def void trace(ValueDeclaration value, FieldHierarchy fieldHierarchy,
			VariableDeclaration lowlevelVariable)
	}
	
	///////////////
	// Deprecated old array and record handling
	///////////////
	
//	def List<VariableDeclaration> transformValue2(ValueDeclaration variable) {
//		val List<VariableDeclaration> transformed = newArrayList
//		val TypeDefinition variableType = variable.typeDefinition
//		// Records are broken up into separate variables
//		if (variableType instanceof RecordTypeDefinition) {
//			for (field : variableType.fieldDeclarations) {
//				val innerField = new FieldHierarchy
//				innerField.add(field)
//				transformed += transformValueField(variable, innerField, newArrayList)
//			}
//			return transformed
//		}
//		else if (variableType instanceof ArrayTypeDefinition) {
//			val arrayStack = <ArrayTypeDefinition>newArrayList
//			arrayStack += variableType
//			transformed += transformValueArray(variable, variableType, arrayStack)
//			return transformed
//		}
//		else {	// Simple variables and arrays of simple types are simply transformed
//			val newVariable = createVariableDeclaration => [
//				it.name = variable.name
//				it.type = variable.type.transformType
//				if (variable instanceof InitializableElement) {
//					it.expression = variable.expression?.transformExpression?.onlyElement
//				}
//				if (variable instanceof VariableDeclaration) {
//					for (annotation : variable.annotations) {
//						it.annotations += annotation.transformAnnotation
//					}
//				}
//			]
//			transformed += newVariable
//			trace.put(variable, transformed.head)
//			return transformed
//		}
//	}
//	
//	private def List<VariableDeclaration> transformValueField(ValueDeclaration variable,
//			FieldHierarchy currentField, List<ArrayTypeDefinition> arrayStack) {
//		val List<VariableDeclaration> transformed = newArrayList
//		
//		val typeDef = currentField.last.typeDefinition
//		if (typeDef instanceof RecordTypeDefinition) { // if another record
//			for (field : typeDef.fieldDeclarations) {
//				val innerField = new FieldHierarchy
//				innerField.add(currentField)
//				innerField.add(field)
//				val innerStack = <ArrayTypeDefinition>newArrayList
//				innerStack += arrayStack
//				transformed += transformValueField(variable, innerField, innerStack)
//			}
//		}
//		else {	// if simple type
//			val transformedField = createVariableDeclaration => [
//				it.name = variable.name + "_" + currentField.last.name	// TODO name provider
//				it.type = createTransformedRecordType(arrayStack, currentField.last.type)
//				if (variable instanceof InitializableElement) {
//					val initial = variable.expression
//					if (initial !== null) {
//						if (initial instanceof RecordLiteralExpression) {
//							it.expression = getExpressionFromRecordLiteral(
//								initial, currentField).transformExpression.onlyElement
//						} 
//						else if (initial instanceof ArrayLiteralExpression) {
//							it.expression = constraintFactory.createArrayLiteralExpression
//							for (op : initial.operands) {
//								if (op instanceof RecordLiteralExpression) {
//									(it.expression as ArrayLiteralExpression).operands += 
//										getExpressionFromRecordLiteral(op, currentField).transformExpression.onlyElement
//								}
//							}
//						} 
//						else if (initial instanceof FunctionAccessExpression) {
//							if (trace.isMapped(initial)) {
//								var possibleValues = trace.get(initial)
//								var VariableDeclaration currentValue = null
//								for (value : possibleValues) {
//									if (value.name.contains(currentField.last.name)) { // TODO nameprovider
//										currentValue = value
//									}
//								}
//								if (currentValue !== null) {
//									val currentValueConst = currentValue
//									it.expression = createDirectReferenceExpression => [
//										it.declaration = currentValueConst
//									]
//								}
//							}
//							else {
//								throw new IllegalArgumentException("Error when transforming function access expression: " +
//									initial + " was not yet transformed.")
//							}
//						} 
//						else {
//							throw new IllegalArgumentException("Cannot transform initial value: " + initial)
//						}
//					}
//				}
//				if (variable instanceof VariableDeclaration) {
//					for (annotation : variable.annotations) {
//						it.annotations += annotation.transformAnnotation
//					}
//				}
//			]
//			transformed += transformedField
//			trace.put(new Pair(variable, currentField), transformedField)
//		}
//		
//		return transformed	
//	}
//	
//	private def List<VariableDeclaration> transformValueArray(ValueDeclaration variable,
//			ArrayTypeDefinition currentType, List<ArrayTypeDefinition> arrayStack) {
//		val List<VariableDeclaration> transformed = newArrayList
//		
//		val TypeDefinition innerType = currentType.elementType.typeDefinition
//		if (innerType instanceof ArrayTypeDefinition) {
//			val innerStack = <ArrayTypeDefinition>newArrayList
//			innerStack += arrayStack
//			innerStack += innerType
//			transformed += transformValueArray(variable, innerType, innerStack)
//		}
//		else if (innerType instanceof RecordTypeDefinition) {
//			for (field : innerType.fieldDeclarations) {
//				val innerField = new FieldHierarchy
//				innerField.add(field)
//				val innerStack = <ArrayTypeDefinition>newArrayList
//				innerStack += arrayStack
//				transformed += transformValueField(variable, innerField, innerStack)
//			}
//			return transformed
//		}
//		else {	// Simple
//			transformed += createVariableDeclaration => [
//				it.name = variable.name
//				it.type = variable.type.transformType
//				if (variable instanceof InitializableElement) {
//					it.expression = variable.expression?.transformExpression?.getOnlyElement
//				}
//				if (variable instanceof VariableDeclaration) {
//					for (annotation : variable.annotations) {
//						it.annotations += annotation.transformAnnotation
//					}
//				}
//			]
//			trace.put(variable, transformed.head)
//		}
//		return transformed
//	}
//	
//	private def Expression getExpressionFromRecordLiteral(RecordLiteralExpression initial,
//			FieldHierarchy currentFieldHierarchy) {
//		val currentField = currentFieldHierarchy.fields
//		for (assignment : initial.fieldAssignments) {
//			val value = assignment.value
//			if (currentField.head.name == assignment.reference) {
//				if (currentField.size == 1) {
//					return value
//				}
//				else {
//					if (assignment.value instanceof RecordLiteralExpression) {
//						val innerField = new FieldHierarchy
//						innerField.add(currentField.subList(1, currentField.size))
//						return getExpressionFromRecordLiteral(
//							value as RecordLiteralExpression, innerField)
//					}
//					else {
//						throw new IllegalArgumentException("Invalid expression!")
//					}
//				}
//			}
//		}
//	}
	
}