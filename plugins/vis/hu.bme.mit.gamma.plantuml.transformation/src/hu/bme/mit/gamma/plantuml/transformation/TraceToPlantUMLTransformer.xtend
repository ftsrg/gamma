package hu.bme.mit.gamma.plantuml.transformation

import hu.bme.mit.gamma.expression.util.ExpressionSerializer
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.InstanceStateConfiguration
import hu.bme.mit.gamma.trace.model.InstanceVariableState
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Schedule
import hu.bme.mit.gamma.trace.model.TimeElapse

class TraceToPlantUMLTransformer {
	
	protected final ExecutionTrace trace
	
	protected extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	
	new(ExecutionTrace trace) {
		this.trace = trace
	}
	
	def execute() {
		return '''
			!pragma teoz true
			
			hide footbox
			skinparam shadowing false
			skinparam ArrowColor #0b910b
			skinparam SequenceLifeLineBorderColor #0b910b
			skinparam SequenceLifeLineBackgroundColor #3ec43e
			skinparam ParticipantBorderColor #043204
			skinparam ParticipantBackgroundColor #3ec43e
			skinparam NoteBackgroundColor #ffe7a4
			skinparam NoteBorderColor #914e0b
			skinparam SequenceDividerBackgroundColor #8cdc8c
			skinparam SequenceDividerBorderColor #0b910b
			skinparam SequenceGroupBackgroundColor #8cdc8c
			skinparam SequenceGroupBorderColor #043204
			
			
			title «trace.name» of «trace.component.name»
			
			participant "«trace.component.name»" as System <<SUT>>
			
			«««{step«stepno++»} Environment -> System ** : initialize
			
			«FOR step : trace.steps»
				«FOR time : step.actions.filter(TimeElapse)»
				«««{step«stepno-1»} <-> {step«stepno»} : «time.elapsedTime»ms
				...wait «time.elapsedTime»ms...
				«ENDFOR»
				
				«FOR act : step.actions.filter(RaiseEventAct)»
				[o-> System : «act.port.name».«act.event.name»(«FOR argument : act.arguments SEPARATOR ', '»«argument.serialize»«ENDFOR»)
				«ENDFOR»
				
				«FOR act : step.actions.filter(Schedule)»
				== Execute ==
				«ENDFOR»
								
				«FOR act : step.outEvents»
				System ->o] : «act.port.name».«act.event.name»(«FOR argument : act.arguments SEPARATOR ', '»«argument.serialize»«ENDFOR»)
				«ENDFOR»
				
				hnote over System 
				«FOR config : step.instanceStates.filter(InstanceStateConfiguration).groupBy[it.instance].entrySet.sortBy[it.key.name]»
				«config.key.name» in {«config.value.map[it.state.name].join(", ")»} «IF step.instanceStates.filter(InstanceVariableState).exists[it.instance.equals(config.key)]»with«ENDIF»
					«FOR varconstraint : step.instanceStates.filter(InstanceVariableState).filter[it.instance.equals(config.key)].sortBy[it.declaration.name]»
					«varconstraint.declaration.name» = «varconstraint.value.serialize»
					«ENDFOR»
				«ENDFOR»
				endhnote
				«««hnote over System
				««««FOR state : step.instanceStates.filter(InstanceVariableState).sortBy[it.instance.name]»
				««««state.instance.name».«state.declaration.name» = «state.value»
				««««ENDFOR»
				«««endhnote
			«ENDFOR»
			
			«IF trace.cycle !== null»
			loop
				«FOR step : trace.cycle.steps»
					«FOR time : step.actions.filter(TimeElapse)»
					«««{step«stepno-1»} <-> {step«stepno»} : «time.elapsedTime»ms
					...wait «time.elapsedTime»ms...
					«ENDFOR»
					
					«FOR act : step.actions.filter(RaiseEventAct)»
					[o-> System : «act.port.name».«act.event.name»(«FOR argument : act.arguments SEPARATOR ', '»«argument.serialize»«ENDFOR»)
					«ENDFOR»
					
					«FOR act : step.actions.filter(Schedule)»
					== Execute ==
					«ENDFOR»
									
					«FOR act : step.outEvents»
					System ->o] : «act.port.name».«act.event.name»(«FOR argument : act.arguments SEPARATOR ', '»«argument.serialize»«ENDFOR»)
					«ENDFOR»
					
					hnote over System 
					«FOR config : step.instanceStates.filter(InstanceStateConfiguration).groupBy[it.instance].entrySet.sortBy[it.key.name]»
					«config.key.name» in {«config.value.map[it.state.name].join(", ")»} «IF step.instanceStates.filter(InstanceVariableState).exists[it.instance.equals(config.key)]»with«ENDIF»
						«FOR varconstraint : step.instanceStates.filter(InstanceVariableState).filter[it.instance.equals(config.key)].sortBy[it.declaration.name]»
						«varconstraint.declaration.name» = «varconstraint.value.serialize»
						«ENDFOR»
					«ENDFOR»
					endhnote
					«««hnote over System
					««««FOR state : step.instanceStates.filter(InstanceVariableState).sortBy[it.instance.name]»
					««««state.instance.name».«state.declaration.name» = «state.value»
					««««ENDFOR»
					«««endhnote
				«ENDFOR»
			end loop
			«ENDIF»
			
			«««{step«stepno++»} Environment -> System !! : shut down
			
		'''
	}
	
}