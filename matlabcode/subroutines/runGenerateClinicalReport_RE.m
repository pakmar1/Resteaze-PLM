
% load input.mat
% addpath ../export_fig
input.numIntervals = floor(input(1).TRT/input(1).intervalSize); % Minutes

for i=1:7
   nightData(i)=input; 
end
nightData2=nightData;
nightData(8)=nightData(7);
nightData(8).TST=mean([nightData2.TST]);
nightData(8).sleepStart=mean([nightData2.sleepStart]);
nightData(8).sleepEnd=mean([nightData2.sleepEnd]);
nightData(8).PLMShr=mean([nightData2.PLMShr]);
nightData(8).sleepEff=mean([nightData2.sleepEff]);
nightData(8).WASOdur=mean([nightData2.WASOdur]);
nightData(8).TRT=mean([nightData2.TRT]);
tic
 generateClinicalReport_RE(nightData)
toc
%% save as a pdf
% export_fig 'graphs.pdf' -transparent;
% figure_list{1,1} = 'graphs.pdf';
% 
% %% Combine all figures in list into one pdf
% append_pdfs(['Data Report.pdf'], figure_list{1,:});
