function LoRaSymbol = LoRaSymbol(fs,BW,SF,Symbol)
%LORASYMBOL Summary of this function goes here
%   Detailed explanation goes here
Ts = 2^SF/BW;
Samples = fs * Ts;
tt1 = 1 : Samples * (1 - Symbol / 2^SF);
tt2 = Samples * (1 - Symbol / 2^SF) + 1 : Samples;
tt1 = tt1 * 1/fs;
tt2 = tt2 * 1/fs;

FH = exp(1j*2*pi*(BW/Ts*0.5*tt1-BW/2 + Symbol*BW/2^SF).*tt1).';
SH = exp(1j*2*pi*(BW/Ts*0.5*tt2-BW/2 + Symbol*BW/2^SF - BW).*tt2).';

LoRaSymbol = [FH ; SH];
end

