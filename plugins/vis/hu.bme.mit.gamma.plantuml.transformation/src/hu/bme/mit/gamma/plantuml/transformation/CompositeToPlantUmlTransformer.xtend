/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
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
import hu.bme.mit.gamma.statechart.composite.AsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.CascadeCompositeComponent
import hu.bme.mit.gamma.statechart.composite.CompositeComponent
import hu.bme.mit.gamma.statechart.composite.ScheduledAsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.SynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.interface_.RealizationMode

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class CompositeToPlantUmlTransformer {

	protected final CompositeComponent composite

	enum LayoutType {
		UMLComponentDiagramStyle,
		UMLCompositeStructureDiagramStyle,
		SysMLInternalBlockDiagramStyle
	}

	enum LineStyle {
		Orthogonal,
		Polyline,
		Curved
	}

	// layout variables
	protected final int padding = 2
	protected final int verticalSpacing = 60
	protected final int horizontalSpacing = 60
	protected final boolean leftToRightDirection = false
	protected final boolean topToBottomDirection = false
	protected final LineStyle lineStyle = LineStyle.Curved
	// Selected Layout
	protected final LayoutType layoutType = LayoutType.SysMLInternalBlockDiagramStyle

	def String generateSkinparams(
		int padding,
		int verticalSpacing,
		int horizontalSpacing,
		boolean leftToRightDirection,
		boolean topToBottomDirection,
		LineStyle lineStyle
	) '''
		skinparam shadowing false
		!theme plain
		«IF lineStyle == LineStyle.Orthogonal»
			skinparam linetype ortho
		«ENDIF»
		«IF lineStyle == LineStyle.Polyline»
			skinparam linetype polyline
		«ENDIF»
		«IF leftToRightDirection»
			left to right direction
		«ENDIF»
		«IF topToBottomDirection»
			top to bottom direction
		«ENDIF»
		skinparam nodesep «verticalSpacing»
		skinparam ranksep «horizontalSpacing»
		skinparam padding «padding»
	'''

	protected extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE

	new(CompositeComponent composite) {
		this.composite = composite
	}

	private def getKindString(CompositeComponent composite) {
		if (composite instanceof SynchronousCompositeComponent) {
			return "synchronous"
		}
		else if (composite instanceof CascadeCompositeComponent) {
			return "cascade"
		}
		else if (composite instanceof AsynchronousCompositeComponent) {
			return "asynchronous"
		}
		else if (composite instanceof ScheduledAsynchronousCompositeComponent) {
			return "scheduled-asynchronous"
		}
		else {
			return composite.class.name
		}
	}

	def String execute() {
		switch (layoutType) {
			case LayoutType.UMLComponentDiagramStyle: {
				return executeUMLComponentDiagramStyle
			}
			case LayoutType.UMLCompositeStructureDiagramStyle: {
				return executeUMLCompositeStructureDiagramStyle
			}
			case LayoutType.SysMLInternalBlockDiagramStyle: {
				return executeSysMLInternalBlockDiagramStyle
			}
			default: {
				return executeSysMLInternalBlockDiagramStyle
			}
		}
	}

	def String executeUMLComponentDiagramStyle() '''
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

	def String executeUMLCompositeStructureDiagramStyle() '''
		@startuml
		skinparam defaultTextAlignment center
		«generateSkinparams(4,20,60,true,false,LineStyle.Polyline)»
		
		component "«composite.name»"<<«composite.kindString»>> {
			
			«FOR component : composite.derivedComponents»
				component  «component.name»  [
				{{
				digraph G {
				graph [pad=0]
				n [ margin=0 height=«(0.3+component.derivedType.allPorts.length*0.4).toString» width=«(0.1+component.derivedType.ports.length*0.1).toString» shape=plaintext fontname="SansSerif" label="«component.name» : «component.getDerivedType.name»"]
				}
				}}
				]
			«ENDFOR»
			
			«FOR port : composite.ports»
				«IF port.interfaceRealization.realizationMode == RealizationMode.REQUIRED»
					portin «port.name»
				«ENDIF»
				«IF port.interfaceRealization.realizationMode == RealizationMode.PROVIDED»
					portout «port.name»
				«ENDIF»
			«ENDFOR»
			
			«FOR binding : composite.portBindings»
				«IF binding.instancePortReference.port.interfaceRealization.realizationMode == RealizationMode.REQUIRED»
					«binding.compositeSystemPort.name» ..# "«binding.instancePortReference.port.name»" «binding.instancePortReference.instance.name»
				«ENDIF»
				«IF binding.instancePortReference.port.interfaceRealization.realizationMode == RealizationMode.PROVIDED»
					«binding.instancePortReference.instance.name» "«binding.instancePortReference.port.name»" #.. «binding.compositeSystemPort.name»
				«ENDIF»
				'«composite.name» "«binding.compositeSystemPort.name»" #.# "«binding.instancePortReference.port.name»" «binding.instancePortReference.instance.name»
			«ENDFOR»
			
			
			«FOR channel : composite.channels»
				«FOR requiredPort : channel.requiredPorts»
					«channel.providedPort.instance.name» "«channel.providedPort.port.name»" #--0)--# "«requiredPort.port.name»" «requiredPort.instance.name» : "<size:10>//«requiredPort.port.interface.name»//" 
				«ENDFOR»
			«ENDFOR»
		}
		
		
		@enduml
	'''

	def String executeSysMLInternalBlockDiagramStyle() '''
		@startuml
		<style>
		title {
		  FontSize 12
		}
		</style>
		
		skinparam shadowing false
		!theme plain
		skinparam defaultTextAlignment center
		skinparam ComponentStereotypeFontSize 10
		skinparam componentStyle rectangle
		«generateSkinparams(2,40,70,false,false,LineStyle.Curved)»
		
		component "«composite.name»"<<«composite.kindString»>> {
			
			«FOR component : composite.derivedComponents»
				component "<size:12>«component.name»:\n<size:12>«component.derivedType.name»" as «component.name»  {
					«FOR port : component.derivedType.allPorts»
						«IF true»
							«IF port.interfaceRealization.realizationMode == RealizationMode.REQUIRED»
								portin "«port.name»:\n ~«port.interface.name» " as «component.name»__«port.name»
							«ENDIF»
							«IF port.interfaceRealization.realizationMode == RealizationMode.PROVIDED»
								portout "«port.name»:\n «port.interface.name»" as «component.name»__«port.name»
							«ENDIF»
						«ENDIF»
					«ENDFOR»
				}
			«ENDFOR»
		
			
			«FOR port : composite.ports»
			«IF port.interfaceRealization.realizationMode == RealizationMode.REQUIRED»
				portin "«port.name»\n ~«port.interface.name»" as «port.name»
			«ENDIF»
			«IF port.interfaceRealization.realizationMode == RealizationMode.PROVIDED»
				portout "«port.name»:\n «port.interface.name»" as «port.name»
			«ENDIF»
			«ENDFOR»
			
			«FOR binding : composite.portBindings»
			«IF binding.instancePortReference.port.interfaceRealization.realizationMode == RealizationMode.REQUIRED»
				«binding.compositeSystemPort.name» . «binding.instancePortReference.instance.name»__«binding.instancePortReference.port.name»
			«ENDIF»
			«IF binding.instancePortReference.port.interfaceRealization.realizationMode == RealizationMode.PROVIDED»
				«binding.instancePortReference.instance.name»__«binding.instancePortReference.port.name» .. «binding.compositeSystemPort.name»
			«ENDIF»
			'«composite.name» "«binding.compositeSystemPort.name»" #.# "«binding.instancePortReference.port.name»" «binding.instancePortReference.instance.name»
			«ENDFOR»
			
			
			«FOR channel : composite.channels»
			«FOR requiredPort : channel.requiredPorts»
				«channel.providedPort.instance.name»__«channel.providedPort.port.name» ---> «requiredPort.instance.name»__«requiredPort.port.name» 
			«ENDFOR»
			«ENDFOR»
		}
		
		
		@enduml
	'''

}
