% Example Script MS_Regress_Fit.m - MS-VAR estimation

clear;

load('inf_rate.mat')
load('inf_rate_avg.mat')
addpath('../MS_Regress_FEX_1.08/m_Files'); % add 'm_Files' folder to the search path
addpath('../MS_Regress_FEX_1.08/data_Files');

logRet=data_no_avg;  % load some Data.

dep=logRet(:,1);                    % Defining dependent variable from .mat file (this takes one column with 1000 rows) (ONE dependent variable)
constVec=ones(length(dep),1);       % Defining a constant vector in mean equation (just an example of how to do it) (column vector of 1000 1's)
indep=constVec				        % Defining some explanatory variables
k=2;                                % Number of States
S=[1 1];                       	    % Defining which parts of the equation will switch states (column 1 and variance only)
advOpt.distrib='Normal';            % The Distribution assumption ('Normal', 't' or 'GED')
advOpt.std_method=1;                % Defining the method for calculation of standard errors. See pdf file for more details

%size of dep is 1000 x 1
%size of indep is 1000 x 3
%k=2, S= [1 0 0 1] 


[Spec_Out]=MS_Regress_Fit(dep,indep,k,S,advOpt); % Estimating the model

rmpath('m_Files');
rmpath('data_Files'); 


rmpath('m_Files');
rmpath('data_Files'); 