/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.property.derivedfeatures;

import hu.bme.mit.gamma.property.model.AtomicFormula;
import hu.bme.mit.gamma.property.model.CommentableStateFormula;
import hu.bme.mit.gamma.property.model.PathFormula;
import hu.bme.mit.gamma.property.model.PathQuantifier;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.property.model.QuantifiedFormula;
import hu.bme.mit.gamma.property.model.StateFormula;
import hu.bme.mit.gamma.property.model.UnaryOperandPathFormula;
import hu.bme.mit.gamma.property.model.UnaryPathOperator;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Package;

public class PropertyModelDerivedFeatures extends StatechartModelDerivedFeatures {

	public static boolean isUnfolded(PropertyPackage propertyPackage) {
		Component component = propertyPackage.getComponent();
		Package containingPackage = getContainingPackage(component);
		return isUnfolded(containingPackage);
		// Atomic instance references?
	}
	
	public static boolean areAllPropertiesInvariants(PropertyPackage propertyPackage) {
		return propertyPackage.getFormulas().stream()
				.allMatch(it -> isInvariant(it));
	}
	
	public static boolean isInvariant(CommentableStateFormula commentableStateFormula) {
		StateFormula formula = commentableStateFormula.getFormula();
		return isInvariant(formula);
	}
	
	public static boolean isInvariant(StateFormula formula) {
		if (formula instanceof QuantifiedFormula quantifiedFormula) {
			PathQuantifier quantifier = quantifiedFormula.getQuantifier();
			PathFormula pathFormula = quantifiedFormula.getFormula();
			if (pathFormula instanceof UnaryOperandPathFormula unaryOperandPathFormula) {
				UnaryPathOperator operator = unaryOperandPathFormula.getOperator();
				PathFormula operand = unaryOperandPathFormula.getOperand();
				if (operand instanceof AtomicFormula atomicFormula) {
					return quantifier == PathQuantifier.FORALL && operator == UnaryPathOperator.GLOBAL || // AG
							quantifier == PathQuantifier.EXISTS && operator == UnaryPathOperator.FUTURE; // EF
				}
			}
		}
		
		return false;
	}
	
}
