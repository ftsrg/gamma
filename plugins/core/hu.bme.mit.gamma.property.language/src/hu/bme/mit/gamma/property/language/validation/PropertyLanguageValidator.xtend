/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.property.language.validation

import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
import hu.bme.mit.gamma.statechart.composite.CompositeModelPackage
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import org.eclipse.xtext.validation.Check

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import hu.bme.mit.gamma.statechart.composite.ComponentInstance

class PropertyLanguageValidator extends AbstractPropertyLanguageValidator {
	
	new() {
		// Registering the ComponentInstanceExpression types
		super.typeDeterminator = PropertyExpressionTypeDeterminator.INSTANCE
	}
	
	@Check
	def checkComponentInstanceReferences(ComponentInstanceReference reference) {
		val instances = reference.componentInstanceHierarchy
		for (var i = 0; i < instances.size - 1; i++) {
			val instance = instances.get(i)
			val nextInstance = instances.get(i + 1)
			val type = instance.derivedType
			val containedInstances = type.eContents.filter(ComponentInstance)
			if (!containedInstances.contains(nextInstance)) {
				error(instance.name + " does not contain component instance " + nextInstance.name,
					CompositeModelPackage.Literals.COMPONENT_INSTANCE_REFERENCE__COMPONENT_INSTANCE_HIERARCHY, i)
			}
		}
		val lastInstance = instances.last
		val lastType = lastInstance.derivedType
		if (!(lastType instanceof StatechartDefinition)) {
			error("The last component instance must have a statechart type.",
				CompositeModelPackage.Literals.COMPONENT_INSTANCE_REFERENCE__COMPONENT_INSTANCE_HIERARCHY)
		}
	}
	
}
