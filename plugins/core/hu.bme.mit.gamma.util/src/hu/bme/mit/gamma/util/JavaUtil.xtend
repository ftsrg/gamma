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
package hu.bme.mit.gamma.util

import java.util.List
import java.util.Map

class JavaUtil {
	// Singleton
	public static final JavaUtil INSTANCE =  new JavaUtil
	protected new() {}
	//

	def <T> List<T> filterIntoList(Iterable<? super T> collection, Class<T> clazz) {
		val list = <T>newArrayList
		for (element : collection) {
			if (clazz.isInstance(element)) {
				list += element as T
			}
		}
		return list
	}
	
	def <T> Iterable<T> flattenIntoList(Iterable<? extends Iterable<? extends T>> inputs) {
		return IterableExtensions.flatten(inputs).toList
	}
	
	def <T> T getOnlyElement(Iterable<T> collection) {
		if (collection.size !== 1) {
			throw new IllegalArgumentException("Not one elment: " + collection)
		}
		return collection.last
	}
	
	def <K, V> List<V> getOrCreateList(Map<K, List<V>> map, K key) {
		if (!map.containsKey(key)) {
			map += key -> newArrayList
		}
		return map.get(key)
	}
	
}