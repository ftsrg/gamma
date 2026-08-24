# Spacecraft Example

This document presents a SysML v2 variant of the Spacecraft example originally introduced [here](https://github.com/Open-MBEE/OpenSE-Cookbook/blob/master/SysML2x/Spacecraft%20Example/Spacecraft_Example_SysML2.ipynb) by NASA in the context of the OpenMBEE framework (a common model repository initiative). This variant differs from the original model in that the activity diagrams (referenced by the state machines) are mapped into state machine elements and imperative code constructs (if-else constructs and variable assignments).

## Structure

The model comprises two communicating state machine components among which data transmission takes place: a _ground station_ and a _spacecraft_ (see figures below).

![Ground station state machine component](images/Groundstation.png "Ground station state machine component")

The ground station receives control events from its environment (*start* and *shutdown*) via its control port, and can ping the spacecraft (*ping* event) to initiate incoming data transmission. The component has several timeouts to handle the absence of incoming events.

![Spacecraft state machine component](images/Spacecraft.png "Spacecraft state machine component")

The spacecraft starts transmitting data upon the reception of a *ping* event in packets via the *connection* port (variable data stores the number of remaining packets). Data transmission for the spacecraft requires energy, denoted by the *battery* variable. If the battery goes too low, the spacecraft enters a recharging state where energy is restored gradually. Similarly to the ground station, the spacecraft has timeouts to measure time lapse and handle idleness.

## Special constructs of interest

- Concurrent (orthogonal) regions
- Timed behavior (timeout transitions)
- The combination of concurrent regions and timed behavior
- Communication via a connection of ports

## Properties worth checking

- The _ground station_ must never spend more than 30s in state _Idle_.
- The _ground station_ may eventually reach state _Operation_.
- The _ground station_ must eventually reach state _Operation_.
- The _spacecraft_ may eventually run out of data to transmit, i.e., reach a state where the value of the _data_ variable is 0.
- The _spacecraft_ must eventually run out of data to transmit, i.e., reach a state where the value of the _data_ variable is 0.
- The _spacecraft_ must always have a battery level over 40, i.e., value of the _battery_ variable is greater than or equal to 40.
- The _spacecraft_ must never be in states _Transmitting_ and _Recharging_ at the same time.
- Whenever the _spacecraft_ is in state _Transmitting_, it will remain in this state until either the battery gets low or the _spacecraft_ runs out of data to transmit.
- If the _spacecraft_ keeps transmitting data (in state _Transmitting_), then the remaining data will eventually reach a certain threshold.
