% === MyLake model, version 1.2, 15.03.05 ===
% by Tom Andersen & Tuomo Saloranta, NIVA 2005
%
% VERSION 1.2.1 (two phytoplankton groups are included; variable Cz denotes
% this second group now. Frazil ice included + some small bug-fixes and code rearrangements. Using convection_v12_1a.m code)
%
% Main module
% Code checked by TSA, xx.xx.200x
% Last modified by TSA, 21.08.2007

% Modified to include Fokema-module by Kai Rasmus. 16.5.2007
% Modified to include the latest Fokema module 30.12.2010 by PK
% New matrices: DOCzt1,DOCzt2,DOCzt3,Daily_BB1t,Daily_BB2t,Daily_BB3t,Daily_PBt

% New DIC variable 29.12.2010 (incl. inflow, convection, diffusion) by PK
% New O2 variable 10.2.2011 by PK

function [zz,Az,Vz,tt,Qst,Kzt,Tzt,Czt,Szt,Pzt,Chlzt,PPzt,DOPzt,DOCzt,DICzt,CO2zt,O2zt,NO3zt,NH4zt,SO4zt,HSzt,H2Szt,Fe2zt,Ca2zt,pHzt,CH4zt,Fe3zt,Al3zt,SiO4zt,SiO2zt,diatomzt,O2_sat_relt,O2_sat_abst,BODzt,Qzt_sed,lambdazt,...
        P3zt_sed,P3zt_sed_sc,His,DoF,DoM,MixStat,Wt,surfaceflux,O2fluxt,CO2_eqt,K0t,O2_eqt,K0_O2t,...
        CO2_ppmt,dO2Chlt,dO2BODt,testi1t,testi2t,testi3t,...
         sediment_results] = ...
    solvemodel_v12_1b_ut(M_start,M_stop,Initfile,Initsheet,Inputfile,Inputsheet,Parafile,Parasheet,varargin)

warning off MATLAB:fzero:UndeterminedSyntax %suppressing a warning message
% Inputs (to function)
%       M_start     : Model start date [year, month, day]
%       M_stop      : Model stop date [year, month, day]
%               + Input filenames and sheetnames

% Inputs (received from input module):
%		tt		: Solution time domain (day)
%       In_Z    : Depths read from initial profiles file (m)
%       In_Az   : Areas read from initial profiles file (m2)
%       In_Tz   : Initial temperature profile read from initial profiles file (deg C)
%       In_Cz   : Initial chlorophyll (group 2) profile read from initial profiles file (-)
%       In_Sz   : Initial sedimenting tracer (or suspended inorganic matter) profile read from initial profiles file (kg m-3)
%       In_TPz  : Initial total P profile read from initial profiles file (incl. DOP & Chla & Cz) (mg m-3)
%       In_DOPz  : Initial dissolved organic P profile read from initial profiles file (mg m-3)
%       In_Chlz : Initial chlorophyll (group 1) profile read from initial profiles file (mg m-3)
%       In_DOCz  : Initial DOC profile read from initial profiles file (mg m-3)
%       In_DICz  : Initial DIC profile read from initial profiles file (mg m-3) (PK)
%       In_O2z  : Initial oxygen profile read from initial profiles file (mg m-3) (PK)
%       In_TPz_sed  : Initial total P profile in the sediment compartments read from initial profiles file (mg m-3)
%       In_Chlz_sed : Initial chlorophyll profile  (groups 1+2) in the sediment compartments read from initial profiles file (mg m-3)
%       In_FIM      : Initial profile of volume fraction of inorganic matter in the sediment solids (dry weight basis)
%       Ice0            : Initial conditions, ice and snow thicknesses (m) (Ice, Snow)
%		Wt		        : Weather data
%       Inflow          : Inflow data
%       Phys_par        : Main 23 parameters that are more or less fixed
%       Phys_par_range  : Minimum and maximum values for Phys_par (23 * 2)
%       Phys_par_names  : Names for Phys_par
%       Bio_par         : Main 23 parameters that are more or less site specific
%       Bio_par_range   : Minimum and maximum values for Bio_par (23 * 2)
%       Bio_par_names   : Names for Bio_par

% Outputs (other than Inputs from input module):
%		Qst : Estimated surface heat fluxes ([sw, lw, sl] * tt) (W m-2)
%		Kzt	: Predicted vertical diffusion coefficient (tt * zz) (m2 d-1)
%		Tzt	: Predicted temperature profile (tt * zz) (deg C)
%		Czt	: Predicted chlorophyll (group 2) profile (tt * zz) (-)
%		Szt	: Predicted passive sedimenting tracer (or suspended inorganic matter) profile (tt * zz) (kg m-3)=(g L-1)
%		Pzt	: Predicted dissolved inorganic phosphorus profile (tt * zz) (mg m-3)
%		Chlzt	    : Predicted chlorophyll (group 1) profileo (tt * zz) (mg m-3)
%		PPzt	    : Predicted particulate inorganic phosphorus profile (tt * zz) (mg m-3)
%		DOPzt	    : Predicted dissolved organic phosphorus profile (tt * zz) (mg m-3)
%		DOCzt	    : Predicted dissolved organic carbon (DOC) profile (tt * zz) (mg m-3)
%		DICzt	    : Predicted dissolved inorganic carbon (DIC) profile (tt * zz) (mg m-3) (PK)
%		CO2zt	    : Predicted dissolved carbon dioxide profile (tt * zz) (mg m-3) (PK)
%		O2zt	    : Predicted dissolved oxygen profile (tt * zz) (mg m-3) (PK)
%       O2_sat_rel  : Predicted relative oxygen saturation (PK)
%       O2_sat_abs  : Predicted absolute oxygen saturation (PK)
%		Qz_sed      : Predicted  sediment-water heat flux (tt * zz) (W m-2, normalised to lake surface area)
%       lambdazt    : Predicted average total light attenuation coefficient down to depth z (tt * zz) (m-1)
%       P3zt_sed    : Predicted P conc. in sediment for P (mg m-3), PP(mg kg-1 dry w.) and Chl (mg kg-1 dry w.) (tt * zz * 3)
%       P3zt_sed_sc : Predicted P source from sediment for P, PP and Chl (mg m-3 day-1) (tt * zz * 3)
%       His         : Ice information matrix ([Hi Hs Hsi Tice Tair rho_snow IceIndicator] * tt)
%       DoF, DoM    : Days of freezing and melting (model timestep number)
%       MixStat     : Temporary variables used in model testing, see code (N * tt)

% Fokema outputs
%       CDOMzt      : Coloured dissolved organic matter absorption m-1
%                   : (tt * zz)

% These variables are still global and not transferred by functions
global ies80 O2_diffzt;

tic
disp(['Running MyLake-DOCOMO from ' datestr(datenum(M_start)) ' to ' datestr(datenum(M_stop)) ' ...']);

% ===Switches===
snow_compaction_switch=1;       %snow compaction: 0=no, 1=yes
river_inflow_switch=1;          %river inflow: 0=no, 1=yes
deposition_switch= 0;			%human impact, atm deposition , point source addition %% NEW_DOCOMO
sediment_heatflux_switch=1;     %heatflux from sediments: 0=no, 1=yes
selfshading_switch=1;           %light attenuation by chlorophyll a: 0=no, 1=yes
tracer_switch=1;                %simulate tracers:  0=no, 1=yes
matsedlab_sediments_module = 1; %MATSEDLAB sediment module  %% NEW_DOCOMO
%fokema
photobleaching=0;               %photo bleaching: 0=TSA model, 1=FOKEMA model
floculation_switch=0;                   % floculation according to Wachenfeldt 2008  %% NEW_DOCOMO
% ==============

dt=1.0; %model time step = 1 day (DO NOT CHANGE!)

if (nargin>8) %if optional command line parameter input is used 
    disp('Bypassing input files...Running with input data & parameters given on command line');
    [In_Z,In_Az,tt,In_Tz,In_Cz,In_Sz,In_TPz,In_DOPz,In_Chlz,In_DOCz,In_DICz,In_O2z,In_NO3z,In_NH4z,In_SO4z,In_HSz,In_H2Sz,In_Fe2z,In_Ca2z,In_pHz,In_CH4z,In_Fe3z,In_Al3z,In_SiO4z,In_SiO2z,In_diatomz,In_TPz_sed,In_Chlz_sed,In_FIM,Ice0,Wt,Inflw,...
            Phys_par,Phys_par_range,Phys_par_names,Bio_par,Bio_par_range,Bio_par_names, Deposition]...
        = deal(varargin{:});
else
    %Read input data
    [In_Z,In_Az,tt,In_Tz,In_Cz,In_Sz,In_TPz,In_DOPz,In_Chlz,In_DOCz,In_DICz,In_O2z,In_NO3z,In_NH4z,In_SO4z,In_HSz,In_H2Sz,In_Fe2z,In_Ca2z,In_pHz,In_CH4z,In_Fe3z,In_Al3z,In_SiO4z,In_SiO2z,In_diatomz,In_TPz_sed,In_Chlz_sed,In_FIM,Ice0,Wt,Inflw,...
            Phys_par,Phys_par_range,Phys_par_names,Bio_par,Bio_par_range,Bio_par_names]...
        = modelinputs_v12(M_start,M_stop,Initfile,Initsheet,Inputfile,Inputsheet,Parafile,Parasheet,dt);
 end

load albedot1.mat; %load albedot1 table, in order to save execution time

% Unpack the more fixed parameter values from input array "Phys_par"
dz = Phys_par(1); %grid stepsize (m)

zm = In_Z(end); %max depth
zz = [0:dz:zm-dz]'; %solution depth domain

Kz_K1 = Phys_par(2); % open water diffusion parameter (-)
Kz_K1_ice = Phys_par(3); % under ice diffusion parameter (-)
Kz_N0 = Phys_par(4); % min. stability frequency (s-2)
C_shelter = Phys_par(5); % wind shelter parameter (-)
lat = Phys_par(6); %latitude (decimal degrees)
lon = Phys_par(7); %longitude (decimal degrees)
alb_melt_ice = Phys_par(8);   %albedo of melting ice (-)
alb_melt_snow = Phys_par(9); %albedo of melting snow (-)
PAR_sat = Phys_par(10);         %PAR saturation level for phytoplankton growth (mol(quanta) m-2 s-1) 
f_par = Phys_par(11);           %Fraction of PAR in incoming solar radiation (-)
beta_chl = Phys_par(12);        %Optical cross_section of chlorophyll (m2 mg-1)
lambda_i = Phys_par(13);       %PAR light attenuation coefficient for ice (m-1)
lambda_s = Phys_par(14);       %PAR light attenuation coefficient for snow (m-1)
F_sed_sld = Phys_par(15);      %volume fraction of solids in sediment (= 1-porosity)
I_scV = Phys_par(16); %scaling factor for inflow volume (-)
I_scT = Phys_par(17); %scaling coefficient for inflow temperature (-) 
I_scC = Phys_par(18); %scaling factor for inflow concentration of C (-)
I_scS = Phys_par(19); %scaling factor for inflow concentration of S (-)
I_scTP = Phys_par(20); %scaling factor for inflow concentration of total P (-)
I_scDOP = Phys_par(21); %scaling factor for inflow concentration of diss. organic P (-)
I_scChl = Phys_par(22); %scaling factor for inflow concentration of Chl a (-)
I_scDOC = Phys_par(23); %scaling factor for inflow concentration of DOC  (-)
I_scDIC = Bio_par(32);   %Scaling factor for inflow concentration of DOC  (-)
I_scO = Bio_par(37); %scaling factor for inflow concentration of O2  (-)

I_scNO3 = 1;%Bio_par(37); %scaling factor for inflow concentration of O2  (-)
I_scNH4 =  1;%Bio_par(37); %scaling factor for inflow concentration of O2  (-)
I_scSO4 =  1;%Bio_par(37); %scaling factor for inflow concentration of O2  (-)
I_scFe2 =  1;%Bio_par(37); %scaling factor for inflow concentration of O2  (-)
I_scCa2 =  1;%Bio_par(37); %scaling factor for inflow concentration of O2  (-)
I_scpH = 1;% Bio_par(37); %scaling factor for inflow concentration of O2  (-)
I_scCH4 =  1;%Bio_par(37); %scaling factor for inflow concentration of O2  (-)
I_scFe3 =  1;%Bio_par(37); %scaling factor for inflow concentration of O2  (-)
I_scAl3 =  1;%Bio_par(37); %scaling factor for inflow concentration of O2  (-)
I_scSiO4 =  1;%Bio_par(37); %scaling factor for inflow concentration of O2  (-)
I_scSiO2 =  1;%Bio_par(37); %scaling factor for inflow concentration of O2  (-)
I_scdiatom =  1;%Bio_par(37); %scaling factor for inflow concentration of O2  (-)

% Unpack the more site specific parameter values from input array "Bio_par"

swa_b0 = Bio_par(1); % non-PAR light atteneuation coeff. (m-1)
swa_b1 = Bio_par(2); %  PAR light atteneuation coeff. (m-1)
S_res_epi = Bio_par(3);      %Particle resuspension mass transfer coefficient, epilimnion (m day-1, dry)
S_res_hypo = Bio_par(4);     %Particle resuspension mass transfer coefficient, hypolimnion (m day-1, dry)
H_sed = Bio_par(5);          %height of active sediment layer (m, wet mass)
Psat_L = Bio_par(6);           %Half saturation parameter for Langmuir isotherm
Fmax_L = Bio_par(7);    %Scaling parameter for Langmuir isotherm !!!!!!!!!!!!

w_s = Bio_par(8);              %settling velocity for S (m day-1)  
w_chl = Bio_par(9);            %settling velocity for Chl a (m day-1)
Y_cp = Bio_par(10);            %yield coefficient (chlorophyll to carbon) * (carbon to phosphorus) ratio (-)
m_twty = Bio_par(11);          %loss rate (1/day) at 20 deg C
g_twty = Bio_par(12);          %specific growth rate (1/day) at 20 deg C
k_twty = Bio_par(13);          %specific Chl a to P transformation rate (1/day) at 20 deg C
dop_twty = Bio_par(14);        %specific DOP to P transformation rate (day-1) at 20 deg C
P_half = Bio_par(15);          %Half saturation growth P level (mg/m3)

%NEW!!!===parameters for the 2 group of chlorophyll variable
PAR_sat_2 = Bio_par(16);        %PAR saturation level for phytoplankton growth (mol(quanta) m-2 s-1) 
beta_chl_2 = Bio_par(17);       %Optical cross_section of chlorophyll (m2 mg-1)
w_chl_2 = Bio_par(18);          %Settling velocity for Chl a (m day-1)
m_twty_2 = Bio_par(19);         %Loss rate (1/day) at 20 deg C
g_twty_2 = Bio_par(20);         %Specific growth rate (1/day) at 20 deg C
P_half_2 = Bio_par(21);         %Half saturation growth P level (mg/m3)

oc_DOC = Bio_par(22);           %Optical cross-section of DOC (m2/mg DOC)
qy_DOC = Bio_par(23);           %Quantum yield (mg DOC degraded/mol quanta)
%===========

% Parameters for oxygen

k_BOD = Bio_par(24);            %Organic decomposition rate (1/d)
k_SOD = Bio_par(25);            %Sedimentary oxygen demand (mg m-2 d-1)
theta_bod = Bio_par(26);        %Temperature adjustment coefficient for BOD, T ? 10 °C
theta_bod_ice = Bio_par(27);    %Temperature adjustment coefficient for BOD, T < 10 °C
theta_sod = Bio_par(28);        %Temperature adjustment coefficient for SOD, T ? 10 °C
theta_sod_ice = Bio_par(29);    %Temperature adjustment coefficient for SOD, T < 10 °C
BOD_temp_switch = Bio_par(30);             %Threshold for bod or bod_ice �C

% Parameters for dissolved inorganic carbon

pH = Bio_par(31);               %Lake water pH
Mass_Ratio_C_Chl = Bio_par(33); % Fixed empirical ratio C:Chl (mass/mass)
I_scDIC = Bio_par(32);          %Scaling factor for inflow concentration of DOC  (-)
SS_C = Bio_par(34);             % Carbon fraction in H_netsed_catch
density_org_H_nc = Bio_par(35); % Density of organic fraction in H_netsed_catch [g cm-3]
density_inorg_H_nc = Bio_par(36);% Density of inorganic fraction in H_netsed_catch [g cm-3]


% ====== Other variables/parameters not read from the input file:

Nz=length(zz); %total number of layers in the water column
N_sed=26; %total number of layers in the sediment column

theta_m = exp(0.1*log(2));    %loss and growth rate parameter base, ~1.072
e_par = 240800;               %Average energy of PAR photons (J mol-1)

% diffusion parameterisation exponents
Kz_b1 = 0.43;
Kz_b1_ice  = 0.43; 

% ice & snow parameter values
rho_fw=1000;        %density of freshwater (kg m-3)
rho_ice=910;        %ice (incl. snow ice) density (kg m-3)
rho_new_snow=250;   %new-snow density (kg m-3)
max_rho_snow=450;   %maximum snow density (kg m-3)
L_ice=333500;       %latent heat of freezing (J kg-1)
K_ice=2.1;          %ice heat conduction coefficient (W m-1 K-1)
C1=7.0;             %snow compaction coefficient #1
C2=21.0;            %snow compaction coefficient #2

Tf=0;               %water freezing point temperature (deg C)

F_OM=1e+6*0.012;    %mass fraction [mg kg-1] of P of dry organic matter (assuming 50% of C, and Redfield ratio)

K_sed=0.035;      %thermal diffusivity of the sediments (m2 day-1) 
rho_sed=2500;      %bulk density of the inorganic solids in sediments (kg m-3)
rho_org=1000;      %bulk density of the organic solids in sediments (kg m-3)
cp_sed=1000;       %specific heat capasity of the sediments (J kg-1 K-1)

ksw=1e-3; %sediment pore water mass transfer coefficient (m/d) 
Fmax_L_sed=Fmax_L;
Fstable=655; % Inactive P conc. in inorg. particles (mg/kg dw);     

Frazil2Ice_tresh=0.03;  % treshold (m) where frazil is assumed to turn into a solid ice cover NEW!!!
%=======


% Allocate and initialise output data matrices
Qst = zeros(3,length(tt));
Kzt = zeros(Nz,length(tt));
Tzt = zeros(Nz,length(tt));
Czt = zeros(Nz,length(tt));
Szt = zeros(Nz,length(tt));
Pzt = zeros(Nz,length(tt));
Chlzt = zeros(Nz,length(tt));
PPzt = zeros(Nz,length(tt));
DOPzt = zeros(Nz,length(tt));
DOCzt = zeros(Nz,length(tt));
DICzt = zeros(Nz,length(tt));
CO2zt = zeros(Nz,length(tt));
O2zt = zeros(Nz,length(tt));

NO3zt  = zeros(Nz,length(tt));
NH4zt  = zeros(Nz,length(tt));
SO4zt  = zeros(Nz,length(tt));
HSzt  = zeros(Nz,length(tt));
H2Szt  = zeros(Nz,length(tt));
Fe2zt  = zeros(Nz,length(tt));
Ca2zt  = zeros(Nz,length(tt));
pHzt  = zeros(Nz,length(tt));
CH4zt  = zeros(Nz,length(tt));
Fe3zt  = zeros(Nz,length(tt));
Al3zt  = zeros(Nz,length(tt));
SiO4zt  = zeros(Nz,length(tt));
SiO2zt  = zeros(Nz,length(tt));
diatomzt  = zeros(Nz,length(tt));

O2_diffzt = zeros(Nz,length(tt));
O2_sat_relt = zeros(Nz,length(tt));
O2_sat_abst = zeros(Nz,length(tt));
Qzt_sed = zeros(Nz,length(tt));
lambdazt = zeros(Nz,length(tt));
P3zt_sed = zeros(Nz,length(tt),4); %3-D
P3zt_sed_sc = zeros(Nz,length(tt),3); %3-D
His = zeros(8,length(tt)); %NEW!!!
MixStat = zeros(23,length(tt)); 
% Fokema 
CDOMzt=zeros(Nz,length(tt));
DOCzt1=zeros(Nz,length(tt)); %Fokema-model subpool 1
DOCzt2=zeros(Nz,length(tt)); %Fokema-model subpool 2
DOCzt3=zeros(Nz,length(tt)); %Fokema-model subpool 3
DOC1tfrac=zeros(Nz,length(tt)); %Fokema-model subpool 1
DOC2tfrac=zeros(Nz,length(tt)); %Fokema-model subpool 2 fraction
DOC3tfrac=zeros(Nz,length(tt)); %Fokema-model subpool 3 fraction
Daily_BB1t=zeros(Nz,length(tt)); %Fokema-model subpool 1 daily bacterial decomposition
Daily_BB2t=zeros(Nz,length(tt)); %Fokema-model subpool 2 daily bacterial decomposition
Daily_BB3t=zeros(Nz,length(tt)); %Fokema-model subpool 3 daily bacterial decomposition
Daily_PBt=zeros(Nz,length(tt)); %Fokema-model daily photobleaching

surfaceflux = zeros(1,length(tt)); %CO2 surface flux
CO2_eqt = zeros(1,length(tt));     %CO2 equilibrium concentration
CO2_ppmt = zeros(1,length(tt));    %CO2 fraction in air
K0t = zeros(1,length(tt));         %CO2 solubility coefficient

O2fluxt = zeros(1,length(tt));     %oxygen surface flux
O2_eqt = zeros(1,length(tt));      %O2 equilibrium concentration
K0_O2t = zeros(1,length(tt));      %O2 solubility coefficient
dO2Chlt = zeros(Nz,length(tt));    %Oxygen change due to phytoplankton (mg m-3))
dO2BODt = zeros(Nz,length(tt));    %Oxygen consumption due to BOD (mg m-3))
% dO2SODt = zeros(Nz,length(tt));    %Oxygen consumption due to SOD (mg m-3))
dfloc =  zeros(Nz,length(tt));  % floculation rates
testi1t = zeros(Nz,length(tt));
testi2t = zeros(Nz,length(tt));testi3t = zeros(Nz,length(tt));

% Initial profiles

Az = interp1(In_Z,In_Az,zz);
Vz = dz * (Az + [Az(2:end); 0]) / 2;

T0 = interp1(In_Z,In_Tz,zz+dz/2); % Initial temperature distribution (deg C)
C0 = interp1(In_Z,In_Cz,zz+dz/2); % Initial  chlorophyll (group 2) distribution (mg m-3)
S0 = interp1(In_Z,In_Sz,zz+dz/2); % Initial passive sedimenting tracer (or suspended inorganic matter) distribution (kg m-3)
TP0 = interp1(In_Z,In_TPz,zz+dz/2);	% Initial total P distribution (incl. DOP & Chla & Cz) (mg m-3)
DOP0 = interp1(In_Z,In_DOPz,zz+dz/2);	% Initial dissolved organic P distribution (mg m-3)
Chl0 = interp1(In_Z,In_Chlz,zz+dz/2);	% Initial chlorophyll (group 2) distribution (mg m-3)
DOC0 = interp1(In_Z,In_DOCz,zz+dz/2);	% Initial DOC distribution (mg m-3)
DIC0 = interp1(In_Z,In_DICz,zz+dz/2);   % Initial DIC distribution (mg m-3)
O20 = interp1(In_Z,In_O2z,zz+dz/2);   % Initial oxygen distribution (mg m-3)
TP0_sed = interp1(In_Z,In_TPz_sed,zz+dz/2); % Initial total P distribution in bulk wet sediment ((mg m-3); particles + porewater)
Chl0_sed = interp1(In_Z,In_Chlz_sed,zz+dz/2); % Initial chlorophyll (group 1+2) distribution in bulk wet sediment (mg m-3)
FIM0 = interp1(In_Z,In_FIM,zz+dz/2);     % Initial sediment solids volume fraction of inorganic matter (-) 

NO30 = interp1(In_Z,In_NO3z,zz+dz/2);
NH40 = interp1(In_Z,In_NH4z,zz+dz/2);
SO40 = interp1(In_Z,In_SO4z,zz+dz/2);
HS0 = interp1(In_Z,In_HSz,zz+dz/2);
H2S0 = interp1(In_Z,In_H2Sz,zz+dz/2);
Fe20 = interp1(In_Z,In_Fe2z,zz+dz/2);
Ca20 = interp1(In_Z,In_Ca2z,zz+dz/2);
pH0 = interp1(In_Z,In_pHz,zz+dz/2);
CH40 = interp1(In_Z,In_CH4z,zz+dz/2);
Fe30 = interp1(In_Z,In_Fe3z,zz+dz/2);
Al30 = interp1(In_Z,In_Al3z,zz+dz/2);
SiO40 = interp1(In_Z,In_SiO4z,zz+dz/2);
SiO20 = interp1(In_Z,In_SiO2z,zz+dz/2);
diatom0 = interp1(In_Z,In_diatomz,zz+dz/2);


VolFrac=1./(1+(1-F_sed_sld)./(F_sed_sld*FIM0)); %volume fraction: inorg sed. / (inorg.sed + pore water)

%Fokema
%CDOM0=interp1(In_Z,In_DOCz,zz+dz/2); %%!!!!NB: assumed CDOM=DOC!!!

if any((TP0-DOP0-(Chl0 + C0)./Y_cp-S0*Fstable)<0) %NEW!!!
    error('Sum of initial DOP, stably particle bound P, and P contained in Chl (both groups) a cannot be larger than TP')
end

if any((TP0_sed-DOP0-Chl0_sed./Y_cp-VolFrac*rho_sed*Fstable)<0)
    error('Sum of initial DOP stably, particle bound P, and P contained in Chl_sed a cannot be larger than TP_sed')
end

if (any(FIM0<0)||any(FIM0>1))
    error('Initial fraction of inorganic matter in sediments must be between 0 and 1')
end

if (any(ksw>(H_sed*(1-F_sed_sld))))
    error('Parameter ksw is larger than the volume (thickness) of porewater')
end  %OBS! Ideally should also be that the daily diffused porewater should not be larger 
%than the corresponding water layer volume, but this seems very unlike in practise

Tz = T0;
Cz = C0; % (mg m-3)
Sz = S0; % (kg m-3)
Chlz = Chl0;  % (mg m-3)
DOPz = DOP0;  % (mg m-3)
[Pz, trash] =Ppart(S0./rho_sed,TP0-DOP0-((Chl0 + C0)./Y_cp),Psat_L,Fmax_L,rho_sed,Fstable);  % (mg m-3) NEW!!!
PPz = TP0-DOP0-((Chl0 + C0)./Y_cp)-Pz; % (mg m-3) NEW!!! 
DOCz = DOC0;   % (mg m-3)
DICz = DIC0;   % (mg m-3)
O2z = O20;   % (mg m-3)

NO3z = NO30;
NH4z =NH40;
SO4z = SO40;
HSz = HS0;
H2Sz = H2S0;
Fe2z = Fe20;
Ca2z = Ca20;
pHz = pH0;
CH4z = CH40;
Fe3z = Fe30;
Al3z = Al30;
SiO4z = SiO40;
SiO2z = SiO20;
diatomz = diatom0;


F_IM = FIM0; %initial VOLUME fraction of inorganic particles of total dry sediment solids
% Fokema
%CDOMz = CDOM0;
%CO2z = NaN*zeros(1,length(zz));
%surfflux = 0;

%== P-partitioning in sediments==
%Pdz_store: %diss. inorg. P in sediment pore water (mg m-3)
%Psz_store: %P conc. in inorganic sediment particles (mg kg-1 dry w.)

[Pdz_store, Psz_store]=Ppart(VolFrac,TP0_sed-(Chl0_sed./Y_cp)-DOP0,Psat_L,Fmax_L_sed,rho_sed,Fstable);

%Chlsz_store: %Chla conc. in organic sediment particles (mg kg-1 dry w.)
Chlsz_store = Chl0_sed./(rho_org*F_sed_sld*(1-F_IM)); %(mg kg-1 dry w.)


% assume linear initial temperature profile in sediment (4 deg C at the bottom)
clear Tzy_sed
for j=1:Nz
    Tzy_sed(:,j) = interp1([0.2 10], [Tz(j) 4], [0.2:0.2:2 2.5:0.5:10])';
end

S_resusp=S_res_hypo*ones(Nz,1); %hypolimnion resuspension assumed on the first time step

rho_snow=rho_new_snow;   %initial snow density (kg m-3)
Tice=NaN;                %ice surface temperature (initial value, deg C)
XE_melt=0;               %energy flux that is left from last ice melting (initial value, W m-2)
XE_surf=0;               %energy flux from water to ice (initial value,  J m-2 per day)

%Initialisation of ice & snow variables
Hi=Ice0(1);               %total ice thickness (initial value, m)
WEQs=(rho_snow/rho_fw)*Ice0(2); %snow water equivalent  (initial value, m)
Hsi=0;                %snow ice thickness (initial value = 0 m)
HFrazil=0;              % (initial value, m) NEW!!! 


if ((Hi<=0)&&(WEQs>0))
    error('Mismatch in initial ice and snow thicknesses')    
end

if (Hi<=0)
    IceIndicator=0;     %IceIndicator==0 means no ice cover
else
    IceIndicator=1;
end

pp=1; %initial indexes for ice freezing/melting date arrays
qq=1;
DoF=[]; %initialize
DoM=[]; %initialize

% ============ Sediments module ============
% Allocation and initial sediments profiles concentrations and reading initial concentrations for sediments from file
[sediment_concentrations, sediment_params, sediment_matrix_templates, species_sediments]  = sediments_init( pH, zm, In_Tz(end) );
% ==========================================


% >>>>>> Start of the time loop >>>>>>
Resuspension_counter=zeros(Nz,1); %kg
Sedimentation_counter=zeros(Nz,1); %kg
SS_decr=0; %kg

for i = 1:length(tt)
       
    % Surface heat fluxes (W m-2), wind stress (N m-2) & daylight fraction (-), based on Air-Sea Toolbox
    [Qsw,Qlw,Qsl,tau,DayFrac,DayFracHeating] = heatflux_v12(tt(i),Wt(i,1),Wt(i,2),Wt(i,3),Wt(i,4),Wt(i,5),Wt(i,6),Tz(1), ...
        lat,lon,WEQs,Hi,alb_melt_ice,alb_melt_snow,albedot1);     %Qlw and Qsl are functions of Tz(1)            
    
    % Calculate total mean PAR and non-PAR light extinction coefficient in water (background + due to Chl a)
    lambdaz_wtot_avg=zeros(Nz,1);
    lambdaz_NP_wtot_avg=zeros(Nz,1);
    
        %NEW!!! below additional term for chlorophyll group 2
    if (selfshading_switch==1)
        lambdaz_wtot=swa_b1 * ones(Nz,1) + beta_chl*Chlz + beta_chl_2*Cz; %at layer z
        lambdaz_NP_wtot=swa_b0 * ones(Nz,1) + beta_chl*Chlz + beta_chl_2*Cz; %at layer z
        for j=1:Nz
            lambdaz_wtot_avg(j)=mean(swa_b1 * ones(j,1) + beta_chl*Chlz(1:j) + beta_chl_2*Cz(1:j)); %average down to layer z
            lambdaz_NP_wtot_avg(j)=mean(swa_b0 * ones(j,1) + beta_chl*Chlz(1:j) + beta_chl_2*Cz(1:j)); %average down to layer z 
        end
    else %constant with depth
        lambdaz_wtot=swa_b1 * ones(Nz,1); 
        lambdaz_wtot_avg=swa_b1 * ones(Nz,1); 
        lambdaz_NP_wtot=swa_b0 * ones(Nz,1); 
        lambdaz_NP_wtot_avg=swa_b0 * ones(Nz,1); 
    end %if selfshading...
    
    
    if(IceIndicator==0)
        IceSnowAttCoeff=1; %no extra light attenuation due to snow and ice
    else    %extra light attenuation due to ice and snow
        IceSnowAttCoeff=exp(-lambda_i * Hi) * exp(-lambda_s * (rho_fw/rho_snow)*WEQs);  
    end
    
    Tprof_prev=Tz; %temperature profile at previous time step (for convection_v12_1a.m)

    rho = polyval(ies80,max(0,Tz(:))) + min(Tz(:),0);  % Density (kg/m3)                                                      
    
    % Sediment vertical heat flux, Q_sed 
    % (averaged over the whole top area of the layer, although actually coming only from the "sides")   
    if (sediment_heatflux_switch==1)
        % update top sediment temperatures
        dz_sf = 0.2; %fixed distance between the two topmost sediment layers (m)
        Tzy_sed(1,:) = Tz';    
        Tzy_sed_upd = sedimentheat_v11(Tzy_sed, K_sed, dt);
        Tzy_sed=Tzy_sed_upd;
        Qz_sed=K_sed*rho_sed*cp_sed*(1/dz_sf)*(-diff([Az; 0])./Az) .* (Tzy_sed(2,:)'-Tzy_sed(1,:)'); %(J day-1 m-2)
        %positive heat flux => from sediment to water
    else
        Qz_sed = zeros(Nz,1);
    end
    
    Cw = 4.18e+6;	% Volumetric heat capacity of water (J K-1 m-3)
    
    %Heat sources/sinks:  
    %Total attenuation coefficient profile, two-band extinction, PAR & non-PAR
    Par_Attn=exp([0; -lambdaz_wtot_avg] .* [zz; zz(end)+dz]);
    NonPar_Attn=exp([0; -lambdaz_NP_wtot_avg] .* [zz; zz(end)+dz]);
    
    Attn_z=(-f_par * diff([1; ([Az(2:end);0]./Az).*Par_Attn(2:end)]) + ...
        (-(1-f_par)) * diff([1; ([Az(2:end);0]./Az).*NonPar_Attn(2:end)])); %NEW (corrected 210807) 

    if(IceIndicator==0)
        % 1) Vertical heating profile for open water periods (during daytime heating)
        Qz = (Qsw + XE_melt) * Attn_z; %(W m-2)        
        Qz(1) = Qz(1) + DayFracHeating*(Qlw + Qsl); %surface layer heating    
        XE_melt=0; %Reset    
        dT = Az .* ((60*60*24*dt) * Qz + DayFracHeating*Qz_sed) ./ (Cw * Vz); %Heat source (K day-1) (daytime heating, ice melt, sediment);
        
        % === Frazil ice melting, NEW!!! === %
        postemp=find(dT>0);
        if (isempty(postemp)==0)
            RelT=dT(postemp)./sum(dT(postemp));    
            HFrazilnew=max(0, HFrazil - sum(dT(postemp))*1/((Az(1)*rho_ice*L_ice)/(Cw * Vz(1)))); %
            sumdTnew = max(0, sum(dT(postemp))-(HFrazil*Az(1)*rho_ice*L_ice)/(Cw * Vz(1)));
            dT(postemp)=RelT.*sumdTnew;
            HFrazil=HFrazilnew; 
        end
        % === === === 
    else
        % Vertical heating profile for ice-covered periods (both day- and nighttime)
        Qz = Qsw * IceSnowAttCoeff * Attn_z; %(W/m2)
        dT = Az .* ((60*60*24*dt) * Qz + Qz_sed) ./ (Cw * Vz); %Heat source (K day-1) (solar rad., sediment);          
    end
    
    Tz = Tz + dT;        %Temperature change after daytime surface heatfluxes (or whole day in ice covered period)
    
    % Convective mixing adjustment (mix successive layers until stable density profile)
    % and 
    % Spring/autumn turnover (don't allow temperature jumps over temperature of maximum density)
    [Tz,Cz,Sz,Pz,Chlz,PPz,DOPz,DOCz,DICz,O2z,NO3z,NH4z,SO4z,HSz,H2Sz,Fe2z,Ca2z,pHz,CH4z,Fe3z,Al3z,SiO4z,SiO2z,diatomz] = convection_v12_1a(Tz,Cz,Sz,Pz,Chlz,PPz,DOPz,DOCz,DICz,O2z,NO3z,NH4z,SO4z,HSz,H2Sz,Fe2z,Ca2z,pHz,CH4z,Fe3z,Al3z,SiO4z,SiO2z,diatomz,Tprof_prev,Vz,Cw,f_par,lambdaz_wtot_avg,zz,swa_b0,tracer_switch,1);
    Tprof_prev=Tz; %NEW!!! Update Tprof_prev
    
    if(IceIndicator==0)
        % 2) Vertical heating profile for open water periods (during nighttime heating)
        [Qsw,Qlw_2,Qsl_2,tau,DayFrac,DayFracHeating] = heatflux_v12(tt(i),Wt(i,1),Wt(i,2),Wt(i,3),Wt(i,4),Wt(i,5),Wt(i,6),Tz(1), ...
            lat,lon,WEQs,Hi,alb_melt_ice,alb_melt_snow,albedot1); %Qlw and Qsl are functions of Tz(1)            
        Qz(1) = (1-DayFracHeating)*(Qlw_2 + Qsl_2); %surface layer heating
        Qz(2:end)=0; %No other heating below surface layer   
        dT = Az .* ((60*60*24*dt) * Qz + (1-DayFracHeating)*Qz_sed) ./ (Cw * Vz); %Heat source (K day-1) (longwave & turbulent fluxes);
        
        % === NEW!!! frazil ice melting === %
        postemp=find(dT>0);
        if (isempty(postemp)==0)
            %disp(['NOTE: positive night heat flux at T=' num2str(Tz(postemp),2)]) %NEW
            RelT=dT(postemp)./sum(dT(postemp));    
            HFrazilnew=max(0, HFrazil - sum(dT(postemp))*1/((Az(1)*rho_ice*L_ice)/(Cw * Vz(1)))); %
            sumdTnew = max(0, sum(dT(postemp))-(HFrazil*Az(1)*rho_ice*L_ice)/(Cw * Vz(1)));
            dT(postemp)=RelT.*sumdTnew;
            HFrazil=HFrazilnew; 
        end
        % === === === 
        
        Tz = Tz + dT;         %Temperature change after nighttime surface heatfluxes
        
        % Convective mixing adjustment (mix successive layers until stable density profile)  
        % and 
        % Spring/autumn turnover (don't allow temperature jumps over temperature of maximum density)
        [Tz,Cz,Sz,Pz,Chlz,PPz,DOPz,DOCz,DICz,O2z,NO3z,NH4z,SO4z,HSz,H2Sz,Fe2z,Ca2z,pHz,CH4z,Fe3z,Al3z,SiO4z,SiO2z,diatomz] = convection_v12_1a(Tz,Cz,Sz,Pz,Chlz,PPz,DOPz,DOCz,DICz,O2z,NO3z,NH4z,SO4z,HSz,H2Sz,Fe2z,Ca2z,pHz,CH4z,Fe3z,Al3z,SiO4z,SiO2z,diatomz,Tprof_prev,Vz,Cw,f_par,lambdaz_wtot_avg,zz,swa_b0,tracer_switch,1);
         
        Qlw = DayFracHeating*Qlw + (1-DayFracHeating)*Qlw_2; %total amounts, only for output purposes
        Qsl = DayFracHeating*Qsl + (1-DayFracHeating)*Qsl_2; %total amounts, only for output purposes
    end
    
    % Vertical turbulent diffusion
    g   = 9.81;							% Gravity acceleration (m s-2)
    rho = polyval(ies80,max(0,Tz(:))) + min(Tz(:),0);  % Water density (kg m-3)                                                      
    % Note: in equations of rho it is assumed that every supercooled degree lowers density by 
    % 1 kg m-3 due to frazil ice formation (probably no practical meaning, but included for "safety")
    
    N2  = g * (diff(log(rho)) ./ diff(zz));	% Brunt-Vaisala frequency (s-2) for level (zz+1)              
    if (IceIndicator==0)
        Kz  = Kz_K1 * max(Kz_N0, N2).^(-Kz_b1);	% Vertical diffusion coeff. in ice free season (m2 day-1)
        % for level (zz+1)              
    else 
        Kz  = Kz_K1_ice * max(Kz_N0, N2).^(-Kz_b1_ice); % Vertical diffusion coeff. under ice cover (m2 day-1)
        % for level (zz+1)              
    end
    
    Fi = tridiag_DIF_v11([NaN; Kz],Vz,Az,dz,dt); %Tridiagonal matrix for general diffusion
    
    Tz = Fi \ (Tz);        %Solving new temperature profile (diffusion, sources/sinks already added to Tz above)
    
    % Convective mixing adjustment (mix successive layers until stable density profile)  
    % (don't allow temperature jumps over temperature of maximum density, no summer/autumn turnover here!)
    [Tz,Cz,Sz,Pz,Chlz,PPz,DOPz,DOCz,DICz,O2z,NO3z,NH4z,SO4z,HSz,H2Sz,Fe2z,Ca2z,pHz,CH4z,Fe3z,Al3z,SiO4z,SiO2z,diatomz] = convection_v12_1a(Tz,Cz,Sz,Pz,Chlz,PPz,DOPz,DOCz,DICz,O2z,NO3z,NH4z,SO4z,HSz,H2Sz,Fe2z,Ca2z,pHz,CH4z,Fe3z,Al3z,SiO4z,SiO2z,diatomz,Tprof_prev,Vz,Cw,f_par,lambdaz_wtot_avg,zz,swa_b0,tracer_switch,0);

%% Deposition 
if deposition_switch == 1
  DOPz(1) = DOPz(1) +  (Deposition(i,6) ./ Vz(1)) ; % qty added in mg to the top layer z
end 

    % NEW!!! === Code rearranging 
    % Calculate again the total mean PAR light extinction coefficient in water (background + due to Chl a)
    lambdaz_wtot_avg=zeros(Nz,1);
    
    %NEW!!! below additional term for chlorophyll group 2
    if (selfshading_switch==1)
        lambdaz_wtot=swa_b1 * ones(Nz,1) + beta_chl*Chlz + beta_chl_2*Cz; %at layer z. 
        for j=1:Nz
            lambdaz_wtot_avg(j)=mean(swa_b1 * ones(j,1) + beta_chl*Chlz(1:j) + beta_chl_2*Cz(1:j)); %average down to layer z 
        end
    else %constant with depth
        lambdaz_wtot=swa_b1 * ones(Nz,1); 
        lambdaz_wtot_avg=swa_b1 * ones(Nz,1); 
    end %if selfshading...
    
    %Photosynthetically Active Radiation (for chlorophyll group 1)                               
    H_sw_z=NaN*zeros(Nz,1);
    
    % ===== NEW!!! bug (when Dayfrac==0) fixed 071107 
    if ((IceIndicator==0)&&(DayFrac>0))
        PAR_z=((3/2) / (e_par * DayFrac)) * f_par * Qsw  * exp(-lambdaz_wtot_avg .* zz);   
        %Irradiance at noon (mol m-2 s-1) at levels zz 
    elseif ((IceIndicator==1)&&(DayFrac>0))    %extra light attenuation due to ice and snow
        PAR_z=((3/2) / (e_par * DayFrac)) * IceSnowAttCoeff * f_par *...
            Qsw  * exp(-lambdaz_wtot_avg .* zz); 
    else PAR_z=zeros(Nz,1); %DayFrac==0, polar night
    end
    % =====   
    
    U_sw_z=PAR_z./PAR_sat; %scaled irradiance at levels zz                                                             
    inx_u=find(U_sw_z<=1); %undersaturated
    inx_s=find(U_sw_z>1);  %saturated
    
    H_sw_z(inx_u)=(2/3)*U_sw_z(inx_u);  %undersaturated
    
    dum_a=sqrt(U_sw_z);
    dum_b=sqrt(U_sw_z-1);
    H_sw_z(inx_s)=(2/3)*U_sw_z(inx_s) + log((dum_a(inx_s) + dum_b(inx_s))./(dum_a(inx_s) ...  %saturated
        - dum_b(inx_s))) - (2/3)*(U_sw_z(inx_s)+2).*(dum_b(inx_s)./dum_a(inx_s));
    
  
    %NEW!!!! modified for chlorophyll group 1        
    Growth_bioz=g_twty*theta_m.^(Tz-20) .* (Pz./(P_half+Pz)) .* (DayFrac./(dz*lambdaz_wtot)) .* diff([-H_sw_z; 0]); 
    Loss_bioz=m_twty*theta_m.^(Tz-20);
    R_bioz = Growth_bioz-Loss_bioz;  
   
       %Photosynthetically Active Radiation (for chlorophyll group 2) NEW!!!                               
    H_sw_z=NaN*zeros(Nz,1);
     
    U_sw_z=PAR_z./PAR_sat_2; %scaled irradiance at levels zz                                                             
    inx_u=find(U_sw_z<=1); %undersaturated
    inx_s=find(U_sw_z>1);  %saturated
    
    H_sw_z(inx_u)=(2/3)*U_sw_z(inx_u);  %undersaturated
    
    dum_a=sqrt(U_sw_z);
    dum_b=sqrt(U_sw_z-1);
    H_sw_z(inx_s)=(2/3)*U_sw_z(inx_s) + log((dum_a(inx_s) + dum_b(inx_s))./(dum_a(inx_s) ...  %saturated
        - dum_b(inx_s))) - (2/3)*(U_sw_z(inx_s)+2).*(dum_b(inx_s)./dum_a(inx_s));
    
    Growth_bioz_2=g_twty_2*theta_m.^(Tz-20) .* (Pz./(P_half_2+Pz)) .* (DayFrac./(dz*lambdaz_wtot)) .* diff([-H_sw_z; 0]); 
    Loss_bioz_2=m_twty_2*theta_m.^(Tz-20);
    R_bioz_2 = Growth_bioz_2-Loss_bioz_2;
        
    %growth rate is limited by available phosphorus 
    exinx = find( (R_bioz.*Chlz*dt + R_bioz_2.*Cz*dt)>(Y_cp*Pz) );
    
    if (isempty(exinx)==0)    
    R_bioz_ratio = (R_bioz(exinx).*Chlz(exinx)*dt)./((R_bioz(exinx).*Chlz(exinx)*dt) + (R_bioz_2(exinx).*Cz(exinx)*dt)); %fraction of Growth rate 1 of total growth rate
    R_bioz(exinx) = R_bioz_ratio.*(Y_cp*Pz(exinx)./(Chlz(exinx)*dt));
    R_bioz_2(exinx) = (1-R_bioz_ratio).*(Y_cp*Pz(exinx)./(Cz(exinx)*dt)); 
    end
%================================    
   
    dDOP =  dop_twty * DOPz .* theta_m.^(Tz-20);  %Mineralisation to P
    DOPz = Fi \ (DOPz - dDOP);         %Solving new dissolved inorganic P profile (diffusion)
    
    % Suspended solids, particulate inorganic P 
    Fi_ad = tridiag_HAD_v11([NaN; Kz],w_s,Vz,Az,dz,dt); %Tridiagonal matrix for advection and diffusion 
    
    dSz_inorg = rho_sed*S_resusp.*F_IM.*(-diff([Az; 0])./Vz);  % Dry inorganic particle resuspension source from sediment (kg m-3 day-1)
    Sz = Fi_ad \ (Sz + dSz_inorg);           %Solving new suspended solids profile (advection + diffusion)        
    
    dPP = dSz_inorg.*Psz_store;  % PP resuspension source from sediment((kg m-3 day-1)*(mg kg-1) = mg m-3 day-1) 
    PPz = Fi_ad \ (PPz + dPP);     %Solving new suspended particulate inorganic P profile (advection + diffusion)
        
    %Chlorophyll, Group 1+2 resuspension (now divided 50/50 between the groups)
    dSz_org = rho_org*S_resusp.*(1-F_IM).*(-diff([Az; 0])./Vz);  %Dry organic particle resuspension source from sediment (kg m-3 day-1)
    dChl_res = dSz_org.*Chlsz_store;  %Chl a resuspension source from sediment resusp. ((kg m-3 day-1)*(mg kg-1) = mg m-3 day-1);  
    
    %Chlorophyll, Group 1
    dChl_growth = Chlz .* R_bioz; %Chl a growth source
    dChl = dChl_growth + 0.5*dChl_res; % Total Chl a source (resuspension 50/50 between the two groups, NEW!!!)
    Fi_ad = tridiag_HAD_v11([NaN; Kz],w_chl,Vz,Az,dz,dt); %Tridiagonal matrix for advection and diffusion    
    Chlz = Fi_ad \ (Chlz + dChl);  %Solving new phytoplankton profile (advection + diffusion) (always larger than background level)
    
    %Chlorophyll, Group 2
    dCz_growth = Cz .* R_bioz_2; %Chl a growth source 
    dCz = dCz_growth + 0.5*dChl_res; % Total Chl a source (resuspension 50/50 between the two groups, NEW!!!)
    Fi_ad = tridiag_HAD_v11([NaN; Kz],w_chl_2,Vz,Az,dz,dt); %Tridiagonal matrix for advection and diffusion    
    Cz = Fi_ad \ (Cz + dCz);  %Solving new phytoplankton profile (advection + diffusion) (always larger than background level)

    %Dissolved inorganic phosphorus
    dP = dDOP - (dChl_growth + dCz_growth)./ Y_cp; %DOP source, P sink = Chla growth source !!!NEW
    Pz = Fi \ (Pz + dP); %Solving new dissolved inorganic P profile (diffusion)
    
    %Dissolved organic carbon
    % - current version
    Kd_old=0;
    Theeta=0;
    Currdate=datevec(tt(i)); %Date
    %Date=0;
    Date=Currdate(1,2); %Month number
    if (photobleaching==1) %Fokema
        %[DOCz,Kd_new] = fokema(DOCz,Kd_old,Qsw,Tz,Theeta,Date,zz);
        DOCz1 = 0.0775.*DOCz; %Subpools
        DOCz2 = 0.1486.*DOCz;
        DOCz3 = 0.7739.*DOCz;
        [DOCz1_new,DOCz2_new,DOCz3_new,DOC1frac,DOC2frac,DOC3frac,Kd_new,Daily_BB1,Daily_BB2,Daily_BB3,Daily_PB] = fokema_new(DOCz1,DOCz2,DOCz3,Kd_old,Qsw,Tz,Theeta,Date,zz);
        DOCz = DOCz1_new + DOCz2_new + DOCz3_new; %Total DOC
        DOCz = Fi \ DOCz; %Solving new dissolved organic C profile (diffusion)
        %DOCz1_new = Fi \ DOCz1_new; %Solving new dissolved organic C profile (diffusion)
        %DOCz2_new = Fi \ DOCz2_new; %Solving new dissolved organic C profile (diffusion)
        %DOCz3_new = Fi \ DOCz3_new; %Solving new dissolved organic C profile (diffusion)
        
    else %TSA model
       dDOC = -oc_DOC*qy_DOC*f_par*(1/e_par)*(60*60*24*dt)*Qsw*Attn_z; %photochemical degradation
           %[m2/mg_doc]*[mg_doc/mol_qnt]*[-]*[mol_qnt/J]*[s/day]*[J/s/m2]*[-] = [1/day]
       DOCz = Fi \ (DOCz + dDOC.*DOCz); %Solving new dissolved organic C profile (diffusion)
    end
    
    %floculation
    if (floculation_switch==1) %Fokema
        
        dfloc = 3.5 * exp(0.25 .* DOCz);
        
        DOCz = max(0, DOCz - dfloc);
        DOCz = Fi \ DOCz;
        
        Sz = Sz + dfloc;
        Sz = Fi \ Sz;
        
    end
    
    %Oxygen
    
    %Oxygen production/consumption in phytoplankton growth & mineralization
    dO2_Chl = 110.*(dChl_growth+dCz_growth);
    
    %Biochemical & sediment oxygen demand
    
    BOD = 1*ones(length(zz),1);
    theta_b = NaN*ones(length(zz),1);
    %theta_s = NaN*ones(length(zz),1);
    
    for k = 1:length(Tz)
        if(Tz(k)<BOD_temp_switch)
            theta_b(k) = theta_bod_ice;
            %theta_s(k) = theta_sod_ice;
        else
            theta_b(k) = theta_bod;
            %theta_s(k) = theta_sod;
        end
    end
  
     if(IceIndicator==0)
        % BOD = 1.5*BOD7*ones(length(zz),1);
         dO2_BOD = (32/12) .* DOCz .* k_BOD.*theta_b.^(Tz-20);
%         dO2_BOD = k_BOD*theta_bod.^(Tz-20).*BOD;
%         dO2_SOD = k_SOD.*theta_sod.^(Tz-20).*(-diff([Az; 0])./Vz);
     else
%         BOD_ice = 1.5*BOD7_ice*ones(length(zz),1);
         dO2_BOD = DOCz .* k_BOD.*theta_b.^(Tz-20);
%         dO2_BOD = k_BOD*theta_bod_ice.^(Tz-20).*BOD_ice;
%         dO2_SOD = k_SOD_ice.*theta_sod_ice.^(Tz-20).*(-diff([Az; 0])./Vz);   
%     %    dO2_BOD = k_BOD.*0.25.*Tz.*BOD;
%     %    dO2_SOD = k_SOD.*0.25.*Tz.*(-diff([Az; 0])./Vz); 
     end
    
    O2_old = O2z;
    O2z = max(0,O2z + dO2_Chl - dO2_BOD);% - dO2_SOD);
    O2_diff = O2z - O2_old;
    O2_new = O2z;

    %Oxygen surface flux
    if(IceIndicator==0)
        [O2z(1),O2flux,O2_eq,K0_O2] = oxygenflux(O2z(1),C_shelter^(1/3)*Wt(i,6),Wt(i,5),Tz(1),dz);
    else
        O2flux = 0;         
    end
            
    O2z = Fi \ O2z; %Solving new dissolved oxygen profile (diffusion)
    DOCz = max(0, DOCz - (12/32) * dO2_BOD);
    DOCz = Fi \ DOCz;
   
    %Dissolved inorganic carbon
    %DIC partitioning in water
    [CO2z,CO2frac] = carbonequilibrium(DICz,Tz,pH);
    
	% CO2 production by degraded DOC
    CO2z = max(0,CO2z + 1.375.*(-O2_diff));
    DICz = CO2z./CO2frac;
    %TC = Tz(1); %For monitoring only
    
    %Carbon dioxide surface flux
    if(IceIndicator==0)
        [CO2z(1),surfflux,CO2_eq,K0,CO2_ppm] = carbondioxideflux(CO2z(1),C_shelter^(1/3)*Wt(i,6),Wt(i,5),Tz(1),dz,tt(i));
        DICz(1) = CO2z(1)/CO2frac(1);
    else
        surfflux=0;
    end
    
    DICz = Fi \ DICz; %Solving new DIC profile (diffusion)
    
    %==================================
    %Dissolved inorganic carbon - version II 
%     
%     pH = 7*ones(1,length(zz));
%     TC = Tz(1); %For monitoring only
%     [CO2z,CO2frac,C_acid,C_basic] = carbonequilibrium(DICz,Tz,pH);
%        
%     C_acid = C_acid + 1.375.*(-O2_erotus); 
%     DICz = C_acid+C_basic;    
%     [CO2z,CO2frac,C_acid,C_basic] = carbonequilibrium(DICz,Tz,pH);    
%     if(IceIndicator==0)
%         [CO2z(1),surfflux,CO2_eq,K0,CO2_ppm] = carbondioxideflux(CO2z(1),Wt(i,6),Wt(i,5),Tz(1),dz,tt(i));
%         DICz(1) = CO2z(1)/CO2frac(1);
%     else
%         surfflux=0;
%     end
%     DICz = Fi \ DICz;
    %==================================
    
    %Sediment-water exchange (DOP source neglected)
    %-porewater to water
    
    PwwFrac=ksw*(-diff([Az; 0]))./Vz; %fraction between resuspended porewater and water layer volumes
    %PwwFrac=(((1-F_sed_sld)/F_sed_sld)*S_resusp.*(-diff([Az; 0]))./Vz); %fraction between resuspended porewater and water layer volumes
    EquP1 = (1-PwwFrac).*Pz + PwwFrac.*Pdz_store; %Mixture of porewater and water 
    dPW_up = EquP1-Pz; %"source/sink" for output purposes
    
    %-water to porewater 
    PwwFrac=ksw./((1-F_sed_sld)*H_sed); %NEW testing 3.8.05; fraction between resuspended (incoming) water and sediment layer volumes
    %PwwFrac=S_resusp./(F_sed_sld*H_sed); %fraction between resuspended (incoming) water and sediment layer volumes
    EquP2 = PwwFrac.*Pz + (1-PwwFrac).*Pdz_store; %Mixture of porewater and water 
    dPW_down = EquP2-Pdz_store; %"source/sink" for output purposes
    
    %-update concentrations
    Pz = EquP1;
    Pdz_store=EquP2;
    
    
    %Calculate the thickness ratio of newly settled net sedimentation and mix these
    %two to get new sediment P concentrations in sediment (taking into account particle resuspension) 
    delPP_inorg=NaN*ones(Nz,1); %initialize
    delC_inorg=NaN*ones(Nz,1); %initialize
    delC_org=NaN*ones(Nz,1); %initialize 
    delC_org2=NaN*ones(Nz,1); %initialize % NEW!!! for chlorophyll group 2
    delC_org3=NaN*ones(Nz,1); % initialize for DOC floculation
    
    delA=diff([Az; 0]); %Area difference for layer i (OBS: negative)
    meanA=0.5*(Az+[Az(2:end); 0]);
    
    %sedimentation is calculated from "Funnelling-NonFunnelling" difference
    %(corrected 03.10.05)
    delPP_inorg(1)=(0 - PPz(1)*delA(1)./meanA(1))./(dz/(dt*w_s) + 1);
    delC_inorg(1)=(0 - Sz(1)*delA(1)./meanA(1))./(dz/(dt*w_s) + 1);
    delC_org(1)=(0 - Chlz(1)*delA(1)./meanA(1))./(dz/(dt*w_chl) + 1);
    delC_org2(1)= (0 - Cz(1)*delA(1)./meanA(1))./(dz/(dt*w_chl_2) + 1); % NEW!!!  for chlorophyll group 2
    delC_org3(1)= (0 - Sz(1)*delA(1)./meanA(1))./(dz/(dt*w_s) + 1); % NEW!!!  for DOC floculates
    
    for ii=2:Nz
        delPP_inorg(ii)=(delPP_inorg(ii-1) - PPz(ii)*delA(ii)./meanA(ii))./(dz/(dt*w_s) + 1); %(mg m-3)
        delC_inorg(ii)=(delC_inorg(ii-1) - Sz(ii)*delA(ii)./meanA(ii))./(dz/(dt*w_s) + 1); %(kg m-3)
        delC_org(ii)=(delC_org(ii-1) - Chlz(ii)*delA(ii)./meanA(ii))./(dz/(dt*w_chl) + 1); %(mg m-3)
        delC_org2(ii)=(delC_org2(ii-1) - Cz(ii)*delA(ii)./meanA(ii))./(dz/(dt*w_chl_2) + 1); %(mg m-3) % NEW!!! for chlorophyll group 2
        delC_org3(ii)=(delC_org3(ii-1) - Sz(ii)*delA(ii)./meanA(ii))./(dz/(dt*w_s) + 1); %(mg m-3) % NEW!!! for DOC floculation
    end
    
    H_netsed_catch=max(0, (Vz./(-diff([Az; 0]))).*delC_inorg./rho_sed - F_IM.*S_resusp); %inorganic(m day-1, dry), always positive
    H_netsed_org=max(0, (Vz./(-diff([Az; 0]))).*(delC_org+delC_org2+delC_org3)./(F_OM*Y_cp*rho_org) - (1-F_IM).*S_resusp);
    %organic (m day-1, dry), always positive,  NEW!!! for chlorophyll group 2
    
    H_totsed=H_netsed_org + H_netsed_catch;  %total (m day-1), always positive
    
    F_IM_NewSed=F_IM;    
    inx=find(H_totsed>0);
    F_IM_NewSed(inx)=H_netsed_catch(inx)./H_totsed(inx); %volume fraction of inorganic matter in net settling sediment
    
    NewSedFrac = min(1, H_totsed./(F_sed_sld*H_sed)); %Fraction of newly fallen net sediment of total active sediment depth, never above 1
    NewSedFrac_inorg = min(1, H_netsed_catch./(F_IM.*F_sed_sld*H_sed)); %Fraction of newly fallen net inorganic sediment of total active sediment depth, never above 1
    NewSedFrac_org = min(1, H_netsed_org./((1-F_IM).*F_sed_sld*H_sed)); %Fraction of newly fallen net organic sediment of total active sediment depth, never above 1
    
    %Psz_store: %P conc. in inorganic sediment particles (mg kg-1 dry w.)
    Psz_store = (1-NewSedFrac_inorg).*Psz_store + NewSedFrac_inorg.*PPz./Sz; %(mg kg-1)  
    
    %Update counters
    Sedimentation_counter = Sedimentation_counter + Vz.*(delC_inorg + (delC_org+delC_org2+delC_org3)./(F_OM*Y_cp)); %Inorg.+Org. (kg)
    Resuspension_counter = Resuspension_counter + Vz.*(dSz_inorg + dSz_org); %Inorg.+Org. (kg) 
       
    %Chlsz_store (for group 1+2): %Chl a conc. in sediment particles (mg kg-1 dry w.)
    Chlsz_store = (1-NewSedFrac_org).*Chlsz_store + NewSedFrac_org.*F_OM*Y_cp; %(mg kg-1)     
    %Subtract degradation to P in pore water
    Chlz_seddeg = k_twty * Chlsz_store .* theta_m.^(Tz-20);
    Chlsz_store = Chlsz_store - Chlz_seddeg;
    Pdz_store=Pdz_store + Chlz_seddeg .* (rho_org*F_sed_sld*(1-F_IM))./Y_cp;
    
    %== P-partitioning in sediments==   
    VolFrac=1./(1+(1-F_sed_sld)./(F_sed_sld*F_IM)); %volume fraction: inorg sed. / (inorg.sed + pore water)
    TIP_sed =rho_sed*VolFrac.*Psz_store + (1-VolFrac).*Pdz_store; %total inorganic P in sediments (mg m-3) 
    [Pdz_store, Psz_store]=Ppart(VolFrac,TIP_sed,Psat_L,Fmax_L_sed,rho_sed,Fstable);
    %calculate new VOLUME fraction of inorganic particles of total dry sediment
    F_IM=min(1,((k_twty *(1-F_IM).*theta_m.^(Tz-20)) + F_IM)).*(1-NewSedFrac) + F_IM_NewSed.*NewSedFrac; 
    
    
    
    % Inflow calculation
    % Inflw(:,1) Inflow volume (m3 day-1)
    % Inflw(:,2) Inflow temperature (deg C)
    % Inflw(:,3) Inflow chlorophyll (group 2) concentration (-)
    % Inflw(:,4) Inflow sedimenting tracer (or suspended inorganic matter) concentration (kg m-3)
    % Inflw(:,5) Inflow total phosphorus (TP) concentration  (incl. DOP & Chla) (mg m-3)
    % Inflw(:,6) Inflow dissolved organic phosphorus (DOP) concentration (mg m-3)
    % Inflw(:,7) Inflow chlorophyll (group 1) concentration (mg m-3)
    % Inflw(:,8) Inflow DOC concentration (mg m-3)
    % Inflw(:,9) Inflow DIC concentration (mg m-3)
    % Inflw(:,10) Inflow O2 concentration (mg m-3)
       
    if (river_inflow_switch==1)
        Iflw = I_scV * Inflw(i,1); % (scaled) inflow rate
        Iflw_T = I_scT + Inflw(i,2); %(adjusted) inflow temperature
        if (Iflw_T<Tf) %negative temperatures changed to Tf
            Iflw_T=Tf;
        end
        Iflw_C = I_scC * Inflw(i,3); %(scaled) inflow C concentration
        Iflw_S = I_scS * Inflw(i,4); %(scaled) inflow S concentration
        Iflw_TP = I_scTP * Inflw(i,5); %(scaled) inflow TP concentration (incl. DOP & Chla)
        Iflw_DOP = I_scDOP * Inflw(i,6); %(scaled) inflow DOP concentration
        Iflw_Chl = I_scChl * Inflw(i,7); %(scaled) inflow Chl a concentration
        Iflw_DOC = I_scDOC * Inflw(i,8); %(scaled) inflow DOC concentration
        Iflw_DIC = I_scDIC * Inflw(i,9); %(scaled) inflow DIC concentration
        Iflw_O2 = I_scO * Inflw(i,10); %(scaled) inflow O2 concentration   
       
        % inflow HS and H2S are neglected
        
      Iflw_NO3 = I_scNO3 * Inflw(i,11); 
      Iflw_NH4 = I_scNH4 * Inflw(i,12); 
      Iflw_SO4 = I_scSO4 * Inflw(i,13); 
      Iflw_Fe2 = I_scFe2 * Inflw(i,14); 
      Iflw_Ca2 = I_scCa2 * Inflw(i,15); 
      Iflw_pH = I_scpH * Inflw(i,16); 
      Iflw_CH4 = I_scCH4 * Inflw(i,17); 
      Iflw_Fe3 = I_scFe3 * Inflw(i,18); 
      Iflw_Al3 = I_scAl3 * Inflw(i,19); 
      Iflw_SiO4 = I_scSiO4 * Inflw(i,20); 
      Iflw_SiO2 = I_scSiO2 * Inflw(i,21); 
      Iflw_diatom = I_scdiatom * Inflw(i,22); 

   %Added suspended solids correction: minimum allowed P bioavailability factor is 0.1 
        if any((1-(Iflw_DOP+(Iflw_Chl+Iflw_C)./Y_cp)./Iflw_TP-(Iflw_S*Fstable)./Iflw_TP)<0.1); % NEW!!!!
            Iflw_S_dum = (1 - (Iflw_DOP+(Iflw_Chl+Iflw_C)./Y_cp)./Iflw_TP - 0.1).*(Iflw_TP./Fstable); %NEW!!!
            SS_decr=SS_decr+(Iflw_S-Iflw_S_dum)*Iflw;
            Iflw_S=Iflw_S_dum;
        end
        
        if any((Iflw_TP-Iflw_DOP-(Iflw_Chl+Iflw_C)./Y_cp-Iflw_S*Fstable)<0)  %NEW!!!
            error('Sum of DOP, inactive PP, and P contained in Chl a (both groups) in inflow cannot be larger than TP')
        end
        
        
        if(Iflw>0)
            if (isnan(Iflw_T))
                lvlD=0;
                Iflw_T=Tz(1);
            else
                rho = polyval(ies80,max(0,Tz(:)))+min(Tz(:),0);	% Density (kg/m3)
                rho_Iflw=polyval(ies80,max(0,Iflw_T))+min(Iflw_T,0);
                lvlG=find(rho>=rho_Iflw);
                if (isempty(lvlG))
                    lvlG=length(rho);
                end
                lvlD=zz(lvlG(1)); %level zz above which inflow is put
            end %if isnan...
            
            
            %Changes in properties due to inflow 
            dummy=IOflow_v11(dz, zz, Vz, Tz, lvlD, Iflw, Iflw_T); Tz=dummy; %Temperature
            dummy=IOflow_v11(dz, zz, Vz, Sz, lvlD, Iflw, Iflw_S); Sz=dummy; %Sedimenting tracer
            dummy=IOflow_v11(dz, zz, Vz, DOPz, lvlD, Iflw, Iflw_DOP); DOPz=dummy; %Particulate organic P
            
            TIPz=Pz + PPz; % Total inorg. phosphorus (excl. Chla and DOP) in the water column (mg m-3)
            
            dummy=IOflow_v11(dz, zz, Vz, TIPz, lvlD, Iflw, Iflw_TP-((Iflw_Chl+Iflw_C)./Y_cp)-Iflw_DOP); %NEW!!!
            TIPz=dummy; %Total inorg. phosphorus (excl. Chla and DOP) 
                        
            %== P-partitioning in water==
            [Pz, trash]=Ppart(Sz./rho_sed,TIPz,Psat_L,Fmax_L,rho_sed,Fstable);
            PPz=TIPz-Pz;
            
            dummy=IOflow_v11(dz, zz, Vz, Cz, lvlD, Iflw, Iflw_C); Cz=dummy; %Chlorophyll (group 2) 
            dummy=IOflow_v11(dz, zz, Vz, Chlz, lvlD, Iflw, Iflw_Chl); Chlz=dummy; %Chlorophyll (group 1)            
            dummy=IOflow_v11(dz, zz, Vz, DOCz, lvlD, Iflw, Iflw_DOC); DOCz=dummy; %DOC            
            dummy=IOflow_v11(dz, zz, Vz, DICz, lvlD, Iflw, Iflw_DIC); DICz=dummy; %DIC            
            dummy=IOflow_v11(dz, zz, Vz, O2z, lvlD, Iflw, Iflw_O2); O2z=dummy; %O2            
            dummy=IOflow_v11(dz, zz, Vz, NO3z, lvlD, Iflw, Iflw_NO3); NO3z=dummy; %NO3            
            dummy=IOflow_v11(dz, zz, Vz, NH4z, lvlD, Iflw, Iflw_NH4); NH4z=dummy; %NH4            
            dummy=IOflow_v11(dz, zz, Vz, SO4z, lvlD, Iflw, Iflw_SO4); SO4z=dummy; %SO4            
            dummy=IOflow_v11(dz, zz, Vz, Fe2z, lvlD, Iflw, Iflw_Fe2); Fe2z=dummy; %Fe2            
            dummy=IOflow_v11(dz, zz, Vz, Ca2z, lvlD, Iflw, Iflw_Ca2);Ca2z=dummy; %Ca2            
            dummy=IOflow_v11(dz, zz, Vz, pHz, lvlD, Iflw, Iflw_pH); pHz=dummy; %pH            
            dummy=IOflow_v11(dz, zz, Vz, CH4z, lvlD, Iflw, Iflw_CH4); CH4z=dummy; %CH4            
            dummy=IOflow_v11(dz, zz, Vz, Fe3z, lvlD, Iflw, Iflw_Fe3); Fe3z=dummy; %Fe3
            dummy=IOflow_v11(dz, zz, Vz, Al3z, lvlD, Iflw, Iflw_Al3); Al3z=dummy; %Al3            
            dummy=IOflow_v11(dz, zz, Vz, SiO4z, lvlD, Iflw, Iflw_SiO4); SiO4z=dummy; %SiO4
            dummy=IOflow_v11(dz, zz, Vz, Al3z, lvlD, Iflw, Iflw_SiO2); SiO2z=dummy; %SiO2            
            dummy=IOflow_v11(dz, zz, Vz, SiO4z, lvlD, Iflw, Iflw_diatom); diatomz=dummy; %diatom
        else
            lvlD=NaN;
        end %if(Iflw>0)
        
    else
        Iflw=0; % (scaled) inflow rate
        Iflw_T = NaN; %(adjusted) inflow temperature
        Iflw_C = NaN; %(scaled) inflow C concentration
        Iflw_S = NaN; %(scaled) inflow S concentration
        Iflw_TP = NaN; %(scaled) inflow TP concentration (incl. DOP & Chla)
        Iflw_DOP = NaN; %(scaled) inflow DOP concentration
        Iflw_Chl = NaN; %(scaled) inflow Chl a concentration
        Iflw_DOC = NaN; %(scaled) inflow DOC concentration
        Iflw_DIC = NaN; %(scaled) inflow DIC concentration
        Iflw_O2 = NaN; %(scaled) inflow concentration
        Iflw_NO3 = NaN; %(scaled) inflow concentration
        Iflw_NH4 = NaN; %(scaled) inflow concentration
        Iflw_SO4 = NaN; %(scaled) inflow  concentration
        Iflw_Fe2 = NaN; %(scaled) inflow concentration
        Iflw_Ca2 = NaN; %(scaled) inflow concentration
        Iflw_pH = NaN; %(scaled) inflow concentration
        Iflw_CH4 = NaN; %(scaled) inflow concentration
        Iflw_Fe3 = NaN; %(scaled) inflow concentration
        Iflw_Al3 = NaN; %(scaled) inflow concentration
        Iflw_SiO4 = NaN; %(scaled) inflow concentration
        Iflw_SiO2 = NaN; %(scaled) inflow concentration
        Iflw_diatom = NaN; %(scaled) inflow concentration
        lvlD=NaN;     
    end  %if (river_inflow_switch==1)
    
    % Convective mixing adjustment (mix successive layers until stable density profile,  no summer/autumn turnover here!)  
    
    [Tz,Cz,Sz,Pz,Chlz,PPz,DOPz,DOCz,DICz,O2z,NO3z,NH4z,SO4z,HSz,H2Sz,Fe2z,Ca2z,pHz,CH4z,Fe3z,Al3z,SiO4z,SiO2z,diatomz] = convection_v12_1a(Tz,Cz,Sz,Pz,Chlz,PPz,DOPz,DOCz,DICz,O2z,NO3z,NH4z,SO4z,HSz,H2Sz,Fe2z,Ca2z,pHz,CH4z,Fe3z,Al3z,SiO4z,SiO2z,diatomz,Tprof_prev,Vz,Cw,f_par,lambdaz_wtot_avg,zz,swa_b0,tracer_switch,0);

    if (IceIndicator==0)
        
        TKE=C_shelter*Az(1)*sqrt(tau^3/rho(1))*(24*60*60*dt); %Turbulent kinetic energy (J day-1) over the whole lake
        
        %Wind mixing
        WmixIndicator=1;
        Bef_wind=sum(diff(rho)==0); %just a watch variable
        while (WmixIndicator==1)
            d_rho=diff(rho);
            inx=find(d_rho>0);
            if (isempty(inx)==0); %if water column not already fully mixed
                zb=inx(1);   
                MLD=dz*zb; %mixed layer depth
                dD=d_rho(zb); %density difference
                Zg=sum( Az(1:zb+1) .* zz(1:zb+1) ) / sum(Az(1:zb+1)); %Depth of center of mass of mixed layer       
                V_weight=Vz(zb+1)*sum(Vz(1:zb))/(Vz(zb+1)+sum(Vz(1:zb)));
                POE=(dD*g*V_weight*(MLD + dz/2 - Zg));
                KP_ratio=TKE/POE;
                if (KP_ratio>=1)
                    
                    Tmix=sum( Vz(1:zb+1).*Tz(1:zb+1) ) / sum(Vz(1:zb+1));
                    Tz(1:zb+1)=Tmix;
                    
                    Cmix=sum( Vz(1:zb+1).*Cz(1:zb+1) ) / sum(Vz(1:zb+1));
                    Cz(1:zb+1)=Cmix;

                    Smix=sum( Vz(1:zb+1).*Sz(1:zb+1) ) / sum(Vz(1:zb+1));
                    Sz(1:zb+1)=Smix;
                    
                    Pmix=sum( Vz(1:zb+1).*Pz(1:zb+1) ) / sum(Vz(1:zb+1));
                    Pz(1:zb+1)=Pmix;
                    
                    Chlmix=sum( Vz(1:zb+1).*Chlz(1:zb+1) ) / sum(Vz(1:zb+1));
                    Chlz(1:zb+1)=Chlmix;
                    
                    PPmix=sum( Vz(1:zb+1).*PPz(1:zb+1) ) / sum(Vz(1:zb+1));
                    PPz(1:zb+1)=PPmix;
                    
                    DOPmix=sum( Vz(1:zb+1).*DOPz(1:zb+1) ) / sum(Vz(1:zb+1));
                    DOPz(1:zb+1)=DOPmix;
                    
                    DOCmix=sum( Vz(1:zb+1).*DOCz(1:zb+1) ) / sum(Vz(1:zb+1));
                    DOCz(1:zb+1)=DOCmix;
                    
                    DICmix=sum( Vz(1:zb+1).*DICz(1:zb+1) ) / sum(Vz(1:zb+1));
                    DICz(1:zb+1)=DICmix;
                    
                    O2mix=sum( Vz(1:zb+1).*O2z(1:zb+1) ) / sum(Vz(1:zb+1));
                    O2z(1:zb+1)=O2mix;
                    
                       NO3mix=sum( Vz(1:zb+1).*NO3z(1:zb+1) ) / sum(Vz(1:zb+1));
                    NO3z(1:zb+1)=NO3mix;
                    
                       NH4mix=sum( Vz(1:zb+1).*NH4z(1:zb+1) ) / sum(Vz(1:zb+1));
                    NH4z(1:zb+1)=NH4mix;
                    
                       SO4mix=sum( Vz(1:zb+1).*SO4z(1:zb+1) ) / sum(Vz(1:zb+1));
                    SO4z(1:zb+1)=SO4mix;
                    
                       HSmix=sum( Vz(1:zb+1).*HSz(1:zb+1) ) / sum(Vz(1:zb+1));
                    HSz(1:zb+1)=HSmix;
                    
                       H2Smix=sum( Vz(1:zb+1).*H2Sz(1:zb+1) ) / sum(Vz(1:zb+1));
                    H2Sz(1:zb+1)=H2Smix;
                    
                       Fe2mix=sum( Vz(1:zb+1).*Fe2z(1:zb+1) ) / sum(Vz(1:zb+1));
                    Fe2z(1:zb+1)=Fe2mix;
                    
                       Ca2mix=sum( Vz(1:zb+1).*Ca2z(1:zb+1) ) / sum(Vz(1:zb+1));
                    Ca2z(1:zb+1)=Ca2mix;
                    
                       pHmix=sum( Vz(1:zb+1).*pHz(1:zb+1) ) / sum(Vz(1:zb+1));
                    pHz(1:zb+1)=pHmix;
                    
                       CH4mix=sum( Vz(1:zb+1).*CH4z(1:zb+1) ) / sum(Vz(1:zb+1));
                    CH4z(1:zb+1)=CH4mix;
                    
                       Fe3mix=sum( Vz(1:zb+1).*Fe3z(1:zb+1) ) / sum(Vz(1:zb+1));
                    Fe3z(1:zb+1)=Fe3mix;
                    
                       Al3mix=sum( Vz(1:zb+1).*Al3z(1:zb+1) ) / sum(Vz(1:zb+1));
                    Al3z(1:zb+1)=Al3mix;
                    
                         SiO4mix=sum( Vz(1:zb+1).*SiO4z(1:zb+1) ) / sum(Vz(1:zb+1));
                    SiO4z(1:zb+1)=SiO4mix;
                    
                         SiO2mix=sum( Vz(1:zb+1).*SiO2z(1:zb+1) ) / sum(Vz(1:zb+1));
                    SiO2z(1:zb+1)=SiO2mix;
                    
                         diatommix=sum( Vz(1:zb+1).*diatomz(1:zb+1) ) / sum(Vz(1:zb+1));
                    diatomz(1:zb+1)=diatommix;
                    
                    rho = polyval(ies80,max(0,Tz(:))) + min(Tz(:),0);
                    TKE=TKE-POE;
                else %if KP_ratio < 1, then mix with the remaining TKE part of the underlying layer 
                    Tmix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*Tz(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    Tz(1:zb)=Tmix;
                    Tz(zb+1)=KP_ratio*Tmix + (1-KP_ratio)*Tz(zb+1);
                    
                    Cmix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*Cz(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    Cz(1:zb)=Cmix;
                    Cz(zb+1)=KP_ratio*Cmix + (1-KP_ratio)*Cz(zb+1);
                    
                    Smix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*Sz(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    Sz(1:zb)=Smix;
                    Sz(zb+1)=KP_ratio*Smix + (1-KP_ratio)*Sz(zb+1);
                    
                    Pmix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*Pz(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    Pz(1:zb)=Pmix;
                    Pz(zb+1)=KP_ratio*Pmix + (1-KP_ratio)*Pz(zb+1);
                    
                    Chlmix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*Chlz(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    Chlz(1:zb)=Chlmix;
                    Chlz(zb+1)=KP_ratio*Chlmix + (1-KP_ratio)*Chlz(zb+1);
                    
                    PPmix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*PPz(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    PPz(1:zb)=PPmix;
                    PPz(zb+1)=KP_ratio*PPmix + (1-KP_ratio)*PPz(zb+1);
                    
                    DOPmix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*DOPz(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    DOPz(1:zb)=DOPmix;
                    DOPz(zb+1)=KP_ratio*DOPmix + (1-KP_ratio)*DOPz(zb+1);
                    
                    DOCmix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*DOCz(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    DOCz(1:zb)=DOCmix;
                    DOCz(zb+1)=KP_ratio*DOCmix + (1-KP_ratio)*DOCz(zb+1);
                    
                    DICmix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*DICz(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    DICz(1:zb)=DICmix;
                    DICz(zb+1)=KP_ratio*DICmix + (1-KP_ratio)*DICz(zb+1);
                    
                    O2mix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*O2z(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    O2z(1:zb)=O2mix;
                    O2z(zb+1)=KP_ratio*O2mix + (1-KP_ratio)*O2z(zb+1);
                    
                    NO3mix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*NO3z(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    NO3z(1:zb)=NO3mix;
                    NO3z(zb+1)=KP_ratio*NO3mix + (1-KP_ratio)*NO3z(zb+1);
                    
                    NH4mix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*NH4z(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    NH4z(1:zb)=NH4mix;
                    NH4z(zb+1)=KP_ratio*NH4mix + (1-KP_ratio)*NH4z(zb+1);
                    
                    SO4mix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*SO4z(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    SO4z(1:zb)=SO4mix;
                    SO4z(zb+1)=KP_ratio*SO4mix + (1-KP_ratio)*SO4z(zb+1);
                    
                    HSmix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*HSz(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    HSz(1:zb)=HSmix;
                    HSz(zb+1)=KP_ratio*HSmix + (1-KP_ratio)*HSz(zb+1);
                    
                    H2Smix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*H2Sz(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    H2Sz(1:zb)=H2Smix;
                    H2Sz(zb+1)=KP_ratio*H2Smix + (1-KP_ratio)*H2Sz(zb+1);
                    
                    Fe2mix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*Fe2z(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    Fe2z(1:zb)=Fe2mix;
                    Fe2z(zb+1)=KP_ratio*Fe2mix + (1-KP_ratio)*Fe2z(zb+1);
                    
                    Ca2mix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*Ca2z(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    Ca2z(1:zb)=Ca2mix;
                    Ca2z(zb+1)=KP_ratio*Ca2mix + (1-KP_ratio)*Ca2z(zb+1);
                    
                    pHmix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*pHz(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    pHz(1:zb)=pHmix;
                    pHz(zb+1)=KP_ratio*pHmix + (1-KP_ratio)*pHz(zb+1);
                    
                    CH4mix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*CH4z(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    CH4z(1:zb)=CH4mix;
                    CH4z(zb+1)=KP_ratio*CH4mix + (1-KP_ratio)*CH4z(zb+1);
                    
                    Fe3mix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*Fe3z(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    Fe3z(1:zb)=Fe3mix;
                    Fe3z(zb+1)=KP_ratio*Fe3mix + (1-KP_ratio)*Fe3z(zb+1);
                    
                    Al3mix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*Al3z(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    Al3z(1:zb)=Al3mix;
                    Al3z(zb+1)=KP_ratio*Al3mix + (1-KP_ratio)*Al3z(zb+1);
                    
                    SiO4mix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*SiO4z(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    SiO4z(1:zb)=SiO4mix;
                    SiO4z(zb+1)=KP_ratio*SiO4mix + (1-KP_ratio)*SiO4z(zb+1);
                    
                    SiO2mix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*SiO2z(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    SiO2z(1:zb)=SiO2mix;
                    SiO2z(zb+1)=KP_ratio*SiO2mix + (1-KP_ratio)*SiO2z(zb+1);
                    
                    diatommix=sum( [Vz(1:zb); KP_ratio*Vz(zb+1)].*diatomz(1:zb+1) ) / sum([Vz(1:zb); KP_ratio*Vz(zb+1)]);
                    diatomz(1:zb)=diatommix;
                    diatomz(zb+1)=KP_ratio*diatommix + (1-KP_ratio)*diatomz(zb+1);
                    
                    rho = polyval(ies80,max(0,Tz(:))) + min(Tz(:),0);
                    TKE=0;       
                    WmixIndicator=0;
                end %if (KP_ratio>=1)
            else
                WmixIndicator=0;
            end %if water column (not) already mixed               
        end %while
        
        Aft_wind=sum(diff(rho)==0); %just a watch variable
        
    else % ice cover module               
        XE_surf=(Tz(1)-Tf) * Cw * dz; %Daily heat accumulation into the first water layer (J m-2)
        Tz(1)=Tf; %Ensure that temperature of the first water layer is kept at freezing point
        TKE=0; %No energy for wind mixing under ice
        
        if (Wt(i,3)<Tf) %if air temperature is below freezing          
            %Calculate ice surface temperature (Tice)
            if(WEQs==0) %if no snow
                alfa=1/(10*Hi);
                dHsi=0;
            else
                K_snow=2.22362*(rho_snow/1000)^1.885; %Yen (1981)
                alfa=(K_ice/K_snow)*(((rho_fw/rho_snow)*WEQs)/Hi);
                %Slush/snow ice formation (directly to ice)
                dHsi=max([0, Hi*(rho_ice/rho_fw-1)+WEQs]);         
                Hsi=Hsi+dHsi;
            end
            Tice=(alfa*Tf+Wt(i,3))/(1+alfa);
            
            %Ice growth by Stefan's law       
            Hi_new=sqrt((Hi+dHsi)^2+(2*K_ice/(rho_ice*L_ice))*(24*60*60)*(Tf-Tice));
            %snow fall
            dWEQnews=0.001*Wt(i,7); %mm->m
            dWEQs=dWEQnews-dHsi*(rho_ice/rho_fw); % new precipitation minus snow-to-snowice in snow water equivalent
            dHsi=0; %reset new snow ice formation       
        else %if air temperature is NOT below freezing
            Tice=Tf;    %ice surface at freezing point
            dWEQnews=0; %No new snow
            if (WEQs>0)
                %snow melting in water equivalents
                dWEQs=-max([0, (60*60*24)*(((1-IceSnowAttCoeff)*Qsw)+Qlw+Qsl)/(rho_fw*L_ice)]);
                if ((WEQs+dWEQs)<0) %if more than all snow melts...
                    Hi_new=Hi+(WEQs+dWEQs)*(rho_fw/rho_ice); %...take the excess melting from ice thickness
                else
                    Hi_new=Hi; %ice does not melt until snow is melted away
                end
            else    
                %total ice melting
                dWEQs=0;
                Hi_new=Hi-max([0, (60*60*24)*(((1-IceSnowAttCoeff)*Qsw)+Qlw+Qsl)/(rho_ice*L_ice)]);
                %snow ice part melting
                Hsi=Hsi-max([0, (60*60*24)*(((1-IceSnowAttCoeff)*Qsw)+Qlw+Qsl)/(rho_ice*L_ice)]);
                if (Hsi<=0)
                    Hsi=0;
                end
            end %if there is snow or not
        end %if air temperature is or isn't below freezing
        
        
        %Update ice and snow thicknesses
        Hi=Hi_new-(XE_surf/(rho_ice*L_ice)); %new ice thickness (minus melting due to heat flux from water)
        XE_surf=0; %reset energy flux from water to ice (J m-2 per day)
        WEQs=WEQs+dWEQs; %new snow water equivalent   
        
        if(Hi<Hsi)
            Hsi=max(0,Hi);    %to ensure that snow ice thickness does not exceed ice thickness 
            %(if e.g. much ice melting much from bottom)
        end
        
        
        if(WEQs<=0)
            WEQs=0; %excess melt energy already transferred to ice above
            rho_snow=rho_new_snow;
        else
            %Update snow density as weighed average of old and new snow densities
            rho_snow=rho_snow*(WEQs-dWEQnews)/WEQs + rho_new_snow*dWEQnews/WEQs;
            if (snow_compaction_switch==1)
                %snow compaction
                if (Wt(i,3)<Tf) %if air temperature is below freezing        
                    rhos=1e-3*rho_snow; %from kg/m3 to g/cm3
                    delta_rhos=24*rhos*C1*(0.5*WEQs)*exp(-C2*rhos)*exp(-0.08*(Tf-0.5*(Tice+Wt(i,3))));
                    rho_snow=min([rho_snow+1e+3*delta_rhos, max_rho_snow]);  %from g/cm3 back to kg/m3 
                else
                    rho_snow=max_rho_snow;    
                end
            end
        end
        
        if(Hi<=0)
            IceIndicator=0;
            %disp(['Ice-off, ' datestr(datenum(M_start)+i-1)])
            XE_melt=(-Hi-(WEQs*rho_fw/rho_ice))*rho_ice*L_ice/(24*60*60); 
            %(W m-2) snow part is in case ice has melted from bottom leaving some snow on top (reducing XE_melt)
            Hi=0;
            WEQs=0;
            Tice=NaN;
            DoM(pp)=i;
            pp=pp+1;
        end
        
    end %of ice cover module           
    
    %== P-partitioning in water==
    TIPz=Pz + PPz; % Total inorg. phosphorus (excl. Chla and DOP) in the water column (mg m-3)
    [Pz, trash]=Ppart(Sz./rho_sed,TIPz,Psat_L,Fmax_L,rho_sed,Fstable);
    PPz=TIPz-Pz;
    
    %DIC-partitioning in water
    
    [CO2z,~] = carbonequilibrium(DICz,Tz,pH);
    
    % Relative dissolved oxygen concentration
    
    [O2_sat_rel, O2_sat_abs] = relative_oxygen(O2z,Tz,Wt(i,5),dz);
    
    %Initial freezing
    Supercooled=find(Tz<Tf);
    if (isempty(Supercooled)==0)
        %===NEW!!! (040707)
        if(Supercooled(1)~=1); disp('NOTE: non-surface subsurface supercooling'); end;
        InitIceEnergy=sum((Tf-Tz(Supercooled)).*Vz(Supercooled)*Cw);
        HFrazil=HFrazil+(InitIceEnergy/(rho_ice*L_ice))/Az(1);
        Tz(Supercooled)=Tf;
        
        if ((IceIndicator==0)&(HFrazil > Frazil2Ice_tresh))
            IceIndicator=1;
            Hi=Hi+HFrazil;
            HFrazil=0;
            DoF(qq)=i;
            %disp(['Ice-on, ' datestr(datenum(M_start)+i-1)])
            qq=qq+1;
        end
        
        if (IceIndicator==1)
            Hi=Hi+HFrazil;
            HFrazil=0;
        end
        Tz(1)=Tf; %set temperature of the first layer to freezing point
        %======================
        
    end   
    
    % Calculate pycnocline depth
    pycno_thres=0.1;  %treshold density gradient value (kg m-3 m-1)
    rho = polyval(ies80,max(0,Tz(:))) + min(Tz(:),0);
    dRdz = [NaN; abs(diff(rho))];
    di=find((dRdz<(pycno_thres*dz)) | isnan(dRdz));
    %dRdz(di)=NaN; 
    %TCz = nansum(zz .* dRdz) ./ nansum(dRdz);
    dRdz(di)=0; %modified for MATLAB version 7
    TCz = sum(zz .* dRdz) ./ sum(dRdz);
    
    %vector with S_res_epi above, and S_res_hypo below the pycnocline
    inx=find(zz <= TCz);
    S_resusp(inx)=S_res_epi;
    inx=find(zz > TCz);
    S_resusp(inx)=S_res_hypo;
    
    if (IceIndicator==1)
        S_resusp(:)=S_res_hypo;  %only hypolimnetic type of resuspension allowed under ice
    end
    
    if( isnan(TCz) & (IceIndicator==0) )  
        S_resusp(:)=S_res_epi;   %if no pycnocline and open water, resuspension allowed from top to bottom   
    end

    if any(isnan(O2z)), error('MyLake error::O2zt is NaN'), end

    % sediment module
    if matsedlab_sediments_module == 1
        % Making cells of params for using during coupling
        MyLake_concentrations = {...
            O2z,                'O2z';
            Chlz,               'Chlz';
            H_netsed_catch,     'H_netsed_catch';
            Pz,                 'Pz';
        };
        MyLake_concentrations = containers.Map({MyLake_concentrations{:,2}},{MyLake_concentrations{:,1}});

        MyLake_params = {...
            SS_C,               'SS_C';
            density_org_H_nc,   'density_org_H_nc';
            w_chl,              'w_chl';
            Mass_Ratio_C_Chl,   'Mass_Ratio_C_Chl';
            Az(end),            'Az(end)';
            Vz(end),            'Vz(end)';
            dt,                 'dt';
        };
        MyLake_params = containers.Map({MyLake_params{:,2}},{MyLake_params{:,1}});

        % Preparing units and estimate flux from [WC] ----> [Sediments]
        sediments_bc = convert_wc_to_sediment(MyLake_concentrations, MyLake_params, sediment_params);
        
       % Running sediment module
        [sediment_bioirrigation_fluxes, sediment_diffusion_fluxes, sediment_concentrations, z_matsedlab, R_values_matsedlabz] = sediments(...
            sediment_concentrations, sediment_params, sediment_matrix_templates, species_sediments, sediments_bc);

       % Update WC:  [Sediments] ----> [WC]
        [O2z, Pz] = update_wc(O2z, Pz, MyLake_params, sediment_diffusion_fluxes, sediment_bioirrigation_fluxes);

        deltaO2(i) = - sediment_diffusion_fluxes{1} * dt * Az(end) / Vz (end)  - sediment_bioirrigation_fluxes{1} * dt * Az(end) / Vz (end) ;
        deltaPz(i) = - sediment_diffusion_fluxes{4} * dt * Az(end) / Vz (end);


        % checking the calculations
        % if deltaO2(i)>0, error('Sediments:: deltaO2 > 0'), end
        % if deltaPz(i)<0, error('Sediments:: deltaPz < 0'), end
    end
    
 if matsedlab_sediments_module == 1;           % MATSEDLAB sediment module

    % Sediment module output
    % Output:
    O2_matsedlabzt(:,i) = sediment_concentrations('Oxygen');
    OM_matsedlabzt(:,i) = sediment_concentrations('OM1');
    OMb_matsedlabzt(:,i) = sediment_concentrations('OM2');
    NO3_matsedlabzt(:,i) = sediment_concentrations('NO3');
    FeOH3_matsedlabzt(:,i) = sediment_concentrations('FeOH3');
    SO4_matsedlabzt(:,i) = sediment_concentrations('SO4');
    NH4_matsedlabzt(:,i) = sediment_concentrations('NH4');
    Fe2_matsedlabzt(:,i) = sediment_concentrations('Fe2');
    FeOOH_matsedlabzt(:,i) = sediment_concentrations('FeOOH');
    H2S_matsedlabzt(:,i) = sediment_concentrations('H2S');
    HS_matsedlabzt(:,i)  = sediment_concentrations('HS');
    FeS_matsedlabzt(:,i) = sediment_concentrations('FeS');
    S0_matsedlabzt(:,i)  = sediment_concentrations('S0');
    PO4_matsedlabzt(:,i) = sediment_concentrations('PO4');
    S8_matsedlabzt(:,i) = sediment_concentrations('S8');
    FeS2_matsedlabzt(:,i) = sediment_concentrations('FeS2');
    AlOH3_matsedlabzt(:,i) = sediment_concentrations('AlOH3');
    PO4adsa_matsedlabzt(:,i) = sediment_concentrations('PO4adsa');
    PO4adsb_matsedlabzt(:,i) = sediment_concentrations('PO4adsb');
    Ca2_matsedlabzt(:,i) = sediment_concentrations('Ca2');
    Ca3PO42_matsedlabzt(:,i) = sediment_concentrations('Ca3PO42');
    OMS_matsedlabzt(:,i) = sediment_concentrations('OMS');
    H_matsedlabzt(:,i) = sediment_concentrations('H');
    OH_matsedlabzt(:,i) = sediment_concentrations('OH');
    CO2_matsedlabzt(:,i) = sediment_concentrations('CO2');
    CO3_matsedlabzt(:,i) = sediment_concentrations('CO3');
    HCO3_matsedlabzt(:,i) = sediment_concentrations('HCO3');
    NH3_matsedlabzt(:,i) = sediment_concentrations('NH3');
    H2CO3_matsedlabzt(:,i) = sediment_concentrations('H2CO3');
    pH_matsedlabzt(:,i) = -log10(H_matsedlabzt(:,i)*10^-6);
    O2_flux_matsedlabzt(i) = sediment_diffusion_fluxes{1};
    OM_flux_matsedlabzt(i) = sediment_diffusion_fluxes{2};
    OM2_flux_matsedlabzt(i) = sediment_diffusion_fluxes{3};
    PO4_flux_matsedlabzt(i) = sediment_diffusion_fluxes{4};
    R1_matsedlabzt(:,i) = R_values_matsedlabz{1};
    R1_int_matsedlabzt(:,i) = R_values_matsedlabz{2};
    R2_matsedlabzt(:,i) = R_values_matsedlabz{3};
    R2_int_matsedlabzt(:,i) = R_values_matsedlabz{4};
    R3_matsedlabzt(:,i) = R_values_matsedlabz{5};
    R3_int_matsedlabzt(:,i) = R_values_matsedlabz{6};
    R4_matsedlabzt(:,i) = R_values_matsedlabz{7};
    R4_int_matsedlabzt(:,i) = R_values_matsedlabz{8};
    R5_matsedlabzt(:,i) = R_values_matsedlabz{9};
    R5_int_matsedlabzt(:,i) = R_values_matsedlabz{10};
    O2_Bioirrigation_matsedlabz(:,i) = sediment_bioirrigation_fluxes{1};
    PO4_Bioirrigation_matsedlabz(:,i) = sediment_bioirrigation_fluxes{2};
    NO3_flux_matsedlabzt(i) = sediment_diffusion_fluxes{5};
    FeOH3_flux_matsedlabzt(i) = sediment_diffusion_fluxes{6};
    R6_matsedlabzt(:,i) = R_values_matsedlabz{11};
    R6_int_matsedlabzt(:,i) = R_values_matsedlabz{12};
   
 end 
 
    % Output MyLake matrices     
    Qst(:,i) = [Qsw Qlw Qsl]';
    Kzt(:,i) = [0;Kz];
    Tzt(:,i) = Tz;
    Czt(:,i) = Cz;
    Szt(:,i) = Sz;
    Pzt(:,i) = Pz;
    Chlzt(:,i) = Chlz;
    PPzt(:,i) = PPz;
    DOPzt(:,i) = DOPz;
    DOCzt(:,i) = DOCz;
    DICzt(:,i) = DICz;
    O2zt(:,i) = O2z;
    
    NO3zt(:,i) = NO3z;
    NH4zt(:,i) = NH4z;
    SO4zt(:,i) = SO4z;
    HSzt(:,i) = HSz;
    H2Szt(:,i) = H2Sz;
    Fe2zt(:,i) = Fe2z;
    Ca2zt(:,i) = Ca2z;
    pHzt(:,i) = pHz;
    CH4zt(:,i) = CH4z;
    Fe3zt(:,i) = Fe3z;
    Al3zt(:,i) = Al3z;
    SiO4zt(:,i) = SiO4z;
    SiO2zt(:,i) = SiO2z;
    diatomzt(:,i) = diatomz;
       
	O2diffzt(:,i) = O2_diff;
    CO2zt(:,i) = CO2z;
    O2_sat_relt(:,i) = O2_sat_rel;
    O2_sat_abst(:,i) = O2_sat_abs;
    BODzt = 0; %for compatibility with the other code
    

    %Fokema
    %CDOMzt(:,i)=CDOMz;
    if (photobleaching==1)
        DOCzt1(:,i) = DOCz1_new; %Fokema-model DOC subpool 1
        DOCzt2(:,i) = DOCz2_new; %Fokema-model DOC subpool 2
        DOCzt3(:,i) = DOCz3_new; %Fokema-model DOC subpool 3
        DOC1tfrac(:,i) = DOC1frac; %Fokema-model subpool 1 fraction
        DOC2tfrac(:,i) = DOC2frac; %Fokema-model subpool 2 fraction
        DOC3tfrac(:,i) = DOC3frac; %Fokema-model subpool 3 fraction
        Daily_BB1t(:,i) = Daily_BB1; %Fokema-model subpool 1 daily bacterial decomposition
        Daily_BB2t(:,i) = Daily_BB2; %Fokema-model subpool 2 daily bacterial decomposition
        Daily_BB3t(:,i) = Daily_BB3; %Fokema-model subpool 3 daily bacterial decomposition
        Daily_PBt(:,i) = Daily_PB; %Fokema-model daily photobleaching
    end
    
    Qzt_sed(:,i) = Qz_sed./(60*60*24*dt); %(J m-2 day-1) -> (W m-2)
    lambdazt(:,i) = lambdaz_wtot_avg;
    
    surfaceflux(1,i) = surfflux; %Carbon dioxide surface flux
    CO2_eqt(1,i) = CO2_eq;       %Carbon dioxide equilibrium concentration
    K0t(:,i) = K0;               %Dissolved carbon doxide solubility coefficient
    CO2_ppmt(:,i) = CO2_ppm;
    
    O2fluxt(1,i) = O2flux;       %Oxygen surface flux
    O2_eqt(1,i) = O2_eq;         %Oxygen equilibrium concentration
    K0_O2t(1,i) = K0_O2;         %Dissolved oxygen solubility coefficient
    dO2Chlt(:,i) = dO2_Chl;
    dO2BODt(:,i) = dO2_BOD;
    %dO2SODt(:,i) = dO2_SOD;
    
    testi1t(:,i) = O2_old;
    testi2t(:,i) = O2_diff; testi3t(:,i) = O2_new;
       
    P3zt_sed(:,i,1) = Pdz_store; %diss. P conc. in sediment pore water (mg m-3)
    P3zt_sed(:,i,2) = Psz_store; %P conc. in inorganic sediment particles (mg kg-1 dry w.)
    P3zt_sed(:,i,3) = Chlsz_store; %Chl conc. in organic sediment particles (mg kg-1 dry w.)
    P3zt_sed(:,i,4) = F_IM; %VOLUME fraction of inorganic particles of total dry sediment
    P3zt_sed(:,i,5) = Sedimentation_counter; %H_netsed_inorg; %Sedimentation (m/day) of inorganic particles of total dry sediment
    P3zt_sed(:,i,6) = Resuspension_counter; %H_netsed_org; %Sedimentation (m/day) of organic particles of total dry sediment
    P3zt_sed(:,i,7) = NewSedFrac; %(monitoring variables)
    
    P3zt_sed_sc(:,i,1) = dPW_up; %(mg m-3 day-1) change in Pz due to exchange with pore water
    P3zt_sed_sc(:,i,2) = dPP; %(mg m-3 day-1)
    P3zt_sed_sc(:,i,3) = dChl_res; %(mg m-3 day-1)
    
    His(1,i) = Hi;
    His(2,i) = (rho_fw/rho_snow)*WEQs;
    His(3,i) = Hsi;
    His(4,i) = Tice;
    His(5,i) = Wt(i,3);
    His(6,i) = rho_snow;
    His(7,i) = IceIndicator; 
    His(8,i) = HFrazil; %NEW!!!
    
   %Original MixStat matrix in v.1.2.1b
    
    %MixStat(1,i) = Iflw_S;
    %MixStat(2,i) = Iflw_TP;
    %MixStat(3,i) = sum(Sz.*Vz);
    %MixStat(4,i) = Growth_bioz(1);%mean(Growth_bioz(1:4)); %Obs! changed to apply to layers 1-4 only
    %MixStat(5,i) = Loss_bioz(1);%mean(Loss_bioz(1:4)); %Obs! changed to apply to layers 1-4 only
    %%MixStat(6,i) = Iflw;
    %MixStat(7:10,i) = NaN;
    
   % MixStat matrix from v.1.2 for figure output purposes
    
   MixStat(1,i) = Iflw_S;
   MixStat(2,i) = Iflw_TP;
   MixStat(3,i) = lambdaz_wtot(2);%Iflw_DOC;
        MixStat(4,i) = mean(Growth_bioz); %Only for chlorophyll group 1 (a)
        MixStat(5,i) = mean(Loss_bioz);  %Only for chlorophyll group 1 (a)
        MixStat(6,i) = Iflw;
          if (IceIndicator == 1)
           MixStat(7:11,i) = NaN;
          else
           dum=interp1(zz,Pz,[0:0.1:4]);
           MixStat(7,i) = mean(dum); %diss-P conc. 0-4m in ice-free period
              
           dum=interp1(zz,Chlz,[0:0.1:4]);
           MixStat(8,i) = mean(dum); %Chla conc. 0-4m in ice-free period
           
           dum=interp1(zz,PPz,[0:0.1:4]);
           MixStat(9,i) = mean(dum); %particulate inorg. P conc. 0-4m in ice-free period

           dum=interp1(zz,DOPz,[0:0.1:4]);
           MixStat(10,i) = mean(dum); %dissolved organic P conc. 0-4m in ice-free period
           
           dum=interp1(zz,Sz,[0:0.1:4]);
           MixStat(11,i) = mean(dum); %particulate matter conc. 0-4m in ice-free period
          end

        MixStat(12,i) = TCz; %pycnocline depth

        MixStat(13,i) = 1e-6*Iflw*Iflw_TP; %total P inflow (kg day-1)
%         if (Iflw>Vz(1))
%             disp('Large inflow!!')
%         end
        MixStat(14,i) = 1e-6*Iflw*(Pz(1)+PPz(1)+DOPz(1)+Chlz(1)+Cz(1)); %total P outflow (kg day-1)
        MixStat(15,i) = sum(1e-6*Vz.*(delPP_inorg + delC_org)); %total P sink due to sedimentation (kg day-1)
        MixStat(16,i) = sum(1e-6*(dPP+dPW_up).*Vz); %Internal P loading (kg day-1, excluding Chla)
        MixStat(17,i) = sum(1e-6*dChl_res.*Vz); %Internal Chla loading (kg day-1)(resuspension 50/50 between the two groups)
        MixStat(18,i)= sum(1e-6*Vz.*((Pz+PPz+DOPz+Chlz+Cz) - TP0)); %Net P change kg
        MixStat(19,i)= sum(1e-6*((dPP+dPW_up-delPP_inorg+dChl_res-delC_org).*Vz - (1-F_sed_sld)*H_sed*(-diff([Az; 0])).*dPW_down)); %Net P flux from sediment kg
        MixStat(20,i) = 1e-6*Iflw*(Iflw_TP-(Iflw_Chl+Iflw_C)./Y_cp-Iflw_DOP-Fstable*Iflw_S); %total algae-available P inflow (kg day-1)
        if (IceIndicator == 1)
         MixStat(21,i) = NaN;
        else 
         dum=interp1(zz,Cz,[0:0.1:4]);
         MixStat(21,i) = mean(dum); %Chl group 2 conc. 0-4m in ice-free period
        end 
        MixStat(22,i) = mean(Growth_bioz_2); %For chlorophyll group 2
        MixStat(23,i) = mean(Loss_bioz_2);  %For chlorophyll group 2
         
end; %for i = 1:length(tt)


%Saving sediment values
if matsedlab_sediments_module == 1;           % MATSEDLAB sediment module

R_values_matsedlabzt = { 

      R1_matsedlabzt,         'R1';
      R1_int_matsedlabzt,     'R1 integrated';
      R2_matsedlabzt,         'R2';
      R2_int_matsedlabzt,     'R2 integrated';
      R3_matsedlabzt,         'R3';
      R3_int_matsedlabzt,     'R3 integrated';
      R4_matsedlabzt,         'R4';
      R4_int_matsedlabzt,     'R4 integrated';
      R5_matsedlabzt,         'R5';
      R5_int_matsedlabzt,     'R5 integrated';
      R6_matsedlabzt,         'R6'; 
      R6_int_matsedlabzt,     'R6 integrated'; 
};

Bioirrigation_matsedlabzt = { O2_Bioirrigation_matsedlabz,  'Oxygen';
                              PO4_Bioirrigation_matsedlabz, 'PO4'};

            MyLake_params = [ (keys(MyLake_params))', (values(MyLake_params))'];
            sediment_params = [ (keys(sediment_params))', (values(sediment_params))'];

sediment_results = {O2_matsedlabzt,     'Oxygen (aq)';
                   FeOH3_matsedlabzt,   'Iron hydroxide pool 1 Fe(OH)3 (s)';
                   FeOOH_matsedlabzt,   'Iron Hydroxide pool 2 FeOOH (s)';
                   SO4_matsedlabzt,     'Sulfate SO4(2-) (aq)';
                   Fe2_matsedlabzt,     'Iron Fe(2+) (aq)'; 
                   H2S_matsedlabzt,     'Sulfide H2S (aq)';
                   HS_matsedlabzt,      'Sulfide HS(-) (aq)'; 
                   FeS_matsedlabzt,     'Iron Sulfide FeS (s)';
                   OM_matsedlabzt,      'Organic Matter pool 1 OMa (s)';
                   OMb_matsedlabzt,     'Organic Matter pool 2 OMb (s)';
                   OMS_matsedlabzt,     'Sulfured Organic Matter (s)';
                   AlOH3_matsedlabzt,   'Aluminum oxide Al(OH)3 (s)'; 
                   S0_matsedlabzt,      'Elemental sulfur S(0) (aq)'; 
                   S8_matsedlabzt,      'Rhombic sulfur S8 (s)'; 
                   FeS2_matsedlabzt,    'Pyrite FeS2 (s)'; 
                   PO4_matsedlabzt,     'Phosphate PO4(3-) (aq)';
                   PO4adsa_matsedlabzt, 'Solid phosphorus pool a PO4adsa (s)';
                   PO4adsb_matsedlabzt, 'Solid phosphorus pool b PO4adsb (s)';
                   NO3_matsedlabzt,     'Nitrate NO3(-) (aq)';
                   NH4_matsedlabzt,     'Ammonium NH4(+) (aq)';
                   H_matsedlabzt,       'H+ concentration';
                   Ca2_matsedlabzt,     'Calcium Ca(2+) (aq)';
                   Ca3PO42_matsedlabzt, 'Apatite Ca3PO42 (s)';
                   H_matsedlabzt,       'H(+)(aq)';
                   OH_matsedlabzt,      'OH(-)(aq)';
                   CO2_matsedlabzt,     'CO2(aq)';
                   CO3_matsedlabzt,     'CO3(2-)(aq)';
                   HCO3_matsedlabzt,    'HCO3(-)(aq)';
                   NH3_matsedlabzt,     'NH3(aq)';
                   H2CO3_matsedlabzt,   'H2CO3(aq)';
                   pH_matsedlabzt,      'pH in sediment';
                   OM_flux_matsedlabzt, 'OM flux to sediments';
                   OM2_flux_matsedlabzt,'OM2 flux to sediments';
                   O2_flux_matsedlabzt, 'Oxygen flux WC to Sediments';
                   deltaO2,             'dO2';
                   PO4_flux_matsedlabzt,'PO4 flux WC to Sediments';
                   deltaPz,             'dPz';
                   w_chl,               'Chl settling velocity m day-1';
                   Mass_Ratio_C_Chl,    'Mass ratio C:Chl';
                   z_matsedlab,         'z';
                   R_values_matsedlabzt,'R values';
                   Bioirrigation_matsedlabzt, 'Fluxes of bioirrigation';
                   MyLake_params,       'MyLake Params important for sediments';
                   sediment_params,     'Sediments params'};

end

runtime=toc;

%disp(['Total model runtime: ' int2str(floor(runtime/60)) ' min ' int2str(round(mod(runtime,60))) ' s']);
%disp(['Reduced SS load due to inconsistencies: '  num2str(round(SS_decr)) ' kg']); 

% >>>>>> End of the time loop >>>>>>

% Below are the two functions for calculating tridiagonal matrix Fi for solving the 
% 1) diffusion equation (tridiag_DIF_v11), and 
% 2) advection-diffusion equation (tridiag_HAD_v11) by fully implicit hybrid exponential numerical scheme, 
% based on Dhamotharan et al. 1981, 
%'Unsteady one-dimensional settling of suspended sediments', Water Resources Research 17(4), 1125-1132
% code checked by TSA, 16.03.2004


%Inputs:
% Kz    diffusion coefficient at layer interfaces (plus surface) N (N,1)
% U     vertical settling velocity (scalar)
% Vz    layer volumes (N,1)
% Az    layer interface areas (N,1)
% dz    grid size
% dt    time step

%Output:
% Fi    tridiagonal matrix for solving new profile Cz

az = (dt/dz) * [0; Kz] .* (Az ./ Vz);
bz = (dt/dz) * [Kz; 0] .* ([Az(2:end); 0] ./ Vz);
Gi = [-bz (1 + az + bz) -az];

%=== DIFFUSIVE EQUATION ===
function[Fi]=tridiag_DIF_v11(Kz,Vz,Az,dz,dt)

Nz=length(Vz); %number of grid points/layers

% Linearized heat conservation equation matrix (diffusion only)
az = (dt/dz) * Kz .* (Az ./ Vz);                                        %coefficient for i-1
cz = (dt/dz) * [Kz(2:end); NaN] .* ([Az(2:end); NaN] ./ Vz);            %coefficient for i+1
bz = 1 + az + cz;                                                       %coefficient for i+1
%Boundary conditions, surface

az(1) = 0;
%cz(1) remains unchanged 
bz(1)= 1 + az(1) + cz(1);


%Boundary conditions, bottom

%az(end) remains unchanged 
cz(end) = 0;
bz(end) = 1 + az(end) + cz(end);

Gi = [-cz bz -az];
Fi = spdiags(Gi,-1:1,Nz,Nz)';
%end of function


%=== ADVECTIVE-DIFFUSIVE EQUATION ===
function[Fi]=tridiag_HAD_v11(Kz,U,Vz,Az,dz,dt)

if (U<0)
    error('only positive (downward) velocities allowed')
end

if (U==0)
    U=eps; %set Vz next to nothing (=2.2204e-016) in order to avoid division by zero
end

Nz=length(Vz); %number of grid points/layers

theta=U*(dt/dz);

az = theta.*(1 + (1./(exp( (U*Vz)./(Kz.*Az) ) - 1)));                   %coefficient for i-1
cz = theta./(exp( (U*Vz)./([Kz(2:end); NaN].*[Az(2:end); NaN]) ) - 1);  %coefficient for i+1
bz = 1 + az + cz;                                                       %coefficient for i

%Boundary conditions, surface

az(1) = 0;
%cz(1) remains unchanged 
bz(1) = 1 + theta + cz(1);

%Boundary conditions, bottom

%az(end) remains unchanged 
cz(end) = 0;
bz(end) = 1 + az(end);

Gi = [-cz bz -az];
Fi = spdiags(Gi,-1:1,Nz,Nz)';
%end of function


function [Pdiss, Pfpart]=Ppart(vf,TIP,Psat,Fmax,rho_sed,Fstable)
% Function for calculating the partitioning between
% dissolved and inorganic particle bound phosphorus. 
% Based on Langmuir isotherm approach 
%vf:    volume fraction of suspended inorganic matter (m3 m-3); S/rho_sed OR (1-porosity)
%TIP:   Total inorganic phosphorus (mg m-3)
%Psat, mg m-3 - Langmuir half-saturation parameter
%Fmax, mg kg-1  - Langmuir scaling parameter
%rho_sed, kg m-3 - Density of dry inorganic sediment mass
%Fstable, mg kg-1 - Inactive P conc. in inorg. particles

N=length(TIP);
Pdiss=NaN*ones(N,1);

for w=1:N
    a = vf(w)-1;
    b = TIP(w) + (vf(w)-1)*Psat - vf(w)*rho_sed*(Fmax+Fstable);
    c = Psat*TIP(w) - vf(w)*rho_sed*Fstable*Psat ;
    Pdiss(w) = max(real(roots([a b c])));
end


%NEW!!!! Threshold value for numerical stability (added 020707):
%truncate negative values
cutinx=find(Pdiss < 0);
if (isempty(cutinx)==0)
    Pdiss(cutinx)=0;
    %disp('NOTE: Pdiss < 0, values truncated') 
end    

%truncate too high values
cutinx=find(Pdiss > (TIP - Fstable*rho_sed*vf));
if (isempty(cutinx)==0)
    Pdiss(cutinx)=(TIP(cutinx) - Fstable*rho_sed*vf(cutinx));
    %disp('NOTE: Pdiss > (TIP - Fstable*rho_sed*vf), values truncated') 
end    

Pfpart = (TIP - (1-vf).*Pdiss)./(rho_sed*vf); %inorg. P conc. in sediment particles(mg kg-1 dry w.) 
%end of function

