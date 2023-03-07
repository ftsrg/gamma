package hu.bme.mit.gamma.xsts.nuxmv.transformation.serializer

import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.util.GammaEcoreUtil

class DeclarationSerializer {
	// Singleton
	public static final DeclarationSerializer INSTANCE = new DeclarationSerializer
	protected new() {}
	//
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
«««		«FOR variableDeclaration : xSts.variableDeclarations
«««				// Native message queue handling
«««				.filter[!Configuration.HANDLE_NATIVE_MESSAGE_QUEUES || !xSts.messageQueueSizeGroup.variables.contains(it)]»
«««			«variableDeclaration.serializeVariableDeclaration»
«««		«ENDFOR»
		TODO
	'''
}