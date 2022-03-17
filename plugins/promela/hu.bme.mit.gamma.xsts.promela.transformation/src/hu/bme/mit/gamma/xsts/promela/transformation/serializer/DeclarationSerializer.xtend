package hu.bme.mit.gamma.xsts.promela.transformation.serializer

import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.expression.util.ExpressionTypeDeterminator2

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class DeclarationSerializer {
	// Singleton
	public static final DeclarationSerializer INSTANCE = new DeclarationSerializer
	
	// test
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	//protected final extension TypeHandler typeHandler = TypeHandler.INSTANCE
	protected new() {}
	
	protected final extension ExpressionTypeDeterminator2 expressionTypeDeterminator = ExpressionTypeDeterminator2.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	def String serializeDeclaration(XSTS xSts) '''
		«FOR typeDeclaration : xSts.typeDeclarations»
			«typeDeclaration.serializeTypeDeclaration»
		«ENDFOR»
		
		«FOR variableDeclaration : xSts.variableDeclarations»
			«variableDeclaration.serializeVariableDeclaration»
		«ENDFOR»
	'''
	
	// Type declaration
	
	def String serializeTypeDeclaration(TypeDeclaration typeDeclaration) '''
		mtype:«typeDeclaration.name» = «typeDeclaration.type.serializeType»
	'''
	
	// Type
	
	def dispatch String serializeType(TypeReference type) '''byte'''
	
	def dispatch String serializeType(BooleanTypeDefinition type) '''bool'''
	
	def dispatch String serializeType(IntegerTypeDefinition type) '''int'''
	
	def dispatch String serializeType(EnumerationTypeDefinition type) '''{ «FOR literal : type.literals SEPARATOR ', '»«type.typeDeclaration.name»«literal.name»«ENDFOR» }'''
		
	// Variable
	
	protected def String serializeVariableDeclaration(VariableDeclaration variable) '''
		«variable.type.serializeType» «variable.name»«IF variable.expression !== null» = «variable.expression.serialize»«ENDIF»;
	'''
	
	def String serializeLocalVariableDeclaration(VariableDeclaration variable) '''
		local «variable.serializeVariableDeclaration»
	'''
}