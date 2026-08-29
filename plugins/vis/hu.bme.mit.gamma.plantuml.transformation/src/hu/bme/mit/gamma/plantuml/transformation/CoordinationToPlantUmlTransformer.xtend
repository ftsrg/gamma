package hu.bme.mit.gamma.plantuml.transformation

import hu.bme.mit.gamma.statechart.statechart.AbstractCoordinationReferenceExpression
import hu.bme.mit.gamma.statechart.statechart.CoordinationStatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.CoordinationTransition
import hu.bme.mit.gamma.statechart.statechart.EntryState
import hu.bme.mit.gamma.statechart.statechart.PseudoState
import hu.bme.mit.gamma.statechart.statechart.SequentialCoordinationReferenceExpression
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.UnorderedCoordinationReferenceExpression

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class CoordinationToPlantUmlTransformer extends StatechartToPlantUmlTransformer {
	protected final CoordinationStatechartDefinition statechart
	
	protected final CompositeToPlantUmlTransformer compositeTransformer
	
	enum CoordinationLayoutType {
		COORDINATION,
		COMPOSITION,
		COORDINATION_COMPOSITION
	}
	
	protected CoordinationLayoutType layoutType
	
	new(CoordinationStatechartDefinition statechart) {
		super(statechart)
		this.statechart = statechart
		this.compositeTransformer = new CompositeToPlantUmlTransformer(statechart)
		this.layoutType = CoordinationLayoutType.COORDINATION
	}
	
	new(CoordinationStatechartDefinition statechart, String layoutType) {
		super(statechart)
		this.statechart = statechart
		this.compositeTransformer = new CompositeToPlantUmlTransformer(statechart)
		this.layoutType = CoordinationLayoutType.valueOf(layoutType)
	}

	/**
	 * execute()
	 * 
	 * This method combines the functionality of the StatechartToPlantUmlTransformer and the functionality of the
	 * CompositeToPlantUmlTransformer
	 * 
	 */
	override String execute() {
		switch (layoutType) {
			case COORDINATION: {
				return executeCoordinationLayout
			}
			case COMPOSITION: {
				return executeCompositionLayout
			}
			case COORDINATION_COMPOSITION: {
				return executeCoordinationCompositionLayout
			}
			default: {
				return executeCoordinationLayout
			}
		}
	}
	
	def String executeCoordinationLayout() '''
		@startuml

			skin rose 
			skinparam backgroundcolor transparent
			skinparam legend {
				BackgroundColor lightgrey
			}
		
			skinparam nodesep 30
			skinparam ranksep 30
			skinparam padding 5
				«statechart.listVariablesInNote()»
				«statechart.mainRegionSearch»	
		
		@enduml
	'''
	
	def String executeCompositionLayout() '''
		«compositeTransformer.execute()»
	'''
	
	// TODO Better solution for replacing the @startuml and @enduml tags
	def String executeCoordinationCompositionLayout() '''
		@startuml
		left to right direction
		
		package Components [
		{{
			«compositeTransformer.execute().replace("@startuml","").replace("@enduml","")»
		}}
		]
		
		package Coordination [
		{{
			skin rose 
			skinparam backgroundcolor transparent
			skinparam legend {
				BackgroundColor lightgrey
			}
		
			skinparam nodesep 30
			skinparam ranksep 30
			skinparam padding 5
				«statechart.listVariablesInNote()»
				«statechart.mainRegionSearch»	
		}}
		]
		
		@enduml
	'''
	
	/**
	 * mainRegionSearch(CoordinationStatechartDefinition)
	 * 
	 * This method has the same functionality as the mainRegionSearch function of the StatechartToPlantUmlTransformer, but using
	 * CoordinationTransitions
	 * 
	 */
	protected def mainRegionSearch(CoordinationStatechartDefinition statechart) {
		val mainString = '''
			«IF statechart.regions.size > 1»state «statechart.name» {«ENDIF»
				«FOR main : statechart.regions»
					«FOR pseudo: main.stateNodes»
						«IF pseudo instanceof PseudoState»
							«pseudo.transformPseudoState»
						«ENDIF»
					«ENDFOR»
					«FOR mainstate: main.stateNodes.filter(State)»
						«regionSearch(mainstate, statechart)»
						«IF !(mainstate instanceof PseudoState)»
							«IF stateActionsSearch(mainstate) !== null»
								«stateActionsSearch(mainstate)»
							«ENDIF»
						«ENDIF»
					«ENDFOR»
					«FOR transition : statechart.coordinationTransitions»
						«FOR mainstate: main.stateNodes»
							«IF transition.sourceState == mainstate»
								«stateSearch(transition)»
							«ENDIF»
						«ENDFOR»
					«ENDFOR»
					
					«IF !(isLastRegion(statechart.regions, main))»
						--
					«ENDIF»
					
				«ENDFOR»
			«IF statechart.regions.size > 1»
				}
				[*] -> «statechart.name»
			«ENDIF»
		'''
		return mainString
	}
	
	/**
	 * stateSearch(CoordinationTransition)
	 * 
	 * This method searches the source and target state of the transition received as parameter.
	 * This is where the visualization of the initial and history states is handled, as well as
	 * the obtaining of the guards and triggers of transitions.
	 * The end result will look like this:
	 * 
	 * State1 -> State2 : trigger [guard] / action
	 * 
	 */
	protected def stateSearch(CoordinationTransition transition) {
		val source = transition.sourceState
		val trigger = transition.trigger
		val guard = transition.guard
		val effects = transition.effects
		val target = transition.targetState
		var arrow = ""
		if (source instanceof EntryState || (source.parentRegion.orthogonal && target.state)) {
			arrow = "->"
		} else {
			arrow = "-->"
		}
		return '''
			«transition.sourceText» «arrow» «target.name»«IF !transition.empty» : «ENDIF»«IF trigger !== null»«trigger.transformTrigger»«ENDIF» «IF guard !== null»\n[«guard.serialize
				.replaceAll("\\|\\|", "||\\\\n").replaceAll("\\&\\&", "&&\\\\n")»]«ENDIF»«FOR effect : effects BEFORE ' /\\n' SEPARATOR '\\n'»«effect.transformAction»«ENDFOR»«transition.coordinatedComponent.serializeCoordinatedComponent»
		'''
	}
	
	protected def serializeCoordinatedComponent (AbstractCoordinationReferenceExpression expression) {
		if (expression instanceof SequentialCoordinationReferenceExpression) {
			return ''' \n / execute: «IF expression.instances.length > 1»SEQ{«ENDIF»«FOR instance : expression.instances SEPARATOR ','»«instance.componentInstance.name»«ENDFOR»«IF expression.instances.length > 1»}«ENDIF»'''
		} else if (expression instanceof UnorderedCoordinationReferenceExpression) {
			return ''' \n / execute: UNORD{«FOR instance : expression.instances SEPARATOR ','»«instance.componentInstance.name»«ENDFOR»}'''
		}
		
		return ''''''
	}
}