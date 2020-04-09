package hu.bme.mit.gamma.querygenerator.util;

import java.util.Scanner;
import java.util.logging.Level;
import java.util.logging.Logger;

public class VerificationResultReader extends Thread {
	
	private final Scanner scanner;
	private volatile boolean isCancelled = false;
	private Logger logger = Logger.getLogger("GammaLogger");
	
	public VerificationResultReader(Scanner scanner) {
		this.scanner = scanner;
	}
	
	public void run() {
		try {
			while (!isCancelled && scanner.hasNext()) {
				logger.log(Level.INFO, scanner.nextLine());
			}
		} finally {
			scanner.close();
		}
	}
	
	public void cancel() {
		this.isCancelled = true;
	}
}
