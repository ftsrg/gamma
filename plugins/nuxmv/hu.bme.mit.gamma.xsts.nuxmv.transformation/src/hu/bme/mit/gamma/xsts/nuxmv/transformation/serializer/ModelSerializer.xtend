package hu.bme.mit.gamma.xsts.nuxmv.transformation.serializer

import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.Action

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*
import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
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
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.xsts.model.ParallelAction
import java.util.ArrayList

class ModelSerializer {
	// Singleton
	public static ModelSerializer INSTANCE = new ModelSerializer
	protected new() {}
	//
	
	protected final Map<Declaration, String> names = newHashMap
	protected final List<String> serialized = new ArrayList
	
	//
	protected final extension DeclarationSerializer declarationSerializer = DeclarationSerializer.INSTANCE
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final extension ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE
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
		
		«initializingActions.serializeInitializingAction»
		
		TRANS	
			«environmentalActions.serializeTransition»
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
	
	protected def dispatch String serializeInitializingAction(AssignmentAction action) {
		return '''INIT «action.lhs.serialize» = «action.rhs.serialize»'''
	}
	
	protected def dispatch String serializeTransition(AssignmentAction action) {
		return '''next(«action.lhs.serialize») = «action.rhs.serialize»'''
	}
	
	protected def dispatch String serialize(VariableDeclarationAction action) {
		val variableDeclaration = action.variableDeclaration
		return variableDeclaration.serializeVariableDeclaration
	}
	
	protected def dispatch String serializeTransition(VariableDeclarationAction action) {
		val variableDeclaration = action.variableDeclaration
		val expression = variableDeclaration.expression
		if (expression === null) {
			return ''''''
		} else {
			return '''
				«variableDeclaration.serializeName» = «expression.serialize»
			'''
		}
	}

	protected def dispatch String serialize(EmptyAction action) ''''''

	protected def dispatch String serializeInitializingAction(EmptyAction action) ''''''

	protected def dispatch String serializeTransition(EmptyAction action) ''''''
	
	
	
	protected def dispatch String serialize(IfAction action) '''
		«action.condition.serialize» -> «action.then.serialize»;
	'''
	
	protected def dispatch String serializeTransition(IfAction action) '''
		«action.condition.serialize» -> «action.then.serializeTransition»
	'''
	
	protected def dispatch String serialize(HavocAction action) {
		val xStsDeclaration = action.lhs.declaration
		val xStsVariable = xStsDeclaration as VariableDeclaration

		return '''
		«xStsVariable.name» = {«FOR element : xStsVariable.createSet SEPARATOR ', '»«element.serialize»«ENDFOR»};
		'''
	}
	
	protected def dispatch String serializeTransition(HavocAction action) {
		val xStsDeclaration = action.lhs.declaration
		val xStsVariable = xStsDeclaration as VariableDeclaration

		return '''
		next(«xStsVariable.name») = {«FOR element : xStsVariable.createSet SEPARATOR ', '»«element.serialize»«ENDFOR»}
		'''
	}
	
	protected def dispatch String serialize(LoopAction action) {
		if (isEvaluable(action.range)) {
			val paramDeclaration = action.iterationParameterDeclaration
			val range = action.range.evaluateRange
			val sequentializedLoop = '''(«FOR i : range SEPARATOR ' & '»«action.action.serialize.replace(paramDeclaration.name, i.toString)»«ENDFOR»)'''
			
			return sequentializedLoop
		} else {
			throw new IllegalArgumentException("Only evaluable loops can be serialized! " + action)
		}
	}
	
	protected def dispatch String serializeInitializingAction(LoopAction action) {
		if (isEvaluable(action.range)) {
			val paramDeclaration = action.iterationParameterDeclaration
			val range = action.range.evaluateRange
			val sequentializedLoop = '''
			«FOR i : range»
			«action.action.serializeInitializingAction.replace(paramDeclaration.name, i.toString)»
			«ENDFOR»
			'''
			
			return sequentializedLoop
		} else {
			throw new IllegalArgumentException("Only evaluable loops can be serialized! " + action)
		}
	}
	
		protected def dispatch String serializeTransition(LoopAction action) {
		if (isEvaluable(action.range)) {
			val paramDeclaration = action.iterationParameterDeclaration
			val range = action.range.evaluateRange
			val sequentializedLoop = '''(«FOR i : range SEPARATOR ' & '»«action.action.serializeTransition.replace(paramDeclaration.name, i.toString)»«ENDFOR»)'''
			
			return sequentializedLoop
		} else {
			throw new IllegalArgumentException("Only evaluable loops can be serialized! " + action)
		}
	}
	
	
	
	
	protected def dispatch String serialize(NonDeterministicAction action) {
		return '''
		{«FOR subaction : action.actions SEPARATOR ', '»«subaction.serialize»«ENDFOR»}
		'''
	}
	
	protected def dispatch String serialize(SequentialAction action) '''
		(«FOR subaction : action.actions SEPARATOR ' & '»«subaction.serialize»«ENDFOR»)
	'''

	protected def dispatch String serializeInitializingAction(SequentialAction action) {
		var ret = ''''''
		for (subaction : action.actions.reverseView) {
			if (subaction instanceof AssignmentAction) {
				if (!serialized.contains(subaction.lhs.serialize)) {
					serialized.add(subaction.lhs.serialize)
					ret += subaction.serializeInitializingAction+'\n'
				}
			} else {
				ret += subaction.serializeInitializingAction+'\n'
			}
		}
		return ret
	}

	// AssumeActions should be the first in the sequence, everywhere else is disregarded
	protected def dispatch String serializeTransition(SequentialAction action) '''
		«IF action.isFirstActionAssume»
			((«action.getFirstActionAssume.assumption.serialize») -> (
			«FOR sequentialSubaction : action.actionsSkipFirst.filter[!(it instanceof AssumeAction) && !it.effectlessAction && !(it instanceof VariableDeclarationAction)] SEPARATOR ' & '»
			«sequentialSubaction.serialize»
			«ENDFOR»
			))
		«ELSE»
			(«FOR subaction : action.actions.filter[!(it instanceof AssumeAction) && !it.effectlessAction && !(it instanceof VariableDeclarationAction)] SEPARATOR ' & '»«subaction.serializeTransition»«ENDFOR»)
		«ENDIF»
	'''
	
	protected def dispatch String serialize(ParallelAction action) {throw new IllegalArgumentException("ParallelAction cannot be serialized! " + action)}
	protected def dispatch String serializeInitializingAction(ParallelAction action) {throw new IllegalArgumentException("ParallelAction cannot be serialized! " + action)}
	protected def dispatch String serializeTransition(ParallelAction action) {throw new IllegalArgumentException("ParallelAction cannot be serialized! " + action)}
		
		//
	
	protected def serializeTransitions(List<? extends XTransition> transitions) {
		if (transitions.size > 1) {
			return '''
					«FOR transition : transitions»
					«transition.action.serializeTransition»;
					«ENDFOR»
			'''
		}
		else {
			return '''«transitions.head.action.serializeTransition»;'''
		}
	}

}