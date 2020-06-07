package hu.bme.mit.gamma.plantuml.transformation

import hu.bme.mit.gamma.trace.model.ExecutionTrace
import org.eclipse.emf.ecore.resource.Resource
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.impl.ExecutionTraceImpl
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.trace.model.InstanceStateConfiguration
import hu.bme.mit.gamma.trace.model.InstanceVariableState

class TraceToPlantUMLTransformer {
	
	protected final ExecutionTrace trace
	
	new(Resource resource) {
		this.trace = resource.contents.head as ExecutionTrace
	}
	
	def execute() {
		var int stepno = 0;
		return '''
			@startuml
			!pragma teoz true
			
			hide footbox
			
			title «trace.name» of «trace.component.name»
			
			participant Environment
			participant "«trace.component.name»" as System <<SUT>>
			
			«««{step«stepno++»} Environment -> System ** : initialize
			
			«FOR step : trace.steps»
				«FOR time : step.actions.filter(TimeElapse)»
				«««{step«stepno-1»} <-> {step«stepno»} : «time.elapsedTime»ms
				...wait «time.elapsedTime»ms...
				«ENDFOR»
				
				«FOR act : step.actions.filter(RaiseEventAct)»
				{step«stepno++»} Environment -> System : «act.port.name».«act.event.name»
				«ENDFOR»
				
				hnote over System 
				«FOR state : step.instanceStates.filter(InstanceStateConfiguration).sortBy[it.instance.name]»
				«state.instance.name».«state.state.name»
				«ENDFOR»
				endhnote
				hnote over System
				«FOR state : step.instanceStates.filter(InstanceVariableState).sortBy[it.instance.name]»
				«state.instance.name».«state.declaration.name» = «state.value»
				«ENDFOR»
				endhnote
				
				«FOR act : step.outEvents»
				{step«stepno++»} System -> Environment : «act.port.name».«act.event.name»
				«ENDFOR»
			«ENDFOR»
			
			«IF trace.cycle!=null»
			loop
				«FOR step : trace.cycle.steps»
					«FOR time : step.actions.filter(TimeElapse)»
					«««{step«stepno-1»} <-> {step«stepno»} : «time.elapsedTime»ms
					...wait «time.elapsedTime»ms...
					«ENDFOR»
					
					«FOR act : step.actions.filter(RaiseEventAct)»
					{step«stepno++»} Environment -> System : «act.port.name».«act.event.name»
					«ENDFOR»
					
					hnote over System 
					«FOR state : step.instanceStates.filter(InstanceStateConfiguration).sortBy[it.instance.name]»
					«state.instance.name».«state.state.name»
					«ENDFOR»
					endhnote
					hnote over System
					«FOR state : step.instanceStates.filter(InstanceVariableState).sortBy[it.instance.name]»
					«state.instance.name».«state.declaration.name» = «state.value»
					«ENDFOR»
					endhnote
					
					«FOR act : step.outEvents»
					{step«stepno++»} System -> Environment : «act.port.name».«act.event.name»
					«ENDFOR»
				«ENDFOR»
			end loop
			«ENDIF»
			
			«««{step«stepno++»} Environment -> System !! : shut down
			
			@enduml
		'''
	}
	
}