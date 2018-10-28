function [paramsiPod] = COMBOinputPLMiPod()
% Thresholds determined by: avg noise level + 5 * standard deviation
paramsiPod = struct('rLowThreshold',0.048,'rHighThreshold',   0.08,...
                    'lLowThreshold',0.048,'lHighThreshold',   0.08,...
                    'MinLowDuration', 0.5, 'MinHighDuration',  0.5,...
                    'MinIMIDuration',  10, 'MaxIMIDuration',    90,...,
                    'MaxLMDuration',   10, 'SamplingRate',      20,...
                    'MinNumIMI',        3, 'minSleepTime',       5);
                                        
prompt = {'rLowThreshold','rHighThreshold','lLowThreshold','lHighThreshold','MinLowDuration','MinHighDuration',...
          'MinIMIDuration','MaxIMIDuration', 'MaxLMDuration',...
          'SamplingRate', 'MinNumIMI', 'minSleepTime'};
dlg_title = 'Input';
num_lines = 1;
def = {'0.048','0.08','0.048','0.08','0.5','0.5','10','90','10','20','3','5'};
answer = inputdlg(prompt,dlg_title,num_lines,def);

for i=1:12   
    paramsiPod.(prompt{i})=str2num(answer{i});
end

end