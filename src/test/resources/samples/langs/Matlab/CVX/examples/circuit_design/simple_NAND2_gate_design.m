% Two-input NAND gate sizing (GP)
% Boyd, Kim, Patil, and Horowitz, "Digital circuit optimization
% via geometric programming"
% Written for CVX by Almir Mutapcic 02/08/06
% (a figure is generated)
%
% This is an example taken directly from the paper:
%
%   Digital circuit optimization via geometrical programming
%   by Boyd, Kim, Patil, and Horowitz
%   Operations Research 53(6): 899-932, 2005.
%
% Solves the problem of choosing device widths w_i for the given
% NAND2 gate in order to achive minimum Elmore delay for different
% gate transitions, subject to limits on the device widths,
% gate area, power, and so on. The problem is a GP:
%
%   minimize   D = max( D_1, ..., D_k )  for k transitions
%       s.t.   w_min <= w <= w_max
%              A <= Amax, etc.
%
% where variables are widths w.
%
% This code is specific to the NAND2 gate shown in figure 19
% (page 926) of the paper. All the constraints and the objective
% are hard-coded for this particular circuit.

%********************************************************************
% problem data and hard-coded GP specs (evaluate all transitions)
%********************************************************************
N = 4;       % number of devices
Cload = 12;  % load capacitance
Vdd = 1.5;   % voltage

% device specs
NMOS = struct('R',0.4831, 'Cdb',0.6, 'Csb',0.6, 'Cgb',1, 'Cgs',1);
PMOS = struct('R',2*0.4831, 'Cdb',0.6, 'Csb',0.6, 'Cgb',1, 'Cgs',1);

% maximum area and power specification
Amax = 24;
wmin = 1;

% varying parameters for the tradeoff curve
Npoints = 25;
Amax = linspace(5,45,Npoints);
Dopt = [];

disp('Generating the optimal tradeoff curve...')
need_sedumi = strncmpi(cvx_solver,'sdpt',4);
if need_sedumi,
    warning('This model does not converge with SDPT3... switching to SeDuMi.');
end
for k = 1:Npoints
    fprintf(1,'  Amax = %5.2f:', Amax(k));
    cvx_begin gp quiet
        if need_sedumi,
            cvx_solver sedumi
        end
            
        % device width variables
        variable w(N)

        % device specs
        device(1:2) = PMOS; device(3:4) = NMOS;

        for num = 1:N
            device(num).R   = device(num).R/w(num);
            device(num).Cdb = device(num).Cdb*w(num);
            device(num).Csb = device(num).Csb*w(num);
            device(num).Cgb = device(num).Cgb*w(num);
            device(num).Cgs = device(num).Cgs*w(num);
        end

        % capacitances
        C1 = sum([device(1:3).Cdb]) + Cload;
        C2 = device(3).Csb + device(4).Cdb;

        % input capacitances
        Cin_A = sum([ device([2 3]).Cgb ]) + sum([ device([2 3]).Cgs ]);
        Cin_B = sum([ device([1 4]).Cgb ]) + sum([ device([1 4]).Cgs ]);

        % resistances
        R = [device.R]';

        % area definition
        area = sum(w);

        % delays and dissipated energies for all six possible transitions
        % transition 1 is A: 1->1, B: 1->0, Z: 0->1
        D1 = R(1)*(C1 + C2);
        E1 = (C1 + C2)*Vdd^2/2;
        % transition 2 is A: 1->0, B: 1->1, Z: 0->1
        D2 = R(2)*C1;
        E2 = C1*Vdd^2/2;
        % transition 3 is A: 1->0, B: 1->0, Z: 0->1
        % D3 = C1*R(1)*R(2)/(R(1) + R(2)); % not a posynomial
        E3 = C1*Vdd^2/2;
        % transition 4 is A: 1->1, B: 0->1, Z: 1->0
        D4 = C1*R(3) + R(4)*(C1 + C2);
        E4 = (C1 + C2)*Vdd^2/2;
        % transition 5 is A: 0->1, B: 1->1, Z: 1->0
        D5 = C1*(R(3) + R(4));
        E5 = (C1 + C2)*Vdd^2/2;
        % transition 6 is A: 0->1, B: 0->1, Z: 1->0
        D6 = C1*R(3) + R(4)*(C1 + C2);
        E6 = (C1 + C2)*Vdd^2/2;

        % objective is the worst-case delay
        minimize( max( [D1 D2 D4] ) )
        subject to
            area <= Amax(k);
            w >= wmin;
    cvx_end
    % display and store computed values
    fprintf(1,' delay = %3.2f\n',cvx_optval);
    Dopt = [Dopt cvx_optval];
end

% plot the tradeoff curve
plot(Dopt,Amax);
xlabel('Dmin'); ylabel('Amax');
disp('Optimal tradeoff curve plotted.')
