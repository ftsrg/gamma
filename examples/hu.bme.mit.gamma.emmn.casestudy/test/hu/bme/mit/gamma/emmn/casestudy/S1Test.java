package hu.bme.mit.gamma.emmn.casestudy;

import static org.junit.Assert.assertTrue;

import org.junit.Before;
import org.junit.Test;

import hu.bme.mit.gamma.emmn.casestudy.s1.ReflectiveS1;

public class S1Test {

	private static ReflectiveS1 s1;
	
	@Before
	public void init() {
		s1 = new ReflectiveS1(); 
		s1.reset();
	}
	
	@Test
	public void test() {
		s1.raiseEvent("Input", "a");
		s1.schedule();
		s1.raiseEvent("Input", "b");
		s1.schedule();
		s1.raiseEvent("Input", "a");
		s1.schedule();
		s1.raiseEvent("Input", "b");
		s1.schedule();
		
		assertTrue(s1.isStateActive("region", "state2"));

		s1.raiseEvent("OutputReversed", "y");
		s1.schedule();
		
		assertTrue(s1.isStateActive("region", "hotComponentViolation")); // Expected hot violation
	}
	
}
