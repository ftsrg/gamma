package hu.bme.mit.gamma.headless.server.util;

import java.io.File;
import java.io.FileFilter;

public class IsDirectoryFilter implements FileFilter {
	
	@Override
	public boolean accept(File file) {
		return file.isDirectory();
	}
	
	public static IsDirectoryFilter Create() {
		return new IsDirectoryFilter();
	}

}
