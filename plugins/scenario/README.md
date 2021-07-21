##  Scenario based testing for the Gamma Framework


The Gamma Scenario Language is based on the Live Sequence Charts formalism and allows the definition of scenarios that describe executions of Gamma systems. Scenarios contain interactions sent or received by the component, delays and combined fragments.
Interactions can either be cold or hot, indicating, weather the given interaction is optional or mandatory for the execution to be accepted. To extend the expressive power of the language, annotations can be used. 

Based on the scenarios tests can be generated, which can verify that the implementation of the system holds up to the expected behaviour. 

A more complete description can be found in the docs sub folder in the Scenario Tutorial document.

Known problems:

1. A large number of abstract tests are generated based on scenarios.
2. The Theta framework, which is used as a formal verification backend, does not produce all possible paths to the Accepting state in all scenarios.
3. If an interaction set contains a delay and atomic interactions, the timer of the delay starts again in every iteration of the interval. 
4. Currently it is not possible, to describe, that an interaction should be sent immediately after the start of the scenario as at the start of the formal verification process, no events are present in the system.