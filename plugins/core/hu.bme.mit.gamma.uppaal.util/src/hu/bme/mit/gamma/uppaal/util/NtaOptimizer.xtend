package hu.bme.mit.gamma.uppaal.util

import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.Set
import uppaal.expressions.LogicalOperator
import uppaal.templates.Edge
import uppaal.templates.Location
import uppaal.templates.LocationKind

import static extension de.uni_paderborn.uppaal.derivedfeatures.UppaalModelDerivedFeatures.*

class NtaOptimizer {
	
	protected extension final NtaBuilder ntaBuilder
	protected extension final GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	
	new(NtaBuilder ntaBuilder) {
		this.ntaBuilder = ntaBuilder
	}
	
	def void optimizeSubsequentEdges(Location location) {
		val outgoingEdges = newHashSet
		outgoingEdges += location.outgoingEdges
		outgoingEdges.optimizeSubsequentEdges(newHashSet)
	}
	
	def void optimizeSubsequentEdges(Set<Edge> edges, Set<Edge> visitedEdges) {
		while (!edges.empty) {
			val firstEdge = edges.head
			visitedEdges += firstEdge
			edges -= firstEdge
			val source = firstEdge.source
			val target = firstEdge.target
			val targetIncomingEdges = target.incomingEdges
			targetIncomingEdges -= firstEdge
			val targetOutgoingEdges = target.outgoingEdges
			if (firstEdge.isEmpty) {
				// Everything is empty, the edge is unnecessary
				if (source.locationTimeKind == LocationKind.COMMITED) {
					// Only if the source is committed
					val sourceIncomingEdges = source.incomingEdges
					val sourceOutgoingEdges = source.outgoingEdges
					if (sourceOutgoingEdges.size == 1) {
						for (incomingEdge : sourceIncomingEdges) {
							incomingEdge.target = target
						}
						firstEdge.remove // Delete does not work due to unsupported basicGetTypeDefinition
						source.remove
					}
				}
			}
			else if (target.locationTimeKind == LocationKind.COMMITED) {
				// Only if the target is committed (we cannot go through normal locations)
				if (targetIncomingEdges.empty && firstEdge.hasOnlyGuard) {
					// Only guard
					val guard = firstEdge.guard
					if (targetOutgoingEdges.forall[it.hasOnlyGuard]) {
						for (outgoingEdge : targetOutgoingEdges) {
							outgoingEdge.addGuard(guard.clone, LogicalOperator.AND)
							outgoingEdge.source = source
						}
						firstEdge.remove // Delete does not work due to unsupported basicGetTypeDefinition
						target.remove
					}
				}
				else if (targetIncomingEdges.empty && firstEdge.hasOnlyUpdate) {
					// Only guard
					val updates = firstEdge.update
					if (targetOutgoingEdges.forall[it.hasOnlyUpdate]) {
						for (outgoingEdge : targetOutgoingEdges) {
							outgoingEdge.update.addAll(0, updates.map[it.clone])
							outgoingEdge.source = source
						}
						firstEdge.remove // Delete does not work due to unsupported basicGetTypeDefinition
						target.remove
					}
				}
			}
			// Recursion
			for (outgoingEdge : targetOutgoingEdges.reject[visitedEdges.contains(it)]) {
				edges += outgoingEdge
			}
		}
	}
	
}