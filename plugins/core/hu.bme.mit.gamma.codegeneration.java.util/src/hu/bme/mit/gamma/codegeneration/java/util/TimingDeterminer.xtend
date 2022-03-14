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
package hu.bme.mit.gamma.codegeneration.java.util

import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.composite.CompositeComponent

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class TimingDeterminer {
	// Singleton
	public static final TimingDeterminer INSTANCE = new TimingDeterminer
	protected new() {}
	//
	
	/**
	 * Returns whether there is a timing specification in any of the statecharts.
	 */
	def boolean needTimer(StatechartDefinition statechart) {
		return statechart.timeoutDeclarations.size > 0
	}
	
	/**
	 * Returns whether there is a time specification inside the given component.
	 */
	def boolean needTimer(Component component) {
		if (component instanceof StatechartDefinition) {
			return component.needTimer
		}
		else if (component instanceof CompositeComponent) {
			val composite = component as CompositeComponent
			return composite.derivedComponents.map[it.derivedType.needTimer].contains(true)
		}
		else if (component instanceof AsynchronousAdapter) {
			val wrapper = component as AsynchronousAdapter
			return !wrapper.clocks.empty || wrapper.wrappedComponent.type.needTimer
		}
		else {
			throw new IllegalArgumentException("No such component: " + component)
		}
	}
	
}