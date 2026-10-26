% run_model.m - builds the RC load-step model, runs it, exports model_output.csv
clear; clc;
params;

here = fileparts(mfilename('fullpath'));
if isempty(here), here = pwd; end

mdl = 'rc_load_step';
if bdIsLoaded(mdl), close_system(mdl, 0); end
new_system(mdl);

% ---- blocks (numeric values are baked in so the .slx is self-contained) ----
add_block('simulink/Sources/Repeating Sequence Stair', [mdl '/I_load'], ...
    'OutValues', mat2str(I_STEPS_A), 'SampleTime', num2str(STEP_S), ...
    'Position', [30 40 130 80]);
add_block('simulink/Sources/Constant', [mdl '/V_supply'], ...
    'Value', sprintf('%.10g', V_SUPPLY), 'Position', [30 130 90 160]);
add_block('simulink/Math Operations/Gain', [mdl '/R_src'], ...
    'Gain', sprintf('%.10g', R_SRC), 'Position', [180 45 230 75]);
add_block('simulink/Math Operations/Sum', [mdl '/Sum'], ...
    'Inputs', '+--', 'Position', [290 95 320 155]);
add_block('simulink/Math Operations/Gain', [mdl '/OneOverRC'], ...
    'Gain', sprintf('%.10g', 1/(R_SRC*C_BULK)), 'Position', [360 110 420 140]);
add_block('simulink/Continuous/Integrator', [mdl '/Integrator'], ...
    'InitialCondition', sprintf('%.10g', V_SUPPLY), 'Position', [460 105 500 145]);
add_block('simulink/Sinks/To Workspace', [mdl '/log_v'], ...
    'VariableName', 'v_cap', 'SaveFormat', 'Timeseries', 'Position', [560 110 640 140]);
add_block('simulink/Sinks/To Workspace', [mdl '/log_i'], ...
    'VariableName', 'i_load', 'SaveFormat', 'Timeseries', 'Position', [560 30 640 60]);

% ---- wiring ----
add_line(mdl, 'I_load/1',     'R_src/1');
add_line(mdl, 'I_load/1',     'log_i/1');
add_line(mdl, 'R_src/1',      'Sum/2');
add_line(mdl, 'V_supply/1',   'Sum/1');
add_line(mdl, 'Sum/1',        'OneOverRC/1');
add_line(mdl, 'OneOverRC/1',  'Integrator/1');
add_line(mdl, 'Integrator/1', 'Sum/3');        % feedback: -V
add_line(mdl, 'Integrator/1', 'log_v/1');

% ---- solver settings ----
set_param(mdl, 'Solver', 'ode45', 'MaxStep', '0.01', 'StopTime', num2str(T_END));

try, Simulink.BlockDiagram.arrangeSystem(mdl); catch, end   % tidy layout (optional)
save_system(mdl, fullfile(here, [mdl '.slx']));

% ---- run ----
out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
v   = out.v_cap;
[tu, iu] = unique(v.Time);
vdat = squeeze(v.Data);  vdat = vdat(iu);

% ---- resample onto the firmware's 50 ms grid ----
t_grid = (1:round(T_END/SAMPLE_S))' * SAMPLE_S;
v_grid = interp1(tu, vdat, t_grid, 'linear');
idx    = min(max(floor((t_grid - SAMPLE_S/2) / STEP_S) + 1, 1), numel(I_STEPS_A));
i_grid = I_STEPS_A(idx)';                       % current during each sample interval

T = table(round(t_grid*1000), round(v_grid*1000), round(i_grid*1000), ...
          round(v_grid .* i_grid * 1000), ...
          'VariableNames', {'time_ms','v_model_mV','i_model_mA','p_model_mW'});
writetable(T, fullfile(here, 'model_output.csv'));
fprintf('Wrote model_output.csv (%d rows)\n', height(T));
fprintf('Expected steady state at 90%% duty: %.2f V\n', V_SUPPLY - R_SRC*I_STEPS_A(3));

% ---- quick look ----
figure;
subplot(2,1,1); plot(t_grid, v_grid, 'b'); ylabel('Voltage (V)'); grid on;
title('Simulink RC model: load-step response');
subplot(2,1,2); stairs(t_grid, i_grid, 'r'); ylabel('Load current (A)');
xlabel('Time (s)'); grid on;

open_system(mdl);    % opens the diagram so you can screenshot it