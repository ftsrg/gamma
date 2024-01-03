/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
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
	
	def <T> T removeLast(List<T> list) {
		return list.remove(list.size - 1)
	}
	
	def <T> void removeAllButFirst(List<T> list) {
		for (var i = 1; i < list.size; /* No op */) {
			list.remove(i)
		}
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
	
	def <K> Integer increment(Map<K, Integer> map, K key) {
		if (!map.containsKey(key)) {
			map.put(key, 0)
		}
		val value = map.get(key)
		return map.put(key, value + 1)
	}
	
	def <K, V> Set<Entry<V, K>> invert(Map<K, V> map) {
		return map.entrySet.invert.toSet
	}
	
	def <K, V, T> Map<K, T> castValues(Map<K, V> map, Class<T> clazz) {
		val castedMap = newHashMap
		
		for (key : map.keySet) {
			val value = map.get(key)
			val castedValue = value as T
			
			castedMap += key -> castedValue
		}
		
		return castedMap
	}
	
	def <K, V> Collection<Entry<V, K>> invert(Collection<? extends Entry<K, V>> entrySet) {
		val entries = <Entry<V, K>>newArrayList
		for (entry : entrySet) {
			entries += new SimpleEntry(entry.value, entry.key)
		}
		return entries
	}
	
	def <T> collectMinimumValues(Map<T, Integer> values, Iterable<? extends Map<T, Integer>> collectableValues) {
		for (Map<T, Integer> collectableValue : collectableValues) {
			for (T key : collectableValue.keySet()) {
				val newValue = collectableValue.get(key)
				
				if (values.containsKey(key)) {
					val oldValue = values.get(key)
					if (newValue < oldValue) {
						values.replace(key, newValue)
					}
				}
				else {
					values += key -> newValue
				}
			}
		}
	}
	
	//
	
	def matchFirstCharacterCapitalization(String string, String example) {
		if (example.nullOrEmpty) {
			return string
		}
		
		val exampleChar = example.charAt(0)
		val isUpperCase = Character.isUpperCase(exampleChar)
		if (isUpperCase) {
			return string.toFirstUpper
		}
		return string.toFirstLower
	}
	
	def String toFirstCharUpper(String string) {
		return string.toFirstUpper
	}
	
	def String toFirstCharLower(String string) {
		return string.toFirstLower
	}
	
	def splitLines(String string) {
		return string.split(System.lineSeparator).reject[it.nullOrEmpty]
	}
	
	def void trim(StringBuilder builder) {
		val trimmedString = builder.toString.trim
		builder.length = 0
		builder.append(trimmedString)
	}
	
	def String deparenthesize(String string) {
		val stringBuilder = new StringBuilder
		stringBuilder.append(string.trim)
		
		while (stringBuilder.deparenthesizable) {
			stringBuilder.deleteCharAt(0)
			stringBuilder.deleteCharAt(stringBuilder.length - 1)
			stringBuilder.trim
		}
		
		return stringBuilder.toString.trim
	}
	
	def boolean isDeparenthesizable(StringBuilder stringBuilder) {
		return stringBuilder.toString.deparenthesizable
	}
	
	def boolean isDeparenthesizable(String string) {
		val char leftParenthesis = '('
		val char rightParenthesis = ')'
		
		if (string.charAt(0) == leftParenthesis &&
				string.charAt(string.length - 1) == rightParenthesis) {
			var parenthesisCount = 0
			for (var i = 1; i < string.length - 1; i++) {
				val charAt = string.charAt(i)
				if (charAt == leftParenthesis) {
					parenthesisCount++
				}
				else if (charAt == rightParenthesis) {
					parenthesisCount--
				}
				if (parenthesisCount < 0) {
					return false
				}
			}
			
			return true
		}
		
		return false
	}
	
	def String simplifyCharacterPairs(String string, char character) {
		val deparenthesizedString = string.deparenthesize
		if (deparenthesizedString.charAt(0) != character) {
			return deparenthesizedString
		}
		
		val charRemoved = deparenthesizedString.substring(1)
		val deparenthesizedCharRemoved = charRemoved.deparenthesize
		if (deparenthesizedCharRemoved.charAt(0) == character) {
			val charDoubleRemoved = deparenthesizedCharRemoved.substring(1)
			return charDoubleRemoved.simplifyCharacterPairs(character) // Recursion to remove next char pair
		}
		
		// No success, we return the original one
		return deparenthesizedString
	}
	
	def String simplifyExclamationMarkPairs(String string) {
		return string.simplifyCharacterPairs('!')
	}
	
}