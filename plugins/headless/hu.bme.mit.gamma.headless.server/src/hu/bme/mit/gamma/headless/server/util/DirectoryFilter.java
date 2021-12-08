package hu.bme.mit.gamma.headless.server.util;

import java.io.File;
import java.io.FileFilter;

public class DirectoryFilter implements FileFilter {

	public static DirectoryFilter INSTANCE = new DirectoryFilter();

	private DirectoryFilter() {
	}

	@Override
	public boolean accept(File file) {
		return file.isDirectory();
	}
}
