package hu.bme.mit.gamma.xsts.nuxmv.transformation.serializer

import com.google.common.collect.ArrayListMultimap
import com.google.common.collect.Multimap
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.HavocAction
import hu.bme.mit.gamma.xsts.model.IfAction
import hu.bme.mit.gamma.xsts.model.LoopAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.ParallelAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XTransition
import hu.bme.mit.gamma.xsts.nuxmv.transformation.util.HavocHandler
import java.util.List
import java.util.Map

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class ModelSerializer {
	// Singleton
	public static ModelSerializer INSTANCE = new ModelSerializer
	protected new() {}
	//
	
	protected final Map<Declaration, String> names = newHashMap
	protected final Multimap<String, Pair<Expression, Action>> transitionMap = ArrayListMultimap.create
	protected final Multimap<String, Pair<Expression, Action>> environmentMap = ArrayListMultimap.create
	protected final List<String> serialized = newArrayList
	
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
		
		transitions.mapTransition(transitionMap, null)
		environmentalActions.mapTransition(environmentMap, null)
			
		val model = '''
		MODULE main
		VAR
			envStep : boolean
			«xSts.serializeDeclaration»
			
		ASSIGN
			init(envStep) := TRUE
			«initializingActions.serializeInitializingAction»
			
			next(envStep) := !envStep
			
			«environmentMap.serializeTransitions(true)»
			
			«transitionMap.serializeTransitions(false)»
«««		TRANS
«««			«environmentalActions.serializeTransition»
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
		return '''«action.rhs.serialize»'''
	}
	
	protected def dispatch String serializeInitializingAction(AssignmentAction action) {
		return '''init(«action.lhs.serialize») := «action.rhs.serialize»'''
	}
	
	protected def dispatch String serializeTransition(AssignmentAction action) {
		return '''next(«action.lhs.serialize») = «action.rhs.serialize»'''
	}
	
	protected def dispatch mapTransition(AssignmentAction action, Multimap<String, Pair<Expression, Action>> map, Expression assumption) {
		map.put(action.lhs.serialize, new Pair(assumption, action))
	}
	
	
	protected def dispatch String serialize(VariableDeclarationAction action) {
		val variableDeclaration = action.variableDeclaration
		return variableDeclaration.expression.serialize
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
	
	protected def dispatch mapTransition(VariableDeclarationAction action, Multimap<String, Pair<Expression, Action>> map, Expression assumption) {
		val variableDeclaration = action.variableDeclaration
		val expression = variableDeclaration.expression
		if (expression !== null) {
			map.put(expression.serialize, new Pair(assumption, action))
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
	
	protected def dispatch mapTransition(IfAction action, Multimap<String, Pair<Expression, Action>> map, Expression assumption) {
		var condition = action.condition
		
		if (assumption !== null) {
			condition = assumption.wrapIntoAndExpression(action.condition)				
		}
		
		action.then.mapTransition(map, condition)
	}
	
	protected def dispatch String serialize(HavocAction action) {
		val xStsDeclaration = action.lhs.declaration
		val xStsVariable = xStsDeclaration as VariableDeclaration

		return '''
		{«FOR element : xStsVariable.createSet SEPARATOR ', '»«element.serialize»«ENDFOR»}
		'''
	}
	
	protected def dispatch String serializeTransition(HavocAction action) {
		val xStsDeclaration = action.lhs.declaration
		val xStsVariable = xStsDeclaration as VariableDeclaration

		return '''
		next(«xStsVariable.name») = {«FOR element : xStsVariable.createSet SEPARATOR ', '»«element.serialize»«ENDFOR»}
		'''
	}
	
	protected def dispatch mapTransition(HavocAction action, Multimap<String, Pair<Expression, Action>> map, Expression assumption) {
		map.put(action.lhs.serialize, new Pair(assumption, action))
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
	
	protected def dispatch mapTransition(LoopAction action, Multimap<String, Pair<Expression, Action>> map, Expression assumption) {
		if (isEvaluable(action.range)) {
			val paramDeclaration = action.iterationParameterDeclaration
			val range = action.range.evaluateRange
			
			for (i : range) {
				//TODO
			}
			val sequentializedLoop = '''(«FOR i : range SEPARATOR ' & '»«action.action.serializeTransition.replace(paramDeclaration.name, i.toString)»«ENDFOR»)'''

		} else {
			throw new IllegalArgumentException("Only evaluable loops can be serialized! " + action)
		}
	}
	
	
	
	protected def dispatch String serialize(NonDeterministicAction action) '''
		{«FOR subaction : action.actions SEPARATOR ', '»«subaction.serialize»«ENDFOR»}
	'''

	
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
			(«FOR subaction : action.actions.filter[!(it instanceof AssumeAction) && !it.effectlessAction && !(it instanceof VariableDeclarationAction)] SEPARATOR ' & '»(«subaction.serializeTransition»)«ENDFOR»)
		«ENDIF»
	'''
	
	protected def dispatch mapTransition(SequentialAction action, Multimap<String, Pair<Expression, Action>> map, Expression assumption) {
		if (action.isFirstActionAssume) {
			var innerAssumption = action.getFirstActionAssume.assumption
			
			if (assumption !== null) {
				innerAssumption = assumption.wrapIntoAndExpression(action.getFirstActionAssume.assumption)				
			} 
			
			for (sequentialSubaction : action.actionsSkipFirst.filter[!(it instanceof AssumeAction) && !it.effectlessAction && !(it instanceof VariableDeclarationAction)]) {
				sequentialSubaction.mapTransition(map, innerAssumption)
			}
		} else {
			for (subaction : action.actions.filter[!(it instanceof AssumeAction) && !it.effectlessAction && !(it instanceof VariableDeclarationAction)]) {
				subaction.mapTransition(map, assumption)
			}
		}	
	}
	
	protected def dispatch String serialize(ParallelAction action) {throw new IllegalArgumentException("ParallelAction cannot be serialized! " + action)}
	protected def dispatch String serializeInitializingAction(ParallelAction action) {throw new IllegalArgumentException("ParallelAction cannot be serialized! " + action)}
	protected def dispatch String serializeTransition(ParallelAction action) {throw new IllegalArgumentException("ParallelAction cannot be serialized! " + action)}
	
	protected def dispatch mapTransition(ParallelAction action, Multimap<String, Pair<Expression, Action>> map, Expression assumption) {throw new IllegalArgumentException("ParallelAction cannot be mapped! " + action)}
		
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
	
	protected def serializeTransitions(Multimap<String, Pair<Expression, Action>> transitionMap, boolean envStep) '''
		«FOR key : transitionMap.keySet»
		next(«key») := case
				«FOR element : transitionMap.get(key)»
				«IF element.key !== null»(«IF !envStep»!«ENDIF»envStep & «element.key.serialize»)«ELSE»«IF !envStep»!«ENDIF»envStep«ENDIF» : «element.value.serialize»;
				«ENDFOR»
				TRUE : «key»;
			esac;
		«ENDFOR»
	'''

	
	protected def mapTransition(List<? extends XTransition> transitions, Multimap<String, Pair<Expression, Action>> map, Expression assumption) {
		if (transitions.size > 1) {
			for (transition : transitions) {
				transition.action.mapTransition(map, assumption)
			}
		}
		else {
			transitions.head.action.mapTransition(map, assumption)
		}
	}

}