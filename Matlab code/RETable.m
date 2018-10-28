function [Table_Handles]=RETable(input)
shiftX_RETable=input.shiftX_RETable;
shiftY_RETable=input.shiftY_RETable;
numIntervals = floor(input.TRT/input.intervalSize); % Minutes
k=.05: .14:1;
Table_Handles(1)=text(k(1)*2*numIntervals/3+shiftX_RETable,0+shiftY_RETable,[num2str(round(input.sleepEff*100,0)) '%']);
Table_Handles(2)=text(k(2)*2*numIntervals/3+shiftX_RETable,0+shiftY_RETable,[num2str(round(input.TST/60,2))]);
Table_Handles(3)=text(k(3)*2*numIntervals/3+shiftX_RETable,0+shiftY_RETable,num2str(round(input.WASOdur/60,2)));
Table_Handles(4)=text(k(4)*2*numIntervals/3+shiftX_RETable,0+shiftY_RETable,num2str(round(input.PLMSI,2)));
Table_Handles(5)=text(k(5)*2*numIntervals/3+shiftX_RETable,0+shiftY_RETable,num2str(round(input.ArI,2)));
Table_Handles(6)=text(k(6)*2*numIntervals/3+shiftX_RETable,0+shiftY_RETable,num2str(round(input.PLMSArI,2))); %%UPDATE
Table_Handles(7)=text(k(7)*2*numIntervals/3+shiftX_RETable,0+shiftY_RETable,[num2str(round(input.SQ*100)) '%']);

end