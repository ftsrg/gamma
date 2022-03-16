package hu.bme.mit.gamma.tutorial.contract.finish;

import static org.junit.Assert.assertTrue;

import java.io.IOException;

import org.junit.Test;

public class StatechartGenerationTest {

	private StatechartComparator comparator = new StatechartComparator();
	private static String reference = "model\\test\\referenceStatecharts\\";
	private static String input = "model\\test\\inputStatecharts\\";

	@Test
	public void alternativeTest() {
		try {
			assertTrue(
					comparator.compare(input + "AlternativeStatechart.gcd", reference + "AlternativeStatechart.gcd"));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	@Test
	public void complexTest() {
		try {
			assertTrue(comparator.compare(input + "ComplexStatechart.gcd", reference + "ComplexStatechart.gcd"));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	@Test
	public void delayTest() {
		try {
			assertTrue(comparator.compare(input + "DelayStatechart.gcd", reference + "DelayStatechart.gcd"));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	@Test
	public void delayAloneTest() {
		try {
			assertTrue(comparator.compare(input + "DelayAloneStatechart.gcd", reference + "DelayAloneStatechart.gcd"));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	@Test
	public void delayWithReceivesTest() {
		try {
			assertTrue(comparator.compare(input + "DelayWithReceivesStatechart.gcd",
					reference + "DelayWithReceivesStatechart.gcd"));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	@Test
	public void InitialOutputsTest() {
		try {
			assertTrue(comparator.compare(input + "InitialOutputsStatechart.gcd",
					reference + "InitialOutputsStatechart.gcd"));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	@Test
	public void loopTest() {
		try {
			assertTrue(comparator.compare(input + "LoopStatechart.gcd", reference + "LoopStatechart.gcd"));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	@Test
	public void negBlockTest() {
		try {
			assertTrue(comparator.compare(input + "NegBlockSendsPermissiveStatechart.gcd",
					reference + "NegBlockSendsPermissiveStatechart.gcd"));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	@Test
	public void negSignalTest() {
		try {
			assertTrue(comparator.compare(input + "NegSendsStrictStatechart.gcd",
					reference + "NegSendsStrictStatechart.gcd"));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	@Test
	public void optionalTest() {
		try {
			assertTrue(comparator.compare(input + "OptionalStatechart.gcd", reference + "OptionalStatechart.gcd"));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	@Test
	public void receivesPermissiveTest() {
		try {
			assertTrue(comparator.compare(input + "ReceivesPermissiveStatechart.gcd",
					reference + "ReceivesPermissiveStatechart.gcd"));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	@Test
	public void sendsPermissiveTest() {
		try {
			assertTrue(comparator.compare(input + "SendsPermissiveStatechart.gcd",
					reference + "SendsPermissiveStatechart.gcd"));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	@Test
	public void receivesStrictTest() {
		try {
			assertTrue(comparator.compare(input + "ReceivesStrictStatechart.gcd",
					reference + "ReceivesStrictStatechart.gcd"));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	@Test
	public void sendsStrictTest() {
		try {
			assertTrue(
					comparator.compare(input + "SendsStrictStatechart.gcd", reference + "SendsStrictStatechart.gcd"));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
}
