package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.statechart.model.TimeSpecification
import java.util.List
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousComponentInstance

import  org.eclipse.xtend.lib.annotations.Data

abstract class Constraint {}

@Data
class OrchestratingConstraint extends Constraint {
	TimeSpecification minimumPeriod
	TimeSpecification maximumPeriod
}

@Data
class SchedulingConstraint extends Constraint {
	List<AsynchronousInstanceConstraint> instanceConstraints = newArrayList
}

@Data
class AsynchronousInstanceConstraint {
	AsynchronousComponentInstance instance
	OrchestratingConstraint orchestratingConstraint
}