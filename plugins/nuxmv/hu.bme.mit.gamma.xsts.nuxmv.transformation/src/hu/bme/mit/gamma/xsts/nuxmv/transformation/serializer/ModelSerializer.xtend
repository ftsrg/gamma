package hu.bme.mit.gamma.xsts.nuxmv.transformation.serializer

import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.Action

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.IfAction
import hu.bme.mit.gamma.xsts.model.HavocAction
import hu.bme.mit.gamma.xsts.model.LoopAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.XTransition
import java.util.List
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.xsts.nuxmv.transformation.util.HavocHandler
import java.util.Map
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.util.GammaEcoreUtil

class ModelSerializer {
	// Singleton
	public static ModelSerializer INSTANCE = new ModelSerializer
	protected new() {}
	//
	
	protected final Map<Declaration, String> names = newHashMap
	
	//
	protected final extension DeclarationSerializer declarationSerializer = DeclarationSerializer.INSTANCE
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final extension TypeSerializer typeSerializer = TypeSerializer.INSTANCE
	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
	protected final extension HavocHandler havocHandler = HavocHandler.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	def String serializeNuxmv(XSTS xSts) {
		xSts.customizeLocalVariableNames
		
		val initializingActions = xSts.initializingAction
		val environmentalActions = xSts.environmentalAction
		
		val actions = <Action>newArrayList
		actions += initializingActions
		actions += environmentalActions
		
		val transitions = xSts.transitions
		for (transition : transitions) {
			actions += transition.action
		}
		
		val model = '''
		MODULE main
		VAR
			«xSts.serializeDeclaration»
«««		IVAR
«««			«environmentalActions.serialize»
		
		«initializingActions.serializeInitializingActions»
		
		TRANS	
			«transitions.serializeTransitions»
		'''
		
		xSts.restoreLocalVariableNames
		
		return model
	}
	
	//
	// Second hash is needed as nuXmv does not support local variables with the same name in different scopes
	protected def customizeLocalVariableNames(XSTS xSts) {
		names.clear
		for (localVariableAction : xSts.getAllContentsOfType(VariableDeclarationAction)) {
			val localVariable = localVariableAction.variableDeclaration
			val name = localVariable.name
			names += localVariable -> name
			
			localVariable.name = localVariable.name + localVariable.hashCode.toString.replaceAll("-","_")
		}
	}
	
	protected def restoreLocalVariableNames(XSTS xSts) {
		for (localVariableAction : xSts.getAllContentsOfType(VariableDeclarationAction)) {
			val localVariable = localVariableAction.variableDeclaration
			val name = names.get(localVariable)
			
			localVariable.name = name
		}
	}
	
	//
	
	protected def dispatch String serialize(AssignmentAction action) {
		return '''«action.lhs.serialize» = «action.rhs.serialize»'''
	}
	
	protected def dispatch String serializeTransition(AssignmentAction action) {
		return '''next(«action.lhs.serialize») = «action.rhs.serialize»'''
	}
	
	protected def dispatch String serializeInitializingActions(AssignmentAction action) {
		return '''INIT «action.lhs.serialize» = «action.rhs.serialize»'''
	}
	
	protected def dispatch String serialize(VariableDeclarationAction action) {
		val variableDeclaration = action.variableDeclaration
		return variableDeclaration.serializeVariableDeclaration
	}
	
	protected def dispatch String serializeTransition(VariableDeclarationAction action) {
		val variableDeclaration = action.variableDeclaration
		val expression = variableDeclaration.expression
		if (expression === null) {
			return '''
				ERROR
			'''
		} else {
			return '''
				«variableDeclaration.serializeName» = «expression.serialize»
			'''
		}

	}

	protected def dispatch String serialize(AssumeAction action) '''
		ASSUME TODO «action.assumption.serialize»
	'''

	protected def dispatch String serialize(EmptyAction action) ''''''

	protected def dispatch String serializeTransition(EmptyAction action) ''''''
	
	protected def dispatch String serialize(IfAction action) '''
«««		case
			«action.condition.serialize» -> «action.then.serialize»;
«««			«IF action.^else !== null && !(action.^else instanceof EmptyAction)»
«««			TRUE : «action.^else.serialize»;
«««			«ENDIF»
«««		esac
	'''
	
	protected def dispatch String serializeTransition(IfAction action) '''
«««		case
			«action.condition.serialize» -> «action.then.serializeTransition»
«««			«IF action.^else !== null && !(action.^else instanceof EmptyAction)»
«««			!(«action.condition.serialize») -> «action.^else.serialize»;
«««			«ENDIF»
«««		esac
	'''
	
	protected def dispatch String serialize(HavocAction action) {
//		return "HAVOC TODO"
		val xStsDeclaration = action.lhs.declaration
		val xStsVariable = xStsDeclaration as VariableDeclaration

		return '''
		-- HAVOC TODO
		«xStsVariable.name» = {«FOR element : xStsVariable.createSet SEPARATOR ', '»«element.serialize»«ENDFOR»};
		'''
	}
	
	protected def dispatch String serialize(LoopAction action) {
		return "Loop TODO"
//		val name = action.iterationParameterDeclaration.name
//		val left = action.range.getLeft(true)
//		val right = action.range.getRight(true)
//		return '''
//			local int «name»;
//			for («name» : «left.serialize»..«right.serialize») {
//				«action.action.serialize»
//			}
//			«name» = 0;
//		'''
	}
	
	protected def dispatch String serialize(NonDeterministicAction action) {
		return '''
		{«FOR subaction : action.actions SEPARATOR ', '»«subaction.serialize»«ENDFOR»}
		'''
	
	}
	
	protected def dispatch String serializeInitializingActions(SequentialAction action) '''
		«FOR subaction : action.actions»
			«subaction.serializeInitializingActions /* Original action*/»
		«ENDFOR»
	'''
	
	protected def dispatch String serialize(SequentialAction action) '''
		(«FOR subaction : action.actions SEPARATOR ' & '»«subaction.serialize»«ENDFOR»)
	'''

	protected def dispatch String serializeTransition(SequentialAction action) '''
		(«FOR subaction : action.actions SEPARATOR ' & '»«subaction.serializeTransition»«ENDFOR»)
	'''
		
		//
	
	protected def serializeTransitions(List<? extends XTransition> transitions) {
		if (transitions.size > 1) {
			return '''
					«FOR transition : transitions»
					:: «transition.action.serialize»;
					«ENDFOR»
			'''
		}
		else {
			return '''«transitions.head.action.serializeTransition»;'''
		}
	}
	
	protected def SequentialAction getLastInitializations(SequentialAction action) {
		return action
	}
}