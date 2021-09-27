package hu.bme.mit.gamma.plantuml.transformation

import hu.bme.mit.gamma.statechart.util.ExpressionSerializer
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Schedule
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.model.TimeElapse

import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

class TraceToPlantUmlTransformer {
	
	protected final ExecutionTrace trace
	// Utility
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	
	new(ExecutionTrace trace) {
		this.trace = trace
	}
	
	def String execute() '''
		@startuml
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
		
		«FOR step : trace.steps»
			«step.serialize»
		«ENDFOR»
		
		«IF trace.cycle !== null»
			loop
			«FOR step : trace.cycle.steps»
				«step.serialize»
			«ENDFOR»
			end loop
		«ENDIF»
		@enduml
	'''
	
	protected def serialize(Step step) '''
		«FOR time : step.actions.filter(TimeElapse)»
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
		«FOR config : step.instanceStateConfigurations.groupBy[it.instance].entrySet.sortBy[it.key.serialize]»
			«config.key.serialize» in {«config.value.map[it.state.name].join(", ")»} «IF step.instanceVariableStates.exists[it.instance.equals(config.key)]»with«ENDIF»
			«FOR varconstraint : step.instanceVariableStates.filter[it.instance.equals(config.key)].sortBy[it.declaration.name]»
				«varconstraint.declaration.name» = «varconstraint.value.serialize»
			«ENDFOR»
		«ENDFOR»
		endhnote
	'''
	
}