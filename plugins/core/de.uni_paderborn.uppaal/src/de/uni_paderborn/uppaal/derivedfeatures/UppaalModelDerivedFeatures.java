package de.uni_paderborn.uppaal.derivedfeatures;

import java.util.ArrayList;
import java.util.List;

import uppaal.templates.Edge;
import uppaal.templates.Location;
import uppaal.templates.Template;

public class UppaalModelDerivedFeatures {

	public static List<Edge> getOutgoingEdges(Location location) {
		List<Edge> outgoingEdges = new ArrayList<Edge>();
		Template template = location.getParentTemplate();
		for (Edge edge : template.getEdge()) {
			if (edge.getSource() == location) {
				outgoingEdges.add(edge);
			}
		}
		return outgoingEdges;
	}
	
	public static List<Edge> getIncomingEdges(Location location) {
		List<Edge> incomingEdges = new ArrayList<Edge>();
		Template template = location.getParentTemplate();
		for (Edge edge : template.getEdge()) {
			if (edge.getTarget() == location) {
				incomingEdges.add(edge);
			}
		}
		return incomingEdges;
	}
	
	public static boolean isEmpty(Edge edge) {
		return edge.getSelection().isEmpty() && edge.getGuard() == null &&
			edge.getSynchronization() == null && edge.getUpdate().isEmpty();
	}
	
	public static boolean hasOnlyGuard(Edge edge) {
		return edge.getSelection().isEmpty() && edge.getGuard() != null &&
			edge.getSynchronization() == null && edge.getUpdate().isEmpty();
	}
	
	public static boolean hasOnlyUpdate(Edge edge) {
		return edge.getSelection().isEmpty() && edge.getGuard() == null &&
			edge.getSynchronization() == null && !edge.getUpdate().isEmpty();
	}
	
}
