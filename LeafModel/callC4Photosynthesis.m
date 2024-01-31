function [LeafMassFlux,LeafState] = callC4Photosynthesis(Constants,Photosynthesis,Weather,LeafState,LeafMassFlux)

leafTemperatureKelvin = LeafState.temperature + 273.15; % [Kelvin] 

%% Temperature effect on Michaelis-Menton constants
LeafState.Ko = 450.0 * 1.2^((LeafState.temperature - 25.0) / 10.0); %(Chen 1994) / Ko{@25} = 450.0; /(vonCaemmerer 2000) Michaelis constant of Rubisco for O2 [m bar]
LeafState.Kc = 650.0 * 2.1^((LeafState.temperature - 25.0) / 10.0); %(Chen 1994) / Kc{@25} = 650.0; /(vonCaemmerer 2000) Michaelis constant of Rubisco for CO2 [u bar]
LeafState.Kp = 80.0 * 2.1^((LeafState.temperature - 25.0) / 10.0); %(Chen 1994) / Kp{@25} = 80.0; /(vonCaemmerer 2000) Michaelis constant of PEP carboxylase for CO2 [u bar]

%% Temperature effect on photosynthetic parameters
LeafMassFlux.jmax = Photosynthesis.jmax25 * exp(77900.0 * (leafTemperatureKelvin - 298.15) / (298.15 * Constants.R * 1000.0* leafTemperatureKelvin))...
    *(1.0 + exp((298.15 * 627.0 - 191929.0) / (298.15 * Constants.R * 1000.0)))...
    /(1.0 + exp((leafTemperatureKelvin * 627.0 - 191929.0) / (leafTemperatureKelvin * Constants.R * 1000.0))); % Max electon transport rate (Massad 2007) [u moles m-2 s-1]
LeafMassFlux.vcmax = Photosynthesis.vcmax25 * exp(67294.0 * (leafTemperatureKelvin - 298.15) / (298.15 * Constants.R * 1000.0 * leafTemperatureKelvin))...
    *(1.0 + exp((298.15 * 472.0 - 144568.0) / (298.15 * Constants.R * 1000.0)))...
    /(1.0 + exp((leafTemperatureKelvin * 472.0 - 144568.0) / (leafTemperatureKelvin * Constants.R * 1000.0))); % Max RuBP saturated carboxylation at given temperature (Massad 2007) [u moles m-2 s-1]
LeafMassFlux.vpmax = Photosynthesis.vpmax25 * exp(70373.0 * (leafTemperatureKelvin - 298.15) / (298.15 * Constants.R * 1000.0 * leafTemperatureKelvin))...
    *(1.0 + exp((298.15 * 376.0 - 117910.0) / (298.15 * Constants.R * 1000.0)))...
    /(1.0 + exp((leafTemperatureKelvin * 376.0 - 117910.0) / (leafTemperatureKelvin * Constants.R * 1000.0))); % Max PEP carboxylation rate at a given leaf temperature (Massad 2007) [u moles m-2 s-1]
LeafState.sco = Photosynthesis.sco25 * exp(-55900.0 * (leafTemperatureKelvin - 298.15) / (298.15 * Constants.R * 1000.0 * leafTemperatureKelvin)); 
LeafState.gammaStar = 1/2/LeafState.sco; % Half of reciprocal of Rubisco specificity (von Cammerer 2000) considered constant [-]

%% Respiration
LeafMassFlux.rd = Photosynthesis.rd25*LeafMassFlux.vcmax; % Dark respiration at leaf (vonCaemmerer 2000) [u moles m-2 s-1]
LeafMassFlux.rm = 0.5*LeafMassFlux.rd; % Mysophyll dark respiration rate (vonCaemmerer 2000) [u moles m-2 s-1]

%% Temperature response for PhiPS2
PhiPS2 = 0.352 + 0.022 * LeafState.temperature - 3.4 * (LeafState.temperature)^2.0 / 10000.0; % Photochemical efficiency of photosythesis (Bernacchi 2003) [-]
ThetaPS2 = Photosynthesis.theta; % Curvature parameter of leaf [-]

%% Electron transport rate
I = Constants.convert * Weather.PAR * PhiPS2 * 0.5; % Photosynthesis photon flux density (vonCaemmerer 2000) [u moles m-2 s-1]
LeafMassFlux.J = (I + LeafMassFlux.jmax - ((I + LeafMassFlux.jmax)^(2.0) - 4.0 * ThetaPS2 * I * LeafMassFlux.jmax)^(0.5))/(2 * ThetaPS2); % Whole chain electron transport rate (vonCaemmerer 2000) [u moles m-2 s-1]
 
%% vp limited rate
LeafMassFlux.vpCO2 = LeafState.ci * LeafMassFlux.vpmax / (LeafState.ci + LeafState.Kp); % CO2 limited PEP carboxylase regeneration (vonCaemmerer 2000) [u moles m-2 s-1]
LeafMassFlux.vpCO2 = min(LeafMassFlux.vpCO2, Photosynthesis.vpr); % (vonCaemmerer 2000)
LeafMassFlux.vpLight = Photosynthesis.x / 2.0 * LeafMassFlux.J; % Light limited PEP regeneration (vonCaemmerer 2000) [u moles m-2 s-1]
LeafMassFlux.vp = min(LeafMassFlux.vpLight, LeafMassFlux.vpCO2); % RUBISCO carboxylation rate at leaf temperature (vonCaemmerer 2000) [u moles m-2 s-1]

%% Optimize vc, cbs, obs, and aNet
LeafMassFlux.vc = LeafMassFlux.vp; % PEP carboxylation rate at leaf temperature [u moles m-2 s-1]
LeafState.cbs = LeafState.ci*1.5 ;%+ (LeafMassFlux.vp - LeafMassFlux.aNet)/Photosynthesis.gbs; % CO2 conc. at bundle sheath [u moles mole-1]
LeafState.obs = Weather.O2; % Oxygen conc. at bundle sheath [u moles mole-1]
LeafMassFlux.aNet = min(LeafMassFlux.vp-LeafMassFlux.rm,LeafMassFlux.vc-LeafMassFlux.rd); % Net rate of CO2 uptake per unit area [u moles m-2 s-1]

optimizeVector(1) = LeafMassFlux.vc; % PEP carboxylation rate at leaf temperature [u moles m-2 s-1]
optimizeVector(2) = LeafState.cbs; % CO2 concentration in bundle sheath [u moles mole-1]
optimizeVector(3) = LeafState.obs; % O2 concentration in bundle sheath [u moles mole-1]
optimizeVector(4) = LeafMassFlux.aNet; % Net rate of CO2 uptake per unit leaf area [u moles m-2 s-1] 

LeafMassFluxStructure = table2struct(LeafMassFlux); % Converting from table to structure to speed computations
LeafStateStructure = table2struct(LeafState); % Converting from table to structure to speed computations
PhotosynthesisStructure = table2struct(Photosynthesis); % Converting from table to structure to speed computations
callInlineOptimizeC4 = @(optimizeVector) callC4PhotosynthesisOptimize ...
    (optimizeVector,LeafMassFluxStructure,LeafStateStructure,PhotosynthesisStructure,Weather);
[optimizeVector,SSE,optimizationFlag] = fminsearch(callInlineOptimizeC4,optimizeVector);

LeafMassFlux.vc = optimizeVector(1); % PEP carboxylation rate at leaf temperature [u moles m-2 s-1]
LeafState.cbs = optimizeVector(2); % CO2 concentration in bundle sheath [u moles mole-1]
LeafState.obs = optimizeVector(3); % O2 concentration in bundle sheath [u moles mole-1]
LeafMassFlux.aNet = optimizeVector(4); % Net rate of CO2 uptake per unit leaf area [u moles m-2 s-1]

if optimizationFlag ~= 1
    % Perturbation to prevent convergence of leaf solution due to failure of fminsearch
    % LeafMassFlux.aNet = LeafMassFlux.aNet+rand(1);
    disp(strcat('Photosynthesis not converged. Leaf ID = ',num2str(Photosynthesis.leafID)))
end

if LeafState.cbs <= 100
    dummy = 1;
end

%% vc limited rate
LeafMassFlux.vcCO2 = LeafState.cbs * LeafMassFlux.vcmax / (LeafState.cbs + LeafState.Kc * (1.0 + LeafState.obs / LeafState.Ko));% CO2 limited carboxylation (vonCaemmerer 2000) [u moles m-2 s-1]
LeafMassFlux.vcLight = (1.0 - Photosynthesis.x) * LeafState.cbs * LeafMassFlux.J...
    /(3.0 * LeafState.cbs + 7.0 * LeafState.gammaStar * LeafState.obs); % Light limited carboxylation (vonCaemmerer 2000) [u moles m-2 s-1]
LeafMassFlux.vc = min(LeafMassFlux.vcLight, LeafMassFlux.vcCO2); % PEP carobylation rate at leaf temperature [u moles m-2 s-1]

%% Compute ac, ap and aj
LeafMassFlux.ac = (1.0-LeafState.gammaStar*LeafState.obs/LeafState.cbs) * min(LeafMassFlux.vcCO2,LeafMassFlux.vcLight); % RUBISCO limited gross rate of CO2 uptake per unit area [u moles m-2 s-1]
LeafMassFlux.ap = (1.0-LeafState.gammaStar*LeafState.obs/LeafState.cbs) * min(LeafMassFlux.vpCO2,LeafMassFlux.vpLight); % TPU limited gross rate of CO2 uptake per unit area [u moles m-2 s-1]
LeafMassFlux.aj = (1.0-LeafState.gammaStar*LeafState.obs/LeafState.cbs) * min(LeafMassFlux.vcLight,LeafMassFlux.vpLight); % RuBP -limited gross rate of CO2 uptake per unit area [u moles m-2 s-1]
LeafMassFlux.aGross = LeafMassFlux.aNet + LeafMassFlux.rd; % Gross rate of CO2 uptake per unit area [u moles m-2 s-1]

%% CO2 compensation point with dark respiration
LeafState.GammaStar = LeafState.gammaStar*LeafState.obs;
LeafState.Gamma_C_CO2 = (LeafState.GammaStar + LeafState.Kc*(1+LeafState.obs/LeafState.Ko)*LeafMassFlux.rd/LeafMassFlux.vcmax)/...
    (1-LeafMassFlux.rd/LeafMassFlux.vcmax); % Gamma for enzyme limited
LeafState.Gamma_C = LeafState.Gamma_C_CO2;
if LeafState.Gamma_C < 0
    LeafState.Gamma_C = 0;
end
GammaQuadratic = [(Photosynthesis.gbs) (Photosynthesis.gbs*(LeafState.Kp-LeafState.Gamma_C)+LeafMassFlux.vpmax-LeafMassFlux.rm)...
    -(LeafState.Gamma_C*LeafState.Kp*Photosynthesis.gbs+LeafMassFlux.rm*LeafState.Kp)];
Root = roots(GammaQuadratic);
LeafState.Gamma = max(Root);
if LeafState.Gamma < 0
    LeafState.Gamma = 0;
end

end


