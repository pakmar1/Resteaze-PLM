function CLM=getCLMiPod(paramsiPod,LM)
% Based on LM matrix the CLM is extracted by criteria LM less than 10sec.
%
% Input
% paramsiPod -input structure that define criteria for scoring (The WASM criteria
%             for scoring different leg movements)
% LM - leg movement matrix. Ran by the getLMiPod. 
%
% Output
% CLM- candidate leg movement matrix. Having duration less than 10 sec. 
if isnan(LM(1,1))
   CLM=NaN;
   return;
elseif isempty(LM)
    CLM=[];
    return;
end
    CLM=LM(LM(:,3)<=paramsiPod.maxCLMDuration,:);
    if isempty(CLM)
        return;
    end
    %% Recalculate IMI in sec in 4th column
    CLM(1,4)=9999;
    if (size(CLM,1)>1)
        CLM(2:size(CLM,1),4)=(CLM(2:size(CLM,1),1)-CLM(1:size(CLM,1)-1,1))/paramsiPod.fs;
    end
end