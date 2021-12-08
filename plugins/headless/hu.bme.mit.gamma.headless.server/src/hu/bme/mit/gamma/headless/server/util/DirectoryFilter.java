package hu.bme.mit.gamma.headless.server.util;

import java.io.File;
import java.io.FileFilter;

public class DirectoryFilter implements FileFilter {
	// Singleton
	public static final DirectoryFilter INSTANCE = new DirectoryFilter();
	protected DirectoryFilter() {}
	//

	@Override
	public boolean accept(File file) {
		return file.isDirectory();
	}
}
