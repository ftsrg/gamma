/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.plantuml.transformation

import hu.bme.mit.gamma.expression.util.ExpressionSerializer
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.interface_.AnyTrigger
import hu.bme.mit.gamma.statechart.interface_.EventReference
import hu.bme.mit.gamma.statechart.interface_.EventTrigger
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference
import hu.bme.mit.gamma.statechart.statechart.ClockTickReference
import hu.bme.mit.gamma.statechart.statechart.PortEventReference

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class AdapterToPlantUmlTransformer {
	//
	protected final AsynchronousAdapter adapter
	//
	protected extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	//
	
	new(AsynchronousAdapter adapter) {
		this.adapter = adapter
	}

	//
	dispatch def getSimpleConnection(AnyPortEventReference source, EventReference target, String queueName) {
		return '''
			«IF target === null»
				c_«source.getPort.name» ...> «queueName» : "any"
				«queueName» ...> comp_«source.getPort.name» : "any"
			«ELSEIF target instanceof AnyPortEventReference»
				c_«target.getPort.name» ...> «queueName» : "any"
				«queueName» ...> comp_«source.getPort.name» : "any"
			«ELSEIF target instanceof PortEventReference»
				c_«target.getPort.name» ...> «queueName» : "«target.event.name»"
				«queueName» ...> comp_«source.getPort.name» : "any"
			«ENDIF»
		'''
	}

	dispatch def getSimpleConnection(PortEventReference source, EventReference target, String queueName) {
		return '''
			«IF target === null»
				c_«source.getPort.name» ..> «queueName» : "any"
				«queueName» ..> comp_«source.getPort.name» : "«source.event.name»"
			«ELSEIF target instanceof AnyPortEventReference»
				c_«target.getPort.name» ..> «queueName» : "any"
				«queueName» ..> comp_«source.getPort.name» : "«source.event.name»"
			«ELSEIF target instanceof PortEventReference»
				c_«target.getPort.name» ..> «queueName» : "«target.event.name»"
				«queueName» ..> comp_«source.getPort.name» : "«source.event.name»"
			«ENDIF»
		'''
	}
	
	dispatch def getSimpleConnection(ClockTickReference source, EventReference target, String queueName) '''
		c_«source.clock.name» ..> «queueName»
	'''
	//

	//
	dispatch def getRefeference(PortEventReference reference) '''«reference.port.name».«reference.event.name»'''
	dispatch def getRefeference(AnyPortEventReference reference) '''«reference.port.name».any'''
	dispatch def getRefeference(ClockTickReference reference) '''«reference.clock.name»'''
	//
	
	//
	dispatch def trigger(AnyTrigger trigger) '''any'''
	dispatch def trigger(EventTrigger trigger)
		'''«trigger.eventSource.name».«trigger.eventReference.refeference»'''
	
	//

	def String execute() '''
		@startuml
		skinparam shadowing false
		
		skinparam shadowing false
		!theme plain
		left to right direction
		skinparam nodesep 30
		skinparam ranksep 30
		
		skinparam padding 5
		
		
		skinparam interface<<Invisible>> {
		  borderColor Transparent
		  backgroundColor Transparent
		  stereotypeFontColor Transparent
		}
		
		component "«adapter.name»"<<Asynchronous Adapter>> {
			
		«FOR port : adapter.wrappedComponent.type.allPortsWithInput»
			portin "«port.name»" as c_«port.name»
		«ENDFOR»
		
		«FOR port : adapter.allPortsWithInput»
			portin "«port.name»" as c_«port.name»
		«ENDFOR»
		
		«FOR port : adapter.wrappedComponent.type.allPortsWithOutput»
			portout "«port.name»" as c_«port.name»
		«ENDFOR»
		
		«FOR port : adapter.allPortsWithOutput»
			portout "«port.name»" as c_«port.name»
		«ENDFOR»
		
				
		component "«adapter.wrappedComponent.name» : «adapter.wrappedComponent.type.name»" as comp {
			«FOR port : adapter.wrappedComponent.type.allPortsWithInput»
				portin "«port.name»" as comp_«port.name»
			«ENDFOR»
			«FOR port : adapter.wrappedComponent.type.allPortsWithOutput»
				portout "«port.name»" as comp_«port.name»
			«ENDFOR»
		}
		
		
		«FOR port : adapter.wrappedComponent.type.allPortsWithOutput»
			comp_«port.name» ...> c_«port.name»
		«ENDFOR»
		
		«FOR queue : adapter.messageQueues»
			queue «queue.name»  [
			«queue.name»
			capacity=«queue.capacity.serialize»,
			priority=«queue.priority»
			]
			«FOR passing : queue.eventPassings»
				«getSimpleConnection(passing.source, passing.target, queue.name)»
			«ENDFOR»
		«ENDFOR»
		
		card Triggers[
		Triggers
		----
		«FOR control : adapter.controlSpecifications»
			when «trigger(control.trigger)» / «control.controlFunction.toString.toLowerCase.replaceAll("_"," ")»
			....
		«ENDFOR»
		]
		«IF !adapter.clocks.empty»
			card Clocks[
			Clocks
			----
			«FOR clock : adapter.clocks»
				clock «clock.name» : «clock.timeSpecification.value.serialize» «clock.timeSpecification.unit.getName»
				....
			«ENDFOR»
			]
		«ENDIF»
		}
		@enduml
	'''

}
