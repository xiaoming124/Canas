function LocalSig = localSigGen(fs,bw,sf,Payload)
%GENLOCALSIG 此处显示有关此函数的摘要
%   此处显示详细说明
LocalSig = [repmat(LoRaSymbol(fs, bw, sf, 0),8,1) ;LoRaSymbol(fs, bw, sf, 8) ;LoRaSymbol(fs, bw, sf, 16) ;conj(LoRaSymbol(fs, bw, sf, 0)) ;conj(LoRaSymbol(fs, bw, sf, 0))];
% dcp = conj(LoRaSymbol(fs, bw, sf, 0));
SFD = conj(LoRaSymbol(fs, bw, sf, 0));
SFD = SFD(1:length(SFD)/4);
LocalSig = [LocalSig ;SFD];
for ii = 1:length(Payload)
    sym = LoRaSymbol(fs, 125e3, 8, Payload(ii));
    LocalSig = [LocalSig ;sym];
end
tt = 1: length(LocalSig);
tt = tt.* 1/fs;
tt = tt';
CFO = 7.080078125000000e+03;
LocalSig = LocalSig .* exp(1j * 2*pi * (CFO) * tt);
end

