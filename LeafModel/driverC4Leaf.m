clear variables
close all
clc
tic

%% Load input data
fileName = "Upper_SecondaryEffect_EngBal";
filePath = strcat("../Input/",fileName,".xlsx");
[Photosynthesis,Stomata,Weather,Constants] = callInputData(filePath);

parfor leafLoop = 1:height(Photosynthesis)    
    % Compute leaf solution
    [LeafMassFlux(leafLoop,:),LeafEnergyFlux(leafLoop,:),LeafState(leafLoop,:)] ...
        = callLeaf(Constants,Weather(leafLoop,:),Photosynthesis(leafLoop,:), ...
        Stomata(leafLoop,:));
end

OutputData = [LeafState,LeafEnergyFlux,LeafMassFlux];

%% Print Output data      
outputfileName = strcat("../Output2/",fileName,"_Output.xlsx");
writetable(OutputData,outputfileName)



