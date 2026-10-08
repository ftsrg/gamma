# Orion Example

This document presents a SysML v2 variant of the so-called Orion protocol designed by [Prolan](https://www.prolan.hu/en/hirek/PRORIS-H) in the context of the [2018-1.3.1-VKE project](https://nkfih.gov.hu/english-2017/nrdi-fund/funded-projects-2018-131-vke). The protocol aims to conduct the establishment of a connection between a sender (master) and a receiver (slave) participant on a shared channel.

## Structure

Orion is a master-slave communication protocol, where the establishment of a connection between two participants is always initiated by a master and the connection request is either accepted or rejected by a slave. Both the master and the slave participants have the same events (commands and messages) that can be classified into two groups:
- _Connect_ and _Disconnect_ events come from the environment and can be used as external commands to initiate a connection or break down an established connection. _Invalid_ event is also an external event indicating an invalid status in the environment of the system.
- Events of the Orion protocol are transmitted between protocol participants and can be used to establish (_OrionConnReq_, _OrionConnResp_ and _OrionConnConf_) or break down a connection (_OrionDisconnCause_), send data in established connections (_OrionAppData_) or keep the established connection alive in the absence of transmittable data (_OrionKeepAlive_).

The initial state of the master state machine (depicted below) is _Closed_. Upon receiving a _Connect_ event or after a specified timeout (_TReconn_: 5 seconds in the example), it goes to state _Connecting_ while sending an _OrionConnReq_ event to the slave. If it receives an _OrionConnResp_ event within a specified time interval, it goes to state _Connected_ while sending an _OrionConnConf_ event to the slave. If in state _Connecting_, it receives any other events, or does not receive any events in a specified time interval (_TConn_: 5 sec), it goes back to state _Closed_ and sends an _OrionDisconn_ event when necessary, i.e., if the received event was not _OrionDisconnCause_. In state _Connected_, application-specific data, or in the absence of data for a specified time interval (_TKeepAlive_: 4 sec) an _OrionKeepAlive_ event are sent (child state _KeepAliveSendTimeout_). Also in state _Connected_, data, as well as _OrionKeepAlive_ events are received (child state _KeepAliveReceiveTimeout_). However, if any other event is received or no events are received in a specified time interval (_TInactive_: 5 sec), the master goes back to state _Closed_ and sends an _OrionDisconn_ event if necessary.

![Master participant](images/Master.png "Master participant")

The slave state machine (see figure below) is very similar to the master.

![Slave participant](images/Slave.png "Slave participant")

## Special constructs of interest

- Concurrent (orthogonal) regions
- Timed behavior (timeout transitions)
- Parameters (for timeouts)
- Communication via a connection of ports

## Properties worth checking

- The _master_ must never spend more than _TReconn_s in state _Closed_.
- Whenever the _master_ is in state _Connection_, the _slave_ must *not* be in state _Connected_.
- The system may eventually reach a state in which both the master and the slave are in state _Connected_.
- The system must eventually reach a state in which both the master and the slave are in state _Connected_.