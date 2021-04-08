package hu.bme.mit.gamma.util

import org.eclipse.xtend.lib.annotations.Data

@Data
class Triple<K, V, T> {
	
	K first;
	V second;
	T third;
	
}