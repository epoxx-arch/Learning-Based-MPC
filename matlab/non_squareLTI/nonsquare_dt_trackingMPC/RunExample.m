%% TRACKING REFERENCE MPC example
close all;
clearvars;

%% Parameters
% Set the prediction horizon:
N = 10;
% syms a b; % for paramterisation
%% Closed-Loop Simulation
% The initial conditions
x = [2;0];
%setpoint
% xs = [0; 0];
% N horizon, 4 num of opt variables U = [u1;u2], theta = [a;b]
u0_1d= zeros(1,N); % start inputs
theta0_1d = 0; % start param values
opt_var = [u0_1d, u0_1d, theta0_1d, theta0_1d];

options = optimoptions('fmincon','Algorithm','sqp','Display','none');

% Simulation time in seconds
iterations = 90;
% Optimization variable bounds (usually control) not constraints per say
u_min=-0.3;u_max=0.3;
LB = [ones(2*N,1)*u_min; ones(2,1)*(-inf)];
UB = [ones(2*N,1)*u_max; ones(2,1)*(+inf)];
% LB =[];
% UB = [];

A = [1, 1; 0, 1];
B = [0.0, 0.5; 1.0, 0.5];
C = [1 0];
n=size(A,1);
m=size(B,2);
o = size(C,1);
M = [A - eye(n), B, zeros(n,o); ...
        C, zeros(o,m), -eye(o)];
V = null(M);
% Mtheta = [1, 0, 0, 0; 0, 1, 1, -2]';
Mtheta = V;
LAMBDA = Mtheta(1:2,1:2);
PSI = Mtheta(3:4,1:2);
MN = [Mtheta; 1, 0];

Q = diag([1,1]);
R = Q;
[P, e, K] = dare(A,B,Q,R);
T = 100*P;
%% Cost Calculation
% Start simulation

xHistory = x;
art_refHistory = [theta0_1d; theta0_1d];
true_refHistory = [0.0;0.0];
% J=costFunction(reshape(opt_var(1:end-2),2,N),reshape(opt_var(end-1:end),2,1),x,xs,N,reshape(opt_var(1:2),2,1),reshape(opt_var(end-1:end),2,1),P,T,LAMBDA,PSI);
for ct = 1:(iterations)
    xs = set_ref(ct);
    % opt_var must be a vector!
    COSTFUN = @(opt_var) costFunction(reshape(opt_var(1:end-2),2,N),reshape(opt_var(end-1:end),2,1),x,xs,N,reshape(opt_var(1:2),2,1),reshape(opt_var(end-1:end),2,1),P,T,LAMBDA,PSI);
    CONSFUN = @(opt_var) constraintsFunction(opt_var(1:end-2),opt_var(end-1:end),x,N);
    opt_var = fmincon(COSTFUN,opt_var,[],[],[],[],LB,UB,[],options);    
    theta_opt = reshape(opt_var(end-1:end),2,1);
    u_opt = reshape(opt_var(1:2),2,1);
    help_setpoint = Mtheta*theta_opt;
    % Implement first optimal control move and update plant states.
    x = getTransitions(x, u_opt);
    
    % Save plant states for display.
    xHistory = [xHistory x]; 
    art_refHistory = [art_refHistory help_setpoint(1:2)];
    true_refHistory = [true_refHistory xs];
end


%% Plot

figure;
subplot(2,1,1);
plot(0:iterations,xHistory(1,:),'Linewidth',1);
grid on
xlabel('iterations');
ylabel('x1');
title('x1');
subplot(2,1,2);
plot(0:iterations,xHistory(2,:),'Linewidth',1);
grid on
xlabel('iterations');
ylabel('x2');
title('x2');

figure;
plot_refs=plot(0:iterations,art_refHistory(1,:), 0:iterations, true_refHistory(1,:),0:iterations,xHistory(1,:),'Linewidth',1);
grid on
xlabel('iterations');
% ylabel('references');
title('Artificial vs true reference vs state response');
legend({'artifical reference','real reference', 'state response'},'Location','northeast')
plot_refs(1).Marker='.';
plot_refs(2).Marker='.';

figure;
plot(xHistory(1,:),xHistory(2,:),'Linewidth',1,'Marker','o');
grid on
xlabel('x1');
ylabel('x2');
title('State space');

%% Help functions
%set reference depending on the iteration
function [xs] = set_ref(ct)
    if ct <=30 
        xs=[4.9;0];
    elseif ct > 30 && ct < 60
        xs=[-4.9;0];
    else
        xs=[2;0];
    end
end