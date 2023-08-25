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
package hu.bme.mit.gamma.fei.language.scoping

import hu.bme.mit.gamma.fei.model.CommonCauseMode
import hu.bme.mit.gamma.fei.model.FaultExtensionInstructions
import hu.bme.mit.gamma.fei.model.FaultSlice
import hu.bme.mit.gamma.fei.model.FeiModelPackage
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.scoping.Scopes

class FaultExtensionLanguageScopeProvider extends AbstractFaultExtensionLanguageScopeProvider {
	
	override getScope(EObject context, EReference reference) {
		if (context instanceof FaultExtensionInstructions) {
			if (reference == FeiModelPackage.Literals.FAULT_EXTENSION_INSTRUCTIONS__COMPONENT) {
				val imports = context.imports
				if (!imports.empty) {
					return Scopes.scopeFor(imports.map[it.components].flatten)
				}
			}
		}
		
		val root = ecoreUtil.getSelfOrContainerOfType(context, FaultExtensionInstructions)
		val packages = root.imports
		val component = root.component
		
		if (reference == FeiModelPackage.Literals.COMMON_CAUSE_MODE__FAULT_SLICE) {
			return Scopes.scopeFor(root.faultSlices)
		}
		if (reference == FeiModelPackage.Literals.COMMON_CAUSE_MODE__FAULT_MODE) {
			if (context instanceof CommonCauseMode) {
				return Scopes.scopeFor(context.faultSlice.faultModes)
			}
			return Scopes.scopeFor(root.faultSlices.map[it.faultModes].flatten)
		}
		
		if (reference == FeiModelPackage.Literals.FAULT_MODE_STATE_REFERENCE__FAULT_MODE) {
			val faultSlice = ecoreUtil.getSelfOrContainerOfType(context, FaultSlice)
			val faultModes = faultSlice.faultModes
			return Scopes.scopeFor(faultModes)
		}
		
		val scope = context.handleTypeDeclarationAndComponentInstanceElementReferences(reference, packages, component)
		if (scope !== null) {
			return scope
		}
		
		return super.getScope(context, reference)
	}
	
}
