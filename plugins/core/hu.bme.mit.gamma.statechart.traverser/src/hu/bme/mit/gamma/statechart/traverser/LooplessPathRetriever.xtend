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
package hu.bme.mit.gamma.statechart.traverser

import hu.bme.mit.gamma.statechart.model.Region
import hu.bme.mit.gamma.statechart.model.StateNode
import java.util.Collection
import java.util.logging.Level
import java.util.logging.Logger

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class LooplessPathRetriever {
	
	val logger = Logger.getLogger("GammaLogger")
	
	def Collection<Path> retrievePaths(Region region) {
		var entryState = region.entryState
		val firstActiveStates = entryState.reachableStates
		val pathsUnderExamination = newArrayList
		val finalPaths = newArrayList
		for (firstActiveState : firstActiveStates) {
			val visitedStates = <StateNode>newHashSet(firstActiveState)
			// Looking for loops resulting in the respective first active states (separately)
			for (firstOutgoingTransition : firstActiveState.outgoingTransitions) {
				pathsUnderExamination += new Path(firstOutgoingTransition)
				while (!pathsUnderExamination.empty) {
					// Copying the paths under examination so that an exception is not thrown
					val copiedPathsUnderExamination = newArrayList
					copiedPathsUnderExamination += pathsUnderExamination
					for (pathUnderExamination : copiedPathsUnderExamination) {
						// Removing the path from the queue
						pathsUnderExamination -= pathUnderExamination
						val targetState = pathUnderExamination.last.targetState
						if (targetState === firstActiveState) {
							// Found a loop
							finalPaths += pathUnderExamination
						}
						else if (visitedStates.contains(targetState)) {
							// We found a loop that does not end in the first active state
							logger.log(Level.INFO, "Found a circle: " + pathUnderExamination)
						}
						else {
							for (outgoingTransition : targetState.outgoingTransitions) {
								val extendedPath = new Path(pathUnderExamination)
								// Extending with one new transition
								extendedPath.extend(outgoingTransition)
								// Putting it into the queue
								pathsUnderExamination += extendedPath
								// Store visited state
								visitedStates += targetState
							}
						}
					}
				}
			}
		}
		return finalPaths
	}
	
}