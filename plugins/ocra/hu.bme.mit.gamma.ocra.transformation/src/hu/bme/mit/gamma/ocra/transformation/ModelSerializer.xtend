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

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.statechart.composite.Channel
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.CompositeComponent
import hu.bme.mit.gamma.statechart.composite.PortBinding
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.List
import java.util.Map
import java.util.Set

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.ocra.transformation.NamingSerializer.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*


class ModelSerializer {
	// Singleton
	public static ModelSerializer INSTANCE = new ModelSerializer
	protected new() {}
	//
	
	protected final String PROXY_INSTANCE_NAME = "_"
	
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final TypeSerializer types = new TypeSerializer
	protected final ExpressionSerializer expressions = new ExpressionSerializer
	
	def String execute(Package _package, Map<String, String> contracts) {
	    val component = _package.firstComponent
	    
	    // Collect all component instances before starting the serialization
	    val componentInstances = collectAllComponentInstances(component)
	    
	    return component.execute(contracts, componentInstances)
	}
	
	def String execute(Component component, Map<String, String> contracts, Set<Pair<ComponentInstance, String>> componentInstances) '''
	    «serializeSystemComponent(component, contracts, componentInstances)»
	    «serializeComponents(extractSubcomponents(component), contracts, componentInstances)»
	'''

	
	
    def String serializeSystemComponent(Component component, Map<String, String> contracts, Set<Pair<ComponentInstance, String>> componentInstances) '''
      	COMPONENT «component.customizeComponentName» system
      		INTERFACE
      			«serializeInterface(component, customizeComponentName(component), contracts)»
      		REFINEMENT
      			«serializeRefinement(component, customizeComponentName(component), componentInstances)»
      			
    '''
    
    
    
	def String serializeComponents(Set<Pair<String, Component>> components, Map<String, String> contracts, Set<Pair<ComponentInstance, String>> componentInstances) '''
	    «FOR component : components»
	    COMPONENT «component.key»
	        INTERFACE
	            «serializeInterface(component.value, component.key, contracts)»
	        REFINEMENT
	            «serializeRefinement(component.value, component.key, componentInstances)»
	            
	    «ENDFOR»
	'''
	

	def String serializeInterface(Component component, String instanceName, Map<String, String> contracts) '''
        «FOR port : component.allPorts»
	    «serializePortName(port, instanceName)»
        «ENDFOR»
        «FOR param : component.parameterDeclarations»
       	«serializeParameterDeclarationName(param)»
       	«ENDFOR»
       	«IF contracts.containsKey(instanceName)»
		«contracts.get(instanceName)»
       	«ENDIF»
    ''' 
    
    
	def String serializeRefinement(Component component, String instanceName, Set<Pair<ComponentInstance, String>> instanceSet) {
	    val subcomponents = extractSubcomponentInstances(component)
	    val bindings = extractBindings(component)
	    val channels = extractChannels(component)
	    val parameters = component.parameterDeclarations
	    '''
	        «FOR sub: subcomponents»
	            «serializeSubName(instanceSet.findFirst[ it.key == sub.value ]?.value)»
	        «ENDFOR»
	        
	        «FOR binding : bindings»
	            «serializeBindingName(binding, instanceName, instanceSet)»
	        «ENDFOR»
	        «FOR channel : channels»
	            «serializeChannelName(channel, instanceName, instanceSet)»
	        «ENDFOR»
	        «FOR sub : subcomponents»
	            «serializeArgumentNames(sub)»
	        «ENDFOR»
	    '''
	}
	
	def String serializeSubName(String name) '''
		SUB «name» : «name»;
	'''
	
    def String serializePortName(Port port, String instanceName) '''
    	«FOR event : port.inputEvents»
    	INPUT PORT «event.customizePortName(port, instanceName)» : boolean;
    	«ENDFOR»
    	«FOR event : port.outputEvents»
    	OUTPUT PORT «event.customizePortName(port, instanceName)» : boolean;
    	«ENDFOR»
   	'''    
	
    def String serializeChannelName(Channel channel, String instanceName, Set<Pair<ComponentInstance, String>> instanceSet) {
	    val events = channel.providedPort.port.allEvents
	    val portReferences = channel.requiredPorts
	    val rightInstance = channel.providedPort.instance
	    val rightPort = channel.providedPort.port
	    
	    // Get the customized name for the right instance from the instance set
	    val rightInstanceName = instanceSet.findFirst[ it.key == rightInstance ]?.value
	    
	    '''
	    «FOR port : portReferences»
	        «FOR event : events»
	        CONNECTION «event.customizeChannelName(port.port, instanceSet.findFirst[it.key == port.instance]?.value, rightPort, rightInstanceName)»;
	        «ENDFOR»
	    «ENDFOR»
	    '''
	}

    
    def String serializeBindingName(PortBinding binding, String instanceName, Set<Pair<ComponentInstance, String>> instanceSet) {
	    val leftInstancePort = binding.compositeSystemPort
	    val rightInstance = binding.instancePortReference.instance
	    val rightPort = binding.instancePortReference.port
	    
	    // Get the customized name for the right instance from the instance set
	    val rightInstanceName = instanceSet.findFirst[ it.key == rightInstance ]?.value
	    
	    '''
	    «FOR event : binding.compositeSystemPort.allEvents»
	    CONNECTION «event.customizeBindinName(leftInstancePort, instanceName, rightPort, rightInstanceName)»;
	    «ENDFOR»
	    '''
	}

    
    def String serializeParameterDeclarationName(ParameterDeclaration parameter) '''
    	PARAMETER «parameter.name» : «types.serializeType(parameter.type)»;
    '''
    
    def String serializeArgumentNames(Pair<String, ? extends ComponentInstance> sub) {
    	val arguments = sub.value.arguments
    	val params = sub.value.parameterDeclarations
    	'''
    	«FOR param : params»
    	CONNECTION «sub.key».«param.name» := «expressions.serializeExpression(arguments.get(param.index))»;
    	«ENDFOR»
    	'''
    }
	
	def Set<Pair<String, ? extends ComponentInstance>> extractSubcomponentInstances(Component component) {
		val subComponents = CollectionLiterals.newHashSet
		if (component instanceof CompositeComponent) {
			for (componentInstanceReference : component.allSimpleInstanceReferences) {
				if(componentInstanceReference.isLast) {
					subComponents.add(new Pair<String, ComponentInstance>(customizeComponentName(componentInstanceReference), componentInstanceReference.lastInstance))
				}
			}
			for(compositeSubComponent : component.derivedComponents) {
				if(compositeSubComponent.derivedType instanceof CompositeComponent) {
					subComponents.add(new Pair<String, ComponentInstance>(customizeComponentName(compositeSubComponent), compositeSubComponent))
				}
			}
		}
		return subComponents
	}
	

	def List<PortBinding> extractBindings(Component component) {
		if (component instanceof CompositeComponent) {
			return component.portBindings			
		}
		return emptyList
	}
	
	def List<Channel> extractChannels(Component component) {
		if (component instanceof CompositeComponent) {
			return component.channels			
		}
		return emptyList
	}
	
	
	def Set<Pair<String, Component>> extractSubcomponents(Component component) {
	    val derivedComponents = CollectionLiterals.newHashSet	    
	    if (component instanceof CompositeComponent) {
	        for (instance : component.allSimpleInstanceReferences) {
	        	
	            val lastInstance = instance.lastInstanceReference
	            val subcomponent = lastInstance.componentInstance.derivedType
	
	            // Add the current component (composite or leaf) to the result list
	            val pair = new Pair<String, Component>(customizeComponentName(instance), subcomponent)
	            derivedComponents.add(pair)
	        }
	        for(derivedComponent : component.derivedComponents) {
	        	derivedComponents.addAll(collectCompositeComponents(derivedComponents, derivedComponent));
	        }
	    }

    	return derivedComponents
	}
	
	def Set<Pair<String, Component>> collectCompositeComponents(Set<Pair<String, Component>> derivedComponents, ComponentInstance instance) {
		val derivedComponent = instance.derivedType
		if(derivedComponent instanceof CompositeComponent) {
			derivedComponents.add(new Pair<String, Component>(customizeComponentName(instance), derivedComponent))
			
			for(derivedComponent2 : derivedComponent.derivedComponents) {
				collectCompositeComponents(derivedComponents, derivedComponent2)
			}
			
		}
		return derivedComponents
	}
	
	def Set<Pair<ComponentInstance, String>> collectAllComponentInstances(Component component) {
	    val instances = CollectionLiterals.newHashSet
	    
	    if (component instanceof CompositeComponent) {
	        for (instance : component.allSimpleInstanceReferences) {
	            val lastInstance = instance.lastInstanceReference
	            val subcomponentInstance = lastInstance.componentInstance
	
	            // Add the current instance (composite or leaf) to the result set
	            val pair = new Pair<ComponentInstance, String>(subcomponentInstance, customizeComponentName(instance))
	            instances.add(pair)
	        }
	        
	        // Recursively collect instances for derived components
	        for (derivedComponent : component.derivedComponents) {
	            instances.addAll(collectCompositeComponentInstances(derivedComponent))
	        }
	    }
	    
	    return instances
	}
	
	def Set<Pair<ComponentInstance, String>> collectCompositeComponentInstances(ComponentInstance instance) {
	    val instances = CollectionLiterals.newHashSet
	    val derivedComponent = instance.derivedType
	    
	    if (derivedComponent instanceof CompositeComponent) {
	        // Add the current composite instance
	        instances.add(new Pair<ComponentInstance, String>(instance, customizeComponentName(instance)))
	        
	        // Recursively collect instances of the derived components
	        for (subComponentInstance : derivedComponent.derivedComponents) {
	            instances.addAll(collectCompositeComponentInstances(subComponentInstance))
	        }
	    }
	    
	    return instances
	}
	
	
}









