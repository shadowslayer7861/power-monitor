% params.m - parameters shared by the model and the firmware simulation
V_SUPPLY   = 5.0;      % source voltage (V)
R_SRC      = 0.5;      % source resistance (ohm)
C_BULK     = 0.4;      % bulk capacitance (F)
I_MAX_LOAD = 2.0;      % load current at 100% duty (A)

DUTY_STEPS = [10 50 90 50 10 70];   % PWM duty sequence (%), same as main.c
STEP_S     = 5;                     % seconds per step
T_END      = 30;                    % total simulated time (s)
SAMPLE_S   = 0.05;                  % firmware sample period (s)

I_STEPS_A  = DUTY_STEPS / 100 * I_MAX_LOAD;   % load current per step (A)
TAU        = R_SRC * C_BULK;                  % time constant (s)