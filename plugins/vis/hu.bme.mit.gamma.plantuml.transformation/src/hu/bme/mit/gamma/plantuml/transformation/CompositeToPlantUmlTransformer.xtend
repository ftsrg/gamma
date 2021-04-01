package hu.bme.mit.gamma.plantuml.transformation

import hu.bme.mit.gamma.expression.util.ExpressionSerializer
import hu.bme.mit.gamma.statechart.composite.AsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.CascadeCompositeComponent
import hu.bme.mit.gamma.statechart.composite.CompositeComponent
import hu.bme.mit.gamma.statechart.composite.SynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.interface_.RealizationMode

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class CompositeToPlantUmlTransformer {
	
	protected final CompositeComponent composite
	
	protected extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	
	new(CompositeComponent composite) {
		this.composite = composite
	}
	
	private def getKindString(CompositeComponent composite) {
		if (composite instanceof SynchronousCompositeComponent) {
			return "synchronous"
		} else if (composite instanceof CascadeCompositeComponent) {
			return "cascade"
		} else if (composite instanceof AsynchronousCompositeComponent) {
			return "asynchronous"
		}
	}
	
	def String execute() '''
		@startuml
		skinparam shadowing false
		
		skinparam interface<<Invisible>> {
		  borderColor Transparent
		  backgroundColor Transparent
		  stereotypeFontColor Transparent
		}
		
		component "«composite.name»"<<«composite.kindString»>> {
			«FOR component : composite.derivedComponents»
				agent «component.name»
			«ENDFOR»
			
			«FOR channel : composite.channels»
				interface "«channel.providedPort.port.interfaceRealization.interface.name»" as «channel.providedPort.instance.name»___«channel.providedPort.port.name»___«channel.providedPort.port.interfaceRealization.interface.name»
				«channel.providedPort.instance.name» #- «channel.providedPort.instance.name»___«channel.providedPort.port.name»___«channel.providedPort.port.interfaceRealization.interface.name»
				«FOR requiredPort : channel.requiredPorts»
					«channel.providedPort.instance.name»___«channel.providedPort.port.name»___«channel.providedPort.port.interfaceRealization.interface.name» )--# «requiredPort.instance.name» : «requiredPort.port.name»
				«ENDFOR»
			«ENDFOR»
		}
		
		«FOR binding : composite.portBindings»
			«IF binding.instancePortReference.port.interfaceRealization.realizationMode == RealizationMode.REQUIRED»
				interface «binding.instancePortReference.port.interfaceRealization.interface.name» as «binding.instancePortReference.instance.name»___«binding.instancePortReference.port.name»___«binding.instancePortReference.port.interfaceRealization.interface.name»<<Invisible>>
				«binding.instancePortReference.instance.name» #-( «binding.instancePortReference.instance.name»___«binding.instancePortReference.port.name»___«binding.instancePortReference.port.interfaceRealization.interface.name» : «binding.instancePortReference.port.name»
			«ENDIF»
			«IF binding.instancePortReference.port.interfaceRealization.realizationMode == RealizationMode.PROVIDED»
				interface «binding.instancePortReference.port.interfaceRealization.interface.name» as «binding.instancePortReference.instance.name»___«binding.instancePortReference.port.name»___«binding.instancePortReference.port.interfaceRealization.interface.name»
				«binding.instancePortReference.instance.name» #- «binding.instancePortReference.instance.name»___«binding.instancePortReference.port.name»___«binding.instancePortReference.port.interfaceRealization.interface.name» : «binding.instancePortReference.port.name»
			«ENDIF»
		«ENDFOR»
		@enduml
	'''
	
}