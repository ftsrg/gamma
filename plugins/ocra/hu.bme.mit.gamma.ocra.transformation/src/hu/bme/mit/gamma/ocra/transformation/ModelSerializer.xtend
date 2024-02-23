/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.ocra.transformation

import hu.bme.mit.gamma.statechart.composite.Channel
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.CompositeComponent
import hu.bme.mit.gamma.statechart.composite.InstancePortReference
import hu.bme.mit.gamma.statechart.composite.PortBinding
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.RealizationMode
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.List
import java.util.Set

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class ModelSerializer {
	// Singleton
	public static ModelSerializer INSTANCE = new ModelSerializer
	protected new() {}
	//
	
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final Naming naming = new Naming
	
	
	
	def String execute(Package _package) {
		val component = _package.firstComponent
		
		return component.execute
	}
	
	def String execute(Component component) '''
        «serializeSystemComponent(component)»
        «serializeSubComponents(getSubComponents(component))»
    '''
	
	
    def String serializeSystemComponent(Component component) '''
      	COMPONENT «component.name» system
      		INTERFACE
        		«serializeInterface(component.allPorts)»
      		REFINEMENT
        		«serializeRefinement(component)»
        		
    '''
    
    
    
	def String serializeSubComponents(Set<Component> components) '''
		«FOR component : components»
		COMPONENT «component.name»
			INTERFACE
				«serializeInterface(component.ports)»
			REFINEMENT
				«serializeRefinement(component)»
			        			
		«ENDFOR»
	'''
	

	def String serializeInterface(List<Port> ports) '''
        «FOR port : ports»
	        «FOR event : port.inputEvents»
		        INPUT «naming.getPortName(port, event)»
	        «ENDFOR»
	        «FOR event : port.outputEvents»
	        	OUTPUT «naming.getPortName(port, event)»
	        «ENDFOR»
        «ENDFOR»
    ''' 
    
    
	def serializeRefinement(Component component) {
		val subcomponents = extractSubcomponentInstances(component)
		val bindings = extractBindings(component)
		val channels = extractChannels(component)
		if (!subcomponents.nullOrEmpty) '''
			«FOR sub: subcomponents»
				«naming.getSubName(sub)»
			«ENDFOR»
			
			«FOR binding : bindings»
				«serializeBinding(binding)»
			«ENDFOR»
			«FOR channel : channels»
				«serializeChannel(channel)»
			«ENDFOR»
		'''
	}
	
		
	def String serializeChannel(Channel channel) {
		val events = channel.providedPort.port.allEvents
		val ports = channel.requiredPorts
		'''
		«FOR port : ports»
			«FOR event : events»
				«naming.getChannelName(channel, port, event)»
			«ENDFOR»
		«ENDFOR»
		'''
	}
	
	def serializeBinding(PortBinding binding) '''
		«FOR event : binding.compositeSystemPort.allEvents»
			«naming.getBindingName(binding, event)»
		«ENDFOR»
	'''

	
	def List<? extends ComponentInstance> extractSubcomponentInstances(Component component) {
		if (component instanceof CompositeComponent) {
			return component.derivedComponents
		}
	}
	

	def List<PortBinding> extractBindings(Component component) {
		if (component instanceof CompositeComponent) {
			return component.portBindings			
		}
	}
	
	def List<Channel> extractChannels(Component component) {
		if (component instanceof CompositeComponent) {
			return component.channels			
		}	
	}
	//TODO itt sajnos nem tudom hogy mire gondoltál, nem találtam olyan funkciót mint írtál
	def Set<Component> getSubComponents(Component component) {
		val derivedComponents = newHashSet
		if (component instanceof CompositeComponent) {
			for (instance : component.derivedComponents) {
				derivedComponents.add(instance.derivedType)
			}
			return derivedComponents
		}
	}
}

class Naming {
	
	def String getSubName(ComponentInstance sub) '''
		SUB «sub.name» : «sub.derivedType.name»;
	'''
	
	
    def String getPortName(Port port, Event event) '''
   		PORT «port.name»_«event.name» : event;
   	'''    

    def String getChannelName(Channel channel, InstancePortReference port, Event event) {
        val leftInstance = port.instance.name
        val leftPort = port.port.name
        val rightInstance = channel.providedPort.instance.name
        val rightPortName = channel.providedPort.port.name '''
        CONNECTION «leftInstance».«leftPort»_«event.name» := «rightInstance».«rightPortName»_«event.name»;
        '''
    }
    
    def String getBindingName(PortBinding binding, Event event) {
    	val leftInstance = binding.compositeSystemPort.name
    	val rightInstance = binding.instancePortReference.instance.name
    	val rightPort = binding.instancePortReference.port.name
    	
    	if (binding.compositeSystemPort.interfaceRealization.realizationMode == RealizationMode.PROVIDED) '''
    		CONNECTION «leftInstance»_«event.name» := «rightInstance».«rightPort»_«event.name»;
    	'''		
    	else '''
    		CONNECTION «rightInstance».«rightPort»_«event.name» := «leftInstance»_«event.name»;
    	'''
    }
    
}





