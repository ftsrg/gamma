package hu.bme.mit.gamma.util

import java.util.Collection
import java.util.List

class JavaUtil {
	// Singleton
	public static final JavaUtil INSTANCE =  new JavaUtil
	protected new() {}
	//

	def <T> List<T> filter(Collection<? super T> collection, Class<T> clazz) {
		val list = <T>newArrayList
		for (element : collection) {
			if (clazz.isInstance(element)) {
				list += element as T
			}
		}
		return list
	}
	
	def <T> T getOnlyElement(Collection<T> collection) {
		if (collection.size !== 1) {
			throw new IllegalArgumentException("Not one elment: " + collection)
		}
		return collection.last
	}
	
}