% =========================================================================
% VEHICLE DATA - BMW i8 Coupe
% =========================================================================
% Loaded by bmw_i8_analysis.m. Every value says where it comes from:
%   [BMW 2018]  BMW i8 Coupe technical data, BMW Group media information, April 2018
%   [BMW 2017]  BMW i8 technical data, BMW Group US media information, model year 2017
%   [estimate]  calculated or estimated from other values
%   [assumed]   assumption for this model
% =========================================================================

% VEHICLE DATA -------------------------------------------------------------
l = 2.800;            % Wheelbase [m]                                             [BMW 2018]
ha = 1.293;           % Vehicle height [m]                                        [BMW 2018]
h = ha * 0.36;        % Centre of gravity height [m], statistical share of height [estimate]
m = 1535;             % Vehicle mass [kg], unladen DIN (EU incl. driver: 1610)    [BMW 2018]
G = m * 9.81;         % Vehicle weight force [N]
wd = 49 / 100;        % Share of the weight on the front axle, unladen 49/51      [BMW 2018]
sf = l * (1-wd);      % Distance of the centre of gravity from the front axle [m] [estimate]
sr = l * wd;          % Distance of the centre of gravity from the rear axle [m]  [estimate]

% POWERTRAIN ----------------------------------------------------------------
% System torque of the 1.5 l engine and the front electric motor together
% (peak 571.5 Nm at about 3,700 rpm, about 275 kW at 5,200 rpm). The model
% treats this combined output as one drivetrain through the six-speed gearbox,
% see the README.
nm = [947.4 1003.3 1059.2 1133.8 1208.3 1282.9 1394.7 1487.9 1618.4 1767.5 1898 2065.8 2196.3 2382.7 2569.1 2755.5 2979.2 3202.9 3445.2 3575.7 3650.2 3743.4 3873.9 4004.4 4134.9 4265.4 4414.5 4563.6 4675.4 4805.9 4936.4 5085.5 5216 5309.2 5439.7 5570.2 5719.3 5868.4 5980.3 6073.5 6129.4 6203.9]; % Engine speed vector [1/min]
Mm = [274.9 292.6 311.7 332.2 352.8 371.9 392.5 414.5 435.1 452.7 470.3 485 498.2 511.4 523.2 533.4 543.7 552.5 564.2 565.6 570 571.5 568.5 567 564.1 561.1 556.7 549.3 543.4 536 528.6 515.4 505.1 493.3 481.5 469.7 457.9 446.1 432.9 421.1 407.9 394.6]; % System torque at each speed [Nm]
Pmax = 275163;        % Maximum system power [W], 275 kW                          [BMW 2018]

% TRANSMISSION --------------------------------------------------------------
i_g = [4.459 2.508 1.556 1.142 0.851 0.672]; % Gear ratios, six-speed automatic   [BMW 2017]
i_f = 3.681;          % Final drive ratio                                         [BMW 2017]
eta = 0.92;           % Transmission efficiency                                   [assumed]

% INPUT DATA FOR AERODYNAMIC DRAG CALCULATION ------------------------------
cd = 0.26;            % Aerodynamic drag coefficient                              [BMW 2018]
A = 2.15;             % Frontal area [m^2]                                        [BMW 2018]

p = 100000;           % Ambient air pressure [Pa]
M = 0.02896;          % Molar mass of air [kg/mol]
R = 8.31;             % Universal gas constant [J/(mol*K)]
T = 293;              % Ambient temperature [K]
rho = (p*M)/(R*T);    % Air density [kg/m^3], ideal gas law, about 1.19

% TIRE DATA ---------------------------------------------------------------
Rd = 0.333;           % Dynamic rolling radius of the driven tyre [m]              [estimate]
vT = [10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200 210 220 230 240 250 260 270 280]; % Speed vector for the rolling resistance coefficient [km/h]
fR = [0.00922 0.009225 0.00925 0.009275 0.0093 0.009325 0.00935 0.009375 0.009404 0.009433 0.0094665 0.0095 0.009575 0.00965 0.009725 0.0098 0.01015 0.0105 0.0111 0.0119 0.013 0.0142 0.0157 0.0185 0.0222 0.0262 0.031 0.036]; % Nominal rolling resistance coefficient, rises with speed [assumed]
%--------------------------------------------------------------------------
% Front tyre 215/45 R20, load index 95                                      [BMW 2017]
pf = 2.5;             % Actual front tyre pressure [bar]                          [assumed]
pTf = 2.5;            % Nominal front tyre pressure [bar]                         [assumed]
NTf = 690*9.81;       % Nominal load capacity of one front tyre [N], index 95 = 690 kg
%--------------------------------------------------------------------------
% Rear tyre 245/40 R20, load index 103                                      [BMW 2017]
pr = 2.5;             % Actual rear tyre pressure [bar]                           [assumed]
pTr = 2.5;            % Nominal rear tyre pressure [bar]                          [assumed]
NTr = 875*9.81;       % Nominal load capacity of one rear tyre [N], index 103 = 875 kg

% INPUT DATA FOR GRADIENT RESISTANCE --------------------------------------
Grad = [0 5 10 15 20 25 30 35 40 45 50 60 70 80 90 100]; % Road gradient [%]

% ACCELERATION AND TOP SPEED ---------------------------------------------
mu = 1.0;             % Tyre-road friction coefficient, dry asphalt               [assumed]
t_shift = 0.2;        % Time per gear change with no acceleration [s]             [assumed]
v_limit = 250;        % Electronically limited top speed [km/h]                   [BMW 2018]
t_0_100_bmw = 4.4;    % Published 0-100 km/h time [s]                             [BMW 2018]
