% Example Script MS_Regress_Fit.m

% Script for simulating a 3 state MS regression model. Just press f5 to run
% it..

addpath('m_Files'); % add 'm_Files' folder to the search path

clear; 

nr=1000;        % Number of observations in simulation
distrib='Normal';  % The distribution assumption ('Normal' or 't')

Coeff.p=[.8 .1 .1; ...    % Transition matrix (this also defines the value of k)
         .1 .8 .1; ...
         .1 .1 .8];
     
Coeff.S=[1 1 0 0];  % Setting up which variables at indep will have switching effect

% Setting up the coefficients at non switching parameters (each row is each
% variables coefficient). The order is the same as Coeff.S

Coeff.nS_param(1,1)= .2;    % Setting up the coefficients at non switching parameters 
Coeff.nS_param(2,1)=-.2;    % Setting up the coefficients at non switching parameters 

% Setting up the coefficients at non switching parameters (each row is each
% variables coefficient and each collum is each state). This example has
% two switching parameters and 2 states

Coeff.S_param(:,1)=[ .5  .1];    % Setting up the coefficients at switching parameters (state 1)
Coeff.S_param(:,2)=[-.3 -.2];    % Setting up the coefficients at switching parameters (state 2)
Coeff.S_param(:,3)=[ .3  .2];    % Setting up the coefficients at switching parameters (state 3) 

Coeff.Std(1,1)=.03;  % Setting up the standard deviavion of the model at State 1
Coeff.Std(1,2)=.02;  % Setting up the standard deviavion of the model at State 2
Coeff.Std(1,3)=.01;  % Setting up the standard deviavion of the model at State 3

% The explanatory variables are going to be random normal ones, so the mean and std of
% them is needed. 

Coeff.indepMean=[.2 .0 .1  0];  % Setting up the mean of independent (explanatory) variables 
Coeff.indepStd= [.1 .2 .2 .1];  % Setting up the mean of independent (explanatory) variables 

k=size(Coeff.p,1);  % getting the value of k, according to Coeff.p

[Simul_Out]=MS_Regress_Sim(nr,Coeff,k,distrib); % calling simulation function

rmpath('m_Files');