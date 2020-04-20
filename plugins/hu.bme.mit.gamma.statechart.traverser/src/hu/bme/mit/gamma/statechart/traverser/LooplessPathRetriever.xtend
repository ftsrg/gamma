package hu.bme.mit.gamma.statechart.traverser

import hu.bme.mit.gamma.statechart.model.Region
import java.util.Collection

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class LooplessPathRetriever {
	
	def Collection<Path> retrievePaths(Region region) {
		var entryState = region.entryState
		val firstActiveStates = entryState.reachableStates
		val pathsUnderExamination = newArrayList
		for (firstActiveState : firstActiveStates) {
			for (firstOutgoingTransition : firstActiveState.outgoingTransitions) {
				pathsUnderExamination += new Path(firstOutgoingTransition)
			}
		}
		val finalPaths = newArrayList
		while (!pathsUnderExamination.empty) {
			// Copying the paths under examination so that an exception is not thrown
			val copiedPathsUnderExamination = newArrayList
			copiedPathsUnderExamination += pathsUnderExamination
			for (pathUnderExamination : copiedPathsUnderExamination) {
				// Retrieving the path from the queue
				pathsUnderExamination -= pathUnderExamination
				val targetState = pathUnderExamination.last.targetState
				if (firstActiveStates.contains(targetState)) {
					finalPaths += pathUnderExamination
				}
				else {
					for (outgoingTransition : targetState.outgoingTransitions) {
						val extendedPath = new Path(pathUnderExamination)
						// Extending with one new transition
						extendedPath.extend(outgoingTransition)
						// Putting it into the queue
						pathsUnderExamination += extendedPath
					}
				}
			}
		}
		return finalPaths
	}
	
}