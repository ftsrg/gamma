package hu.bme.mit.gamma.xsts.nuxmv.transformation.serializer

import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.XSTS

class DeclarationSerializer {
	// Singleton
	public static final DeclarationSerializer INSTANCE = new DeclarationSerializer
	protected new() {}
	//
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final extension TypeSerializer typeSerializer = TypeSerializer.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	//
	def String serializeDeclaration(XSTS xSts) '''
«««		«FOR type : xSts.getAllContentsOfType(ArrayTypeDefinition).allArrayTypeDefinition»
«««			«IF type.elementType instanceof ArrayTypeDefinition»«type.elementType.serializeArrayTypeDeclaration»«ENDIF»
«««		«ENDFOR»
«««		
«««		«FOR typeDeclaration : xSts.typeDeclarations»
«««			«typeDeclaration.serializeTypeDeclaration»
«««		«ENDFOR»
«««		
		«FOR variableDeclaration : xSts.variableDeclarations»
			«variableDeclaration.serializeVariableDeclaration»
		«ENDFOR»
	'''
	
	protected def String serializeVariableDeclaration(VariableDeclaration variable) {
		val type = variable.type
		return '''
			«variable.serializeName» : «type.serializeType»;
		'''
	}
	
	protected def String serializeName(Declaration variable) {
		val name = variable.name
		return name
	}
}