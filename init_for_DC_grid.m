%% DESCRIPTION:
% This script is a prerequisty for simulation.
% It generates the start point for the iteratives simulation as .mat files

% Fill the function parameters as follow to generate initial states:
% make_initialState(
%       'name of the simulink model'
%       model_constants structure
%       initial current of the FC delivered to the bus (in p.u., between
%                                        the DC/DC converter and the bus
%       initial load ID (see below)
%       'name of the .mat file to be generated'

% Initial load ID:
% In the simunink model, a switch block allows to select a type of load
% (constant, square, sinus). The ID are the followings:
% 1- 50% load
% 2- 100% load
% 3- Pulse of period 1sec
% 4- Pulse of period 5sec
% 5- Pulse of period 60sec
% 6- Sinus of period 1sec
% 7- Sinus of period 5sec
% 8- Sinus of period 60sec
% 9- 0% load
% 10- Realistic load (to be initialized with 2X or 3X)


% NOTE: The FC have internal resistance, then I_bus_FC is not proportionnal
% to the power output.
% I_bus_FC = 16.18A => P_FC = 3kW
% I_bus_FC = 36.64A => P_FC = 6kW
% I_bus_FC = 56.31A => P_FC = 8kW
% Remember to divide by the nominal current.

model = 'DC_grid_V2';

% ################          Model constants          ######################
% Note: It is misuse of language to say that the initial SOC is a constant,
% but it is percieved as it by the model.
model_constants_1_5Ah_70 = struct(...
    'nominal_voltage',100,...
    'rated_capacity',1.5,...
    'initial_SOC',70,...
    'battery_response_time',2,...
    'checkbox','on',...
    'max_capacity',1.5,...
    'cut_off_voltage',75,...
    'fully_charged_voltage',116.3985,...
    'nominal_discharge_current',75,... 
    'internal_R',0.66667,...
    'capacity_at_nominal_voltage',1.3565,...
    'exponential_zone',[108.0386 0.07369565]);
make_initialState(model,model_constants_1_5Ah_70,0,9,'initialState_1_5Ah_70'); % No load for initialization

model_constants_1_5Ah_95 = struct(...
    'nominal_voltage',100,...
    'rated_capacity',1.5,...
    'initial_SOC',95,...
    'battery_response_time',2,...
    'checkbox','on',...
    'max_capacity',1.5,...
    'cut_off_voltage',75,...
    'fully_charged_voltage',116.3985,...
    'nominal_discharge_current',75,... 
    'internal_R',0.66667,...
    'capacity_at_nominal_voltage',1.3565,...
    'exponential_zone',[108.0386 0.07369565]);
make_initialState(model,model_constants_1_5Ah_95,0,9,'initialState_1_5Ah_95'); % No load for initialization

model_constants_1_5Ah_20 = struct(...
    'nominal_voltage',100,...
    'rated_capacity',1.5,...
    'initial_SOC',20,...
    'battery_response_time',2,...
    'checkbox','on',...
    'max_capacity',1.5,...
    'cut_off_voltage',75,...
    'fully_charged_voltage',116.3985,...
    'nominal_discharge_current',75,... 
    'internal_R',0.66667,...
    'capacity_at_nominal_voltage',1.3565,...
    'exponential_zone',[108.0386 0.07369565]);
make_initialState(model,model_constants_1_5Ah_20,0,9,'initialState_1_5Ah_20'); % No load for initialization

model_constants_30Ah = struct(...
    'nominal_voltage',100,...
    'rated_capacity',30,...
    'initial_SOC',70,...
    'battery_response_time',2,...
    'checkbox','on',...
    'max_capacity',30,...
    'cut_off_voltage',75,...
    'fully_charged_voltage',116.3985,...
    'nominal_discharge_current',75,...
    'internal_R',0.033333,...
    'capacity_at_nominal_voltage',27.1304,...
    'exponential_zone',[108.0386      1.473913]);
make_initialState(model,model_constants_30Ah,0,9,'initialState_30Ah'); % No load for initialization

function make_initialState(simulinkModel,model_constants,I_bus_FC_0,ID_load_profile_0,name)
% DESCRIPTION:
% OUTPUTS:
% A .mat file containing:
%   - A SimState set of values (the current system parameters in the
%   Simulink point of view. Does not contain data of interest for the user.
%   Type: ModelSimState
%
%   - Model Constants
%   Some values of interest for the Mask of the FC and Battery models,
%   such as the initial SOC (%), the rated capacity (Ah) or the response
%   time (s) for the battery. This values stay the same all along the
%   simulation.
%   Note that other values for the FC and Battery models are passed 
%   graphically. For further work++, all the values (i.e. the complete 
%   mask) should be passed programatically (out of scope here). 
%   Type: struct
%
%   - The input parameters of the DC grid (see inputsFromWS in the simulink
%   model). This values are supposed to change during simulation. 
%   Type: Array
%
%   - The output parameters of the DC grid (see outputsToWS in the simulink
%   model). Type: struct
%% Setting the input parameters for initialization:

% ################         Input parameters          ###################### 
% Converting the initial set points in an array form for the model:
inputArray = [I_bus_FC_0,ID_load_profile_0]; 
inputsFromWS = Simulink.Parameter(inputArray);
assignin('base','inputsFromWS',inputsFromWS);
inputsFromWS.StorageClass='ExportedGlobal';

% Call the function which initialize the user chosen model constants in the
% Simulink model:
initialize_model_constants(simulinkModel,model_constants)

% Generate the SimState and the Output structure of values
[initialSimState,initial_outputsToWS] = generate_start_point(simulinkModel);

% Make a .mat file containing the total state after initialization precedure
save([name,'.mat'],'initialSimState','model_constants',...
    'inputArray','initial_outputsToWS');
end

function [initialSimState,initial_outputsToWS] = generate_start_point(simulinkModel)
% DESCRIPTION:
% The goal of this function is to generate an initial state for a model which
% has no initial state already. The initial state outputed is the state
% after 10s of simulation (it is supposed that after 10s, the system is in 
% a steady state).
%
% INPUTS:
% The model for which the initial state has to be generated.
%
% OUTPUTS:
% Save an initial state in the current folder as .mat file
%
% FREQUENCY OF EXECUTION:
% To be ran for getting new initial states i.e. not so often. 
% NB: To generate multiple initial states, there is need to rename them
% manually in the folder.
% EXAMPLE OF USE:
% See example and test in the script SimState_testing_and_example

set_param(simulinkModel,'FastRestart','off');
set_param(simulinkModel,'SaveFinalState','on','FinalStateName','myOperPoint',...
    'SaveCompleteFinalSimState','on','LoadInitialState','off');
disp('You have been setting your initial conditions and model constants, the initial state is being generated');
simOut = sim(simulinkModel,'StopTime','10','SimulationMode','accelerator');

% The operation point of the model in the Simulink view
initialSimState = simOut.myOperPoint;   

% Variables of interest in the the user view:
initial_outputsToWS = struct(...
    'P_FC',simOut.outputsToWS.P_FC.Data(end),...
    'P_batt',simOut.outputsToWS.P_FC.Data(end),...
    'SOC',simOut.outputsToWS.SOC.Data(end),...
    'Fuel_flow',simOut.outputsToWS.Fuel_flow.Data(end),...
    'Stack_efficiency',simOut.outputsToWS.Stack_efficiency.Data(end),...
    'Load_profile',simOut.outputsToWS.Load_profile.Data(1)); 

set_param(simulinkModel,'LoadInitialState','on');  % Prevent of being off
set_param(simulinkModel,'FastRestart','on');
end

