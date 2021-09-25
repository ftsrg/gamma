/********************************************************************************
 * Copyright (c) 2018-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.property.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference;
import hu.bme.mit.gamma.statechart.composite.CompositeModelPackage;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.util.StatechartModelValidator;

public class PropertyModelValidator extends StatechartModelValidator {
	// Singleton
	public static final PropertyModelValidator INSTANCE = new PropertyModelValidator();
	protected PropertyModelValidator() {
		super.typeDeterminator = ExpressionTypeDeterminator.INSTANCE;
	}
	//
	
	public Collection<ValidationResultMessage> checkComponentInstanceReferences(
			ComponentInstanceReference reference) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<ValidationResultMessage>();
		
		validationResultMessages.addAll(
				super.checkComponentInstanceReferences(reference));
		
		if (StatechartModelDerivedFeatures.isFirst(reference)) {
			ComponentInstance firstInstance = reference.getComponentInstance();
			if (!isUnfolded(firstInstance)) {
				PropertyPackage propertyPackage = ecoreUtil.getContainerOfType(reference, PropertyPackage.class);
				if (propertyPackage != null) {
					Component component = propertyPackage.getComponent();
					List<ComponentInstance> containedComponents = StatechartModelDerivedFeatures.getInstances(component);
					if (!containedComponents.contains(firstInstance)) {
						validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR,
							"The first component instance must be the component of " + component.getName(),
							new ReferenceInfo(
								CompositeModelPackage.Literals.COMPONENT_INSTANCE_REFERENCE__COMPONENT_INSTANCE)));
					}
				}
			}
		}
		
		ComponentInstance lastInstance = StatechartModelDerivedFeatures.getLastInstance(reference);
		if (lastInstance != null && // Xtext parsing
				!StatechartModelDerivedFeatures.isStatechart(lastInstance)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"The last component instance must have a statechart type", 
					new ReferenceInfo(CompositeModelPackage.Literals.COMPONENT_INSTANCE_REFERENCE__COMPONENT_INSTANCE)));
		}
		
		return validationResultMessages;
	}
			
	/**
	 * In the case of unfolded systems, a single (leaf) component instance if sufficient.
	 */
	protected boolean isUnfolded(EObject object) {
		Package gammaPackage = StatechartModelDerivedFeatures.getContainingPackage(object);
		return StatechartModelDerivedFeatures.isUnfolded(gammaPackage);
	}
	
}
