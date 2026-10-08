# NanosatC-Br Example

This document presents a SysML v2 variant of the NanosatC-Br subsystem designed by [INPE](http://antigo.inpe.br/). The subsystems comprises two communicating components, an on-board computer (_OBC_) and an _SLP_ payload subsystem. The communication channel is an I2C bus and the communication protocol follows a master-slave setting.

## Structure

The _OBC_ subsystem assumes the role of master and its nominal behavior shall be represented by the following states: 1) be in operation waiting for information received by the _SLP_ (_Idle_ state), 2) send Command to the _SLP_ (_Send_ state), 3) receive Information from the _SLP_ to define the next operation (_Receive_ state), and 4) write in the memory area the data read from the _SLP_ experiment (_Write_ state).

The payload subsystem _SLP_ assumes the role of slave and its nominal behavior shall be represented by the following states: 1) be in operation (_On_ state) waiting to begin communication with the _OBC_, 2) receive _OBC_ Command (_Receive_ state) to evaluate the next operation to be performed, 3) send Information requested by the _OBC_ (_Send_ state), 4) acquire the data of the experiment and store in the buffer (*Acquisition_Experiment* state), and 5) read the experiment data (*Read_Experiment* state) and send it to the _OBC_ (*Send* state).

![OBC and SLP components](images/OBC_SLP.png "OBC and SLP components")

## Special constructs of interest

- Parametric events
- Communication via a connection of ports

## Properties worth checking

Information of interest are the exceptional conditions between the subsystems. We can focus on the following conditions: 1) in case the _OBC_ receives a "noacknowledge" information, it shall inform that there was a Problem and it shall resend the first Command, 2) in case the SPL receives a "noacknowledge" command, it shall read again the first command returned by the _OBC_, 3) in case the _SLP_ acknowledges the command received from the _OBC_, the _SLP_ shall inform the _OBC_ that the command received is OK, 4) when the _SLP_ finishes the acquisition of the experiment it shall inform that it is ready to read a new Command and it shall send the experiment data to the _OBC_, and 5) when the _SLP_ finishes sending the data to the _OBC_, the _SLP_ shall inform the _OBC_ that it is OK and return to the acquisition of new data of the experiment.
