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
package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.statechart.lowlevel.model.EventDirection
import hu.bme.mit.gamma.statechart.lowlevel.model.Persistency

class EventAttributeTransformer {
	
	protected def EventDirection transform(hu.bme.mit.gamma.statechart.model.interface_.EventDirection direction) {
		switch (direction) {
			case OUT: {
				return EventDirection.OUT
			}
			case IN: {
				return EventDirection.IN
			}
			default: {
				throw new IllegalArgumentException("In-out direction is not interpreted on low level: " + direction)
			}
		}
	}
	
	protected def Persistency transform(hu.bme.mit.gamma.statechart.model.interface_.Persistency persistency) {
		switch (persistency) {
			case TRANSIENT: {
				return Persistency.TRANSIENT
			}
			case PERSISTENT: {
				return Persistency.PERSISTENT
			}
			default: {
				throw new IllegalArgumentException("This persistency type is not interpreted on low level: " + persistency)
			}
		}
	}
	
}