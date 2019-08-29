package hu.bme.mit.gamma.codegenerator.java

import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.Type

class TypeTransformer {
	
	protected extension Trace trace
	
	new(Trace trace) {
		this.trace = trace
	}
	
	/**
	 * Returns the Java type of the given Yakindu type as a string.
	 */
	protected def getEventParameterType(org.yakindu.base.types.Type type) {
		if (type !== null) {
			return type.name.transformType
		}
		return ""
	}
	
	/**
	 * Returns the Java type equivalent of the Yakindu type.
	 */
	protected def transformType(String type) {
		switch (type) {
			case "integer": 
				return "long"
			case "string": 
				return "String"
			case "real": 
				return "double"
			default:
				return type
		}
	}
	
	/**
	 * Returns the Java type equivalent of the Gamma type.
	 */
	protected def transformType(Type type) {
		switch (type) {
			IntegerTypeDefinition: {
				val types = type.getAllValuesOfFrom.filter(org.yakindu.base.types.Type).toSet
				val strings = types.filter[it.name.equals("string")]
				val integers = types.filter[it.name.equals("integer")]
				if (strings.size > 0 && integers.size > 0) {
					throw new IllegalArgumentException("Integers and string mapped to the same integer type: " + type)
				}
				if (strings.size > 0) {
					return "string"
				}
				else {
					return "long"
				}
			}				
			BooleanTypeDefinition: 
				return "boolean"
			DecimalTypeDefinition: 
				return "double"
			default:
				throw new IllegalArgumentException("Not known type: " + type)
		}
	}
}