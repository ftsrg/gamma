/********************************************************************************
 * Copyright (c) 2018-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package de.uni_paderborn.uppaal.derivedfeatures;

import java.util.ArrayList;
import java.util.List;

import uppaal.declarations.Variable;
import uppaal.declarations.VariableContainer;
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
	
	public static Variable getOnlyVariable(VariableContainer container) {
		List<Variable> variable = container.getVariable();
		if (variable.size() != 1) {
			throw new IllegalArgumentException("Not one variable: " + variable);
		}
		return variable.get(0);
	}
	
}
