/********************************************************************************
 * Copyright (c) 2024-2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.expression.model.AddExpression
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.DecimalLiteralExpression
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.DivExpression
import hu.bme.mit.gamma.expression.model.DivideExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.FalseExpression
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression
import hu.bme.mit.gamma.expression.model.FunctionDeclaration
import hu.bme.mit.gamma.expression.model.GreaterEqualExpression
import hu.bme.mit.gamma.expression.model.GreaterExpression
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.ImplyExpression
import hu.bme.mit.gamma.expression.model.InequalityExpression
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.LessEqualExpression
import hu.bme.mit.gamma.expression.model.LessExpression
import hu.bme.mit.gamma.expression.model.LiteralExpression
import hu.bme.mit.gamma.expression.model.MultiplyExpression
import hu.bme.mit.gamma.expression.model.NotExpression
import hu.bme.mit.gamma.expression.model.NullaryExpression
import hu.bme.mit.gamma.expression.model.OpaqueExpression
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.SubtractExpression
import hu.bme.mit.gamma.expression.model.TrueExpression
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.UnaryMinusExpression
import hu.bme.mit.gamma.expression.model.UnaryPlusExpression
import hu.bme.mit.gamma.expression.model.XorExpression
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.property.util.ExpressionTypeDeterminator
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceQueueSizeReferenceExpression
import hu.bme.mit.gamma.xsts.model.FunctionCallAction
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.List

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.iml.transformation.util.Namings.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.QueueNamings.*

class ImlPropertyExpressionSerializer extends ThetaPropertyExpressionSerializer {
	//
	protected final extension ExpressionTypeDeterminator typeDeterminator = ExpressionTypeDeterminator.INSTANCE
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	//
	protected final String OPAQUE_PREFIX = "language IML"
	//
	
	new(AbstractReferenceSerializer referenceSerializer) {
		super(referenceSerializer)
	}
	
	// Int-float related operators (in OCaml, there is no automatic conversion between the two)
	
	override String _serialize(AddExpression expression) { expression.operands.adjustArithmeticExpression("+") }
	
	override String _serialize(SubtractExpression expression) { expression.adjustArithmeticExpression("-") }
	
	override String _serialize(MultiplyExpression expression) { expression.operands.adjustArithmeticExpression("*") }
	
	override String _serialize(DivideExpression expression) { expression.adjustArithmeticExpression("/") }
	
	override String _serialize(DivExpression expression) { expression.adjustArithmeticExpression("/") }
	
	override String _serialize(LessExpression expression) { expression.adjustArithmeticExpression("<") }
	
	override String _serialize(LessEqualExpression expression) { expression.adjustArithmeticExpression("<=") }
	
	override String _serialize(GreaterExpression expression) { expression.adjustArithmeticExpression(">") }
	
	override String _serialize(GreaterEqualExpression expression) { expression.adjustArithmeticExpression(">=") }
	
	protected def adjustArithmeticExpression(BinaryExpression expression, String operator) {
		return #[expression.leftOperand, expression.rightOperand].adjustArithmeticExpression(operator)
	}
	
	protected def adjustArithmeticExpression(List<? extends Expression> operands, String operator) {
		val operandTypes = operands.map[it.typeDefinition]
		val isEachOperandInteger = operandTypes.forall[it instanceof IntegerTypeDefinition]
		
		if (isEachOperandInteger) {
			return '''(«FOR operand : operands SEPARATOR ''' «operator» '''»«operand.serialize»«ENDFOR»)'''
		}
		// There is a decimal operand
		val OPERAND_PREFIX = "Real.of_int "
		val OPERATOR_POSTFIX = "."
		
		return '''(«FOR operand : operands SEPARATOR ''' «operator»«OPERATOR_POSTFIX» '''»«IF
				operand.typeDefinition instanceof IntegerTypeDefinition &&
					operand instanceof NullaryExpression && operand instanceof LiteralExpression»«
				OPERAND_PREFIX»«ENDIF»«operand.serialize»«ENDFOR»)'''
	}
	
	//
	
	override String _serialize(UnaryPlusExpression expression) '''(«super._serialize(expression)»)'''
	
	override String _serialize(UnaryMinusExpression expression) '''(«super._serialize(expression)»)'''
	
	override String _serialize(IntegerLiteralExpression expression) {
		val string = super._serialize(expression)
		val value = expression.value
		if (value.signum < 0) {
			return '''(«string»)''' // For some reason, IML needs this
		}
		return string
	}
	
	override String _serialize(DecimalLiteralExpression expression) {
		val string = super._serialize(expression)
		val value = expression.value
		if (value.signum < 0) {
			return '''(«string»)''' // For some reason, IML needs this
		}
		return string
	}
	
	override String _serialize(OpaqueExpression expression) {
		val string = expression.expression
		return string.serializeOpaqueElement
	}
	
	override String _serialize(TrueExpression expression) '''true'''

	override String _serialize(FalseExpression expression) '''false'''
	
	override String _serialize(NotExpression expression) '''(not («expression.operand.serialize»))'''
	
	override String _serialize(ImplyExpression expression) '''(«expression.leftOperand.serialize» ==> «expression.rightOperand.serialize»)'''
	
	override String _serialize(XorExpression expression) '''(«FOR operand : expression.operands SEPARATOR " <> "»«operand.serialize»«ENDFOR»)'''
	
	override String _serialize(EqualityExpression expression) '''(«expression.leftOperand.serialize» = «expression.rightOperand.serialize»)'''
	
	override String _serialize(InequalityExpression expression) '''(«expression.leftOperand.serialize» <> «expression.rightOperand.serialize»)'''
	
	override String _serialize(IfThenElseExpression expression) '''(if «expression.condition.serialize» then «expression.then.serialize» else «expression.^else.serialize»)'''

	override String _serialize(EnumerationLiteralExpression expression) '''«expression.typeReference.reference.serializeName».«expression.serializeName»''' // See module elements when serializing type declarations
	
	override String _serialize(DirectReferenceExpression expression) {
		val declaration = expression.declaration
		val id = (declaration instanceof ParameterDeclaration) ? '' : // Function declaration's parameter
				declaration.id + "." // Default: 'r' or 'l'
		return '''«id»«declaration.serializeName»'''
	}
	
	override String _serialize(ArrayAccessExpression arrayAccessExpression) '''(Map.get «arrayAccessExpression.index.serialize» «arrayAccessExpression.operand.serialize»)'''
	
	override String _serialize(ArrayLiteralExpression expression) {
		val operands = expression.operands
		val typeDefinition = expression.typeDefinition as ArrayTypeDefinition
		
		val defaultExpression = typeDefinition.elementType.defaultExpression
		val imlDefaultValue = defaultExpression.serialize
		
		var imlArrayLiteral = '''(Map.const «imlDefaultValue»)'''
		
		if (!defaultExpression.typeDefinition.array) {
			val evaluatedDefaultExpression = defaultExpression.evaluate
			if (operands.forall[it.helperEquals(defaultExpression) || it.evaluable && it.evaluate == evaluatedDefaultExpression]) {
				return imlArrayLiteral.toString // No need for Map.add commands
			}
		}
		
		for (var i = 0; i < operands.size; i++) {
			val operand = operands.get(i)
			imlArrayLiteral = '''(Map.add «i» «operand.serialize» «imlArrayLiteral»)'''
		} 
		
		return imlArrayLiteral
	}
	
	override String _serialize(FunctionAccessExpression expression) {
		val isExpression = !(expression.eContainer instanceof FunctionCallAction) // As rhs - cannot support functions with both a side effect and return value
		val hasSideEffect = expression.hasFunctionCallSideEffect
		val function = expression.operand.declaration as FunctionDeclaration
		val isLambda = function.lambdaDeclaration
		
		val functionCall = '''(«function.serializeName» «GLOBAL_RECORD_IDENTIFIER» «
				FOR argument : expression.arguments SEPARATOR ' '»«argument.serialize»«ENDFOR»)'''
		
		if (isLambda || /* (r) is not returned */
				isExpression && hasSideEffect /* Special code handles this case at a higher (assignment) level */) {
			// See ActionSerializer.serializeAction: 'needR'
			return functionCall
		}
		
		val string = '''let «GLOBAL_RECORD_IDENTIFIER», «FUNCTION_RETURN_VALUE_NAME» = «
				functionCall» in«IF isExpression» «FUNCTION_RETURN_VALUE_NAME»«ENDIF»'''
		
		return (isExpression) ?
			'''(«string»)''' :
			string
	}
	
	def getFunctionReturnValues() '''«GLOBAL_RECORD_IDENTIFIER», «LOCAL_RECORD_IDENTIFIER».«FUNCTION_RETURN_VALUE_NAME.customizeDeclarationName»'''
	
	def serializeOpaqueElement(String string) {
		val IML = "language IML"
		if (string.startsWith(IML)) {
			val serialization = string.substring(IML.length).trim
			return serialization
		}
		return ""
	}
	
	//
	
	def String serializeName(Declaration declaration) {
		val customizedName = (declaration.local) ?
			declaration.customizeLocalDeclarationName : // To avoid having the same names in different record types
			declaration.customizeName
		return customizedName
	}
	
	def String serializeName(TypeDeclaration declaration) {
		val customizedName = declaration.customizeName
		return customizedName
	}
	
	def String serializeName(EnumerationLiteralExpression literal) {
		val customizedName = literal.customizeName
		return customizedName
	}
	
	def String serializeName(EnumerationLiteralDefinition literal) {
		val customizedName = literal.customizeName
		return customizedName
	}
	
	//
	
	def getId(Declaration declaration) {
		return ImlReferenceSerializer.recordIdentifier
	}
	
	// Unique - do not delete!
	
	protected override dispatch serializeStateExpression(ComponentInstanceQueueSizeReferenceExpression expression) {
		val instance = expression.instance
		val queue = expression.queue
		val capacity = evaluator.evaluate(queue.capacity)
		val r = ImlReferenceSerializer.recordIdentifier
		val imlQueueName = queue.getId(instance).customizeDeclarationName
		return (capacity > 1) ?
			'''(List.length «r».«imlQueueName»)''' :
			expression.get1CapacityQueueEmptyExpression
					.createIfThenElseExpression(0.toIntegerLiteral, 1.toIntegerLiteral)._serialize
	}
	
	protected override get1CapacityQueueEmptyExpression(ComponentInstanceQueueSizeReferenceExpression expression) {
		val instance = expression.instance
		val queue = expression.queue
		val queueName = queue.getId(instance)
		val imlQueueName = queue.getId(instance).customizeDeclarationName
		val r = ImlReferenceSerializer.recordIdentifier
		return '''«OPAQUE_PREFIX»«r».«imlQueueName» = «
						TYPE_DECLARATION_NAME_PREFIX»«queueName.getQueueTypeName».«
						emptyLiteralName.customizeEnumLiteralName»'''
				.createOpaqueExpression
	}
	
}