##  Scenario-based verification in the Gamma framework

The Gamma Scenario Language is based on the Live Sequence Charts formalism and allows the definition of scenarios that describe executions of Gamma systems. Scenarios contain interactions sent or received by the component, delays and combined fragments.
Interactions can either be cold or hot, indicating, whether the given interaction is optional or mandatory for the execution to be accepted. To extend the expressive power of the language, annotations can be used.
Furthermore, variables can be declared in scenarios. Check expressions can be used to define constraints for the expected behaviour. 

Based on the scenarios tests can be generated, which can verify that the implementation of the system holds up to the expected behaviour. 

A more complete description can be found in the [docs](docs) subfolder in the Scenario Tutorial document.

For further verification of the system, negative tests can also be derived from scenarios. 

Furthermore, the framework allows the generation of scenario-based monitor automata. These automata can be used for runtime verification (or also for contract-based verification of the designed behavior).

Known problems:

1. Check expressions can set an acceptable interval for an event parameters value. Currently, each possible value from an interval leads to a separate test, e.g. check _(0 <= Port.event::value and 0 Port.event::value <= 100)_ would lead to 100 test cases. A possible method to mitigate this problem could be to allow the user to choose an option where only a select few tests are produced. For example, 5 tests could cover the middle of the interval, the lower and upper bounds and cases just above and below the bounds.
2. During test generation, negated interactions are not back-annotated to abstract tests. The reason for this is that based on a path leading to the target state, it is not trivial to determine the cause of an absence of an event. The absence could simply indicate that in the concrete example, the event was not observed, however the event could also be explicitly forbidden by a negated interaction.
3. Waiting (i.e., delays) directly before combined fragments can only described by using several delay expressions in the corresponding branches. A possible solution would be to allow for the description of such structures: _{delay alternative {} or {} }_. Currently, this is not allowed in the scenario language, due to the complexity it would introduce to the scenario-based transformations.
