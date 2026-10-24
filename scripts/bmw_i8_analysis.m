% =========================================================================
% BMW i8 VEHICLE PERFORMANCE ANALYSIS - MAIN SCRIPT
% =========================================================================
%
% DESCRIPTION:
% Longitudinal vehicle dynamics of the BMW i8 Coupe: driving resistances,
% tractive force in each gear, acceleration in each gear, climbing ability,
% top speed and a 0-100 km/h run compared with BMW's published time.
%
% ANALYSIS COMPONENTS:
% 1. Aerodynamic drag
%    - Drag force and power as a function of speed
% 2. Rolling resistance
%    - Speed-dependent rolling resistance coefficient, corrected for tyre
%      pressure and tyre load on the front and rear axle
% 3. Grade resistance
%    - Power needed to climb gradients of 0 to 100%, as a 3D surface
% 4. Tractive force
%    - Tractive force in all 6 gears from the system torque curve
%    - Total resistance on gradients of 0 to 100%, engine speed lines,
%      the ideal constant-power (CVT) curve and the tyre grip limit
%    - Steepest gradient each gear can climb
% 5. Acceleration
%    - Acceleration in each gear on a flat road, with the rotating mass
%      factor, limited by tyre grip
%    - Top speed the drivetrain could reach
% 6. 0-100 km/h
%    - Speed against time with gear changes, compared with BMW's 4.4 s
%
% MODEL ASSUMPTIONS (more in the README):
% - The torque curve is the system output of the engine and the front
%   electric motor together, applied through the six-speed gearbox as one
%   drivetrain. In the car, the six-speed carries only the engine to the
%   rear axle, and the electric motor drives the front axle through its own
%   two-speed gearbox.
% - Because both axles are driven, the grip limit is mu * G on a flat road
%   (all-wheel drive with an ideal torque split).
%
% USAGE:
% Run this script from any folder, for example in Octave or MATLAB:
%   run('scripts/bmw_i8_analysis.m')
% All inputs are in VehicleData.m, in the same folder as this script.
% The figures open in windows and are saved as PNG files in ../figures.
%
% AUTHOR: Sou Komiya
% DATE: January 2026, updated October 2026
% =========================================================================

clear all
close all
clc

save_figures = true;  % false: only show the figures, do not save PNG files

% Folder of this script, so the data file is found from any working folder
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir)
  script_dir = pwd;
end
fig_dir = fullfile(script_dir, '..', 'figures');
if save_figures && ~exist(fig_dir, 'dir')
  mkdir(fig_dir);
end

fprintf('========================================\n');
fprintf('BMW i8 VEHICLE PERFORMANCE ANALYSIS\n');
fprintf('========================================\n\n');

%% LOAD VEHICLE DATA
fprintf('Loading vehicle data...\n');
run(fullfile(script_dir, 'VehicleData.m'))
fprintf('  ✓ Vehicle data loaded\n\n');

%% 1. AERODYNAMIC DRAG ANALYSIS
fprintf('Running Aerodynamic Drag Analysis...\n');

% Calculate air drag -------------------------
Fd = rho / 2 * cd * A * (vT/3.6).^2; % Aerodynamic drag [N]
Pd = Fd .* (vT/3.6); % Power [W]

% Graphs -------------------------------------
fig1 = figure('Name','1. Aerodynamic Drag Analysis','NumberTitle','off');
subplot(1,2,1)
plot(vT,Fd,'LineWidth',2)
title('Aerodynamic drag vs. velocity','fontweight','bold')
xlabel('Velocity [km/h]','fontweight','bold')
ylabel('Force [N]','fontweight','bold')
grid on

subplot(1,2,2)
plot(vT,Pd/1000,'LineWidth',2)
title('Power vs. velocity','fontweight','bold')
xlabel('Velocity [km/h]','fontweight','bold')
ylabel('Power [kW]','fontweight','bold')
grid on

fprintf('  ✓ Aerodynamic drag analysis complete\n\n');

%% 2. ROLLING RESISTANCE ANALYSIS
fprintf('Running Rolling Resistance Analysis...\n');

% Rolling resistance calculation -----------------------------
Gtf = G * sr / l / 2; % Single wheel vertical load for front [N]
Gtr = G * sf / l / 2; % Single wheel vertical load for rear [N]

frf = fR * (1.3-0.3*pf/pTf)*(1.3-0.3*NTf/Gtf); % "Real" rolling resistance coefficient
frr = fR * (1.3-0.3*pr/pTr)*(1.3-0.3*NTr/Gtr); % "Real" rolling resistance coefficient

Ftf = frf * Gtf * 2; % Front axle rolling resistance [N]
Ftr = frr * Gtr * 2; % Rear axle rolling resistance [N]
Ft = Ftf + Ftr; % Rolling resistance for the whole vehicle [N]

Pt = vT/3.6 .* Ft; % Power calculated from rolling resistance [W]

% Graphs ------------------------------------------------------
fig2 = figure('Name','2. Rolling Resistance Analysis','NumberTitle','off');

subplot(1,2,1)
plot(vT,Ft,'LineWidth',2)
title('Rolling resistance force vs. vehicle speed','fontweight','bold')
xlabel('Speed [km/h]','fontweight','bold')
ylabel('Force [N]','fontweight','bold')
grid on

subplot(1,2,2)
plot(vT,Pt/1000,'LineWidth',2)
title('Power vs. vehicle speed','fontweight','bold')
xlabel('Speed [km/h]','fontweight','bold')
ylabel('Power [kW]','fontweight','bold')
grid on

fprintf('  ✓ Rolling resistance analysis complete\n\n');

%% 3. GRADE RESISTANCE ANALYSIS
fprintf('Running Grade Resistance Analysis...\n');

Fg_grade = zeros(1,length(Grad)); % Creates a vector filled with zeros
Pg = zeros(length(Grad),length(vT));

% Grade resistance and power needed ---------------------
for i=1:length(Grad)
  alpha = atand(Grad(i)/100); % Calculate incline in degrees
  Fg_grade(i) = G * sind(alpha); % Grade resistance
  Pg(i,:) = vT / 3.6 * Fg_grade(i); % Power needed for the grade resistance and velocity range
end

% Graphs-----------------------------
fig3 = figure('Name','3. Grade Resistance Analysis','NumberTitle','off');
surf(vT,Grad,Pg/1000)
title('Power needed for driving on an incline','fontweight','bold')
xlabel('Velocity [km/h]','fontweight','bold')
ylabel('Incline [%]','fontweight','bold')
zlabel('Power [kW]','fontweight','bold')
colorbar

fprintf('  ✓ Grade resistance analysis complete\n\n');

%% 4. TRACTIVE FORCE CALCULATION
fprintf('Running Tractive Force Calculation...\n');

% Create Variables / Vectors for calculation -----------------------
n = length(Grad); % Number of road inclines
nn = length(vT); % Length of the velocity vector
nnn = length(i_g); % Number of gears
Fg = zeros(n,1); % Grade resistance [N]
Gtf_trac = zeros(n,1); % Front axle load [N]
Gtr_trac = zeros(n,1); % Rear axle load [N]
frf_trac = zeros(n,nn); % Front tire rolling resistance coefficient
frr_trac = zeros(n,nn); % Rear tire rolling resistance coefficient
Fr = zeros(n,nn); % Total rolling resistance [N]
FR = zeros(n,nn); % Total driving resistance [N]

% Calculate air drag -----------------------------------------------
Fd_trac = rho / 2 * cd * A * (vT/3.6).^2; % Aerodynamic drag [N]

% Grade / Rolling / Total resistance -------------------------------
for i = 1:n
  alpha = atand(Grad(i)/100); % Calculate incline in degrees

  % Grade resistance -----------------------------------------------
  Fg(i) = G * sind(alpha); % Grade resistance [N]

  % Rolling resistance ---------------------------------------------
  Gtf_trac(i) = G * ( sr/l * cosd(alpha) - h/l * sind(alpha)) ; % Front axle load [N]
  Gtr_trac(i) = G * ( sf/l * cosd(alpha) + h/l * sind(alpha)) ; % Rear axle load [N]

  frf_trac(i,:) = fR * (1.3-0.3*pf/pTf)*(1.3-0.3*(NTf*2)/Gtf_trac(i)); % Real rolling resistance coefficient for front axle
  frr_trac(i,:) = fR * (1.3-0.3*pr/pTr)*(1.3-0.3*(NTr*2)/Gtr_trac(i)); % Real rolling resistance coefficient for rear axle

  Fr(i,:) = frf_trac(i,:)*Gtf_trac(i)+frr_trac(i,:)*Gtr_trac(i); % Total rolling resistance [N]

  % Total resistance [N]
  FR(i,:) = Fd_trac + Fg(i) + Fr(i,:); % Total resistance [N]
end

% Tractive force calculation----------------------------------------
v = zeros(nnn,length(nm)); % Vehicle speed in each gear [km/h]
Fx = zeros(nnn,length(nm)); % Tractive force [N]

for i=1:nnn
  v(i,:) = 2*pi*Rd*(nm/60) / (i_f*i_g(i))*3.6; % Velocity [km/h]
  Fx(i,:) = eta * Mm * i_f * i_g(i) / Rd; % Tractive force [N]
end

F_grip = mu * G; % Most force the tyres can transmit on a flat road, both axles driven [N]

% Steepest gradient each gear can climb at a steady speed ------------
% The force at the wheels is the smaller of the tractive force and the
% grip limit mu * G * cos(alpha). Speeds above the tyre data give NaN.
grad_fine = 0:0.5:150; % Gradients to test [%]
fR_gear = zeros(nnn,length(nm));
for i = 1:nnn
  fR_gear(i,:) = interp1([0 vT], [fR(1) fR], v(i,:), 'pchip', NaN); % Coefficient at the speeds of gear i
end
max_grade = zeros(1,nnn); % Steepest gradient per gear [%]
for i = 1:nnn
  Fd_gear = rho / 2 * cd * A * (v(i,:)/3.6).^2;
  for g = grad_fine
    alpha = atand(g/100);
    Gf = G * (sr/l*cosd(alpha) - h/l*sind(alpha)); % Front axle load [N]
    Gr = G * (sf/l*cosd(alpha) + h/l*sind(alpha)); % Rear axle load [N]
    Froll = fR_gear(i,:)*(1.3-0.3*pf/pTf)*(1.3-0.3*(NTf*2)/Gf)*Gf + ...
            fR_gear(i,:)*(1.3-0.3*pr/pTr)*(1.3-0.3*(NTr*2)/Gr)*Gr;
    F_need = Fd_gear + Froll + G*sind(alpha);
    F_have = min(Fx(i,:), mu*G*cosd(alpha));
    if any(F_have >= F_need)
      max_grade(i) = g;
    end
  end
end

% Graphs -----------------------------------------------------------
fig4 = figure('Name','4. Tractive Force Graph','NumberTitle','off');
hold on

% Resistance plots
for i = 1:n
  hR = plot(vT,FR(i,:),'k','LineWidth',1);
end

% Text for the incline percentage
for i = 1:n
  grade = [' ' num2str(Grad(i)) '%'];
  text(vT(end),FR(i,end),grade,'fontsize',8);
end

% Tractive forces
for i = 1:nnn
  hF = plot(v(i,:),Fx(i,:),'b','LineWidth',1);
end

% RPM graphs -------------------------------------------------------
for i= 1:nnn
  hN = plot(v(i,:),nm,'-.r','LineWidth',1);
end

% Add gear numbers -------------------------------------------------
for i = 1:nnn
  gear = [' ' num2str(i) '.'];
  text(v(i,end),nm(end)+20,gear);
end

% CVT-graph ---------------------------------------------------------
Fcvt = Pmax * eta ./ (vT/3.6); % Tractive force for CVT-gear box
hC = plot(vT,Fcvt,'--k','LineWidth',1);

% Grip limit on a flat road ----------------------------------------
hG = plot([0 320],[F_grip F_grip],':m','LineWidth',2);

title('Tractive force graph','fontweight','bold','fontsize',18)
xlabel('Velocity [km/h]','fontweight','bold','fontsize',14)
ylabel('Force [N] / Engine speed [rpm]','fontweight','bold','fontsize',14)
legend([hF hR hN hC hG], {'Tractive force, gears 1 to 6', ...
  'Driving resistance, 0 to 100% gradient', 'Engine speed [rpm]', ...
  'Ideal constant power (CVT)', sprintf('Grip limit, mu = %.1f, flat road', mu)}, ...
  'location','northeast')
grid on
xlim([0 320])
ylim([0 30000])

fprintf('  ✓ Tractive force calculation complete\n');
for i = 1:nnn
  fprintf('    Gear %d: steepest gradient %.1f %%\n', i, max_grade(i));
end
fprintf('\n');

%% 5. ACCELERATION ANALYSIS
fprintf('Running Acceleration Analysis...\n');

% Flat-road resistance at any speed inside the tyre data [N]. Below 10 km/h
% the rolling resistance of 10 km/h is used. Above 280 km/h there is no tyre
% data, so the result is NaN instead of an extrapolated value.
FR_flat = @(vk) rho/2*cd*A*(vk/3.6).^2 + interp1([0 vT], [Ft(1) Ft], vk, 'pchip', NaN);

n_gears = length(i_g); % Measure the number of gears
a_engine = zeros(n_gears,length(nm)); % Acceleration limited by torque [m/s^2]
a = zeros(n_gears,length(nm)); % Acceleration, also limited by grip [m/s^2]

fig5 = figure('Name','5. Acceleration Performance','NumberTitle','off');
hold on

% Calculate acceleration for each gear
for i=1:n_gears
  phi = 1.04+0.0025 * (i_g(i)*i_f)^2; % Rotating mass factor
  FR_i = FR_flat(v(i,:)); % Resistance on a flat road [N]
  a_engine(i,:) = (Fx(i,:)-FR_i) / (phi*m);
  % Grip limit: the tyres move the car's mass. The rotating parts sit
  % before the tyres, so the mass factor does not apply here.
  a_grip = (F_grip-FR_i) / m;
  a(i,:) = a_engine(i,:);
  limited = a_grip < a_engine(i,:);
  a(i,limited) = a_grip(limited);

  plot(v(i,:),a(i,:),'LineWidth',1.5)
end

% Grip limit line
v_line = 0:1:vT(end);
plot(v_line,(F_grip-FR_flat(v_line))/m,':m','LineWidth',2)

title('Acceleration for each gear','fontweight','bold','fontsize',18)
xlabel('Velocity [km/h]','fontweight','bold','fontsize',14)
ylabel('Acceleration [m/s^2]','fontweight','bold','fontsize',14)
legend({'1st gear','2nd gear','3rd gear','4th gear','5th gear','6th gear', ...
  sprintf('Grip limit, mu = %.1f', mu)},'location','northeast')
grid on
xlim([0 300])

% Top speed: where the acceleration in the best gear falls to zero --------
v_top = NaN;
for i = 1:n_gears
  ok = ~isnan(a_engine(i,:));
  vi = v(i,ok);
  ai = a_engine(i,ok);
  k = find(ai(1:end-1) > 0 & ai(2:end) <= 0, 1);
  if ~isempty(k)
    v_zero = vi(k) + (vi(k+1)-vi(k)) * ai(k)/(ai(k)-ai(k+1));
    v_top = max([v_top v_zero]);
  end
end
% Acceleration in the top gear at the last speed of the tyre data
phi_top = 1.04+0.0025 * (i_g(end)*i_f)^2;
a_last_gear = (interp1(v(end,:), Fx(end,:), vT(end)) - FR_flat(vT(end))) / (phi_top*m);

fprintf('  ✓ Acceleration analysis complete\n');
fprintf('    Highest acceleration: %.2f m/s^2 (grip limit %.2f m/s^2)\n', ...
  max(a(:)), (F_grip-FR_flat(0))/m);
if isnan(v_top)
  fprintf('    Top speed: above %d km/h, the end of the tyre data (6th gear still %.2f m/s^2 there)\n', ...
    vT(end), a_last_gear);
else
  fprintf('    Top speed: %.0f km/h\n', v_top);
end
fprintf('    The car is electronically limited to %d km/h\n\n', v_limit);

%% 6. 0-100 KM/H
fprintf('Running 0-100 km/h simulation...\n');

dv = 0.1; % Speed step [km/h]
v_run = 0:dv:100; % Speeds of the run [km/h]

% Acceleration of every gear at every speed of the run. Below the lowest
% speed of 1st gear (engine at its lowest speed in the data), the torque
% converter slips and the car accelerates as at that lowest speed.
a_gears = NaN(n_gears,length(v_run));
for i = 1:n_gears
  a_gears(i,:) = interp1(v(i,:), a(i,:), v_run, 'linear', NaN);
end
a_gears(1, v_run < v(1,1)) = a(1,1);

% The driver always uses the gear with the most acceleration
[a_run, gear_run] = max(a_gears, [], 1);

% Time from dt = dv / a, plus t_shift for every gear change
dt = (dv/3.6) * (1./a_run(1:end-1) + 1./a_run(2:end)) / 2;
shifts = gear_run(2:end) ~= gear_run(1:end-1);
t_ideal = [0 cumsum(dt)];
t_run = [0 cumsum(dt + shifts*t_shift)];
n_shifts = sum(shifts);
shift_speeds = v_run([false shifts]);

fig6 = figure('Name','6. 0-100 km/h','NumberTitle','off');
hold on
plot(t_run, v_run, 'LineWidth', 2)
plot([t_0_100_bmw t_0_100_bmw], [0 100], '--k', 'LineWidth', 1)
text(t_0_100_bmw, 10, sprintf(' BMW: %.1f s', t_0_100_bmw))
for k = 1:n_shifts
  ks = find(v_run == shift_speeds(k), 1);
  plot(t_run(ks), v_run(ks), 'ok', 'MarkerFaceColor', 'k')
  text(t_run(ks), v_run(ks), sprintf('  %d to %d', gear_run(ks-1), gear_run(ks)))
end
title(sprintf('0-100 km/h in %.1f s (model)', t_run(end)),'fontweight','bold','fontsize',18)
xlabel('Time [s]','fontweight','bold','fontsize',14)
ylabel('Velocity [km/h]','fontweight','bold','fontsize',14)
grid on
xlim([0 ceil(max(t_run(end), t_0_100_bmw)) + 0.5])
ylim([0 110])

fprintf('  ✓ 0-100 km/h simulation complete\n');
fprintf('    0-100 km/h: %.2f s with %d gear changes of %.1f s (%.2f s without the shift time)\n', ...
  t_run(end), n_shifts, t_shift, t_ideal(end));
fprintf('    Gear changes at: %s km/h\n', num2str(round(shift_speeds)));
fprintf('    BMW published: %.1f s\n\n', t_0_100_bmw);

%% SAVE FIGURES
if save_figures
  names = {'aerodynamic_drag', 'rolling_resistance', 'grade_resistance', ...
           'tractive_force', 'acceleration', 'zero_to_100'};
  figs = [fig1 fig2 fig3 fig4 fig5 fig6];
  for k = 1:numel(figs)
    print(figs(k), fullfile(fig_dir, [names{k} '.png']), '-dpng', '-r200');
  end
  fprintf('Figures saved in %s\n\n', fig_dir);
end

%% ANALYSIS COMPLETE
fprintf('========================================\n');
fprintf('ALL ANALYSES COMPLETED SUCCESSFULLY!\n');
fprintf('========================================\n');
fprintf('\nGenerated Figures:\n');
fprintf('  1. Aerodynamic Drag Analysis\n');
fprintf('  2. Rolling Resistance Analysis\n');
fprintf('  3. Grade Resistance Analysis\n');
fprintf('  4. Tractive Force Graph\n');
fprintf('  5. Acceleration Performance\n');
fprintf('  6. 0-100 km/h\n\n');
