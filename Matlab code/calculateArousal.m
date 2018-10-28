function [Arousal]=calculateArousal(bCLM,leftBandData,rightBandData)
percentVal = .45;
Arousal=bCLM(:,[1,2]);

if ~isempty(leftBandData)
    %leftrmsAcc=rms(removeAccGrav(leftBandData(:,8:10)),2);
    leftrmsAcc=rms(leftBandData(:,8:10),2);
    leftrmsGyr=rms(leftBandData(:,11:13),2);
end

if ~isempty(rightBandData)
    %rightrmsAcc=rms(removeAccGrav(rightBandData(:,8:10)),2);
    rightrmsAcc=rms(rightBandData(:,8:10),2);
    rightrmsGyr=rms(rightBandData(:,11:13),2);
end

DurationArr=bCLM(:,3);
CLM_OR_PLM=bCLM(:,5);
for i=1:size(bCLM,1)
    if bCLM(i,13)==2
        AUCArr(i)=sum(leftrmsAcc(bCLM(i,1):bCLM(i,2),1));
        MAXActivityArr(i)=max(leftrmsAcc(bCLM(i,1):bCLM(i,2),1));
        GYRORMS_AUCArr(i)=sum(leftrmsGyr(bCLM(i,1):bCLM(i,2),1));
        GYRORMS_MAXActivityArr(i)=max(leftrmsGyr(bCLM(i,1):bCLM(i,2),1));
        GYROX_AUCArr(i)=sum(leftBandData(bCLM(i,1):bCLM(i,2),11));
        GYROX_MAXActivityArr(i)=max(leftBandData(bCLM(i,1):bCLM(i,2),11));
        GYROY_AUCArr(i)=sum(leftBandData(bCLM(i,1):bCLM(i,2),12));
        GYROY_MAXActivityArr(i)=max(leftBandData(bCLM(i,1):bCLM(i,2),12));
        GYROZ_AUCArr(i)=sum(leftBandData(bCLM(i,1):bCLM(i,2),13));
        GYROZ_MAXActivityArr(i)=max(leftBandData(bCLM(i,1):bCLM(i,2),13));
        ACC_STD_Arr(i)=std(leftrmsAcc(bCLM(i,1):bCLM(i,2),1));
        GYRO_STD_Arr(i)=std(leftrmsGyr(bCLM(i,1):bCLM(i,2),1));
        CAP1_STD_Arr(i)=std(leftBandData(bCLM(i,1):bCLM(i,2),5));
        CAP2_STD_Arr(i)=std(leftBandData(bCLM(i,1):bCLM(i,2),6));
        CAP3_STD_Arr(i)=std(leftBandData(bCLM(i,1):bCLM(i,2),7));
    elseif bCLM(i,13)==1
        AUCArr(i)=sum(rightrmsAcc(bCLM(i,1):bCLM(i,2),1));
        MAXActivityArr(i)=max(rightrmsAcc(bCLM(i,1):bCLM(i,2),1));
        GYRORMS_AUCArr(i)=sum(rightrmsGyr(bCLM(i,1):bCLM(i,2),1));
        GYRORMS_MAXActivityArr(i)=max(rightrmsGyr(bCLM(i,1):bCLM(i,2),1));
        GYROX_AUCArr(i)=sum(rightBandData(bCLM(i,1):bCLM(i,2),11));
        GYROX_MAXActivityArr(i)=max(rightBandData(bCLM(i,1):bCLM(i,2),11));
        GYROY_AUCArr(i)=sum(rightBandData(bCLM(i,1):bCLM(i,2),12));
        GYROY_MAXActivityArr(i)=max(rightBandData(bCLM(i,1):bCLM(i,2),12));
        GYROZ_AUCArr(i)=sum(rightBandData(bCLM(i,1):bCLM(i,2),13));
        GYROZ_MAXActivityArr(i)=max(rightBandData(bCLM(i,1):bCLM(i,2),13));
        ACC_STD_Arr(i)=std(rightrmsAcc(bCLM(i,1):bCLM(i,2),1));
        GYRO_STD_Arr(i)=std(rightrmsGyr(bCLM(i,1):bCLM(i,2),1));
        CAP1_STD_Arr(i)=std(rightBandData(bCLM(i,1):bCLM(i,2),5));
        CAP2_STD_Arr(i)=std(rightBandData(bCLM(i,1):bCLM(i,2),6));
        CAP3_STD_Arr(i)=std(rightBandData(bCLM(i,1):bCLM(i,2),7));
    else
        AUCArr(i)=mean([sum(rightrmsAcc(bCLM(i,1):bCLM(i,2),1)),sum(leftrmsAcc(bCLM(i,1):bCLM(i,2),1))]);
        MAXActivityArr(i)=mean([max(rightrmsAcc(bCLM(i,1):bCLM(i,2),1)),max(leftrmsAcc(bCLM(i,1):bCLM(i,2),1))]);
        GYRORMS_AUCArr(i)=mean([sum(rightrmsGyr(bCLM(i,1):bCLM(i,2),1)),sum(leftrmsGyr(bCLM(i,1):bCLM(i,2),1))]);
        GYRORMS_MAXActivityArr(i)=mean([max(rightrmsGyr(bCLM(i,1):bCLM(i,2),1)),max(leftrmsGyr(bCLM(i,1):bCLM(i,2),1))]);
        GYROX_AUCArr(i)=mean([sum(rightBandData(bCLM(i,1):bCLM(i,2),11)),sum(leftBandData(bCLM(i,1):bCLM(i,2),11))]);
        GYROX_MAXActivityArr(i)=mean([max(rightBandData(bCLM(i,1):bCLM(i,2),11)),max(leftBandData(bCLM(i,1):bCLM(i,2),11))]);
        GYROY_AUCArr(i)=mean([sum(rightBandData(bCLM(i,1):bCLM(i,2),12)),sum(leftBandData(bCLM(i,1):bCLM(i,2),12))]);
        GYROY_MAXActivityArr(i)=mean([max(rightBandData(bCLM(i,1):bCLM(i,2),12)),max(leftBandData(bCLM(i,1):bCLM(i,2),12))]);
        GYROZ_AUCArr(i)=mean([sum(rightBandData(bCLM(i,1):bCLM(i,2),13)),sum(leftBandData(bCLM(i,1):bCLM(i,2),13))]);
        GYROZ_MAXActivityArr(i)=mean([max(rightBandData(bCLM(i,1):bCLM(i,2),13)),max(leftBandData(bCLM(i,1):bCLM(i,2),13))]);
        ACC_STD_Arr(i)=mean([std(rightrmsAcc(bCLM(i,1):bCLM(i,2),1)),std(leftrmsAcc(bCLM(i,1):bCLM(i,2),1))]);
        GYRO_STD_Arr(i)=mean([std(rightrmsGyr(bCLM(i,1):bCLM(i,2),1)),std(leftrmsGyr(bCLM(i,1):bCLM(i,2),1))]);
        CAP1_STD_Arr(i)=mean([std(rightBandData(bCLM(i,1):bCLM(i,2),5)),std(leftBandData(bCLM(i,1):bCLM(i,2),5))]);
        CAP2_STD_Arr(i)=mean([std(rightBandData(bCLM(i,1):bCLM(i,2),6)),std(leftBandData(bCLM(i,1):bCLM(i,2),6))]);
        CAP3_STD_Arr(i)=mean([std(rightBandData(bCLM(i,1):bCLM(i,2),7)),std(leftBandData(bCLM(i,1):bCLM(i,2),7))]);
    end

val = LRplot(DurationArr(i),AUCArr(i),MAXActivityArr(i),GYRORMS_AUCArr(i),GYRORMS_MAXActivityArr(i),GYROX_AUCArr(i),GYROX_MAXActivityArr(i),GYROY_AUCArr(i),GYROY_MAXActivityArr(i),GYROZ_AUCArr(i),GYROZ_MAXActivityArr(i),ACC_STD_Arr(i),GYRO_STD_Arr(i),CAP1_STD_Arr(i),CAP2_STD_Arr(i),CAP3_STD_Arr(i),CLM_OR_PLM(i));
Arousal(i,3)=val>percentVal;
end

end