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
package hu.bme.mit.gamma.scenario.reduction;

public class FragmentInteractionPair {
	
	private int fragment=-1;
	
	private int interaction=-1;

	public int getFragment() {
		return fragment;
	}

	public int getInteraction() {
		return interaction;
	}

	public FragmentInteractionPair(int fragment, int interaction) {
		this.fragment = fragment;
		this.interaction = interaction;
	}
}
