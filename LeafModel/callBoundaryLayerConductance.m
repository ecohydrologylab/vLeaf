function [LeafState] = callBoundaryLayerConductance(Constants,Weather,LeafState,LeafMassFlux)

leafDimension = 0.06; % Leaf width/needle diameter [m]
temperatureKelvin = Weather.temperature + 273.15; % Air temperature [Kelvin]
convert = Constants.Pressure/(8.309*temperatureKelvin); % Convertion of boundary layer conductance from [m s-1] to [moles m-2 s-1] Nikolov et al 1995 (Page 212)
leafTemperatureKelvin = LeafState.temperature + 273.15; % Leaf temperature [Kelvin]

callEs = @(temperature) (0.611*exp(17.502*temperature/(240.97+temperature)))*1000; % Saturation Vapour Pressure [Pa]
callEa = @(temperature) (Weather.RH*callEs(temperature)); % Atmospheric Vapour Pressure [Pa]
Weather.ea = callEa(Weather.temperature); % Atmospheric vapour pressure [Pa]

%% Forced convection conductance
LeafState.gbforced = Constants.cforced*temperatureKelvin^0.56*((temperatureKelvin + 120.0)...
    * (Weather.wind / leafDimension / Constants.Pressure))^0.5; % Nikolov et al 1995 Boundary layer forced conductance [m s-1] 

%% Free convection conductance
TDifference = (leafTemperatureKelvin / (1.0 - 0.378 * LeafState.eb / Constants.Pressure)) -...
    (temperatureKelvin / (1.0 - 0.378 * Weather.ea / Constants.Pressure)); % Virtual temperature difference [Kelvin] Nikolov et al 1995 (Page 211)
LeafState.gbfree = Constants.cfree*leafTemperatureKelvin^0.56*((leafTemperatureKelvin + 120.0)...
    / Constants.Pressure)^0.5*(abs(TDifference) / leafDimension)^0.25; % Nikolov et al 1995 Boundary layer free conductance [m s-1]

%% Maximum of two conductances
LeafState.gb = max(LeafState.gbfree, LeafState.gbforced); % Boundary layer conductance for vapour [m s-1]

%% Compute leaf boundary layer conductance for vapour
LeafState.gb = LeafState.gb * convert; % Boundary layer conductance for vapour [mol m-2 s-1]
LeafState.Mbv = 0.5*(LeafState.s + 1)^2/(LeafState.s^2 + 1); 
LeafState.g = LeafState.gs*LeafState.Mbv*LeafState.gb/(LeafState.gs + LeafState.Mbv*LeafState.gb); % Total leaf vapour conductance [mol m-2 sec-1]
LeafState.ei = callEs(LeafState.temperature);

LeafState.eb = (LeafState.gs / convert * LeafState.ei + LeafState.gb  / convert * Weather.ea)...
    / (LeafState.gs / convert + LeafState.gb / convert); % Vapour Pressure at leaf for boundary layer conductance [Pa]

LeafState.cb = Weather.ca - 1.37 * LeafMassFlux.aNet / (LeafState.Mbv*LeafState.gb); % Leaf boundary layer concentration of CO2 [ppm]

end