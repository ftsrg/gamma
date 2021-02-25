package hu.bme.mit.gamma.util

import java.util.Collection
import java.util.List

class JavaUtil {
	
	def <T> List<T> filter(Collection<? super T> collection, Class<T> clazz) {
		val list = <T>newArrayList
		for (element : collection) {
			if (clazz.isInstance(element)) {
				list += element as T
			}
		}
		return list
	}
	
}