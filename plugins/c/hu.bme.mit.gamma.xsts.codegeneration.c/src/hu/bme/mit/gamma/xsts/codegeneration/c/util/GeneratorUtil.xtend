package hu.bme.mit.gamma.xsts.codegeneration.c.util

import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.impl.ArrayLiteralExpressionImpl
import hu.bme.mit.gamma.expression.model.impl.ArrayTypeDefinitionImpl
import hu.bme.mit.gamma.xsts.codegeneration.c.serializer.VariableDeclarationSerializer
import hu.bme.mit.gamma.xsts.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.MultiaryAction

class GeneratorUtil {
	
	static val extension VariableDeclarationSerializer variableDeclarationSerializer = VariableDeclarationSerializer.INSTANCE;
	
	/**
	 * Transforms a string with underscores to camel case by converting each word's first letter
	 * after an underscore to uppercase.
	 *
	 * @param input the string to transform
	 * @return the transformed string in camel case
	 */
	static def String transformString(String input) {
  		val parts = input.split("_")
  		val transformedParts = parts.map [ it.toFirstUpper ]
  		return transformedParts.join("_")
	}
	
	/**
	 * Retrieves the length of an enumeration type.
	 *
	 * @param type The enumeration type to get the length for
	 * @return The number of literals in the enumeration type
 	 */
	static def String getLength(Type type) {
		val type_enum = type as EnumerationTypeDefinition
		return '''«type_enum.literals.size»'''
	}
	
	/**
 	 * Calculates array type based on the given ArrayTypeDefinition.
	 *
	 * @param type the ArrayTypeDefinition to generate the array type for.
	 * @param clock a boolean indicating whether it's a clock.
	 * @param name the name of the array type.
	 * @return the generated array type as a String.
	 */
	static def String getArrayType(ArrayTypeDefinition type, boolean clock, String name) {
		if (!(type.elementType instanceof ArrayTypeDefinitionImpl))
			return type.elementType.serialize(clock, name)
		return (type.elementType as ArrayTypeDefinition).getArrayType(clock, name)
	}
	
	/**
	 * Calculate the array size of an ArrayLiteralExpression recursively.
	 *
	 * @param literal the ArrayLiteralExpression to calculate the size for
	 * @return the size of the ArrayLiteralExpression as an array String
	 */
	static def String getLiteralSize(ArrayLiteralExpression literal) {
		if (literal.operands.head instanceof ArrayLiteralExpressionImpl)
			return '''[«literal.operands.size»]«getLiteralSize(literal.operands.head as ArrayLiteralExpression)»'''
		return '''[«literal.operands.size»]'''
	}
	
	/**
	 * Checks if a MultiaryAction is empty, meaning it has no actions or contains only EmptyAction instances.
	 *
	 * @param action The MultiaryAction to be checked
	 * @return `true` if the MultiaryAction is empty, `false` otherwise
	 */
	static def boolean isEmpty(MultiaryAction action) {
		return action.empty || action.actions.filter[!(it instanceof EmptyAction)].size == 0
	}
	
}