/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.util

import java.util.AbstractMap.SimpleEntry
import java.util.Collection
import java.util.List
import java.util.Map
import java.util.Map.Entry
import java.util.Set

class JavaUtil {
	// Singleton
	public static final JavaUtil INSTANCE = new JavaUtil
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
	
	def <T> List<T> flattenIntoList(Iterable<? extends Iterable<? extends T>> inputs) {
		return IterableExtensions.flatten(inputs).toList
	}
	
	def <T> T getFirstOfType(Iterable<? super T> collection, Class<T> clazz) {
		for (element : collection) {
			if (clazz.isInstance(element)) {
				return element as T
			}
		}
	}
	
	def <T> T getLastOfType(Iterable<? super T> collection, Class<T> clazz) {
		return collection.toList
			.reverseView
			.getFirstOfType(clazz)
	}
	
	def <T> T getLast(Iterable<T> collection) {
		var T last = null
		for (element : collection) {
			last = element
		}
		return last
	}
	
	def boolean isUnique(Iterable<?> collection) {
		val set = newHashSet
		for (element : collection) {
			if (set.contains(element)) {
				return false
			}
			set += element
		}
		return true
	}
	
	def boolean containsAny(Collection<?> lhs, Iterable<?> rhs) {
		for (element : rhs) {
			if (lhs.contains(element)) {
				return true
			}
		}
		return false
	}
	
	def boolean containsNone(Collection<?> lhs, Iterable<?> rhs) {
		return !lhs.containsAny(rhs)
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
	
	def <K, V> Set<V> getOrCreateSet(Map<K, Set<V>> map, K key) {
		if (!map.containsKey(key)) {
			map += key -> newLinkedHashSet
		}
		return map.get(key)
	}
	
	def <K, V> V checkAndGet(Map<K, V> map, K key) {
		if (!map.containsKey(key)) {
			throw new IllegalArgumentException("Not contained element: " + key)
		}
		return map.get(key)
	}
	
	def <K, V> Set<Entry<V, K>> invert(Map<K, V> map) {
		return map.entrySet.invert.toSet
	}
	
	def <K, V> Collection<Entry<V, K>> invert(Collection<? extends Entry<K, V>> entrySet) {
		val entries = <Entry<V, K>>newArrayList
		for (entry : entrySet) {
			entries += new SimpleEntry(entry.value, entry.key)
		}
		return entries
	}
	
	def String toFirstCharUpper(String string) {
		return string.toFirstUpper
	}
	
	def String toFirstCharLower(String string) {
		return string.toFirstLower
	}
	
}