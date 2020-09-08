package hu.bme.mit.gamma.util

class PathEscaper {
	// Singleton
	public static final PathEscaper INSTANCE = new PathEscaper
	protected new() {}
	//
	
	protected final extension SystemChecker systemChecker = SystemChecker.INSTANCE
	
	def String escapePath(String path) {
		if (isWindows) {
			return '''"«path»"'''
		}
		else {
			// Unix
			return path.replaceAll(" ", "\\ ")
		}
	}
	
}