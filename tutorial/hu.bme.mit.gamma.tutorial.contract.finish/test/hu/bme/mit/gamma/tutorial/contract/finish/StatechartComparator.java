package hu.bme.mit.gamma.tutorial.contract.finish;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.List;
import java.util.stream.Stream;

public class StatechartComparator {

	public boolean compare(String filename1, String filename2) throws IOException {
		InputStreamReader filereader1 = new InputStreamReader(new FileInputStream(filename1));
		BufferedReader bufReader1 = new BufferedReader(filereader1);
		InputStreamReader filereader2 = new InputStreamReader(new FileInputStream(filename2));
		BufferedReader bufReader2 = new BufferedReader(filereader2);
		Object[] lines1 = bufReader1.lines().toArray();
		Object[] lines2 = bufReader2.lines().toArray();
		if (lines1.length != lines2.length) {
			System.err.println("Files " + filename1 + " and " + filename2 + "has different number of rows.");
			bufReader2.close();
			bufReader1.close();
			return false;
		}
		boolean ok = true;
		for (int i = 0; i < lines1.length; i++) {
			if (!lines1[i].equals(lines2[i])) {
				ok = false;
				System.err.println("Different lines: " + lines1[i] + " and " + lines2[i] + ".");
			}
		}
		bufReader2.close();
		bufReader1.close();
		return ok;
	}

}
