function [paramsiPod] = inputPLMiPod()
% Thresholds determined by: avg noise level + 5 * standard deviation
paramsiPod = struct('PatientName', '',...
                    'LowThreshold',  0.048, 'HighThreshold',   0.08,...
                    'MinLowDuration', 0.5, 'MinHighDuration',  0.5,...
                    'MinIMIDuration',  10, 'MaxIMIDuration',    90,...,
                    'MaxLMDuration',   10, 'SamplingRate',      20,...
                    'MinNumIMI',        3, 'minSleepTime',       5,...
                    'restless_u2d1Factor', 1, 'restless_LMFactor', 0.5,...
                    'restless_IntervalSize', 15,'restfulThreshold', 0.2...
                );
                                        
prompt = {'PatientName','LowThreshold','HighThreshold',...
          'MinLowDuration','MinHighDuration','MinIMIDuration',...
          'MaxIMIDuration','MaxLMDuration',...
          'SamplingRate', 'MinNumIMI', 'minSleepTime'};
dlg_title = 'Input';
num_lines = 1;
def = {'','0.048','0.08','0.5','0.5','10','90','10','20','3','5'};
answer = inputdlg(prompt,dlg_title,num_lines,def);
paramsiPod.(prompt{1})=answer{1};

for i=2:size(prompt,2)
    paramsiPod.(prompt{i})=str2num(answer{i});
end

%% Restless Measures
prompt = {'restless_u2d1Factor', 'restless_LMFactor',...
          'restless_IntervalSize','restfulThreshold'};
dlg_title = 'Input2';
num_lines = 1;
def = {'1','0.5','15','0.2'};
answer = inputdlg(prompt,dlg_title,num_lines,def);

for i=1:size(prompt,2)
    paramsiPod.(prompt{i})=str2num(answer{i});
end

end