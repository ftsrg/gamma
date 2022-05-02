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
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition

import static extension hu.bme.mit.gamma.xsts.promela.transformation.util.Namings.*
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.xsts.promela.transformation.util.ArrayHandler
import java.util.List

class DeclarationSerializer {
	// Singleton
	public static final DeclarationSerializer INSTANCE = new DeclarationSerializer
	
	// test
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final ArrayHandler arrayHandler = ArrayHandler.INSTANCE
	
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
	
	def dispatch String serializeType(TypeReference type) '''mtype:«type.reference.name»'''
	
	def dispatch String serializeType(BooleanTypeDefinition type) '''bool'''
	
	def dispatch String serializeType(IntegerTypeDefinition type) '''int'''
	
	def dispatch String serializeType(EnumerationTypeDefinition type) '''{ «FOR literal : type.literals SEPARATOR ', '»«type.costumizeEnumLiteralName(literal)»«ENDFOR» }'''
	
	def dispatch String serializeType(ArrayTypeDefinition type) '''«type.elementType.serializeType»'''
		
	// Variable
	
	protected def String serializeVariableDeclaration(VariableDeclaration variable) {
		var typeDefinition = variable.type
		if (typeDefinition instanceof ArrayTypeDefinition) {
			arrayHandler.addArray(typeDefinition, variable.name)
			return '''«typeDefinition.serializeType» «variable.name»[«arrayHandler.getArraySize(typeDefinition)»]«IF variable.expression !== null» = «variable.expression.serialize»«ENDIF»;'''
		}
		return '''«variable.type.serializeType» «variable.name»«IF variable.expression !== null» = «variable.expression.serialize»«ENDIF»;'''
	}
	
	def String serializeLocalVariableDeclaration(VariableDeclaration variable) {
		var typeDefinition = variable.type
		if (typeDefinition instanceof ArrayTypeDefinition) {
			arrayHandler.addArray(typeDefinition, variable.name)
			return '''
			local «variable.type.serializeType» «variable.name»[«arrayHandler.getArraySize(typeDefinition)»];
			«IF variable.expression !== null»
			«variable.serializeArrayAtomicInit(variable.expression)»
			«ENDIF»
			'''
		}
		return '''local «variable.serializeVariableDeclaration»'''
	}
	
	def String serializeArrayAtomicInit(Declaration declaration, Expression expression) {
		if (expression instanceof ArrayLiteralExpression) {
			val literals = arrayHandler.getAllArrayLiteral(expression)
			return '''
			«FOR i : 0 ..< literals.size»
				«declaration.name»[«i»] = «literals.get(i).serialize»;
			«ENDFOR»
			'''
		}
	}
	
	def String serializeArrayAtomicInit(Declaration declaration, Expression expression, List<Integer> indices) {
		if (expression instanceof ArrayLiteralExpression) {
			val literals = arrayHandler.getAllArrayLiteral(expression)
			return '''
			«FOR i : 0 ..< literals.size»
				«declaration.name»[«indices.get(i)»] = «literals.get(i).serialize»;
			«ENDFOR»
			'''
		}
	}
}