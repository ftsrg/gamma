package hu.bme.mit.gamma.xsts.codegeneration.java

import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration

import static extension hu.bme.mit.gamma.xsts.model.derivedfeatures.XSTSDerivedFeatures.*

class ExpressionSerializer extends hu.bme.mit.gamma.codegenerator.java.util.ExpressionSerializer {
	
	override dispatch String serialize(ReferenceExpression expression) {
		val declaration = expression.declaration
		if (declaration instanceof VariableDeclaration) {
			// 'this' is important as without it, the reference would refer to the temporary variable
			return '''this.«declaration.originalVariable.name»'''
		}
		return declaration.name
	}
	
}