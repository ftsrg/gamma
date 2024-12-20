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
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.property.model.Contract;
import hu.bme.mit.gamma.property.model.PathQuantifier;
import hu.bme.mit.gamma.property.model.PropertyModelPackage;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.property.model.QuantifiedFormula;
import hu.bme.mit.gamma.property.model.StateFormula;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.CompositeModelPackage;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.statechart.PortEventReference;
import hu.bme.mit.gamma.statechart.util.StatechartModelValidator;

public class PropertyModelValidator extends StatechartModelValidator {
	// Singleton
	public static final PropertyModelValidator INSTANCE = new PropertyModelValidator();
	protected PropertyModelValidator() {
		super.typeDeterminator = ExpressionTypeDeterminator.INSTANCE;
	}
	//
	
	public Collection<ValidationResultMessage> checkContractInstance(Contract contract) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<>();
		// contract.instance = contract.instance.lastInstanceReference
		if (contract.getInstance() != null) {
			validationResultMessages.addAll(checkMatchingComponentInstance(contract));
			validationResultMessages.addAll(checkRootReferencesWhenInstanceProvided(contract));
		} else {
			validationResultMessages.addAll(checkNoInstanceProvided(contract));
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkMatchingComponentInstance(Contract contract) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<>();
		List<ComponentInstanceReferenceExpression> assumeReferences = getLastComponentInstanceReferences(contract.getAssume());
		List<ComponentInstanceReferenceExpression> guaranteeReferences = getLastComponentInstanceReferences(contract.getGuarantee());
		ComponentInstanceReferenceExpression contractLastInstance = StatechartModelDerivedFeatures.getLastInstanceReference(contract.getInstance());

		for (ComponentInstanceReferenceExpression ref : assumeReferences) {
			if (!isSameComponentInstance(ref, contractLastInstance)) {
				validationResultMessages.add(new ValidationResultMessage(
					ValidationResult.ERROR,
					"The ComponentInstanceReferenceExpression in the assume formula does not match the instance declared in the contract header.",
					new ReferenceInfo(PropertyModelPackage.Literals.CONTRACT__ASSUME)));
			}
		}

		for (ComponentInstanceReferenceExpression ref : guaranteeReferences) {
			if (!isSameComponentInstance(ref, contractLastInstance)) {
				validationResultMessages.add(new ValidationResultMessage(
					ValidationResult.ERROR,
					"The ComponentInstanceReferenceExpression in the guarantee formula does not match the instance declared in the contract header.",
					new ReferenceInfo(PropertyModelPackage.Literals.CONTRACT__GUARANTEE)));
			}
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkRootReferencesWhenInstanceProvided(Contract contract) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<>();
		List<PortEventReference> assumeRootReferences = getAllRootElementReferences(contract.getAssume());
		List<PortEventReference> guaranteeRootReferences = getAllRootElementReferences(contract.getGuarantee());

		if (!assumeRootReferences.isEmpty()) {
			validationResultMessages.add(new ValidationResultMessage(
				ValidationResult.ERROR,
				"RootElementReference (e.g., 'self') is not allowed in the assume formula when an instance is declared in the contract header.",
				new ReferenceInfo(PropertyModelPackage.Literals.CONTRACT__ASSUME)));
		}

		if (!guaranteeRootReferences.isEmpty()) {
			validationResultMessages.add(new ValidationResultMessage(
				ValidationResult.ERROR,
				"RootElementReference (e.g., 'self') is not allowed in the guarantee formula when an instance is declared in the contract header.",
				new ReferenceInfo(PropertyModelPackage.Literals.CONTRACT__GUARANTEE)));
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkNoInstanceProvided(Contract contract) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<>();
		List<ComponentInstanceReferenceExpression> assumeReferences = getLastComponentInstanceReferences(contract.getAssume());
		List<ComponentInstanceReferenceExpression> guaranteeReferences = getLastComponentInstanceReferences(contract.getGuarantee());

		if (!assumeReferences.isEmpty()) {
			validationResultMessages.add(new ValidationResultMessage(
				ValidationResult.ERROR,
				"No ComponentInstanceReferenceExpression is allowed in the assume formula since no instance is declared in the contract header.",
				new ReferenceInfo(PropertyModelPackage.Literals.CONTRACT__ASSUME)));
		}

		if (!guaranteeReferences.isEmpty()) {
			validationResultMessages.add(new ValidationResultMessage(
				ValidationResult.ERROR,
				"No ComponentInstanceReferenceExpression is allowed in the guarantee formula since no instance is declared in the contract header.",
				new ReferenceInfo(PropertyModelPackage.Literals.CONTRACT__GUARANTEE)));
		}
		return validationResultMessages;
	}

	public Collection<ValidationResultMessage> checkNoExistentialQuantifierInContracts(Contract contract) {
		Collection<ValidationResultMessage> validationResultMessages = new ArrayList<>();
		
		List<QuantifiedFormula> assumeQuantifiedFormulas = ecoreUtil.getSelfAndAllContentsOfType(contract.getAssume(), QuantifiedFormula.class);
		List<QuantifiedFormula> guaranteeQuantifiedFormulas = ecoreUtil.getSelfAndAllContentsOfType(contract.getGuarantee(), QuantifiedFormula.class);

		for (QuantifiedFormula quantifiedFormula : assumeQuantifiedFormulas) {
			if (quantifiedFormula.getQuantifier() == PathQuantifier.EXISTS) {
				validationResultMessages.add(new ValidationResultMessage(
					ValidationResult.ERROR,
					"EXISTS (E) quantifier is not allowed in the assume formula of contracts.",
					new ReferenceInfo(PropertyModelPackage.Literals.CONTRACT__ASSUME)));
			}
		}

		for (QuantifiedFormula quantifiedFormula : guaranteeQuantifiedFormulas) {
			if (quantifiedFormula.getQuantifier() == PathQuantifier.EXISTS) {
				validationResultMessages.add(new ValidationResultMessage(
					ValidationResult.ERROR,
					"EXISTS (E) quantifier is not allowed in the guarantee formula of contracts.",
					new ReferenceInfo(PropertyModelPackage.Literals.CONTRACT__GUARANTEE)));
			}
		}
		return validationResultMessages;
	}

	public List<PortEventReference> getAllRootElementReferences(StateFormula formula) {
		return ecoreUtil.getAllContentsOfType(formula, PortEventReference.class);
	}

	public List<ComponentInstanceReferenceExpression> getLastComponentInstanceReferences(StateFormula formula) {
		// Collect all ComponentInstanceReferenceExpression from the formula
		List<ComponentInstanceReferenceExpression> references = ecoreUtil.getAllContentsOfType(formula, ComponentInstanceReferenceExpression.class);

		// Map each reference to its last instance
		return references.stream()
				.map(ref -> StatechartModelDerivedFeatures.getLastInstanceReference(ref))
				.collect(Collectors.toList());
	}

	public boolean isSameComponentInstance(ComponentInstanceReferenceExpression instance1, ComponentInstanceReferenceExpression instance2) {
		if (instance1 == null || instance2 == null) {
			return false;
		}
		return instance1.getComponentInstance().equals(instance2.getComponentInstance());
	}
	
	//
	public Collection<ValidationResultMessage> checkComponentInstanceReferences(
			ComponentInstanceReferenceExpression reference) {
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
								CompositeModelPackage.Literals.COMPONENT_INSTANCE_REFERENCE_EXPRESSION__COMPONENT_INSTANCE)));
					}
				}
			}
		}
		
		ComponentInstance lastInstance = StatechartModelDerivedFeatures.getLastInstance(reference);
		if (lastInstance != null && // Xtext parsing
				!StatechartModelDerivedFeatures.isStatechart(lastInstance)) {
			validationResultMessages.add(new ValidationResultMessage(ValidationResult.ERROR, 
				"The last component instance must have a statechart type", 
					new ReferenceInfo(CompositeModelPackage.Literals.COMPONENT_INSTANCE_REFERENCE_EXPRESSION__COMPONENT_INSTANCE)));
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
