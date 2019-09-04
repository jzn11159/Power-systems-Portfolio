
* Planning and Operations for Aggregated Grid connected DER 

$onEolCom

Sets
h         "hours" 
m         "months" 
y         "years" 
p         "points of peicewise linear function" 
s         "number of scenarios" 
* scenarios - 3 or more (Stochastic case)
xy        "x/y parameter for energy cost curve" 
;


Parameter ppCostCurveXY(P,XY,M,H) "X/Y energy cost curve parameters"
$gdxin RDC_XY.gdx
$loaddc ppCostCurveXY
$gdxin
;

Parameter pDemandElec(M,H) "Electricity demand (kWh)"
$gdxin Dem_Elec.gdx
$loaddc pDemandElec
$gdxin
;

Parameters
pCOP "coefficient of performance" 
pPVLoss "electric losses in PV system (%)" 
pHPLoss "thermal losses in HP system (%)"
pBatEff "battery efficiency (%)" 
pGridTariffElec "electricity grid access tariff ($/kWh)"   
pDaysinMonth(m) "number of days in a month" 
pPriceElec(y) "original electricity buying price in year y ($/kWh)" 
pPriceTher(y) "original thermal energy buying price in year y ($/kWh)" 
pTariffElec "access tariff for electric power ($/kW)" 
pTariffTher "access tariff for thermal power ($/client)" 
pLifeSpanPV "expected life span for PV systems (years)"
pLifeSpanHP "expected life span for HP systems (years)" 
pLifeSpanBat "expected life span for Bat systems (years)" 
pDistSize "aggregated clients district size" 
pCostPV "total overnight capital cost of PV ($/kW)" 
pCostHP "total overnight capital cost of HP ($/kW)" 
pCostBat "total overnight capital cost of Battery ($/kWh)" 
pCostDR "total overnight capital cost of Demand Response equipment ($/client)" 
pCostOMPV "fixed O&M costs of PV per year ($/kW)" 
pCostOMHP "fixed O&M costs of HP per year ($/kW)" 
pCostOMBat "fixed O&M costs of Battery per year ($/kWh)" 
pDemandShift "percentage of load shift allowed (%)" 
pGI "global irradiance (W/m^2)" 
pCostCurveX(s,p,m,h) "energy value from energy cost curve - x_parameter (kWh) "
pCostCurveY(s,p,m,h) "energy cost value from energy cost curve - y_parameter ($/kWh)"
pDemandTher(m) "original thermal demand (kWh)"
pDNI(m,h) "direct normal irradiance (W)"
;

pCostCurveX('s1',p,m,h) = ppCostCurveXY(P,'XY0',M,H);
pCostCurveY('s1',p,m,h) = ppCostCurveXY(P,'XY1',M,H);
pDemandElec(m,h) = pDemandElec(M,H);


Variables
vCost_EnerE "total electric energy cost ($)"
vCost_EnerT "total thermal energy cost ($)"
vCost_PowE "total electric power cost ($)"
vCost_PowT "total thermal power cost ($)"
vGridEnTrans(s,m,h) "energy transaction with grid (kWh)"
vElectricCost(s,m,h) "cost of electric energy transaction ($)"
z "objective function value ($)"
;

Positive Variables
vCost_PV "total PV Investment costs ($)"
vCost_OMPV "total PV O&M costs ($)"
vCost_HP "total HP investment costs ($)"
vCost_OMHP "total HP O&M costs ($)"
vCost_Bat "total battery investment costs ($)"
vCost_OMBat "total battery O&M costs ($)"
vCost_DR "total costs for Demand Response equipment ($)"
vCapPV "installed capacity of PV (kW)"
vCapHP "installed capacity of HP (kW)"
vCapBat "installed capacity of Battery (kWh)"
vElecHPin(s,m,h) "electricity for thermal production with HP (kWh)"
vSOC(s,m,h) "battery state of charge (kWh)"
vPVProd(s,m,h) "electric energy produced by PV (kWh)"
vBatDis(s,m,h) "battery energy discharged (kWh)"
vBatCh(s,m,h) "battery energy charged (kWh)"
vDemandDec(s,m,h) "decrease in original demand (kWh)"
vDemandInc(s,m,h) "increase in original demand (kWh)"
vDemandNew(s,m,h) "new demand after load shifting (kWh)"
vGridCostElec(s,m,h) "cost of electric energy transaction with the grid ($)"
vGridEnPos(s,m,h) "total energy bought from grid per hour (kWh)"
vGridEnNeg(s,m,h) "total energy sold to grid per hour (kWh)"
vBoughtTh(s,m) "thermal energy(natural gas) bought from the grid (kWh)"
vBoughtElec(s) "electric energy bought from the grid per year (kWh)"
;

SOS2 Variables
vDelta(s,m,h,p) "SOS2 variable for piecewise linear function"  
;


Equations
eObjFun "objective function"
eCostEnerE "total costs of electric energy"
eCostEnerT "total costs of thermal energy"
eCostPowE "total costs of electric power"
eCostPowT "total costs of thermal power"
eCostPV "total installation costs of PV"
eCostOMPV "total operation and maintenance costs of PV"
eCostHP "total installation costs of heat pump"
eCostOMHP "total operation and maintenance costs of HP"
eCostBat "total installation costs of battery storage"
eCostOMBat "total operation and maintenance costs of battery storage"
eCostDR "total installation costs of demand response equipment"
eTotalDem(s,m) "total demand per day (no elasticity)"
eDemShiftBal(s,m,h) "demand shift per hour balance"
eDemShiftUB(s,m) "upper bound on demand shift per hour"
ePVProd(s,m,h) "PV generation calculation"
eHPProd(s,m) "HP production calculation"
eHPProdUB(s,m,h) "upper bounds on HP production"
eHPProdLB(s,m) "lower bounds on HP production"
eBoughtElecLB(s,m,h) "lower bounds on electricity bought from the grid"
eSupDemBal(s,m,h) "supply demand balance"
eGridTrans(s,m,h) "grid energy transfer calculation"
eGridCostElec(s,m,h) "costs of electricity bought from the grid"
eSOC1(s,m,h) "state of charge constraint 1"
eSOC2(s,m,h) "state of charge constraint 2"
eSOC3(s,m,h) "state of charge constraint 3"
eSOCUB(s,m,h) "upper bounds on state of charge constraint"
eSOCCal(s,m,h) "state of charge calculation"
eBatDisUB(s,m,h) "upper bounds on battery discharge"
eBatChUB(s,m,h) "upper bounds on battery charge"
eElectricCost(s,m,h) "electric cost calculated from energy cost curve"
eGridTransEner(s,m,h) "energy used from grid transfer calculated from energy cost curve"
;

*** Objective function ***
eObjFun..  z =e= vCost_EnerE + vCost_EnerT + vCost_PowE + vCost_PowT + vCost_PV
                 + vCost_OMPV + vCost_HP + vCost_OMHP + vCost_Bat + vCost_DR;
                 
eCostEnerE..  vCost_EnerE =e= sum(y, pPriceElec(y) * 
                                sum((s,m), pDaysinMonth(m) *
                                sum(h, vElectricCost(s,m,h) + vGridCostElec(s,m,h)) )
                                );

eCostEnerT..  vCost_EnerT =e= sum(y, pPriceTher(y) * 
                              sum((s,m),pDaysinMonth(m)*vBoughtTh(s,m) )) ;       

eCostPowE..  vCost_PowE =e= sum(y, pPriceElec(y) * pTariffElec * sum(s, vBoughtElec(s)));
eCostPowT..  vCost_PowT =e= pLifeSpanHP * pDistSize * pTariffTher;
eCostPV..  vCost_PV =e= pCostPV * vCapPV;
eCostOMPV..  vCost_OMPV =e= pCostOMPV * vCapPV * pLifeSpanPV;
eCostHP..  vCost_HP =e= pCostHP * vCapHP;
eCostOMHP..  vCost_OMHP =e= pCostOMHP * vCapHP * pLifeSpanHP;
eCostBat..  vCost_Bat =e= pCostBat * vCapBat;
eCostOMBat..  vCost_OMBat =e= pCostOMBat * vCapBat * pLifeSpanBat;
eCostDR..  vCost_DR =e= pCostDR * pDistSize;

*** Demand Response Constraints ***
eTotalDem(s,m)..  sum(h, vDemandNew(s,m,h)) =e= sum(h, pDemandElec(m,h));

eDemShiftBal(s,m,h)..  vDemandNew(s,m,h) + vDemandDec(s,m,h) =e= pDemandElec(m,h)
                                                            + vDemandInc(s,m,h);
                                                            
eDemShiftUB(s,m)..  sum(h, vDemandInc(s,m,h)) =l= pDemandShift * sum(h, pDemandElec(m,h));

*** Energy Production Constraints ***
ePVProd(s,m,h)..  vPVProd(s,m,h) =l= ((pDNI(m,h) * vCapPV)/pGI) * (1 - pPVLoss);

eHPProd(s,m)..  vBoughtTh(s,m)  =e=  pDemandTher(m) - 
                (sum(h, vElecHPin(s,m,h) * pCOP * (1 - pHPLoss))/0.8);    

eHPProdUB(s,m,h)..  vElecHPin(s,m,h) =l= vCapHP;

eHPProdLB(s,m)..  (sum(h$( 12 < ord(h) and ord(h) < 21), 
                    vElecHPin(s,m,h) * pCOP) * (1 - pHPLoss)/0.8)
                    =g= 0.3 * pDemandTher(m);         

eBoughtElecLB(s,m,h)..  vBoughtElec(s) =g= vGridEnTrans(s,m,h);

*** Supply Demand Balance ***
eSupDemBal(s,m,h)..  vGridEnTrans(s,m,h) =e= vDemandNew(s,m,h) - vPVProd(s,m,h) 
                                            + vElecHPin(s,m,h) - (vBatDis(s,m,h) * pBatEff) 
                                            + (vBatCh(s,m,h)/pBatEff);
                                       
*** Grid Electricity cost ***
eGridTrans(s,m,h)..  vGridEnPos(s,m,h) - vGridEnNeg(s,m,h) =e= vGridEnTrans(s,m,h);

eGridCostElec(s,m,h)..  vGridCostElec(s,m,h) =e= pGridTariffElec * vGridEnPos(s,m,h);

* State of Charge Constraints
eSOC1(s,m,h)..  vSOC(s,'m1','h1') =e= 0;

eSOC2(s,m,h)$(ord(m)>1)..  vSOC(s,m,'h1') =e= vSOC(s,m-1,'h24');

eSOC3(s,m,h)$(ord(m)>1 and ord(m)<3)..  vSOC(s,m,'h1') =e= vSOC(s,m,'h24');

eSOCUB(s,m,h)..  vSOC(s,m,h) =l= vCapBat;

eSOCCal(s,m,h)..  vSOC(s,m,h) =e= vSOC(s,m,h-1) - vBatDis(s,m,h) + vBatCh(s,m,h);

eBatDisUB(s,m,h)..  vBatDis(s,m,h) =l= vSOC(s,m,h-1);

eBatChUB(s,m,h)..  vBatCh(s,m,h) =l= vCapBat - vSOC(s,m,h-1);

* Piecewise Linear function Constraints
eElectricCost(s,m,h)..  vElectricCost(s,m,h) =e= sum(p, vDelta(s,m,h,p) * pCostCurveY(s,p,m,h));

eGridTransEner(s,m,h)..  vGridEnTrans(s,m,h) =e= sum(p, vDelta(s,m,h,p) * pCostCurveX(s,p,m,h));


Model der_opr "a DER operations planning model" / all /;
Option limrow = 1000000;

der_opr.savepoint = 1;
*execute_loadpoint 'der_opr_p';

der_opr.optfile = 1;
der_opr.prioropt = 1;
option optcr = 0.0001;

Solve der_opr using mip minimizing z;

execute_unload "der_opr.gdx" z, pCostCurveX, pCostCurveY, vCost_EnerE.l, 
                vCost_EnerT.l, vCost_PowE.l, vCost_PowT.l, vCost_PV.l, vCost_HP.l, vCost_Bat.l
                vPVProd.l, vGridEnTrans.l, vElectricCost.l, vSOC.l, vDemandNew.l, vCost_DR.l;
display z.l, vCost_EnerE.l, vCost_EnerT.l, vCost_PowE.l, 
            vCost_PowT.l, vCost_PV.l, vCost_HP.l, vCost_Bat.l,vCost_DR.l
            vPVProd.l, vGridEnTrans.l, vElectricCost.l, 
            vDemandNew.l,vElecHPin.l, vSOC.l, vBatDis.l, 
            vBatCh.l;
