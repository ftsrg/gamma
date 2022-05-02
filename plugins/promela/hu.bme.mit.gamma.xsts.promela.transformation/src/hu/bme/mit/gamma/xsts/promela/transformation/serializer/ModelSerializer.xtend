package hu.bme.mit.gamma.xsts.promela.transformation.serializer

import hu.bme.mit.gamma.xsts.model.XSTS

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.IfAction
import hu.bme.mit.gamma.xsts.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.HavocAction
import hu.bme.mit.gamma.xsts.model.LoopAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.promela.transformation.util.HavocHandler
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression

class ModelSerializer {
	// Singleton
	public static final ModelSerializer INSTANCE = new ModelSerializer
	protected new() {}
	// Auxiliary objects
	protected final extension DeclarationSerializer declarationSerializer = DeclarationSerializer.INSTANCE
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final extension HavocHandler havocHandler = HavocHandler.INSTANCE
	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
	
	def String serializePromela(XSTS xSts) '''
		«xSts.serializeDeclaration»
		
		byte flag = 0;
		
		
		proctype EnvTrans() {
			(flag > 0);
		ENV:
			atomic {
				«xSts.environmentalAction.serialize»
				flag = 2;
			};
			goto TRANS;
		TRANS:
			atomic {
				«FOR transition : xSts.transitions»
					«transition.action.serialize»
				«ENDFOR»
				flag = 1;
			};
			goto ENV;
		}
		
		init {
			atomic {
				«xSts.initializingAction.serialize»
				run EnvTrans();
				flag = 1;
			}
		}
	'''
	
	
	def dispatch String serialize(AssumeAction action) '''
		if
		:: («action.assumption.serialize»);
		fi;
	'''
	
	def dispatch String serialize(AssignmentAction action) {
		var lhsExpression = action.lhs
		var lhsType = lhsExpression.declaration.typeDefinition
		if (lhsType instanceof ArrayTypeDefinition) {
			if (lhsExpression instanceof ArrayAccessExpression) {
				if (arrayHandler.getDimensions(lhsExpression).size != arrayHandler.getDimensions(lhsType).size) {
					val indices = arrayHandler.getIndices(lhsExpression)
					val arrayLiteralExp = action.rhs as ArrayLiteralExpression
					return '''«lhsExpression.declaration.serializeArrayAtomicInit(arrayLiteralExp, indices)»'''
				}
			}
			else {
				val arrayLiteralExp = action.rhs as ArrayLiteralExpression
				return '''«lhsExpression.declaration.serializeArrayAtomicInit(arrayLiteralExp)»'''
			}
		}
		return '''«action.lhs.serialize» = «action.rhs.serialize»;'''
	}
	
	def dispatch String serialize(VariableDeclarationAction action) '''
		«action.variableDeclaration.serializeLocalVariableDeclaration»
	'''
	
	def dispatch String serialize(EmptyAction action) ''''''
	
	def dispatch String serialize(IfAction action) '''
		if
		:: «action.condition.serialize» -> 
			«action.then.serialize»
		«IF action.^else !== null && !(action.^else instanceof EmptyAction)»
		:: else ->
			«action.^else.serialize»
		«ELSE»
		:: else
		«ENDIF»
		fi;
	'''
	
	def dispatch String serialize(HavocAction action) {
		val xStsDeclaration = action.lhs.declaration
		val xStsVariable = xStsDeclaration as VariableDeclaration
		
		return '''
			if
			«FOR i : xStsVariable.createSet»
			:: «xStsVariable.name» = «i»;
			«ENDFOR»
			fi;'''
	}
	
	def dispatch String serialize(LoopAction action) {
		val name = action.iterationParameterDeclaration.name
		val left = action.range.getLeft(true)
		val right = action.range.getRight(true)
		return '''
			int «name»;
			for («name» : «left.serialize»..«right.serialize») {
				«action.action.serialize»
			}
		'''
	}
	
	def dispatch String serialize(NonDeterministicAction action) '''
		if
		«FOR subaction : action.actions»
		:: «subaction.serialize»
		«ENDFOR»
		fi;
	'''
	
	def dispatch String serialize(SequentialAction action) '''
		«FOR subaction : action.actions»
			«subaction.serialize»
		«ENDFOR»
	'''
}