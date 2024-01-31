%% Function to compute leaf temperature using energy balance approach
function [LeafState,LeafMassFlux,LeafEnergyFlux,Weather] = ...
    callEnergyBalance(Constants,Photosynthesis,LeafMassFlux,LeafState,Weather,LeafEnergyFlux)

callEs = @(temperature) (0.611*exp(17.502*temperature/(240.97+temperature)))*1000; % Saturation Vapour Pressure [Pa]
callEa = @(temperature) (Weather.RH*callEs(temperature)); % Atmospheric Vapour Pressure [Pa]
Weather.ea = callEa(Weather.temperature); % Atmospheric vapour pressure [Pa]

callSensibleHeat = @(temperature) (Constants.Hfactor*Constants.Cp*0.924* ...
    LeafState.gb*(temperature-Weather.temperature)); % Sensible heat flux [W m-2]
callLatentHeat = @(temperature) (Constants.LEfactor*Constants.LatentHeatVapourization* ...
        LeafState.g/(Constants.Pressure)*(callEs(temperature)-Weather.ea)); % Latent heat flux [W m-2]
callEmission = @(temperature) (Constants.LWfactor*Constants.Leafepsilon*Constants.Boltzman* ...
    (273.15+temperature)^4.0); % Long wave radiation flux emitted [W m-2]

if Photosynthesis.leafPosition == 1
    long = @(temperature) Weather.long + Constants.Leafepsilon*(Constants.Leafepsilon*Constants.Boltzman*(273.15+temperature)^4.0);
else
    long = @(temperature) Constants.Leafepsilon*(Constants.LWfactor*Constants.Leafepsilon*Constants.Boltzman*(273.15+temperature)^4.0);
end

callEnergyBalanceResidual = @(temperature) (Weather.PAR + Weather.NIR + long(temperature)...
    - LeafEnergyFlux.me-callSensibleHeat(temperature)-callLatentHeat(temperature)- ...
    callEmission(temperature))^2; % Compute energy balance residual [W m-2

LeafEnergyFlux.me = 0.506 * LeafMassFlux.aNet; % Energy of photosynthesis [W m-2]

if Photosynthesis.energyOption == 1
    [temperature,SSE,optimizationFlag] = fminbnd(callEnergyBalanceResidual,2,60); % Compute leaf temperature [Celsius]
else
    temperature = Weather.controlTemp; % Turn off leaf energy balance
end

%% Update values
LeafState.temperature = temperature; % [Celsius]
LeafEnergyFlux.radiation = Weather.PAR + Weather.NIR + long(temperature); % Net radiation flux [W m-2]
LeafEnergyFlux.sensibleHeat = callSensibleHeat(temperature); % Sensible heat flux [W m-2]
LeafEnergyFlux.latentHeat = callLatentHeat(temperature); % Latent heat flux [W m-2]
LeafEnergyFlux.emission = callEmission(temperature); % Long wave radiation flux emitted [W m-2]
LeafEnergyFlux.residual = (callEnergyBalanceResidual(temperature))^0.5; % Net radiation flux [W m-2]
LeafMassFlux.transpiration = LeafEnergyFlux.latentHeat/Constants.LatentHeatVapourization*1E6; % Leaf transpiration [u moles m-2 s-1]

end
