package hu.bme.mit.gamma.headless.server.util;

import java.io.File;
import java.io.FileFilter;
import java.io.FilenameFilter;

public class IsEclipseProjectFilter implements FileFilter {

	@Override
	public boolean accept(File file) {
		if (file.isDirectory()) {
			File[] eclipseProjectFiles = file.listFiles(new FilenameFilter() {
				@Override
				public boolean accept(File dir, String name) {
					return ".project".equals(name);
				}

			});
			return eclipseProjectFiles.length > 0;
		}
		return false;
	}

	public static IsEclipseProjectFilter Create() {
		return new IsEclipseProjectFilter();
	}

}
