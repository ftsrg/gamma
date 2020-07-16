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

import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
import hu.bme.mit.gamma.statechart.composite.CompositeModelPackage
import org.eclipse.xtext.validation.Check

class PropertyLanguageValidator extends AbstractPropertyLanguageValidator {
	
	new() {
		// Registering the ComponentInstanceExpression types
		super.typeDeterminator = PropertyExpressionTypeDeterminator.INSTANCE
	}
	
	@Check
	override checkComponentInstanceReferences(ComponentInstanceReference reference) {
		super.checkComponentInstanceReferences(reference)
		val instances = reference.componentInstanceHierarchy
		val model = ecoreUtil.getContainerOfType(reference, PropertyPackage)
		if (model !== null) {
			val component = model.component
			val containedComponents = component.eContents.filter(ComponentInstance)
			val firstInstance = instances.head
			if (!containedComponents.contains(firstInstance)) {
				error("The first component instance must be the component of " + component.name,
					CompositeModelPackage.Literals.COMPONENT_INSTANCE_REFERENCE__COMPONENT_INSTANCE_HIERARCHY, 0)
			}
		}
	}
	
}
