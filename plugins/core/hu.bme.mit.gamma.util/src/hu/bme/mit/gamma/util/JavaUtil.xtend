package hu.bme.mit.gamma.util

import java.util.List

class JavaUtil {
	// Singleton
	public static final JavaUtil INSTANCE =  new JavaUtil
	protected new() {}
	//

	def <T> List<T> filter(Iterable<? super T> collection, Class<T> clazz) {
		val list = <T>newArrayList
		for (element : collection) {
			if (clazz.isInstance(element)) {
				list += element as T
			}
		}
		return list
	}
	
	def <T> Iterable<T> flatten(Iterable<? extends Iterable<? extends T>> inputs) {
		return inputs.flatten
	}
}