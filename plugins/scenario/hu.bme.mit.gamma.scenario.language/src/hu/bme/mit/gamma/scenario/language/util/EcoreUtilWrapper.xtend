/********************************************************************************
 * Copyright (c) 2020-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scenario.language.util

import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.xtext.EcoreUtil2

class EcoreUtilWrapper {
	
	static def isNull(EObject obj){
		obj === null
	}

	static def getAllContainers(EObject obj) {
		return EcoreUtil2::getAllContainers(obj)
	}

	static def equals(EObject obj1, EObject obj2) {
		return new EcoreUtil.EqualityHelper().equals(obj1, obj2)
	}

	static def <T extends EObject> getContainedObjectsByType(EObject container, Class<T> cls) {
		switch (container) {
			case null: null
			default: EcoreUtil2::getAllContentsOfType(container, cls)
		}

	}
}
