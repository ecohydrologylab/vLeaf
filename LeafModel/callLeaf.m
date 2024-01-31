%% Function to compute leaf photosynthesis
function [LeafMassFlux,LeafEnergyFlux,LeafState] = callLeaf(Constants,...
    Weather,Photosynthesis,Stomata)


    %% Initialize leaf states
    [LeafMassFlux,LeafEnergyFlux,LeafState] = ...
        callInitializeLeaf(Photosynthesis,Weather);

    %% Relaxation Method
    MinError.ci = 0.01; % [ppm]
    MinError.gs = 0.001; % [mol m-2 s-1]
    MinError.aNet = 0.005; % [u mol m-2 s-1]
    MinError.temperature = 0.01; % [Celcius]
    MinError = struct2table(MinError);
    
    Error.loop = 1;
    Error.relax = 0.85;
    Error.maxLoop = 500;
    
    StoreLeafState = array2table(nan(Error.maxLoop,width(LeafState)));
    StoreLeafState.Properties.VariableNames = LeafState.Properties.VariableNames;
    StoreLeafState(1,:) = LeafState;
    StoreLeafMassFlux = array2table(nan(Error.maxLoop,width(LeafMassFlux)));
    StoreLeafMassFlux.Properties.VariableNames = LeafMassFlux.Properties.VariableNames;
    StoreLeafMassFlux(1,:) = LeafMassFlux;
    StoreLeafEnergyFlux = array2table(nan(Error.maxLoop,width(LeafEnergyFlux)));
    StoreLeafEnergyFlux.Properties.VariableNames = LeafEnergyFlux.Properties.VariableNames;
    StoreLeafEnergyFlux(1,:) = LeafEnergyFlux;
    
    %% Initiating the error structure
    ErrorLeafState = array2table(ones(1,width(LeafState)));
    ErrorLeafState.Properties.VariableNames = LeafState.Properties.VariableNames;
    ErrorLeafMassFlux = array2table(ones(1,width(LeafMassFlux)));
    ErrorLeafMassFlux.Properties.VariableNames = LeafMassFlux.Properties.VariableNames;
    
    %% Gauss Seidal Method for leaf solution with successive relaxation
    while ((Error.loop < Error.maxLoop) && (ErrorLeafState.ci >= MinError.ci || ...
            ErrorLeafState.gs >= MinError.gs || ErrorLeafMassFlux.aNet >= MinError.aNet...
            || ErrorLeafState.temperature >= MinError.temperature))
        
        % Compute photosynthesis
        [LeafMassFlux,LeafState] = callC4Photosynthesis(Constants,Photosynthesis,Weather,LeafState,LeafMassFlux);
        LeafMassFlux.aNet = LeafMassFlux.aNet - Error.relax*(LeafMassFlux.aNet - StoreLeafMassFlux(Error.loop,:).aNet); % Apply relaxation to prevent oscillation
        LeafState.cbs = LeafState.cbs - Error.relax*(LeafState.cbs - StoreLeafState(Error.loop,:).cbs); % Apply relaxation to prevent oscillation
        LeafState.obs = LeafState.obs - Error.relax*(LeafState.obs - StoreLeafState(Error.loop,:).obs); % Apply relaxation to prevent oscillation
        
        % Compute Boundary Layer Conductance
        [LeafState] = callBoundaryLayerConductance(Constants,Weather,LeafState,LeafMassFlux);
        LeafState.cb = LeafState.cb - Error.relax*(LeafState.cb - StoreLeafState(Error.loop,:).cb); % Apply relaxation to prevent oscillation
        
        % Compute stomatal conductance
        [LeafState] = callStomatalConductance(Stomata,Photosynthesis,LeafState,LeafMassFlux);
        LeafState.ci = LeafState.ci - Error.relax*(LeafState.ci - StoreLeafState(Error.loop,:).ci); % Apply relaxation to prevent oscillation
        LeafState.gs = LeafState.gs - Error.relax*(LeafState.gs - StoreLeafState(Error.loop,:).gs); % Apply relaxation to prevent oscillation
        
        % Compute leaf energy balance
        [LeafState,LeafMassFlux,LeafEnergyFlux,Weather] = callEnergyBalance(Constants,Photosynthesis,LeafMassFlux,LeafState,Weather,LeafEnergyFlux);        
        LeafState.temperature = LeafState.temperature - Error.relax*(LeafState.temperature - StoreLeafState(Error.loop,:).temperature); % Apply relaxation to prevent oscillation

        
        % Update loop variables
        Error.loop = Error.loop + 1;
        StoreLeafState(Error.loop,:) = LeafState;
        StoreLeafMassFlux(Error.loop,:) = LeafMassFlux;
        StoreLeafEnergyFlux(Error.loop,:) = LeafEnergyFlux;
        
        % Compute error in percentage
        ErrorLeafState{1,:} = abs(StoreLeafState{Error.loop,:}-StoreLeafState{Error.loop-1,:});
        ErrorLeafMassFlux{1,:} = abs(StoreLeafMassFlux{Error.loop,:}-StoreLeafMassFlux{Error.loop-1,:});
        
    end
    if Error.loop>= Error.maxLoop
        LeafState.flag = 1;
    end
    
end
