%% Function to get model input parameters
function [Photosynthesis,Stomata,Weather,Constants] = ...
    callInputData(fileName)

%% Constant values
Constants = table();
Constants.R = 8.314/1000; % Universal gas constant [kJ mol-1 K-1]
Constants.convert = 4.57;%1E6/(2.35E5); % [u mole J-1] Convert radiation from [W m-2] to [u mol m-2 s-1]
Constants.LatentHeatVapourization = 44E3; % Latent heat of vaporization of water [J mol-1]
Constants.Boltzman = 5.67E-8; % Stefan Boltzman's constant [J K-1]
Constants.Cp = 29.3; % Specific heat capacity of air [J K-1 mol-1]
Constants.Pressure = 101325 ; % Atmospheric Pressure [Pa]
Constants.cforced = 4.322*1E-3; % 1.2035*1E-3 for coniferous shoot
Constants.cfree = 1.6361*1E-3; % 0.86691*E-3 for coniferous shoot
Constants.Leafepsilon = 0.94; % Emissivity [-] => Drewry 2010a
Constants.Airepsilon = 0.8; % Emissivity [-] => Drewry 2010a
Constants.absorptivityPAR = 0.85; % PAR absorptivity => vonCaemmerer 2013 (Since, Drewry 2010a was too low, 
                                  % general range 0.88-0.91 for fress leaves)
Constants.absorptivityNIR = 0.23; % NIR absorptivity => Drewry 2010a
Constants.LEfactor = 1; % Stomata on one side of leaf [-]
Constants.LWfactor = 2.0; % Emission from two sides of leaf [-]
Constants.Hfactor = 1; % Sensible heat loss from two sides of leaf [-]

%% Photosynthesis and stomatal parameters, and weather data
inputData = readtable(fileName,'ReadVariableNames',true); % Read input data in table format
Photosynthesis = inputData(1:end,{'leafID','leafPosition','energyOption','vpr','vcmax25','jmax25','vpmax25', ...
    'rd25','sco25','theta','gbs','alpha','waterStress','x'});
Stomata = inputData(1:end,{'slope','intercept'});
Weather = inputData(1:end,{'PAR','NIR','long','RH','temperature','wind','ca','O2',...
    'controlTemp'});
clear inputData

%% Calculating the absoprbed radiation from incident radiation
Weather.PAR = Weather.PAR*Constants.absorptivityPAR; % Absorbed PAR
Weather.NIR = Weather.NIR*Constants.absorptivityNIR; % Absorbed NIR
Weather.skyemissivity =  0.926 + 1.006*(Weather.RH.*(0.611*exp(17.502*Weather.temperature./(Weather.temperature+240.97))./...
 (Weather.temperature+273.15))).^(1.067); % Sky emittivity modified from Brutsaert (1982)
Weather.long = Constants.Leafepsilon*Weather.skyemissivity.*Constants.Boltzman.* ...
    (273.15 + Weather.temperature).^4; % Absorbed longwave from sky
end