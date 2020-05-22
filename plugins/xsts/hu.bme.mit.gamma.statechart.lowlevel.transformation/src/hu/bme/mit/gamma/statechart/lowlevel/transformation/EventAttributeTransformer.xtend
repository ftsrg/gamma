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