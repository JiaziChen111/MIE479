
tic
clear
clc
%----------------------------------------------------------------------------------------
% STEP 1: RETRIEVING HISTORICAL INFLATION RATES & ALL STOCK DATA AVAILABLE
% NOTE: THIS CAN BE PREPROCESSED

%can be monthly, quarterly or annual
inflation_interval='monthly';
begcol=1;

[inf_file endcol] = return_inflation_file(inflation_interval)



syear=2002;
eyear=2012;
diffyear=eyear-syear;
num_of_time_periods=5;
eachyear=diffyear/num_of_time_periods;
num_of_reop=1;
desired_R=0.008;
desired_transaction=0.0001
T_reb= (diffyear-eachyear)*12/(num_of_reop+1);

    

[MLEinf_data, inf_avg] =fetch_inflation_data(1914,syear,begcol,endcol,inf_file);
size(MLEinf_data)
run 'Symbols_NYSE_SP.m';
[month day year price fail_symbols success_symbols]=...
						all_stock_data(SP500_symb_csv,SP500_symb);

[infmonth infyear infprice ] = all_inflation_data('inflation_rate_1200.csv');
 [rfmonth rfyear rfprice] = all_riskfree_data('riskfreerate2.csv');
%----------------------------------------------------------------------------------------
% STEP 2: SOLVE FOR THE MLE PARAMETERS OF THE REGIME-SWITCHING MODEL
% AS WELL AS MATRIX OF ASSOCIATED REGIME FOR EACH TIME PERIOD

k=2 %DECLARE THE NUMBER OF REGIMES

[Spec_Out p11 p22 p12 p21 var1 var2 var3 ar1 ar2 ar3 c1 c2 c3]= ...
                                  RegimeSwitching_MLE(k,MLEinf_data);

timelength=length(MLEinf_data);

[whichregime, countregime] =regimecount(k,Spec_Out.smoothProb,timelength);

%Parameter 1 is the number of monthly time periods, 2 is the current inflation rate
curr_regime=whichregime(timelength);
% curr_regime=2;
curr_inf_rate=MLEinf_data(timelength);
disp('CHECKPOINT 1');
%----------------------------------------------------------------------------------------
% STEP 3: CONSTRUCT MARKOV TREE FOR INFLATION TREE & FIND
%         THE EXPECTED INFLATION RATE
% markov_periods=10; %this is chosen number of periods for markov tree(in months)

% [expected_inf, tnodes,tnodeval]=exp_inf2(markov_periods,curr_inf_rate,curr_regime...
% 					 ,c1,c2,ar1,ar2,p11,p12,p21,p22);

% i_expected_inf=expected_inf;
% [expected_inf_var] = ...
% 	exp_infvar2(markov_periods,curr_regime,c1,c2,var1,var2,p11,p12,p21,p22);



% i_expected_inf_var=expected_inf_var;
disp('CHECKPOINT 2');

%[expected_inf_var] = exp_infvar2(2,1,3,2,0.5,1,0.95,0.05,0.03,0.97);

%----------------------------------------------------------------------------------------
% TEMP CODE FOR TESTING NEW INFLATION EXPECTED VARIANCE 

markov_periods=10; %this is chosen number of periods for markov tree(in months)

[expected_inf, tnodes,tnodeval]=new_exp_inf2(markov_periods,curr_inf_rate,curr_regime...
                     ,c1,c2,ar1,ar2,p11,p12,p21,p22);
[expected_inf_var] = ...
    new_exp_infvar2(markov_periods,1,tnodeval,var1,var2,p11,p12,p21,p22);

%----------------------------------------------------------------------------------------
% STEP 4 : RETRIEVE THE ASSET AND MARKET PRICES FOR THE DESIRED TIME PERIODS


lcase_month='Jan'
ucase_month=upper(lcase_month);

[tcurrprices currpricenames2 market_prices num_assets2 catch_assets2 totalmonths] = ...
	SEC_fetch_stock_data...
        (lcase_month,eyear,lcase_month,syear,month,day,year,price,success_symbols);

%Use the fetch inflation data to compute the inflation rates and the riskfree rates
[inf_prices] = fetch_inflation_data2...
    (ucase_month,eyear,ucase_month,syear,infmonth,infyear,infprice);

[riskfree_prices] = fetch_inflation_data2...
    (ucase_month,eyear,ucase_month,syear,infmonth,infyear,rfprice);
disp('CHECKPOINT 3');


[beg_indices end_indices]=divide_interval(num_of_time_periods,totalmonths);

asset_prices=cell2mat(tcurrprices);

%Parameters are first number of time divisions, then total months


currassetprices=asset_prices(beg_indices(1):end_indices(1)+1,:);
currmarketprices=market_prices(beg_indices(1):end_indices(1)+1);
currinfprices=inf_prices(beg_indices(1):end_indices(1)+1);
currriskfreeprices=riskfree_prices(beg_indices(1):end_indices(1)+1);



% asset_prices=cell2mat(currprices2);
asset_prices_with_market=[currmarketprices currassetprices];
asset_prices_with_inf=[currinfprices currassetprices];

%----------------------------------------------------------------------------------------
% STEP 5: SOLVE FOR THE MVO PARAMETERS, THE MUS, Q'S AND R'S FOR ALL ASSETS AND 
% THE MARKET OVER THE SPECIFIED TIME PERIODS. ALSO SOLVE FOR THE CAPM BETAS OR 
% EACH ASSET

[asset_mu,asset_Q,asset_r]= solve_mvo_params(currassetprices,1,size(currassetprices,1));

%Solve for only the market
[Market_mu,Market_Q,Market_r]= solve_mvo_params(currmarketprices,1,size(currmarketprices,1));


% Calculate relevant parameters for testing horizon



disp('CHECKPOINT 4');

% desired_R=0.002;
% desired_transaction=0.0001

[Inf_Beta R2_inf]   =solve_beta3(asset_prices_with_inf,1);
i_Inf_Beta=Inf_Beta;


currinfprices2=currinfprices(1:end-1);
xalloc=zeros(num_assets2,1);

[modelMVO_x(1,:) modelMVO_var MVO_adjret_diagQ nom_ret temp_Q] = ...
    main_MVO(currinfprices2,asset_r,expected_inf/100,expected_inf_var,...
				Inf_Beta',desired_R,desired_transaction,xalloc);

i_MVO_adjret_diagQ_InfBeta=MVO_adjret_diagQ;
i_nom_ret=nom_ret;
i_temp_Q=temp_Q;


% [modelMVO_x modelMVO_var temp_Q adj_ret nom_ret] = main_MVO(currinfprices,asset_r,1.8/100,0.04,...
% 							Inf_Beta',0.000002,0.0005,0.05,xalloc);

%-----------------------------------------------------------------------------------
futureassetprices=asset_prices(beg_indices(2):end_indices(num_of_time_periods),:);
futuremarketprices=market_prices(beg_indices(2):end_indices(num_of_time_periods));
futureinfprices=inf_prices(beg_indices(2):end_indices(num_of_time_periods));
futureriskfreeprices=riskfree_prices(beg_indices(2):end_indices(num_of_time_periods));

[future_asset_mu,future_asset_Q,future_asset_r]= ...
    solve_mvo_params(futureassetprices,1,size(futureassetprices,1));

%Solve for only the market
[future_Market_mu,future_Market_Q,future_Market_r]= solve_mvo_params(futuremarketprices,1,size(futuremarketprices,1));




[future_MK1_r] = future_asset_r(:,end);
[future_MK2_r] = future_asset_r(:,end-1);

[benchMVO_x(1,:) benchMVO] = ...
benchmark_MVO(asset_mu', asset_Q, desired_R,desired_transaction, xalloc);

[cumul_benchMVO cumul_modelMVO cumul_SP cumul_MF1 cumul_MF2] = ...
    MVO_comparison(benchMVO_x(1,:)', modelMVO_x(1,:)',future_asset_r,future_Market_r,...
        future_MK1_r,future_MK2_r,syear+eachyear,eyear);

obj_vals = [modelMVO_var benchMVO_x(1,:)*temp_Q*benchMVO_x(1,:)'
            modelMVO_x(1,:)*asset_Q*modelMVO_x(1,:)' benchMVO]


%--------------------------------------------------------------------------------------
%Using our model version of the Sharpe ratio, Preface M

[P_SRATIOS(:,1) S_SRATIOS(:,1)]=calculateSharpeRatio(asset_mu, asset_Q, temp_Q, ...
    modelMVO_x(1,:), benchMVO_x(1,:),modelMVO_var,currriskfreeprices);

% [P_premodel_sratios] = ...
%         (asset_mu*modelMVO_x'-currriskfreeprices(end)/100)/(modelMVO_var^0.5);

% [P_preMVO_sratios P_preMVO_smu P_preMVO_s_sigmap]=...
%     sharperatio2(asset_mu,asset_Q,benchMVO_x,currriskfreeprices(end)/100)

% %--------------------------------------------------------------------------------------
% %Using regular version of the Sharpe ratio, Preface S
% [S_premodel_sratios S_premodel_smu S_premodel_s_sigmap]=...
%     sharperatio2(asset_mu,asset_Q,modelMVO_x,currriskfreeprices(end)/100)

% [S_preMVO_sratios S_preMVO_smu S_postMVO_sigmap]=...
%     sharperatio2(asset_mu,asset_Q,benchMVO_x,currriskfreeprices(end)/100)

% P_SRATIOS = [P_premodel_sratios; P_preMVO_sratios]
% S_SRATIOS = [S_premodel_sratios; S_preMVO_sratios]
% %--------------------------------------------------------------------------------------
% [S_postmodel_sratios S_postmodel_smu S_postmodel_s_sigmap]=...
%     sharperatio2(future_asset_mu,future_asset_Q,modelMVO_x,futureriskfreeprices(end)/100)

% [S_postMVO_sratios S_postMVO_smu S_postMVO_sigmap]=sharperatio2(future_asset_mu, ...
%     future_asset_Q,benchMVO_x,futureriskfreeprices(end)/100)
%----------------------------------------------------------------------------------------
% STEP 6: REBALANCING PORTFOLIOS FOR OPTIMIZED PERFORMANCE

% Let T_reb be the number of periods before rebalancing
% then for the first iteration of MVO comparison, only feed in information
% asset_r and market_r for the relevant time

% e.g. T_reb = T/4 = 1 year i.e. T_reb = 12 (months)
% in our case, T = 5 years * months = 60
% T_reb = T/5 = 12 lol


if (num_of_reop>0)

    MVO_returns_reb(1:T_reb)= ...
        future_asset_r(1:T_reb,:)*benchMVO_x(1,:)';
    inf_returns_reb(1:T_reb) = ...
        future_asset_r(1:T_reb,:)*modelMVO_x(1,:)';



      for p = 1:num_of_reop

     %   RECALCULATE RELEVANT PARAMETERS AND REOPTIMIZE

        markov_periods =  10;

        beg_indices(1) = beg_indices(1) + T_reb;
        end_indices(1) = end_indices(1) + T_reb;



        currassetprices=asset_prices(beg_indices(1):end_indices(1),:);
        currmarketprices=market_prices(beg_indices(1):end_indices(1));
        currinfprices=inf_prices(beg_indices(1):end_indices(1));
        currriskfreeprices=riskfree_prices(beg_indices(1):end_indices(1)+1);


        [expected_inf, tnodes]=exp_inf2(markov_periods,futureinfprices(T_reb*p+1),...
            curr_regime,c1,c2,ar1,ar2,p11,p12,p21,p22);

        [expected_inf_var] = ...
            exp_infvar2(markov_periods,curr_regime,c1,c2,var1,var2,p11,p12,p21,p22);

        asset_prices_with_inf=[currinfprices currassetprices];

        [Inf_Beta R2_inf]   =solve_beta3(asset_prices_with_inf,1);

        currinfprices2=currinfprices(1:end-1);

        [asset_mu,asset_Q,asset_r]= solve_mvo_params(currassetprices,1,size(currassetprices,1));

        [modelMVO_x(p+1,:) modelMVO_var MVO_adjret_diagQ nom_ret] = ...
            main_MVO(currinfprices2,asset_r,expected_inf/100,expected_inf_var,...
    			Inf_Beta',desired_R,desired_transaction,modelMVO_x(p,:)');


        [benchMVO_x(p+1,:) benchMVO] = ...
         benchmark_MVO(asset_mu', asset_Q, desired_R,desired_transaction, benchMVO_x(p,:)');

        MVO_returns_reb(T_reb*p+1:min((p+1)*T_reb,size((future_asset_r),1)))= ...
            future_asset_r((T_reb*p+1):...
                    min((p+1)*T_reb,size((future_asset_r),1)),:)...
                *benchMVO_x(p+1,:)';

        inf_returns_reb(T_reb*p+1:min((p+1)*T_reb,size((future_asset_r),1))) = ...
            future_asset_r(T_reb*p+1:min((p+1)*T_reb,size((future_asset_r),1)),:)...
                *modelMVO_x(p+1,:)';

        [P_SRATIOS(:,p+1) S_SRATIOS(:,p+1)]=...
            calculateSharpeRatio(asset_mu, asset_Q, temp_Q, ...
                modelMVO_x(p+1,:), benchMVO_x(p+1,:), modelMVO_var, currriskfreeprices);

      end

        cumul_MVO_reb(1) = MVO_returns_reb(1);
        cumul_inf_reb(1) = inf_returns_reb(1);



       T = length(MVO_returns_reb);
        
        for i = 2:T
            cumul_MVO_reb(i) = (1+cumul_MVO_reb(i-1))*(1+MVO_returns_reb(i))  - 1;
            cumul_inf_reb(i) = (1+cumul_inf_reb(i-1))*(1+inf_returns_reb(i)) - 1;
        end

        figure
        plot(1:T,cumul_MVO_reb*100, '-b');
        hold all
        plot(1:T,cumul_inf_reb*100, '-r');
        hold all
        plot(1:length(cumul_SP),cumul_SP*100, '-g');
        hold all
        plot(1:T,cumul_MF1*100, '-m');
        hold all
        plot(1:T,cumul_MF2*100, '-c');

      h = {'Standard MVO', 'Inflation Hedged SF', 'S&P500',...
             'Vanguard Wellington Inv','CGM Mutual Fund'};
        h = legend(h);
         
        grid on;

        title(['Comparing Cumulative Returns of Optimal Rebalanced Portfolios and Market'...
                ,num2str(syear+eachyear),' to ',num2str(eyear)]);
        
        xlabel('Time (in months)')
        ylabel('Cumlative Returns in %')
end
toc
%----------------------------------------------------------------------------------------
% STEP 10. AT THE END OF THE LOOP, PLOT THE PORTFOLIO'S PERFORMANCE OVER TIME AND COMPARE IT TO
%    HOW THE STANDARD S&P500 INDEX DID (PLOT BOTH ON SAME GRAPH)
rmpath('m_Files');
rmpath('data_Files');    