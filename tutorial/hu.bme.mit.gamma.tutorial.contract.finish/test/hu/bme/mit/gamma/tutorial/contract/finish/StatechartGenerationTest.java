package hu.bme.mit.gamma.tutorial.contract.finish;

import static org.junit.Assert.assertTrue;

import java.io.IOException;

import org.junit.Test;

public class StatechartGenerationTest {
	
	private StatechartComparator comparator = new StatechartComparator();
	private static String reference ="model\\test\\referenceStatecharts\\";
	private static String input = "model\\test\\inputStatecharts\\";

	@Test
	public void alternativeTest(){
		try {
			assertTrue(comparator.compare(input+"AlternativeStatechart.gcd", reference+"AlternativeStatechart.gcd"));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
}
