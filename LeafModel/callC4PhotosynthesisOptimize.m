function [SSE] = callC4PhotosynthesisOptimize(optimizeVector,LeafMassFlux,LeafState,Photosynthesis,Weather)

LeafMassFlux.vc   = optimizeVector(1); % PEP carboxylation rate at leaf temperature [u moles m-2 s-1]
LeafState.cbs = optimizeVector(2); % CO2 conc. at bundle sheath [u moles mole-1]
LeafState.obs = optimizeVector(3); % Oxygen conc. at bundle sheath [u moles mole-1]
LeafMassFlux.aNet = optimizeVector(4); % Net rate of CO2 uptake [u moles m-2 s-1]

%% vc limited rate
LeafMassFlux.vcCO2 = LeafState.cbs * LeafMassFlux.vcmax / (LeafState.cbs +...
    LeafState.Kc * (1.0 + LeafState.obs / LeafState.Ko)); % CO2 limited RUBISCO carboxylation rate (vonCaemmerer 2000)% Oxygen conc. at bundle sheath [u moles m-2 s-1]
LeafMassFlux.vcLight = (1.0 - Photosynthesis.x) * LeafState.cbs * LeafMassFlux.J...
    /(3.0 * LeafState.cbs + 7.0 * LeafState.gammaStar * LeafState.obs); % Light limited RUBISCO carboxylation rate (vonCaemmerer 2000)[u moles m-2 s-1]
LeafMassFlux.vc = min(LeafMassFlux.vcLight, LeafMassFlux.vcCO2); % PEP carboxylation rate at leaf temperature [u moles m-2 s-1]

%% Compute cbs
LeafState.cbs = max(LeafState.ci,LeafState.ci + (LeafMassFlux.vp - LeafMassFlux.aNet - LeafMassFlux.rm)...   
    / Photosynthesis.gbs); % CO2 conc. at bundle sheath [u moles mole-1]
% LeafState.cbs = max(0,LeafState.cbs);
if LeafState.cbs <= 100
    dummy = 1;
end
%% Compute obs
LeafState.obs = Photosynthesis.alpha * LeafMassFlux.aNet /... 
(0.047 * Photosynthesis.gbs) + Weather.O2; % O2 conc. at bundle sheath [u moles mole-1]
% LeafState.obs = max(0,LeafState.obs);

%% Photosynthesis
LeafMassFlux.aNet = (1.0 - LeafState.gammaStar * LeafState.obs / LeafState.cbs)*...
    LeafMassFlux.vc - LeafMassFlux.rd; % Net rate of CO2 uptake (vonCaemmerer 2000) [u moles m-2 s-1]
LeafMassFlux.aNet = min(LeafMassFlux.vp,LeafMassFlux.aNet);

%% Sum of squares error
SSE = (LeafMassFlux.vc-optimizeVector(1))^2.0+ ...
      (LeafState.cbs-optimizeVector(2))^2.0+ ...
      (LeafState.obs-optimizeVector(3))^2.0+ ...
      (LeafMassFlux.aNet-optimizeVector(4))^2.0;
end