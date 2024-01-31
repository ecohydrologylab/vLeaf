function [LeafMassFlux,LeafEnergyFlux,LeafState] =  callInitializeLeaf(Photosynthesis,Weather)

LeafState = table();
LeafState.flag = 0; % Flag for convergence of leaf solution [-] 0 = converged, 1 = not converged
LeafState.compensationFlag = 0; % When light and CO_2 both are low the code will not work
LeafState.leafID = Photosynthesis.leafID; % Tag for leaf ID
LeafState.temperature = Weather.temperature; % Temperature of leaf [C]
LeafState.Gamma = 0; % Compensation Point  considering dark respiration point for whole leaf [ppm] 
LeafState.eb = 0.611*exp(17.502*Weather.temperature/(240.97+Weather.temperature))*1000;%(0.611*exp(17.502*Weather.temperature/(240.97+Weather.temperature)))*1000; % Vapour pressure at leaf boundary [Pa]
LeafState.ei = 0.611*exp(17.502*Weather.temperature/(240.97+Weather.temperature))*1000;%(0.611*exp(17.502*Weather.temperature/(240.97+Weather.temperature)))*1000; % Saturation Vapour Pressure inside the leaf [Pa]
LeafState.cb = 0;%Weather.ca; % Leaf boundary layer concentration of CO2 [ppm]
LeafState.ci = 0.7*Weather.ca; % Intercellular concentration of CO2 in air corrected for solubility relative to 25 degree Celcius [ppm]
LeafState.Mbv = 1;
LeafState.s = 0.71;
LeafState.cbs = 0;%Weather.ca; % CO2 conc. at bundle sheath [u moles mole-1]
LeafState.g = 0.4; % Total leaf stomatal Conductance [mol m-2 s-1]
LeafState.gs = 0.1; % Stomatal conductance for vapour [mol m-2 s-1]
LeafState.gb = 5; % Boundary layer conductance for vapour [mol m-2 s-1]
LeafState.gbforced = 1; % Forced boundary layer conductance [m s-1]
LeafState.gbfree = 1; % Free boundary layer conductance [m s-1]
LeafState.gammaStar = 0.000193; %  Half of inverse of rubisco specifiity [-] 
LeafState.GammaStar = 0.143; % Compensation Point without dark respiration [ppm] 
LeafState.Gamma_C = 50; % Compensation Point considering dark respiration point at chloroplast site [ppm] 
LeafState.Gamma_C_CO2 = 50; % Compensation Point considering dark respiration point at chloroplast site [ppm] 
LeafState.Ko = 450.0; % (Chen 1994) / Ko{@25} = 450.0; /(vonCaemmerer 2000) Michaelis constant of Rubisco for O2 [u bar]
LeafState.Kp = 650.0; % (Chen 1994) / Kc{@25} = 650.0; /(vonCaemmerer 2000) Michaelis constant of Rubisco for CO2 [u bar]
LeafState.Kc = 80.0; % (Chen 1994) / Kp{@25} = 80.0; /(vonCaemmerer 2000) Michaelis constant of PEP carboxylase for CO2 [u bar]
LeafState.obs = 210; % Oxygen concenctration at bundle sheath [u moles mole-1]
LeafState.sco = Photosynthesis.sco25;

LeafMassFlux = table();
LeafMassFlux.vpCO2 = 2;%1; % CO2 limited PEP carboxylase regeneration (vonCaemmerer 2000) [u moles m-2 s-1]
LeafMassFlux.vpLight = 2;%1; % Light limited PEP regeneration (vonCaemmerer 2000) [u moles m-2 s-1]
LeafMassFlux.vcCO2 = 2;%1; % CO2 limited RUBISCO carboxylation rate (vonCaemmerer 2000)% Oxygen conc. at bundle sheath [u moles m-2 s-1]
LeafMassFlux.vcLight = 2;%1; % Light limited RUBISCO carboxylation rate (vonCaemmerer 2000)[u moles m-2 s-1]
LeafMassFlux.ac = 2;%1; % RUBISCO limited gross rate of CO2 uptake per unit area [u moles m-2 s-1]
LeafMassFlux.aj = 2;%1; % TPU limited gross rate of CO2 uptake per unit area [u moles m-2 s-1]
LeafMassFlux.ap = 2;%1; % RuBP -limited gross rate of CO2 uptake per unit area [u moles m-2 s-1]
LeafMassFlux.aGross = 0;%Weather.ca/10;%1; % Gross rate of CO2 uptake per unit area [u moles m-2 s-1]
LeafMassFlux.aNet = Weather.ca/10; % Net rate of CO2 uptake [u mol m-2 s-1]
LeafMassFlux.J = 2;%1; % Whole chain electron transport rate (vonCaemmerer 2000) [u moles m-2 s-1]
LeafMassFlux.rd = Photosynthesis.rd25;%1; % Dark respiration at leaf (vonCaemmerer 2000) [u moles m-2 s-1]
LeafMassFlux.rm = 2;%1; % Mysophyll dark respiration rate (vonCaemmerer 2000) [u moles m-2 s-1]
LeafMassFlux.vcmax = 0;%Photosynthesis.vcmax25;%1; % Max RuBP saturated carboxylation at given temperature (Massad 2007) [u moles m-2 s-1]
LeafMassFlux.vpmax = 0;%Photosynthesis.vpmax25;%1; % Max PEP carboxylation rate at a given leaf temperature (Massad 2007) [u moles m-2 s-1]
LeafMassFlux.jmax = 0;%Photosynthesis.jmax25;%1; % Max electon transport rate (Massad 2007) [u moles m-2 s-1]
LeafMassFlux.vc = 2;%1; % PEP carboxylation rate at leaf temperature [u moles m-2 s-1]
LeafMassFlux.vp = 2;%1; % RUBISCO carboxylation rate at leaf temperature (vonCaemmerer 2000) [u moles m-2 s-1]
LeafMassFlux.transpiration = 2;%1; % Leaf transpiration [u moles m-2 s-1]

LeafEnergyFlux = table();
LeafEnergyFlux.me = 2; % Energy flux of photosynthesi [W m-2]
LeafEnergyFlux.sensibleHeat = 2; % Sensible heat flux [W m-2]
LeafEnergyFlux.latentHeat = 2; % Latent heat flux [W m-2]
LeafEnergyFlux.emission = 2; % Long wave radiation flux emitted [W m-2]
LeafEnergyFlux.radiation = 2; % Net radiation flux [W m-2]
LeafEnergyFlux.residual = 2; % Error radiation flux [W m-2]

end