package hu.bme.mit.gamma.xsts.promela.transformation.util

import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import org.eclipse.emf.common.util.EList
import java.util.Map

class TypeHandler {
	// Singelton
	public static final TypeHandler INSTANCE = new TypeHandler
	protected new() {}
	
	protected Map<String, Integer> hashMap = newHashMap
	
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	def String serialize(EList<TypeDeclaration> list) {
		for (typeDeclaration : list) {
			if (typeDeclaration.type instanceof EnumerationTypeDefinition) {
				val type = typeDeclaration.type as EnumerationTypeDefinition
				for (literal : type.literals) {
					hashMap.put(typeDeclaration.name + literal.name, hashMap.size)
				}
			}
		}
		serialize
	}
	
	protected def String serialize() '''
		«FOR entry : hashMap.entrySet»
			#define «entry.key» «entry.value»
		«ENDFOR»
	'''
}