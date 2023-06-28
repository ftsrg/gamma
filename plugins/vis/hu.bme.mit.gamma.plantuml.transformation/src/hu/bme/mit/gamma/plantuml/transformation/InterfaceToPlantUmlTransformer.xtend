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

import hu.bme.mit.gamma.action.model.ProcedureDeclaration
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.FunctionDeclaration
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition
import hu.bme.mit.gamma.expression.util.ExpressionSerializer
import hu.bme.mit.gamma.expression.util.TypeSerializer
import hu.bme.mit.gamma.statechart.interface_.Interface
import java.util.ArrayList
import java.util.List

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class InterfaceToPlantUmlTransformer {

	protected final List<Interface> interfaces
	protected final List<EnumerationTypeDefinition> enums
	protected extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected extension TypeSerializer typeSerializer = TypeSerializer.INSTANCE
	protected final List<RecordTypeDefinition> structs
	protected final List<FunctionDeclaration> funcs

	protected List<Interface> externalParents = new ArrayList()

	new(List<Interface> interfaces, List<EnumerationTypeDefinition> enums, List<RecordTypeDefinition> structs,
		List<FunctionDeclaration> funcs) {
		this.interfaces = interfaces
		this.enums = enums
		this.structs = structs
		this.funcs = funcs
	}

	//
	def String execute() '''
		@startuml
		skinparam shadowing false
		
		«FOR _enum : enums»
			enum «_enum.serialize» {
				«FOR item : _enum.literals»
					«item.name»
				«ENDFOR»
			}
		«ENDFOR»
		
		«FOR struct : structs»
			struct «struct.serialize» {
				«FOR field : struct.fieldDeclarations»
					{field} «field.name» : «field.type.serialize»
				«ENDFOR»
			}
		«ENDFOR»
		
		«FOR func : funcs»
			protocol «func.name» {
				«FOR param : func.parameterDeclarations»
					{field} «param.name» : «param.type.serialize»
				«ENDFOR»
				«IF func instanceof ProcedureDeclaration»
					....
					returns «func.type.serialize»
				«ENDIF»
			}
		«ENDFOR»
		
		«FOR _interface : interfaces»
			«ifGenerate(_interface)»
			«FOR parent : _interface.parents»
				«IF interfaces.contains(parent)»
					«_interface.name» --|> «parent.name»
				«ELSEIF externalParents.contains(parent)»
					«_interface.name» --|> «parent.name»
				«ELSE»
					'«externalParents.add(parent)»
					package «parent.containingPackage.name» {
						«ifGenerate(parent)»
					}
					«_interface.name» --|> «parent.name»
				«ENDIF»
			«ENDFOR»
		«ENDFOR»
		
		@enduml
	'''

	def ifGenerate(Interface _interface) '''
		interface «_interface.name» {
		«FOR event : _interface.events»
			«event.direction.name().toLowerCase» event «event.event.name» («FOR param : event.event.parameterDeclarations SEPARATOR ", "»«param.name» : «param.type.serialize»«ENDFOR»)
		«ENDFOR»
		}
	'''

}
