# Canas-Matlab

Instructions to use Canas to receive LoRa packets.

Canas can cancel the logical channel interference to receive concurrent logical channels.

## Folders: 

Matlab: the matlab-implementation of Canas
  filter - coe of digital LP filters (bandwidth 125kHz~500kHz).
  input - two data traces of raw signal.

gr-lora-ChannelS: a sample configuration project of the USRP to collect the raw signal.

NodeConfig: a sample configuration project for the LoRa node in our testbed (i.e., SX1276 + Arduino Uno)

## Key Functions: 

LGIC_v2.m - logical channel interference cancellation function.

localSigGen.m - generate local signal copy based on the payload data.

## Hardware Requirements:

LoRa transmitter: SX1276 + Arduino Uno (or other LoRa-compatible radios)

Data trace collection: USRP N210 (or other Software Defined Radios with equivalent functionality)

Data trace processing: A workstation with Matlab (version:R2024a)

## To run the artifact:

We provide two data traces that reproduce the key functions of Canas.

Open the "Matlab" folder, and run two main files, the spectrum and amplitude of raw signal and signal after logical channel interference cancellation are plotted. Canas can enhance weak packet reception (reduce decoding errors) by canceling interference from strong packets.

main_singlePacket.m - cancel the signal of a single packet. 

main_concurrentPacket.m - receive two packets concurrently and cancel the strong one before receiving the weak one. Case 1: decode the weak packet directly from the Rx signal; Case 2: decode the weak packet after canceling the strong packet. The Symbol Error Rate (SER) of two cases is displayed in the command window. 

## To run and evaluate XGate on your own testbed

Collect data traces: 

1. Set up USRP at 2M sps (by default) with appropriate central frequency under your experiment settings (e.g., central frequency = 915MHz).
2. Use the GNURadio Project "gr-lora-ChannelS\examples\rx_usrp.grc" to collect data traces. The trace will be saved by the "File Sink" block. Then forward the received data traces to the workstation.

Pre-process and synthesize the data traces:

1. Extract the ground truth files of the modulated symbols (e.g., the '.mat' files in the 'input' folder). Receive the LoRa packet individually using standard LoRa demodulators, and we can get the results.
2. Normalize the packet amplitude by modifying the Rx gain in USRP or other factors.
3. Select multiple data traces and add them up with random time offsets to emulate large-scale network traffic.
