close all; clc;

% Sampling parameters
Fs = 2e6;          % default sample rate 2MHz

% LORA pkt variables
bw = 125e3;
num_data_sym_SF8 = 112; % for (125kHz, SF8) packet
num_data_sym_SF10 = 88; % for (125kHz, SF10) packet

% figure display configuration
SHOW_SIGNALS = 1;   % show the raw signals or not
SHOW_SPECTRUM = 1;  % show the spectrum of raw signals or not

% load filter coe
filter125 = load("filter\125k_Filter.mat").Num';
filter250 = load("filter\250k_Filter.mat").Num';
filter500 = load("filter\500k_Filter.mat").Num';
filter500_62 = load("filter\filter_500_62.5.mat").Num';

% load true symbols
payloadSF8 = load("input/concurrentPacket/125e3_8_0cf_gth_112sym.mat").grd_truth_SF8;

% data loading section
fi_1 = fopen('Input/concurrentPacket/concurrentPacket_125e3_8_10.dat','rb');
x_inter_1 = fread(fi_1, 'float32');
fclose(fi_1);

% if data is complex
x_1 = x_inter_1(1:2:end) + 1i*x_inter_1(2:2:end);

%% directly decode SF10 packet
rxSig = conv(x_1,filter125,'full');
rxSig = downsample(rxSig, 16);
payloadSF10 = demodulation(bw,rxSig,bw,10,num_data_sym_SF10);

grdTruthSF10 = load("input/concurrentPacket/125e3_10_0cf_gth_88sym.mat").grd_truth_SF10;
disp('******************************************');
disp(['Symbol Error Rate before LGIC:' num2str(SER(10,payloadSF10,grdTruthSF10))]);
disp('******************************************');

%% re-sample the Rx signal to fs sampling rate
fs = 250e3;
rxSig = conv(x_1,filter125,'full');
rxSig = downsample(rxSig, 8);

%% generate local signal at fs sampling rate
localSigSF8 = localSigGen(fs, bw, 8, payloadSF8);

%% logical channel interference cancellation - remove SF8 packet from the Rx signal
[outputSig,outputRawSig] = LGIC_v2(rxSig,localSigSF8,fs,bw,8,payloadSF8);

%% decode SF10 packet after LGIC
rxSigAf = conv(outputRawSig,filter500_62,'full');
rxSigAf = downsample(rxSigAf, 2);
payloadSF10 = demodulation(bw,rxSigAf,bw,10,num_data_sym_SF10);
disp('******************************************');
disp(['Symbol Error Rate after LGIC:' num2str(SER(10,payloadSF10,grdTruthSF10))]);
disp('******************************************');

%% figure plot

if (SHOW_SIGNALS > 0)
    figure(1);
    subplot(211);
    plot(abs(rxSig),LineWidth=0.1,color=[0.2 0.2 0.2],Markersize=2,MarkerFaceColor=[0.2 0.2 0.2]);
    ylim([0 0.03]);
    xlabel('Samples');
    ylabel('Amplitude');
    title('Raw signals (before cancellation)');
    
    subplot(212);
    plot(abs(outputRawSig),LineWidth=0.1,color=[0.2 0.2 0.2],Markersize=2,MarkerFaceColor=[0.2 0.2 0.2]);
    ylim([0 0.03]);
    xlabel('Samples');
    ylabel('Amplitude');
    title('Raw signals (after cancellation)');
    set(gcf,'Position',[200 500 600 300]);
end

if (SHOW_SPECTRUM > 0)
    figure;
    subplot(211);
    pspectrum(rxSig,fs,'spectrogram','OverlapPercent',99,'Leakage',0.85,'MinThreshold',-70,'TimeResolution',0.001)
    xlabel('Time (ms)');
    ylabel('Freq (kHz)');
    title('Spectrum (before cancellation)');
    
    subplot(212);
    pspectrum(outputRawSig,fs,'spectrogram','OverlapPercent',99,'Leakage',0.85,'MinThreshold',-70,'TimeResolution',0.001);
    xlabel('Time (ms)');
    ylabel('Freq (kHz)');
    title('Spectrum (after cancellation)');
    
    set(gcf,'Position',[800 500 600 300]);
end