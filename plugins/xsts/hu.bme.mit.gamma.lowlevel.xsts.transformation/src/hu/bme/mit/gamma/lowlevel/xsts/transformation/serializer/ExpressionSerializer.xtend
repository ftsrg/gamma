package hu.bme.mit.gamma.lowlevel.xsts.transformation.serializer

import hu.bme.mit.gamma.expression.model.ElseExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.xsts.model.model.PrimedVariable

import static extension hu.bme.mit.gamma.xsts.model.derivedfeatures.XSTSDerivedFeatures.*

class ExpressionSerializer extends hu.bme.mit.gamma.expression.util.ExpressionSerializer {
	
	override String _serialize(ElseExpression expression) {
		// No op, this cannot be transformed on this level
		throw new IllegalArgumentException("Cannot be transformed")
	}
	
	override String _serialize(EnumerationLiteralExpression expression) '''«expression.reference.name»'''
	
	override String _serialize(ReferenceExpression expression) {
		val declaration = expression.declaration
		if (declaration instanceof PrimedVariable) {
			return '''next(«declaration.originalVariable.name»)'''
		}
		return '''«declaration.name»'''
	}
	
}