/********************************************************************************
 * Copyright (c) 2022-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.promela.verification

import hu.bme.mit.gamma.querygenerator.serializer.PromelaPropertySerializer
import hu.bme.mit.gamma.verification.util.AbstractVerification

class PromelaVerification extends AbstractVerification {
	// Singleton
	public static final PromelaVerification INSTANCE = new PromelaVerification
	protected new() {}
	//
	
	override protected getTraceabilityFileName(String fileName) {
		return fileName.unfoldedPackageFileName
	}
	
	protected override createVerifier() {
		return new PromelaVerifier
	}
	
	override getDefaultArgumentsForInvarianceChecking() {
		val INVARIANT_ARGUMENTS = #["-DSAFETY", "-DSFH"]
		val defaultArguments = defaultArguments
		val defaultArgumentsForInvariants = defaultArguments.map[it + " " + INVARIANT_ARGUMENTS.join(" ")]
		
		return defaultArgumentsForInvariants
	}
	
	override getDefaultArguments() {
		val MAX_DEPTH = 1200
		val HASH_TABLE_SIZE = 27
		return #[
			'''-search -n -I -m«MAX_DEPTH» -w«HASH_TABLE_SIZE» -DVECTORSZ=4096 -DNOBOUNDCHECK''' // -DBITSTATE -DNOFAIR
//			'''-search -n -m«MAX_DEPTH» -w«HASH_TABLE_SIZE» -DVECTORSZ=4096 -DNOBOUNDCHECK'''
//			'''-search -n -bfs -DVECTORSZ=4096 -DCOLLAPSE -DNOBOUNDCHECK'''
		]
		// -A apply slicing algorithm
		// -m Changes the semantics of send events. Ordinarily, a send action will be (blocked) if the target message buffer is full. With this option a message sent to a full buffer is lost.
		// -a search for acceptance cycles
		// -b bounded search mode, makes it an error to exceed the search depth, triggering and error trail
		// -I like -i, but approximate and faster
		// -i search for shortest path to error (causes an increase of complexity)
		// -mN set max search depth to N steps (default N=10000)
		// -MN use N Megabytes for bitstate hash array (bitstate mode)
		// -GN use N Gigabytes for bitstate hash array (bitstate mode)
		// -n no listing of unreached states at the end of the run
//		hint: to reduce memory, recompile with
//		-DCOLLAPSE # good, fast compression, or
//		-DMA=1380   # better/slower compression, or
//		-DHC # hash-compaction, approximation
//		-DBITSTATE # supertrace, under-approximation
		// Multi-core DFS mode
//		-DMEMLIM=8000 --> necessary for multi-core settings - allow up to 8 GB of shared memory
//		-DNCORE=N   --> enables multi_core verification if N>1
//		-DFULL_TRAIL --> support full error trails (but increases memory use)

/*
 *	Directives to Increase Speed
NOBOUNDCHECK	don't check array bound violations (faster)
NOCOMP	don't compress states with fullstate storage (faster, but not compatible with liveness unless -DBITSTATE)
NOFAIR	disable the code for weak-fairness (is faster)
NOSTUTTER	disable stuttering rules (warning: changes semantics) stuttering rules are the standard way to extend a finite execution sequence into and infinite one, to allow for a consistent interpretation of B\(u"chi acceptance rules
SAFETY	optimize for the case where no cycle detection is needed (faster, uses less memory, disables both -l and -a)
SFH  faster verification of safety properties, sets also NOCOMP (faster, uses slightly more memory, disables both -l and -a)
	* Directives to Reduce Memory Use
BITSTATE	use supertrace/bitstate instead of exhaustive exploration
COLLAPSE	a state vector compression mode; collapses state vector sizes by up to 80% to 90% (see Spin97 workshop paper) variations: add -DSEPQS or -DJOINPROCS (off by default)
FULL_TRAIL leaving this directive out significantly reduces memory in multi-core mode, but reduces error-trails to a suffix of the full trail only. adding it restores the capability to generate full error trails.
Only relevant in mult-core verifications; no effect elsewhere.
HC	a state vector compression mode; collapses state vector sizes down to 32+16 bits and stores them in conventional hash-table (a version of Wolper's hash-compact method -- new in version 3.2.2.) Variations: HC0, HC1, HC2, HC3 for 32, 40, 48, or 56 bits respectively. The default is equivalent to HC2.
MA=N	use a minimized DFA encoding for the state space, similar to a BDD, assuming a maximum of N bytes in the state-vector (this can be combined with -DCOLLAPSE for greater effect in cases when the original state vector is long)
MEMCNT=N	set upperbound to the amount of memory that can be allocated usage, e.g.: -DMEMCNT=20 for a maximum of 2^20 bytes
MEMLIM=N	set upperbound to the true number of Megabytes that can be allocated; usage, e.g.: -DMEMLIM=200 for a maximum of 200 Megabytes (meant to be a simple alternative to MEMCNT)
SC	enables stack cycling. this will swap parts of a very long search stack to a diskfile during verifications. the runtime flag -m for setting the size of the search stack still remains, but now sets the size of the part of the stack that remains in core. it is meant for rare applications where the search stack is many millions of states deep and eats up the majority of the memory requirements.
SPACE	optimize for space not speed 
*/
	}
	
	protected override String getArgumentPattern() {
		return "(-([A-Za-z_])*([0-9])*(=)?([0-9])*( )*)*"
	}
	
	override protected createPropertySerializer() {
		return PromelaPropertySerializer.INSTANCE
	}
	
}