package hu.bme.mit.gamma.ocra.transformation

import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator

class TypeSerializer {
	
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	
	def dispatch String serializeType(Type type) {
		throw new IllegalArgumentException("Not known type: " + type)
	}
	
	def dispatch String serializeType(TypeReference type) '''«type.reference.type.serializeType»'''
	
	def dispatch String serializeType(BooleanTypeDefinition type) '''boolean'''
	
	def dispatch String serializeType(IntegerTypeDefinition type) '''integer'''
	
	def dispatch String serializeType(RationalTypeDefinition type) '''real'''
	
	def dispatch String serializeType(EnumerationTypeDefinition type) '''{ «FOR literal : type.literals SEPARATOR ', '»«literal.name»«ENDFOR» }''' //??
	
	// Arrays: both sides are inclusive
	def dispatch String serializeType(ArrayTypeDefinition type) '''array 0..«
		type.size.evaluate » of «type.elementType.serializeType»''' //???	
    
}