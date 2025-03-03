function LoRaPacket = LoRaPacket(fs,BW,SF)
%LORAPACKET Summary of this function goes here
%   Detailed explanation goes here
LoRaPacket = repmat(LoRaSymbol(fs,BW,SF,0),10,1);
SFD = conj(LoRaSymbol(fs,BW,SF,0));
LoRaPacket = [LoRaPacket;SFD;SFD;SFD(1:length(SFD)/4)];
for ii = 1:86
    sym = round(rand()*2^SF);
    LoRaPacket = [LoRaPacket; LoRaSymbol(fs,BW,SF,sym)];
end

end

