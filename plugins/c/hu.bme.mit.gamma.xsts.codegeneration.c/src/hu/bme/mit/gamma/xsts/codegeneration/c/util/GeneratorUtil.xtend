package hu.bme.mit.gamma.xsts.codegeneration.c.util

import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.xsts.model.MultiaryAction
import hu.bme.mit.gamma.xsts.model.EmptyAction

class GeneratorUtil {
	
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
	 * Checks if a MultiaryAction is empty, meaning it has no actions or contains only EmptyAction instances.
	 *
	 * @param action The MultiaryAction to be checked
	 * @return `true` if the MultiaryAction is empty, `false` otherwise
	 */
	static def boolean isEmpty(MultiaryAction action) {
		return action.empty || action.actions.filter[!(it instanceof EmptyAction)].size == 0
	}
	
}