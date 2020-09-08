package hu.bme.mit.gamma.util

class SystemChecker {
	// Singleton
	public static final SystemChecker INSTANCE = new SystemChecker
	protected new() {}
	//
	
	protected static String OS = System.getProperty("os.name").toLowerCase
	
	def boolean isWindows() {
		return OS.contains("win")
	}

	def boolean isMac() {
		return OS.contains("mac")
	}

	def boolean isUnix() {
		return (OS.contains("nix") || OS.contains("nux") || OS.contains("aix"))
	}

	def boolean isSolaris() {
		return OS.contains("sunos")
	}
	
	def String getOS(){
		if (isWindows) {
			return "win"
		} else if (isMac) {
			return "osx"
		} else if (isUnix) {
			return "uni"
		} else if (isSolaris) {
			return "sol"
		} else {
			return "err"
		}
	}
	
}