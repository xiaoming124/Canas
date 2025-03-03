function [outputSig,outputRawSig] = LGIC_v2(rxSig,localSig,fs,bw,sf,payload)
%LGIC Logical Channel Interference Cancellation

% detect start of Rx signal
windowLength = 2^sf*fs/bw;
corrDet = xcorr(rxSig,conj(LoRaSymbol(fs,bw,8,0)));
corrDetNorm = normalize(abs(corrDet),'range');
peak = [];
for ii = 1:length(corrDetNorm)
    if corrDetNorm(ii) > 0.7 && corrDetNorm(ii)>corrDetNorm(ii+1) && corrDetNorm(ii)>corrDetNorm(ii-1)
        peak = [peak ii];
    end
end
startRx = min(peak) - (length(corrDet)+1)/2 - windowLength*10 - 24;
packetStart = startRx;

outputSig = zeros(length(localSig),1);
outputRawSig = rxSig;
ucp = LoRaSymbol(fs,bw,8,0);
dcp = conj(LoRaSymbol(fs,bw,8,0));

% Preamble
for winID = 0:9
    rxSigTemp = rxSig(startRx+windowLength*winID:startRx+windowLength*winID+windowLength-1);
    localSigTemp = localSig(1+windowLength*winID:1+windowLength*winID+windowLength-1);
    rxConjMult = fft(rxSigTemp.*dcp);
    localConjMult = fft(localSigTemp.*dcp);
    [~,idx1] = max(abs(rxConjMult));
    [~,idx2] = max(abs(localConjMult));
    localSigReconstruct = localSigTemp/localConjMult(idx2)*rxConjMult(idx1);
    outputSig(1+windowLength*winID:1+windowLength*winID+windowLength-1) = rxSigTemp - localSigReconstruct;
    amp1 = mean(abs(rxSigTemp - localSigReconstruct));

    startRx = startRx - 1;
    rxSigTemp = rxSig(startRx+windowLength*winID:startRx+windowLength*winID+windowLength-1);
    localSigTemp = localSig(1+windowLength*winID:1+windowLength*winID+windowLength-1);
    rxConjMult = fft(rxSigTemp.*dcp);
    localConjMult = fft(localSigTemp.*dcp);
    [~,idx1] = max(abs(rxConjMult));
    [~,idx2] = max(abs(localConjMult));
    localSigReconstruct = localSigTemp/localConjMult(idx2)*rxConjMult(idx1);    
    amp2 = mean(abs(rxSigTemp - localSigReconstruct));
    if amp2 < amp1
        outputSig(1+windowLength*winID:1+windowLength*winID+windowLength-1) = rxSigTemp - localSigReconstruct;
    end   
    startRx = startRx + 1;
end

% SFD
startRx = startRx - 5;
for winID = 10:11
    rxSigTemp = rxSig(startRx+windowLength*winID:startRx+windowLength*winID+windowLength-1);
    localSigTemp = localSig(1+windowLength*winID:1+windowLength*winID+windowLength-1);
    rxConjMult = fft(rxSigTemp.*ucp);
    localConjMult = fft(localSigTemp.*ucp);
    [~,idx1] = max(abs(rxConjMult));
    [~,idx2] = max(abs(localConjMult));
    localSigReconstruct = localSigTemp/localConjMult(idx2)*rxConjMult(idx1);
    outputSig(1+windowLength*winID:1+windowLength*winID+windowLength-1) = rxSigTemp - localSigReconstruct;
    amp1 = mean(abs(rxSigTemp - localSigReconstruct));

    startRx = startRx - 1;
    rxSigTemp = rxSig(startRx+windowLength*winID:startRx+windowLength*winID+windowLength-1);
    localSigTemp = localSig(1+windowLength*winID:1+windowLength*winID+windowLength-1);
    rxConjMult = fft(rxSigTemp.*dcp);
    localConjMult = fft(localSigTemp.*dcp);
    [~,idx1] = max(abs(rxConjMult));
    [~,idx2] = max(abs(localConjMult));
    localSigReconstruct = localSigTemp/localConjMult(idx2)*rxConjMult(idx1);    
    amp2 = mean(abs(rxSigTemp - localSigReconstruct));
    if amp2 < amp1
        outputSig(1+windowLength*winID:1+windowLength*winID+windowLength-1) = rxSigTemp - localSigReconstruct;
    end   
    startRx = startRx + 1;
end

winID = 12;
ucp = ucp(1:length(ucp)/4);
rxSigTemp = rxSig(startRx+windowLength*winID:startRx+windowLength*winID+windowLength/4-1);
localSigTemp = localSig(1+windowLength*winID:1+windowLength*winID+windowLength/4-1);
rxConjMult = fft(rxSigTemp.*ucp);
localConjMult = fft(localSigTemp.*ucp);
[~,idx1] = max(abs(rxConjMult));
[~,idx2] = max(abs(localConjMult));
localSigReconstruct = localSigTemp/localConjMult(idx2)*rxConjMult(idx1);
outputSig(1+windowLength*winID:1+windowLength*winID+windowLength/4-1) = rxSigTemp - localSigReconstruct;

% Payload
startRx = startRx + 8;
for winID = 12.25: 12.25 + length(payload) - 1
    rxSigTemp = rxSig(startRx+windowLength*winID:startRx+windowLength*winID+windowLength-1);
    localSigTemp = localSig(1+windowLength*winID:1+windowLength*winID+windowLength-1);
    rxConjMult = fft(rxSigTemp.*dcp);
    rxConjMultNorm = normalize(abs(rxConjMult),'range');
    peak = [];
    for ii = 1:length(rxConjMultNorm)
        if rxConjMultNorm(ii) > 0.3 && rxConjMultNorm(ii)>rxConjMultNorm(mod(ii+1-1,windowLength)+1) && rxConjMultNorm(ii)>rxConjMultNorm(mod(ii-1-1,windowLength)+1)
            peak = [peak ii];
        end
    end
    if length(peak) == 1

        if peak(1) < 257
            peak = [peak peak(1)+256];
        else
            peak = [peak(1)-256 peak];
        end
    end

    localConjMult = fft(localSigTemp.*dcp);
    rxPhaseDrift = (angle(rxConjMult(peak(2)))-angle(rxConjMult(peak(1))))/pi;
    rxPhaseDrift = mod(rxPhaseDrift+1,2) - 1;
    localPhaseDrift = (angle(localConjMult(peak(2)))-angle(localConjMult(peak(1))))/pi;
    localPhaseDrift = mod(localPhaseDrift+1,2) - 1;
    driftDiff = rxPhaseDrift - localPhaseDrift;
    driftDiff = mod(driftDiff+1,2) - 1;
    driftDiff = driftDiff*pi;

    edge = windowLength * (1 - payload(winID-12.25+1)/2^8);
    localSigTemp(edge:end) = localSigTemp(edge:end).*exp(1j*(driftDiff));

    localConjMult = fft(localSigTemp.*dcp);
    localConjMultNorm = normalize(abs(localConjMult),'range');
    peak_local = [];
    for ii = 1:length(localConjMultNorm)
        if localConjMultNorm(ii) > 0.3 && localConjMultNorm(ii)>localConjMultNorm(mod(ii+1-1,windowLength)+1) && localConjMultNorm(ii)>localConjMultNorm(mod(ii-1-1,windowLength)+1)
            peak_local = [peak_local ii];
        end
    end
    if length(peak) == 1
        if peak(1) < 257
            peak = [peak peak(1)+256];
        else
            peak = [peak(1)-256 peak];
        end
    end
    localSigReconstruct = localSigTemp/localConjMult(peak_local(1))*rxConjMult(peak(1));
    localRecConjMult = fft(localSigReconstruct.*dcp);
    if abs(angle(rxConjMult(peak(1))) - angle(localRecConjMult(peak_local(1)))) > 0.01
        localSigReconstruct = localSigTemp/localConjMult(peak_local(2))*rxConjMult(peak(2));
    end
    ampLeft = mean(abs(rxSigTemp - localSigReconstruct));

    localSigReconstruct2 = localSigTemp/localConjMult(peak(1))*rxConjMult(peak(1));
    localRecConjMult2 = fft(localSigReconstruct2.*dcp);
    if abs(angle(rxConjMult(peak(1))) - angle(localRecConjMult2(peak_local(1)))) > 0.01
        localSigReconstruct2 = localSigTemp/localConjMult(peak(2))*rxConjMult(peak(2));
    end
    ampRight = mean(abs(rxSigTemp - localSigReconstruct2));
    
    if ampLeft < ampRight
        outputSig(1+windowLength*winID:1+windowLength*winID+windowLength-1) = rxSigTemp - localSigReconstruct;
    else
        outputSig(1+windowLength*winID:1+windowLength*winID+windowLength-1) = rxSigTemp - localSigReconstruct2;
    end
    amp1 = min(ampLeft,ampRight);


    startRx = startRx - 1;
    rxSigTemp = rxSig(startRx+windowLength*winID:startRx+windowLength*winID+windowLength-1);
    localSigTemp = localSig(1+windowLength*winID:1+windowLength*winID+windowLength-1);
    rxConjMult = fft(rxSigTemp.*dcp);
    rxConjMultNorm = normalize(abs(rxConjMult),'range');
    peak = [];
    for ii = 1:length(rxConjMultNorm)
        if rxConjMultNorm(ii) > 0.3 && rxConjMultNorm(ii)>rxConjMultNorm(mod(ii+1-1,windowLength)+1) && rxConjMultNorm(ii)>rxConjMultNorm(mod(ii-1-1,windowLength)+1)
            peak = [peak ii];
        end
    end
    if length(peak) == 1

        if peak(1) < 257
            peak = [peak peak(1)+256];
        else
            peak = [peak(1)-256 peak];
        end
    end

    localConjMult = fft(localSigTemp.*dcp);
    rxPhaseDrift = (angle(rxConjMult(peak(2)))-angle(rxConjMult(peak(1))))/pi;
    rxPhaseDrift = mod(rxPhaseDrift+1,2) - 1;
    localPhaseDrift = (angle(localConjMult(peak(2)))-angle(localConjMult(peak(1))))/pi;
    localPhaseDrift = mod(localPhaseDrift+1,2) - 1;
    driftDiff = rxPhaseDrift - localPhaseDrift;
    driftDiff = mod(driftDiff+1,2) - 1;
    driftDiff = driftDiff*pi;

    edge = windowLength * (1 - payload(winID-12.25+1)/2^8);
    localSigTemp(edge:end) = localSigTemp(edge:end).*exp(1j*(driftDiff));

    localConjMult = fft(localSigTemp.*dcp);
    localConjMultNorm = normalize(abs(localConjMult),'range');
    peak_local = [];
    for ii = 1:length(localConjMultNorm)
        if localConjMultNorm(ii) > 0.3 && localConjMultNorm(ii)>localConjMultNorm(mod(ii+1-1,windowLength)+1) && localConjMultNorm(ii)>localConjMultNorm(mod(ii-1-1,windowLength)+1)
            peak_local = [peak_local ii];
        end
    end
    if length(peak) == 1
        if peak(1) < 257
            peak = [peak peak(1)+256];
        else
            peak = [peak(1)-256 peak];
        end
    end
    localSigReconstruct = localSigTemp/localConjMult(peak_local(1))*rxConjMult(peak(1));
    localRecConjMult = fft(localSigReconstruct.*dcp);
    if abs(angle(rxConjMult(peak(1))) - angle(localRecConjMult(peak_local(1)))) > 0.01
        localSigReconstruct = localSigTemp/localConjMult(peak_local(2))*rxConjMult(peak(2));
    end
    ampLeft = mean(abs(rxSigTemp - localSigReconstruct));

    localSigReconstruct2 = localSigTemp/localConjMult(peak(1))*rxConjMult(peak(1));
    localRecConjMult2 = fft(localSigReconstruct2.*dcp);
    if abs(angle(rxConjMult(peak(1))) - angle(localRecConjMult2(peak_local(1)))) > 0.01
        localSigReconstruct2 = localSigTemp/localConjMult(peak(2))*rxConjMult(peak(2));
    end
    ampRight = mean(abs(rxSigTemp - localSigReconstruct2));
    amp2 = min(ampLeft,ampRight);

    if amp2 < amp1*0.8
        if ampLeft < ampRight
            outputSig(1+windowLength*winID:1+windowLength*winID+windowLength-1) = rxSigTemp - localSigReconstruct;
        else
            outputSig(1+windowLength*winID:1+windowLength*winID+windowLength-1) = rxSigTemp - localSigReconstruct2;
        end
    end
    startRx = startRx + 1;

end

outputRawSig(packetStart:packetStart+length(outputSig)-1) = outputSig;

end



