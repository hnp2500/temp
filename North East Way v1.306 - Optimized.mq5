//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property  copyright "Myfxlab @2022"
#property  link      "https://t.me/forexeasfx"
#property version    "1.306"
#property strict
#property description  "With high risk control this ea has protection from high risk grid (only 6 steps) and additional ATR filter. \n\nDecompile sprecial for MyFxlab: telegram @MyFxLab  \n\n If interested in source code contact: telegram @MyFxLab"

#include <Trade\Trade.mqh> //Instatiate Trades Execution Library

enum NY_Weekends {
   days_0 = 2, // Days 0
   days_7 = 1, // Days 7
   days_14 = 0 // Days 14
};
enum FirstPositiontype {
   NotOpen = 4,         // Not Open
   Short = 3,           // Short Only
   Long = 2,            // Long Only
   Long_and_Short = 1   // Long+Short
};
enum TypeBFLC {
   balance = 1,         // Balance
   equity = 0           // Equity
};


//---------------------
struct T_Set {
   string  Descriz;
   long  Indic_Period;
   double  Mult_iStdDev;
   double  Mult1;
   double  Base1_Pow;
   double  Numerator;
   double  Base2_Pow;
   double  Mult_Period;
   //void T_Set_8();
   //void T_Set_9();
   //void T_Set_10();
   //void T_Set_11();
};

//Informazioni sull'ordine
//string  Sym,long pOrderType,long pOrderMagic,long pOrderTicket,string pOrderComment
struct _orderInfo {
   string orderSymbol;
   long orderType;
   long orderMagic;
   ulong orderTicket;
   string orderComment;
   datetime openTime;
};
input string _info_ = "telegram @MyFxLab"  ;
input string _information_ = "our group in telegram https://t.me/forexeasfx"  ;
input string _base_ = "=========Basic settings========="  ;
input string inMultiCurrency = "AUDNZD,NZDCAD,AUDCAD,EURCAD*0.5,EURGBP*0.5,GBPCAD*0.5,USDCAD*0.5,EURUSD*0.5,GBPUSD*0.5"  ; //OneChartSetup multi currency mode.
input string inBaseComment = "21%"  ; //Prefix for comment
input  FirstPositiontype  inFirstPositionp = Long_and_Short  ;  //First Position
input bool inFastClose = false ;  //Emergency closing at breakeven
input long   inNmbrThisServer = 1  ;  //For magic: 0 to 99
input  NY_Weekends  inHolidays = days_14  ;  //Duration of the weekend after the New Year
input bool inUseVirtualTP = false ;  //Using a virtual take-profit?
input string _mm_ = "=========Money Management Settings========="  ;
input long   inMaxOtherMagics = 0  ;  //Number of magics no more
input long   inMaxOtherSymbols = 0  ;  //Or Number of symbols no more
input  TypeBFLC  inBaseForLotCalc = equity  ;  //For autolot use
input double inVirtBalance = 0  ;  //Additional funds in account currency
input double inFix_balance = 0  ;  //Or use fix balance in account currency
input double inAutoMM = 3000  ;  //AutoMM. Aggressive=1000, Conservative=5000.
input double inLots = 0.01  ;  //Fix lot if AutoMM=0
input string _aver_ = "=========Averaging Settings========="  ;
input bool inUseUnloss = true  ;  //Recovery Mode
input double inLotsMartinp = 2.5  ;  //Martin ratio
input string _grid_ = "=========Grid Level Settings========="  ;
input long   inFirstNumberp = 3  ;  //First real deal from this level n>=0
input string _add_ = "=========Add Settings========="  ;
input bool   inRelated = false ;       //Include related symbols?
input bool  inStopLessFlag = false;   //Set StopLess when emergency closing?
input bool   inGridReset = false;  //Grid Level reset
input int   inTopGrid = 6;           //Top Grid Level
input string   inLevelSpace = "_";  //Level Space
input string   inLevelFirst = "C";  //Level First char

//Input parameters
string MultiCurrency = inMultiCurrency  ; //OneChartSetup multi currency mode.
string BaseComment = inBaseComment  ; //Prefix for comment
FirstPositiontype  FirstPositionp = inFirstPositionp  ;  //First Position
bool FastClose = inFastClose ;  //Emergency closing at breakeven
long   NmbrThisServer = inNmbrThisServer  ;  //For magic: 0 to 99
NY_Weekends  Holidays = inHolidays  ;  //Duration of the weekend after the New Year
bool UseVirtualTP = inUseVirtualTP ;  //Using a virtual take-profit?
long   MaxOtherMagics = inMaxOtherMagics  ;  //Number of magics no more
long   MaxOtherSymbols = inMaxOtherSymbols  ;  //Or Number of symbols no more
bool   Related = inRelated ;       //Include related symbols?
bool   StopLessFlag = inStopLessFlag;   //Set StopLess when emergency closing?
TypeBFLC  BaseForLotCalc = inBaseForLotCalc  ;  //For autolot use
double VirtBalance = inVirtBalance  ;  //Additional funds in account currency
double Fix_balance = inFix_balance  ;  //Or use fix balance in account currency
double AutoMM = inAutoMM  ;  //AutoMM. Aggressive=1000, Conservative=5000.
double Lots = inLots  ;  //Fix lot if AutoMM=0
bool UseUnloss = inUseUnloss  ;  //Recovery Mode
double LotsMartinp = inLotsMartinp  ;  //Martin ratio
long   FirstNumberp = inFirstNumberp  ;  //First real deal from this level n>=0

bool   GridReset = inGridReset;  //Grid Level reset
double MinProfit = 0.0004; //Min Profit
//double AllowProf = inAllowProf;
int   TopGrid = inTopGrid;           //Top Grid Level
string   LevelSpace = inLevelSpace;
string   LevelFirst = inLevelFirst;

CTrade   Trade;

T_Set     LstSet[];
string    LstSymbol[];




long       Global_Tipo_Inizializzazione = 7;
string    Global_Stringa_Parametro_01 = "";

//order level
int       global_orderLevel = 0;
//Allowable price slippage when placing an order
long       global_slippage = 10;////0;

double    global_maxSpread = 0.0;
int       Global_Indic_Period = 0;
int       Global_Indic_Period_Default = 400;

double    Golbal_Mult_iStdDev = 1.4;
int       Global_ATR_Period = 14;
double    Global_ATR_MAX = 0.0143;
bool      Use_StrangeNumber_for_iStdDev = true;
long       global_OrderMagic = 0;   //planning magic code

//Line number: 2-digit currency number + 2-digit line sequence number
long       global_lineCode = 0;

double    Global_Mult1 = 0.7;
double    Global_Base1_Pow = 0.9;
long       Global_Numerator = 70;
double    Global_Base2_Pow = 1.5;
double    Global_MA_Dist_Perc = 0.9;
double    Global_Mult_Period = 0.0;
//Risk coefficient
double    global_riskCoefficient = 0.0;
//Currency pair default multiple
double    global_defaultMulti = 1.0;
double    global_symbolMulti = 1.0;
int       global_lotsDigits = 0;
double    global_minLots = 0.0;
int       global_priceDigits = 0;

double    global_MaxLots = 100.0;
bool      Global_EnableProcessOrder = true;
double    global_lotsMartinp = 0.0;

long       global_maxLevel = 70;
long       global_maxLotLevel = 50;
long       Global_OrderLevel_Soglia = 6;

double    global_Takeprofit = 0.0;
double    global_iMaiStdDevAdd = 0.0;
double    global_iMA = 0.0;
double    global_iMaiStdDevSub = 0.0;
double    Global_iStdDev_Price = 0.0;

double    global_PriceDist = 0.0;
long       Global_iStdDev_Pips = 0;
long       global_buySellFlag = 0;

long       DTT_CandelaValutazione[100][15];

double    Global_Livello1_perTP = 0.0;
double    Global_Livello2_perTP = 0.0;
string    global_lineSeq_st = "";

double    global_ArySymbolMulti[];
int       global_ArySymbolLotsDigits[];
int       global_ArySymbolPriceDigits[];
bool      global_M15Flag = true;

// Currency pair sequence number (0,AUDCAD;1,AUDNZD;2,NZDCAD;GBPCAD,3;EURGBP,4;5,others[EURUSD GBPUSD USDCAD EURCAD]), level,
double    MatrixStrangeNumber[6][5][2];
bool      Global_ATR_underMAX = true;
string    global_labelObjAry[];
double    Global_Spread_Price = 0.0;
double    Global_Ask_Price = 0.0;
double    Global_Bid_Price = 0.0;
double    Global_Point_Price = 1; // 0.0;
double    Global_Spread_Points = 0.0;
double    Global_Bid_Su_ClosePrec = 0.0;
double    global_131_do_ko[];

//add
_orderInfo aryTardOrderInfo[];
long TimePrev = 0;
datetime Time[1];
int global_lineSeq = 1;

double global_allowSlippagePips = 2.0;
//Real-time floating profit percentage
double global_floatProfitPre = 0.0;
int global_halfTotal = 0;
int global_tradCount = 0;

int tmp_rise = 0;
bool AbsoluteProhibition = false;   //It is absolutely prohibited to open new orders
int fastCount = 10;
int maxFastCount = 0;
bool global_topFlag = false;  //Top Grid Level Flag

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   //PrintFormat("++++++++++++111 Enter OnInit+++++++++++++");
   double tmp_firstLot = 0.0;

   //Parametri di input
   MultiCurrency = inMultiCurrency  ; //OneChartSetup multi currency mode.
   BaseComment = inBaseComment  ; //Prefix for comment
   FirstPositionp = inFirstPositionp  ;  //First Position
   FastClose = inFastClose ;  //Emergency closing at breakeven
   NmbrThisServer = inNmbrThisServer  ;  //For magic: 0 to 99
   Holidays = inHolidays  ;  //Duration of the weekend after the New Year
   UseVirtualTP = inUseVirtualTP ;  //Using a virtual take-profit?
   MaxOtherMagics = inMaxOtherMagics  ;  //Number of magics no more
   MaxOtherSymbols = inMaxOtherSymbols  ;  //Or Number of symbols no more
   Related = inRelated ;       //Include related symbols?
   BaseForLotCalc = inBaseForLotCalc  ;  //For autolot use
   VirtBalance = inVirtBalance  ;  //Additional funds in account currency
   Fix_balance = inFix_balance  ;  //Or use fix balance in account currency
   AutoMM = inAutoMM  ;  //AutoMM. Aggressive=1000, Conservative=5000.
   Lots = inLots  ;  //Fix lot if AutoMM=0
   UseUnloss = inUseUnloss  ;  //Recovery Mode
   LotsMartinp = inLotsMartinp  ;  //Martin ratio
   FirstNumberp = inFirstNumberp  ;  //First real deal from this level n>=0
   GridReset = inGridReset;  //Grid Level reset
   MinProfit = 0.0004; //Min Profit
   LevelSpace = inLevelSpace;
   LevelFirst = inLevelFirst;
   TopGrid = inTopGrid;

   TimePrev = 0;

   //global_screenDpi=TerminalInfoInteger(27) * 100 / 96;
   //global_screenDpi = TerminalInfoInteger(TERMINAL_SCREEN_DPI) * 100 / 96;

   //rrr();
   if ( Period() != 15 ) {
      Print("The adviser works only on the M15 period. Change the timeframe to M15");
      Alert("The adviser works only on the M15 period. Change the timeframe to M15 and restart advosor.");
      global_M15Flag = false ;
   } else {
      global_M15Flag = true ;
   }

   global_topFlag = false;

   ArrayResize(global_ArySymbolMulti, 1, 0);
   ArrayResize(LstSymbol, 1, 0);
   ArrayResize(global_ArySymbolLotsDigits, 1, 0);
   ArrayResize(global_ArySymbolPriceDigits, 1, 0);

   //Print("&&&&MultiCurrency=",MultiCurrency);

   //if ( trim(MultiCurrency) != "" && !(MQLInfoInteger(MQL_TESTER)) ){
   if ( trim(MultiCurrency) != "") {
      fn_splitSymbol(",", MultiCurrency, LstSymbol);
      fn_splitSymbolMulti(LstSymbol, global_ArySymbolMulti);
   } else {
      LstSymbol[0] = Symbol();
      global_ArySymbolMulti[0] = global_symbolMulti;

      //Calcolare il numero di cifre decimali nella dimensione del lotto
      global_minLots = SymbolInfoDouble(LstSymbol[0], SYMBOL_VOLUME_MIN);
      int nMinLot = (int)(1 / global_minLots);
      int nMinLot2 = -1;
      while(nMinLot != 0) {
         nMinLot2 = nMinLot2 + 1;
         nMinLot = nMinLot / 10;
      }
      global_ArySymbolLotsDigits[0] = nMinLot2;

      global_ArySymbolPriceDigits[0] = (int)SymbolInfoInteger(LstSymbol[0], SYMBOL_DIGITS);
   }

   //Print("==ArraySize(global_AryTryMagic)=",ArraySize(global_AryTryMagic));

   //global_SymbolCount = ArraySize(LstSymbol) ;
   /*
   if ( MQLInfoInteger(MQL_TESTER) ){
      Sym = Symbol() ;
   }
   */

   T_Set     Sets00 = {"Set1-159", 159, 1.4, 0.4, 1, 50, 1.5, 0};
   T_Set     Sets01 = {"Set1-318", 318, 1.4, 0.4, 1, 50, 1.5, 0};
   T_Set     Sets02 = {"Set1-635", 635, 1.4, 0.4, 1, 50, 1.5, 0};
   T_Set     Sets03 = {"Set1-225", 225, 1.4, 0.4, 1, 50, 1.5, 0};
   T_Set     Sets04 = {"Set1-450", 450, 1.4, 0.4, 1, 50, 1.5, 0};
   T_Set     Sets05 = {"Set2-200", 200, 1.35, 0.7, 0.9, 70, 1.5, 0};
   T_Set     Sets06 = {"Set2-400", 400, 1.4, 0.7, 0.9, 70, 1.5, 0};
   T_Set     Sets07 = {"Set2-800", 800, 1.4, 0.65, 0.85, 30, 1.5, 0};
   T_Set     Sets08 = {"Set2-283", 283, 1.4, 0.7, 0.9, 70, 1.5, 0};
   T_Set     Sets09 = {"Set2-566", 566, 1.4, 0.7, 0.9, 70, 1.5, 0};
   T_Set     Sets10 = {"Set3-252", 252, 1.4, 0.9, 0.8, 60, 1.5, 0};
   T_Set     Sets11 = {"Set3-504", 504, 1.4, 0.9, 0.8, 60, 1.5, 0};
   T_Set     Sets12 = {"Set3-1008", 1008, 1.4, 0.85, 0.75, 20, 1.5, 0};
   T_Set     Sets13 = {"Set3-356", 356, 1.4, 0.9, 0.8, 60, 1.5, 0};
   T_Set     Sets14 = {"Set3-713", 713, 1.4, 0.85, 0.75, 20, 1.5, 0};

   if ( Global_Tipo_Inizializzazione == 1 && trim(Global_Stringa_Parametro_01) == "" ) {
      //global_linesCount = 1 ;
   } else if ( Global_Tipo_Inizializzazione == 1 && trim(Global_Stringa_Parametro_01) != "" ) {
      Decodifica_Stringa_Parametro_01(Global_Stringa_Parametro_01, LstSet);
      //global_linesCount = ArraySize(LstSet) ;
//      Set_ArrayOfSets(LstSet, ArraySets);
   } else if ( Global_Tipo_Inizializzazione == 2 ) {
      //ArrayResize(LstSet, 3, 0);
      //global_linesCount = 3 ;
      zArrayAppend(LstSet, Sets00);
      zArrayAppend(LstSet, Sets01);
      zArrayAppend(LstSet, Sets02);
   } else if ( Global_Tipo_Inizializzazione == 3 ) {
      //ArrayResize(LstSet, 3, 0);
      //global_linesCount = 3 ;
      zArrayAppend(LstSet, Sets05);
      zArrayAppend(LstSet, Sets06);
      zArrayAppend(LstSet, Sets07);
   } else if ( Global_Tipo_Inizializzazione == 4 ) {
      //ArrayResize(LstSet, 3, 0);
      //global_linesCount = 3 ;
      zArrayAppend(LstSet, Sets10);
      zArrayAppend(LstSet, Sets11);
      zArrayAppend(LstSet, Sets12);
   } else if ( Global_Tipo_Inizializzazione == 5 ) {
      //ArrayResize(LstSet, 9, 0);
      //global_linesCount = 9 ;
      zArrayAppend(LstSet, Sets00);
      zArrayAppend(LstSet, Sets01);
      zArrayAppend(LstSet, Sets02);
      zArrayAppend(LstSet, Sets05);
      zArrayAppend(LstSet, Sets06);
      zArrayAppend(LstSet, Sets07);
      zArrayAppend(LstSet, Sets10);
      zArrayAppend(LstSet, Sets11);
      zArrayAppend(LstSet, Sets12);
   } else if ( Global_Tipo_Inizializzazione == 6 ) {
      //ArrayResize(LstSet, 3, 0);
      //global_linesCount = 3 ;
      zArrayAppend(LstSet, Sets01);
      zArrayAppend(LstSet, Sets06);
      zArrayAppend(LstSet, Sets11);
   } else if ( Global_Tipo_Inizializzazione == 7 ) {
      //ArrayResize(LstSet, 15, 0);
      //global_linesCount = 15 ;
      zArrayAppend(LstSet, Sets00);
      zArrayAppend(LstSet, Sets01);
      zArrayAppend(LstSet, Sets02);
      zArrayAppend(LstSet, Sets03);
      zArrayAppend(LstSet, Sets04);
      zArrayAppend(LstSet, Sets05);
      zArrayAppend(LstSet, Sets06);
      zArrayAppend(LstSet, Sets07);
      zArrayAppend(LstSet, Sets08);
      zArrayAppend(LstSet, Sets09);
      zArrayAppend(LstSet, Sets10);
      zArrayAppend(LstSet, Sets11);
      zArrayAppend(LstSet, Sets12);
      zArrayAppend(LstSet, Sets13);
      zArrayAppend(LstSet, Sets14);
   }

   global_riskCoefficient = (AutoMM == 0.0) ? 0.0 : 1000.0 / AutoMM / ArraySize(LstSet);
   //Print("+++++global_riskCoefficient=",global_riskCoefficient);
   if ( !(UseUnloss) ) {
      global_maxLevel = 7 ;
      global_maxLotLevel = 5 ;
   }
   if (FastClose) {
      global_maxLevel = 6 ;
      global_maxLotLevel = 6 ;
   }
   Init_Factor_for_StrangeNumber();
   //Suppress display of indicators
   TesterHideIndicators(true);

   for (int I = 0 ; I < ArraySize(LstSymbol) ; I ++) {
      string Sym = LstSymbol[I] ;
      for (int J = 1 ; J <= ArraySize(LstSet) ; J ++) {
         global_lineSeq_st = IntegerToString(J, 2, 48) ;
         global_lineCode = (long)StringToInteger(GetSymbolNumber(Sym) + global_lineSeq_st) ;
         //Line ID
         global_OrderMagic = (long)StringToInteger( GetMagic(global_lineSeq_st )) ;
         GlobalVariableSet(fn_isTestToStr() + "Magic" + Sym + string(global_lineCode), global_OrderMagic);
         //global_85_do_si7si10000[3][0] = AccountInfoDouble(ACCOUNT_EQUITY);
      }
   }

   PreControl();

   if (GridReset) {
      //fn_resetLine();
   }

   EventSetTimer(1);

   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PreControl() {
   //ArraySetAsSeries(Time,true);
   CopyTime(_Symbol, _Period, 0, 1, Time);
   //Print("########TimePrev=",TimePrev,";Time[0]=",(long)Time[0]);
   if (TimePrev != (long)Time[0]) {
      TimePrev = (long)Time[0]; //Current time (second level)

      //Print("########Start reading positions");


      tmp_rise = (int)AutoMM;
      if (tmp_rise == 0) {
         tmp_rise = 3000;
      }

      //Read position order information
      global_tradCount = fn_getTradeOrderInfo();
      if (global_halfTotal >= fastCount * 3 / FirstNumberp) {
         PrintFormat("Warning!!! The number of orders opened within 40 minutes %d >= 10, automatically enters emergency processing status!", global_halfTotal);
         FastClose = true;
         FirstPositionp = NotOpen;
         global_maxLevel = 6 ;
         global_maxLotLevel = 6 ;
         AbsoluteProhibition = true;
      } else
         //The real-time floating profit percentage is low and the emergency processing state is carried out.
         if (global_floatProfitPre <= (-0.2) * 3000 / tmp_rise) {
            FastClose = true;
            FirstPositionp = NotOpen;
            global_maxLevel = 6 ;
            global_maxLotLevel = 6 ;
         } else if (false == inFastClose && true == FastClose && global_tradCount < 10 * 3 / FirstNumberp && global_floatProfitPre >= (-0.067) * 3000 / tmp_rise) {
            FastClose = false;
            FirstPositionp = Long_and_Short;
            global_maxLevel = 70 ;
            global_maxLotLevel = 50 ;
            AbsoluteProhibition = false;
         }
   }
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {

//   string CMT = "";
//   for(int GV = 0; GV < GlobalVariablesTotal(); GV++) {
//      string GVN = GlobalVariableName(GV);
//      double GVV = GlobalVariableGet(GVN);
//      datetime GVT = GlobalVariableTime(GVN);
//      StringReplace(GVN, "true", "");
//      StringReplace(GVN, Symbol(), "");
//
//      CMT += (CMT == "" ? "" : ( GV % ArraySize(LstSet) == 0 ? "\n" : " - ")) + /*IntegerToString(GV) + */GVN + "=" + DoubleToString( GVV, Digits());
//   }
//   Comment(CMT);



   double local_avgPrice = 0.0;
   long tmp_tradCount = 0;
   long local_otherMagicsCount = 0;
   long local_otherSymbolsCount = 0;
   double tmp_firstLot = 0.0;
   double local_sendLots = 0.0;
   double local_realProf = 0.0;
   int local_orderCount = 0;
   string strMultiCurrency = "";

   // verifico di essere in M15 altrimenti stop
   if ( !(global_M15Flag)) {
      Print("The adviser adapted only on the M15 period. Change the timeframe to M15");
   }

   /*
   if (global_closeNum >= 3){
      Sleep(3000);
   }
   */

   PreControl();

   for (int i = 0 ; i < ArraySize(LstSymbol) ; i ++) {
////      Sym = fn_checkSymbol( LstSymbol[i] ) ;
      string Sym = ( LstSymbol[i] ) ;
      if ( Sym == "" )   continue;

      global_symbolMulti = global_ArySymbolMulti[i] ;
      global_lotsDigits = global_ArySymbolLotsDigits[i];
      global_minLots = SymbolInfoDouble(Sym, SYMBOL_VOLUME_MIN);
      global_priceDigits = global_ArySymbolPriceDigits[i];

      if ( ArraySize(LstSet) < 1 )   continue;



      for (global_lineSeq = 1 ; global_lineSeq <= ArraySize(LstSet) ; global_lineSeq ++) {
         if ( UseVirtualTP ) {
            if (fn_isExistOrder(Sym, -1, -1, 0, "") ) {
               fn_getEvnPara(Sym, global_lineSeq);
               fn_orderClose_onTP(Sym);
            }
         }
         if ( FastClose ) {
            if ( fn_isExistOrder(Sym, -1, -1, 0, "") ) {
               fn_getEvnPara(Sym, global_lineSeq);
               if ( fn_orderProfitTotal(Sym, -1, global_OrderMagic) > 0.0 ) {
                  fn_orderCloseByPara(Sym, -1, global_OrderMagic);
               }
            }
         }

         if ( DTT_CandelaValutazione[global_lineSeq][i] == iTime(Sym, PERIOD_CURRENT, 0) ) {
            continue;
         }

         fn_getEvnPara(Sym, global_lineSeq);

         tmp_rise = (int)AutoMM;
         if (tmp_rise == 0) {
            tmp_rise = 3000;
         }

         if (AbsoluteProhibition || global_floatProfitPre <= (-0.2) * 3000 / tmp_rise - 0.05) {
            FastClose = true;
            FirstPositionp = NotOpen;
            global_maxLevel = 6 ;
            global_maxLotLevel = 6 ;
            //AbsoluteProhibition = true;

            //Set stop loss
            if (StopLessFlag) {
               //PrintFormat("11111 %s %d Set stop loss",Sym,global_OrderMagic);
               fn_ModifyStopLoss(Sym, global_OrderMagic);
            }
         }

         // buy ammessi e il max tra H_1 e Bid >= alla GV tp
         if ( Get_BuySell_Enabled(Sym, ORDER_TYPE_BUY) && MathMax(iHigh(Sym, PERIOD_CURRENT, 1), Global_Bid_Price) >= GlobalVariableGet(fn_isTestToStr() + Sym + string(global_lineCode) + "tp") ) {
            //SELL logo
            GlobalVariableSet(fn_isTestToStr() + Sym + "0" + string(global_lineCode), 0.0);
            //level -1
            GlobalVariableSet(fn_isTestToStr() + "NUMBER" + Sym + string(global_lineCode), 0.0);
         }
         // sell ammessi e il min tra (L_1 + spread) e Ask <= GV tp
         if ( Get_BuySell_Enabled(Sym, ORDER_TYPE_SELL) && MathMin(iLow(Sym, PERIOD_CURRENT, 1) + Global_Ask_Price - Global_Bid_Price, Global_Ask_Price) <= GlobalVariableGet(fn_isTestToStr() + Sym + string(global_lineCode) + "tp") ) {
            //BUY logo
            GlobalVariableSet(fn_isTestToStr() + Sym + "1" + string(global_lineCode), 0.0);
            GlobalVariableSet(fn_isTestToStr() + "NUMBER" + Sym + string(global_lineCode), 0.0);
         }
         if ( global_iMaiStdDevAdd == 0.0 ) {
            continue;
         }

         if ( Global_EnableProcessOrder && Global_ATR_underMAX ) {
            CalcoloLivelliAperture(Sym);
         }
         //BuySell logo: 1,buy;2,sell
         global_buySellFlag = fn_buySellFlag(Sym) ;
         long   local_3_in = 0 ;
         double   local_7_in = 0 ;
         if ( fn_isExistOrder(Sym, -1, global_OrderMagic, 0, "") ) {
            continue;
         }

         //Plan failed
         if ( fn_lineEnabled(Sym) || !(Global_ATR_underMAX) ) {
            //Print("====1 fn_lineEnabled()=",fn_lineEnabled(),";Global_ATR_underMAX=",Global_ATR_underMAX);
            continue;
         }
         if ( isHolidays() != "" ) {
            //Print("====2");
            continue;
         }

         long    Tkt = 0 ;
         if ( global_buySellFlag == 1 ) {
            // ho il flag buy
            //Print("====3");
            bool   NoCanBuy = false;
            if ( FirstNumberp >  global_orderLevel ) {
               // se il numero di ordini è inferiore al paramentro primo ordine
               //Print("====4");
               //Set the long order flag to 1
               GlobalVariableSet(fn_isTestToStr() + Sym + "0" + string(global_lineCode), 1.0);
               NoCanBuy = true ;
               Tkt = -1 ;
               Print("1 ", Sym + " " + string(global_OrderMagic) + " The opened grid level(", global_orderLevel, ") is less than the minimum level(", FirstNumberp, "). The deal is virtualized");
            } else {
               // il numero di ordini è superiore al paramentro primo ordine
               //Print("====5");
               local_sendLots = fn_comBaseLots(Sym, true);
               if ( local_sendLots < global_minLots ) {
                  // se i lotti calcolati sono inferiori ai lotti minimi
                  //Set the long order flag to 1
                  GlobalVariableSet(fn_isTestToStr() + Sym + "0" + string(global_lineCode), 1.0);
                  NoCanBuy = true ;
                  Tkt = -1 ;
                  Print("2 ", Sym + " " + string(global_OrderMagic) + " Current lot(", local_sendLots, ") < ", DoubleToString(global_minLots, global_lotsDigits), ". The deal is virtualized");
               } else {
                  // i lotti calcolati sono superiori a quelli minimi
                  if ( MaxOtherMagics > 0 ) {
                     // posso avere altri magic
                     local_otherMagicsCount = fn_getOtherMagicsCount("", global_OrderMagic);
                     //Print("&&&&2MaxOtherMagics=",MaxOtherMagics,";local_otherMagicsCount=",local_otherMagicsCount);
                     if ( local_otherMagicsCount >= MaxOtherMagics ) {
                        // gli altri magic sono troppi
                        GlobalVariableSet(fn_isTestToStr() + Sym + "0" + string(global_lineCode), 1.0);
                        NoCanBuy = true ;
                        Tkt = -1 ;
                        Print("3 ", Sym + " " + string(global_OrderMagic) + " GetOtherMagicsCount(", local_otherMagicsCount, ") >= MaxOtherMagics(", MaxOtherMagics, "). The deal is virtualized");
                        //continue;
                     }
                  } else {
                     // non posso avere altri magic
                     if ( MaxOtherSymbols >  0 ) {
                        // posso avere altri symbol
                        local_otherSymbolsCount = fn_GetOtherSymbolsCount(Sym);
                        //Print("&&&&12MaxOtherSymbols=",MaxOtherSymbols,";local_otherSymbolsCount=",local_otherSymbolsCount,
                        //   ";local_otherSymbolsCount_old=",fn_GetOtherSymbolsCount_old(Sym));
                        if ( local_otherSymbolsCount >= MaxOtherSymbols ) {
                           // gli altri symbol sono più del massimo consentito
                           GlobalVariableSet(fn_isTestToStr() + Sym + "0" + string(global_lineCode), 1.0);
                           NoCanBuy = true ;
                           Tkt = -1 ;
                           Print("4 ", Sym + " " + string(global_OrderMagic) + " GetOtherSymbolsCount(", local_otherSymbolsCount, ") >= MaxOtherSymbols(", MaxOtherSymbols, "). The deal is virtualized");
                           //continue;
                        }
                     }
                  }

                  //BUY Creare e modificare ordini
                  if (NoCanBuy == false) {
                     // il flag è 0 posso ordinare
                     Tkt = fn_createOrder(Sym, ORDER_TYPE_BUY, fn_comBaseLots(Sym, true), 0, 0, global_OrderMagic, LevelFirst + "0", 0.0) ;
                     if ( Tkt >  0 ) {
                        NoCanBuy = true  ;
                     }
                  }
               }
            }
            if ( NoCanBuy == true ) {
               Global_iStdDev_Pips = (long)((global_iMaiStdDevAdd - global_iMA) / Global_Point_Price) ;
               global_PriceDist = MathMin(iClose(Sym, PERIOD_CURRENT, 1), Global_Bid_Price) + Global_Ask_Price - Global_Bid_Price - Global_iStdDev_Pips * Global_Point_Price ;
               global_PriceDist = NormalizeDouble(global_PriceDist, global_priceDigits);
               GlobalVariableSet(fn_isTestToStr() + "NUMBER" + Sym + string(global_lineCode), 0.0);
               GlobalVariableSet(fn_isTestToStr() + "Distance_Price" + Sym + string(global_lineCode), global_PriceDist);
               //Create planning lines
////               CreateModifyLine_G();
            }
         }
         if ( global_buySellFlag != 2 ) {

            bool   NoCanSell = false;
            if ( FirstNumberp >  global_orderLevel ) {
               //Print("====6");
               //Imposta il flag vuoto su 1
               GlobalVariableSet(fn_isTestToStr() + Sym + "1" + string(global_lineCode), 1.0);
               NoCanSell = true ;
               Tkt = -1 ;
               Print("5 ", Sym + " " + string(global_OrderMagic) + " The opened grid level(", global_orderLevel, ") is less than the minimum level(", FirstNumberp, "). The deal is virtualized");
            } else {
               //Print("====7");
               local_sendLots = fn_comBaseLots(Sym, true);
               if ( local_sendLots < global_minLots ) {
                  //Imposta il flag vuoto su 1
                  GlobalVariableSet(fn_isTestToStr() + Sym + "1" + string(global_lineCode), 1.0);
                  NoCanSell = true ;
                  Tkt = -1 ;
                  Print("6 ", Sym + " " + string(global_OrderMagic) + " Current lot(", local_sendLots, ") < ", DoubleToString(global_minLots, global_lotsDigits), ". The deal is virtualized");
               } else {
                  if ( MaxOtherMagics >  0 ) {
                     local_otherMagicsCount = fn_getOtherMagicsCount("", global_OrderMagic);
                     //Print("&&&&3MaxOtherMagics=",MaxOtherMagics,";local_otherMagicsCount=",local_otherMagicsCount);
                     if ( local_otherMagicsCount >= MaxOtherMagics ) {
                        //Imposta il flag vuoto su 1
                        GlobalVariableSet(fn_isTestToStr() + Sym + "1" + string(global_lineCode), 1.0);
                        NoCanSell = true ;
                        Tkt = -1 ;
                        Print("7 ", Sym + " " + string(global_OrderMagic) + " GetOtherMagicsCount(", local_otherMagicsCount, ") >= MaxOtherMagics(", MaxOtherMagics, "). The deal is virtualized");
                        //continue;
                     }
                  } else {
                     if ( MaxOtherSymbols >  0 ) {
                        local_otherSymbolsCount = fn_GetOtherSymbolsCount(Sym);
                        //Print("&&&&13MaxOtherSymbols=",MaxOtherSymbols,";local_otherSymbolsCount=",local_otherSymbolsCount,
                        //   ";local_otherSymbolsCount_old=",fn_GetOtherSymbolsCount_old(Sym));
                        if ( local_otherSymbolsCount >= MaxOtherSymbols ) {
                           //Imposta il flag vuoto su 1
                           GlobalVariableSet(fn_isTestToStr() + Sym + "1" + string(global_lineCode), 1.0);
                           NoCanSell = true ;
                           Tkt = -1 ;
                           Print("8 ", Sym + " " + string(global_OrderMagic) + " GetOtherSymbolsCount(", local_otherSymbolsCount, ") >= MaxOtherSymbols(", MaxOtherSymbols, "). The deal is virtualized");
                           //continue;
                        }
                     }
                  }

                  //SELL Creare e modificare ordini
                  if (NoCanSell == false) {
                     Tkt = fn_createOrder(Sym, ORDER_TYPE_SELL, fn_comBaseLots(Sym, true), 0, 0, global_OrderMagic, LevelFirst + "0", 0.0) ;
                     if ( Tkt >  0 ) {
                        NoCanSell = true ;
                     }
                  }
               }
            }
            if ( NoCanSell == true ) {
               Global_iStdDev_Pips = (long)((global_iMaiStdDevAdd - global_iMA) / Global_Point_Price) ;
               global_PriceDist = MathMax(iClose(Sym, PERIOD_CURRENT, 1), Global_Bid_Price) + Global_iStdDev_Pips * Global_Point_Price  ;
               global_PriceDist = NormalizeDouble(global_PriceDist, global_priceDigits);
               GlobalVariableSet(fn_isTestToStr() + "NUMBER" + Sym + string(global_lineCode), 0.0);
               GlobalVariableSet(fn_isTestToStr() + "Distance_Price" + Sym + string(global_lineCode), global_PriceDist);
               //Create planning lines
////         CreateModifyLine_G();
            }
         }
      }
   }

   for (int NSym = 0 ; NSym < ArraySize(LstSymbol) ; NSym ++) {
      string Sym = LstSymbol[NSym] ;
      global_symbolMulti = global_ArySymbolMulti[NSym] ;
      global_lotsDigits = global_ArySymbolLotsDigits[NSym];
      global_minLots = SymbolInfoDouble(Sym, SYMBOL_VOLUME_MIN);
      global_priceDigits = global_ArySymbolPriceDigits[NSym];

      if ( SymbolInfoDouble(Sym, SYMBOL_BID) == 0.0 ) {
         continue;
      }

      if ( ArraySize(LstSet) < 1 ) {
         continue;
      }
      for (int lineSeq = 1 ; lineSeq <= ArraySize(LstSet) ; lineSeq ++) {
         // lavoro a nuova candela
         if ( DTT_CandelaValutazione[lineSeq][NSym] == iTime(Sym, 0, 0) ) {
            continue;
         }
         // memorizzo la candela
         DTT_CandelaValutazione[lineSeq][NSym] = (long)iTime(Sym, 0, 0);

         fn_getEvnPara(Sym, lineSeq);

         if ( fn_isExistOrder(Sym, ORDER_TYPE_BUY, global_OrderMagic, 0, "") || Get_BuySell_Enabled(Sym, ORDER_TYPE_BUY)) {
            // ho ordine buy o ho buy abilitato

            // calcolo il punto di BE
            local_avgPrice = fn_avgOrderOpenPrice(Sym, ORDER_TYPE_BUY, global_OrderMagic);
            // calcolo il TP
            Global_Livello1_perTP = MathPow(Global_Base2_Pow, MathLog(Global_Indic_Period / 100.0) / 0.6931471805599) * Global_Numerator / MathPow(Global_Base2_Pow, 2.0) * Global_Bid_Price * 0.00001 + local_avgPrice ;
            Global_Livello2_perTP = MathPow(Global_Base2_Pow, MathLog(Global_Indic_Period / 100.0) / 0.6931471805599) * Global_Numerator / MathPow(Global_Base2_Pow, 2.0) * Global_Bid_Price * 0.00001 + Global_Mult1 * MathPow(Global_Base1_Pow, global_orderLevel) * (global_iMA - Global_Bid_Price) + Global_Ask_Price ;
            if ( UseUnloss ) {
               global_Takeprofit = !fn_isExistOrder(Sym, ORDER_TYPE_BUY, global_OrderMagic, 0, "") ? Global_Livello2_perTP : MathMax(Global_Livello1_perTP, Global_Livello2_perTP) ;
               global_Takeprofit = (global_orderLevel >= Global_OrderLevel_Soglia) ? Global_Livello1_perTP : global_Takeprofit  ;

               if (local_avgPrice > 0) {
                  if (global_Takeprofit < local_avgPrice + MinProfit) {
                     global_Takeprofit = local_avgPrice + MinProfit;
                  }
               }
            } else {
               global_Takeprofit = Global_Livello2_perTP ;
            }
            global_Takeprofit = NormalizeDouble(global_Takeprofit, global_priceDigits);
            // riposiziono i TP
            if ( !(UseVirtualTP) ) {
               //Modify order (multiple orders)
               fn_ModifyTakeprofit(Sym, ORDER_TYPE_BUY, global_OrderMagic, global_Takeprofit);
            } else {
               //Modify order (multiple orders)
               fn_ModifyTakeprofit(Sym, ORDER_TYPE_BUY, global_OrderMagic, 0.0);
            }
            GlobalVariableSet(fn_isTestToStr() + Sym + string(global_lineCode) + "tp", global_Takeprofit);
            double   local_iLow = GlobalVariableGet(fn_isTestToStr() + Sym + string(global_lineCode) + "peak") ;
            if ( ( iLow(Sym, PERIOD_CURRENT, 1) < local_iLow || local_iLow == 0.0 ) ) {
               local_iLow = iLow(Sym, PERIOD_CURRENT, 1) ;
               GlobalVariableSet(fn_isTestToStr() + Sym + string(global_lineCode) + "peak", local_iLow);
            }

            // verifico se devo eseguire chiusure
            if ( global_iMA - local_iLow != 0.0 && (Global_Bid_Price - local_iLow) / (global_iMA - local_iLow) > Global_MA_Dist_Perc ) {
               if ( !(UseUnloss) || (fn_orderProfitTotal(Sym, ORDER_TYPE_BUY, global_OrderMagic) > 0.0 && Global_Bid_Price > local_avgPrice + MinProfit && UseUnloss)) {
                  fn_orderCloseByPara(Sym, -1, global_OrderMagic);
                  if ( !fn_isExistOrder(Sym, -1, global_OrderMagic, 0, "") ) {
                     GlobalVariableSet(fn_isTestToStr() + Sym + "0" + string(global_lineCode), 0.0);
                     GlobalVariableSet(fn_isTestToStr() + "NUMBER" + Sym + string(global_lineCode), 0.0);
                  }
               }
            }
         }

         if ( fn_isExistOrder(Sym, ORDER_TYPE_SELL, global_OrderMagic, 0, "") || Get_BuySell_Enabled(Sym, ORDER_TYPE_SELL)) {
            // ho ordine buy o ho buy abilitato

            // calcolo il punto di BE
            local_avgPrice = fn_avgOrderOpenPrice(Sym, ORDER_TYPE_SELL, global_OrderMagic);
            // calcolo il TP
            Global_Livello1_perTP = local_avgPrice - MathPow(Global_Base2_Pow, MathLog(Global_Indic_Period / 100.0) / 0.6931471805599) * Global_Numerator / MathPow(Global_Base2_Pow, 2.0) * Global_Bid_Price * 0.00001 ;
            Global_Livello2_perTP = Global_Bid_Price - Global_Mult1 * MathPow(Global_Base1_Pow, global_orderLevel) * (Global_Bid_Price - global_iMA) - MathPow(Global_Base2_Pow, MathLog(Global_Indic_Period / 100.0) / 0.6931471805599) * Global_Numerator / MathPow(Global_Base2_Pow, 2.0) * Global_Bid_Price * 0.00001 ;
            if ( UseUnloss ) {
               global_Takeprofit = !fn_isExistOrder(Sym, ORDER_TYPE_SELL, global_OrderMagic, 0, "") ? Global_Livello2_perTP : MathMin(Global_Livello1_perTP, Global_Livello2_perTP);
               global_Takeprofit = (global_orderLevel >= Global_OrderLevel_Soglia) ? Global_Livello1_perTP : global_Takeprofit;

               if (local_avgPrice > 0) {
                  if (global_Takeprofit > local_avgPrice - MinProfit) {
                     global_Takeprofit = local_avgPrice - MinProfit;
                  }
               }
            } else {
               global_Takeprofit = Global_Livello2_perTP ;
            }
            global_Takeprofit = NormalizeDouble(global_Takeprofit, global_priceDigits);
            // riposiziono i TP
            if ( !(UseVirtualTP) ) {
               //Modify order (empty order)
               fn_ModifyTakeprofit(Sym, ORDER_TYPE_SELL, global_OrderMagic, global_Takeprofit);
            } else {
               //Modify order (empty order)
               fn_ModifyTakeprofit(Sym, ORDER_TYPE_SELL, global_OrderMagic, 0.0);
            }
            GlobalVariableSet(fn_isTestToStr() + Sym + string(global_lineCode) + "tp", global_Takeprofit);
            double   local_iHigh = GlobalVariableGet(fn_isTestToStr() + Sym + string(global_lineCode) + "peak") ;
            if ( ( iHigh(Sym, PERIOD_CURRENT, 1) > local_iHigh || local_iHigh == 0.0 ) ) {
               local_iHigh = iHigh(Sym, PERIOD_CURRENT, 1) ;
               GlobalVariableSet(fn_isTestToStr() + Sym + string(global_lineCode) + "peak", local_iHigh);
            }

            // verifico che il bod non sia 0 perchè è al denominatore
            double    local_bid = SymbolInfoDouble(Sym, SYMBOL_BID) ;
            if ( local_bid <= 0.0 ) {
               continue;
            }
            // calcolo lo spreat
            double local_spread = ((SymbolInfoDouble(Sym, SYMBOL_ASK) - local_bid) / local_bid) * 100000.0 ;
            //ask > bid

            // verifico se devo eseguire chiusure
            if ( ((local_iHigh - global_iMA) != 0.0) && (local_spread < 50.0) && ((local_iHigh - Global_Bid_Price) / (local_iHigh - global_iMA) > Global_MA_Dist_Perc) ) { //Spread less than 5 pips

               if ( !(UseUnloss) || (fn_orderProfitTotal(Sym, ORDER_TYPE_SELL, global_OrderMagic) > 0.0 && Global_Ask_Price < local_avgPrice - MinProfit && UseUnloss) ) {
                  fn_orderCloseByPara(Sym, -1, global_OrderMagic);
                  if ( !fn_isExistOrder(Sym, -1, global_OrderMagic, 0, "") ) {
                     GlobalVariableSet(fn_isTestToStr() + Sym + "1" + string(global_lineCode), 0.0);
                     GlobalVariableSet(fn_isTestToStr() + "NUMBER" + Sym + string(global_lineCode), 0.0);
                  }
               }
            }
         }
      }
   }

   if ( ( MQLInfoInteger(MQL_TESTER) && !(MQLInfoInteger(MQL_VISUAL_MODE)) ) ) {
      return;
   }

   ////fn_setRealInfo();
}
//OnTick <<==--------   --------

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int fn_getTradeOrderInfo() {
   int i = 0;
   int orderCount = 0;
   int tardOrderCount = 0;

   ulong tmp_ticket = 0;
   ulong orderType = 0;
   string localOrderComm;
   int allFindLoc = 0;
   double tmp_floatProfit = 0.0;
   long tmp_curTime = (long)TimeCurrent();
   int realCount = 0;
   int orderLevel = 0;

   global_topFlag = false;
   global_halfTotal = 0;
   ArrayResize(aryTardOrderInfo, tardOrderCount, 0);

   orderCount = PositionsTotal();
   for(i = 0; i < orderCount; i++) {
      // 获得订单的唯一编号
      tmp_ticket = PositionGetTicket(i);

      if ( !PositionSelectByTicket(tmp_ticket) ) {
         continue;
      }

      //processing level
      localOrderComm = PositionGetString(POSITION_COMMENT);
      allFindLoc = StringFind(localOrderComm, LevelSpace + LevelFirst);
      if (-1 == allFindLoc) {
         continue;
      }
      orderLevel = (int)StringToInteger(StringSubstr(localOrderComm, allFindLoc + StringLen(LevelSpace + LevelFirst)));
      if (orderLevel >= TopGrid) {
         global_topFlag = true;
      }

      tmp_floatProfit = tmp_floatProfit + PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if (tmp_curTime - (long)PositionGetInteger(POSITION_TIME) <= 40 * 60) {
         global_halfTotal = global_halfTotal + 1;
      }

      realCount = realCount + 1;

      tardOrderCount = tardOrderCount + 1;
      ArrayResize(aryTardOrderInfo, tardOrderCount, 0);
      aryTardOrderInfo[tardOrderCount - 1].orderComment = localOrderComm;
      aryTardOrderInfo[tardOrderCount - 1].orderMagic = (long)PositionGetInteger(POSITION_MAGIC);
      aryTardOrderInfo[tardOrderCount - 1].orderSymbol = PositionGetString(POSITION_SYMBOL);
      aryTardOrderInfo[tardOrderCount - 1].orderTicket = tmp_ticket;
      aryTardOrderInfo[tardOrderCount - 1].orderType = (long)PositionGetInteger(POSITION_TYPE);
      aryTardOrderInfo[tardOrderCount - 1].openTime = (datetime)PositionGetInteger(POSITION_TIME);
   }

   orderCount = OrdersTotal();
   for(i = 0; i < orderCount; i++) {
      // 获得订单的唯一编号
      tmp_ticket = OrderGetTicket(i);

      if ( !OrderSelect(tmp_ticket) ) {
         continue;
      }

      orderType = OrderGetInteger(ORDER_TYPE);

      //processing level
      localOrderComm = OrderGetString(ORDER_COMMENT);
      allFindLoc = StringFind(localOrderComm, LevelSpace + LevelFirst);
      if (-1 == allFindLoc) {
         continue;
      }
      orderLevel = (int)StringToInteger(StringSubstr(localOrderComm, allFindLoc + StringLen(LevelSpace + LevelFirst)));
      if (orderLevel >= TopGrid) {
         global_topFlag = true;
      }

      //PositionGetInteger(POSITION_TIME); PositionGetString(POSITION_SYMBOL)
      tardOrderCount = tardOrderCount + 1;
      ArrayResize(aryTardOrderInfo, tardOrderCount, 0);
      aryTardOrderInfo[tardOrderCount - 1].orderComment = localOrderComm;
      aryTardOrderInfo[tardOrderCount - 1].orderMagic = (long)OrderGetInteger(ORDER_MAGIC);
      aryTardOrderInfo[tardOrderCount - 1].orderSymbol = OrderGetString(ORDER_SYMBOL);
      aryTardOrderInfo[tardOrderCount - 1].orderTicket = tmp_ticket;
      if (ORDER_TYPE_BUY_LIMIT == orderType) {
         aryTardOrderInfo[tardOrderCount - 1].orderType = POSITION_TYPE_BUY;
      } else {
         aryTardOrderInfo[tardOrderCount - 1].orderType = POSITION_TYPE_SELL;
      }
      //aryTardOrderInfo[tardOrderCount - 1].orderType = (long)PositionGetInteger(POSITION_TYPE);
      aryTardOrderInfo[tardOrderCount - 1].openTime = (datetime)OrderGetInteger(ORDER_TIME_DONE);
   }

   if (MQLInfoInteger(MQL_TESTER) && !(MQLInfoInteger(MQL_VISUAL_MODE))) {
      if ( AccountInfoDouble(ACCOUNT_BALANCE) > 0.0 ) {
         global_floatProfitPre = tmp_floatProfit / AccountInfoDouble(ACCOUNT_BALANCE);
      } else {
         global_floatProfitPre = 0.0;
      }
   }

   if (0 == realCount && tardOrderCount > 0) {
      //Delete pending order
      for(i = 0; i < tardOrderCount; i++) {
         if (!Trade.OrderDelete(aryTardOrderInfo[i].orderTicket)) {
//         if (!OrderDeleteMQL4(aryTardOrderInfo[i].orderTicket, aryTardOrderInfo[i].orderSymbol)) {
            PrintFormat("Deletion of pending order %d failed, please check!", aryTardOrderInfo[i].orderTicket);
         }
      }
      ArrayResize(aryTardOrderInfo, 0, 0);
   }

   //Print("+++++++++tardOrderCount=",tardOrderCount);
   if (0 == maxFastCount || maxFastCount < global_halfTotal) {
      maxFastCount = global_halfTotal;
   }

   return (realCount);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   if (MQLInfoInteger(MQL_TESTER) && !(MQLInfoInteger(MQL_VISUAL_MODE))) {
      return;
   }
   //Print("++++in Timer1");
   ////fn_setRealInfo();
}
//OnTimer <<==--------   --------

double OnTester() {
   /*
   ArrayResize(global_131_do_ko,global_89_in - 1,0);
   for (int local_2_in = 1 ; local_2_in < global_89_in ; local_2_in ++)
   {
      global_131_do_ko[local_2_in - 1] = global_85_do_si7si10000[3][local_2_in] / global_85_do_si7si10000[3][local_2_in - 1] - 1.0;
   }
   ArraySetAsSeries (global_131_do_ko,true);
   double local_3_do = iMAOnArray(global_131_do_ko,0,global_89_in - 1,0,0,0) ;
   double local_4_do = iStdDevOnArray(global_131_do_ko,0,global_89_in - 1,0,0,0) ;
   if ( local_4_do!=0.0 ){
      return(local_3_do / local_4_do);
   }
   */
   return(0.0);
}
//OnTester <<==--------   --------

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   EventKillTimer();

   /*
   if ( MQLInfoInteger(MQL_TESTER) && global_47_bo ){
      lizong_22();
   }
   if ( MQLInfoInteger(MQL_TESTER) && global_48_bo ){
      lizong_21();
   }
   */
   for (int I = 0 ; I < ArraySize(LstSymbol) ; I ++) {
      string Sym = LstSymbol[I] ;

      //Print("----",Sym," begin;ArraySize(LstSet)=",ArraySize(LstSet));
      for (int I = 1 ; I <= ArraySize(LstSet) ; I ++) {
         global_lineSeq_st = IntegerToString(I, 2, 48) ;
         global_lineCode = (long)StringToInteger(( StringLen(Sym)  != 6 ) ? "99" : GetCurrencyNumber(StringSubstr(Sym, 0, 3)) + GetCurrencyNumber(StringSubstr(Sym, 3, 3)) + global_lineSeq_st) ;

         /*
         //falseNUMBEREURCAD3215
         Print(fn_isTestToStr() + "NUMBER" + Sym + string(global_lineCode)," = ",
            GlobalVariableGet(fn_isTestToStr() + "NUMBER" + Sym + string(global_lineCode)));
         //falseiBands_periodEURCAD3215
         Print(fn_isTestToStr() + "iBands_period" + Sym + string(global_lineCode)," = ",
            GlobalVariableGet(fn_isTestToStr() + "iBands_period" + Sym + string(global_lineCode)));
         //falseDistance_PriceEURCAD3215
         Print(fn_isTestToStr() + "Distance_Price" + Sym + string(global_lineCode)," = ",
            GlobalVariableGet(fn_isTestToStr() + "Distance_Price" + Sym + string(global_lineCode)));
         //falseEURCAD3215peak
         Print(fn_isTestToStr() + Sym + string(global_lineCode) + "peak"," = ",
            GlobalVariableGet(fn_isTestToStr() + Sym + string(global_lineCode) + "peak"));
         //falseMagicEURCAD3215
         Print(fn_isTestToStr() + "Magic" + Sym + string(global_lineCode)," = ",
            GlobalVariableGet(fn_isTestToStr() + "Magic" + Sym + string(global_lineCode)));
         //falseEURCAD3215tp
         Print(fn_isTestToStr() + Sym + string(global_lineCode) + "tp"," = ",
            GlobalVariableGet(fn_isTestToStr() + Sym + string(global_lineCode) + "tp"));
         //falseEURCAD03215
         Print(fn_isTestToStr() + Sym + "0" + string(global_lineCode)," = ",
            GlobalVariableGet(fn_isTestToStr() + Sym + "0" + string(global_lineCode)));
         //falseEURCAD13215
         Print(fn_isTestToStr() + Sym + "1" + string(global_lineCode)," = ",
            GlobalVariableGet(fn_isTestToStr() + Sym + "1" + string(global_lineCode)));
         */

         if ( MQLInfoInteger(MQL_TESTER) ) {
            //level-1
            //trueNUMBEREURCAD3215
            GlobalVariableDel(fn_isTestToStr() + "NUMBER" + Sym + string(global_lineCode));
            //Band period: default is 0
            //falseiBands_periodEURCAD3215
            GlobalVariableDel(fn_isTestToStr() + "iBands_period" + Sym + string(global_lineCode));
            //Distance price (planned line price)
            //falseDistance_PriceEURCAD3215
            GlobalVariableDel(fn_isTestToStr() + "Distance_Price" + Sym + string(global_lineCode));
            //highscore
            //falseEURCAD3215peak
            GlobalVariableDel(fn_isTestToStr() + Sym + string(global_lineCode) + "peak");
            //magic number
            //falseMagicEURCAD3215
            GlobalVariableDel(fn_isTestToStr() + "Magic" + Sym + string(global_lineCode));
            //Take profit price
            //falseEURCAD3215tp
            GlobalVariableDel(fn_isTestToStr() + Sym + string(global_lineCode) + "tp");
            //Long order flag: 1, invalid; 0, effective
            //falseEURCAD03215
            GlobalVariableDel(fn_isTestToStr() + Sym + "0" + string(global_lineCode));
            //Short order flag: 1, invalid; 0, effective
            //falseEURCAD13215
            GlobalVariableDel(fn_isTestToStr() + Sym + "1" + string(global_lineCode));
         }
      }
   }


}


//Long and short flags: 0, none; 1, buy direction; 2, sell direction
// verifica le condizioni Buy/Sell e calcola il TP
long fn_buySellFlag(string Sym) {
   //long       local_1_in;
   long       BuySell = 0;
   //----- -----

   //Slippage
   Global_Spread_Points = (double)SymbolInfoInteger(Sym, SYMBOL_SPREAD);
   Global_Spread_Price = (double)SymbolInfoInteger(Sym, SYMBOL_SPREAD) * SymbolInfoDouble(Sym, SYMBOL_TRADE_TICK_SIZE) ;
   Global_Ask_Price = SymbolInfoDouble(Sym, SYMBOL_ASK) ;
   Global_Bid_Price = SymbolInfoDouble(Sym, SYMBOL_BID) ;
   Global_Point_Price = SymbolInfoDouble(Sym, SYMBOL_TRADE_TICK_SIZE) ;
   if (Global_Point_Price == 0)Global_Point_Price = 0.00001; ////
   Global_Bid_Su_ClosePrec = 0.0 ;
   //PERIOD_CURRENT
   if ( iClose(Sym, PERIOD_CURRENT, 1) > 0.0 ) {
      Global_Bid_Su_ClosePrec = (MathAbs(Global_Bid_Price / iClose(Sym, PERIOD_CURRENT, 1) - 1.0)) * 10000.0 ;
   }
   //SELL
   //Bid：Latest bid price (seller's bid)
   if ( Global_Bid_Price > global_iMaiStdDevAdd ) {
      if ( ( FirstPositionp == 1 || FirstPositionp == 3 ) ) {
         BuySell = 2 ;
         global_Takeprofit = 0.00001 / Global_Point_Price * MathPow(Global_Base2_Pow, MathLog(Global_Indic_Period / 100.0) / 0.6931471805599) * Global_Numerator / MathPow(Global_Base2_Pow, 2.0) * Global_Bid_Price + Global_Mult1 * MathPow(Global_Base1_Pow, global_orderLevel) * (Global_Bid_Price - global_iMA) / Global_Point_Price ;
      }
   }
   //BUY
   //ASK：Latest selling price (buyer's bid) ASK > BID
   if ( Global_Ask_Price < global_iMaiStdDevSub ) {
      if ( ( FirstPositionp == 1 || FirstPositionp == 2 ) ) {
         BuySell = 1 ;
         global_Takeprofit = 0.00001 / Global_Point_Price * MathPow(Global_Base2_Pow, MathLog(Global_Indic_Period / 100.0) / 0.6931471805599) * Global_Numerator / MathPow(Global_Base2_Pow, 2.0) * Global_Bid_Price + Global_Mult1 * MathPow(Global_Base1_Pow, global_orderLevel) * (global_iMA - Global_Bid_Price) / Global_Point_Price ;
      }
   }

   global_Takeprofit = NormalizeDouble(global_Takeprofit, global_priceDigits);
   return(BuySell);
}
//lizong_12 <<==--------   --------

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


// Calculate basic (level 0) initial lot size
double fn_comBaseLots(string Sym, bool pFormatFlag) {
   double     comEquity;
   double     tmp_riskCoefficient;
   double     tickValue;
   double     bidcorr;
   double     tmp_do_6;
   long        syLoc = 0;

   //local_2_st = " Author of the function: " ;
   if (0 == StringCompare("", Sym)) {
      Sym = Symbol();
   }
   double local_comLot = 0.0 ;
   double locat_minLot = 0.0 ;
   double local_comBalance = 0.0 ;
   int local_lotDigits = global_lotsDigits;

   locat_minLot = SymbolInfoDouble(Sym, SYMBOL_VOLUME_MIN);
   if ( Lots < locat_minLot ) {
      Lots = locat_minLot ;
   }

   if ( global_riskCoefficient != 0.0 ) {
      if ( Fix_balance > 0.0 ) {
         local_comBalance = Fix_balance ;
      } else {
         if ( BaseForLotCalc == 0 ) {
            local_comBalance = AccountInfoDouble(ACCOUNT_EQUITY);
         } else {
            local_comBalance = AccountInfoDouble(ACCOUNT_BALANCE);
         }
      }
      local_comBalance = local_comBalance + VirtBalance ;
      comEquity = local_comBalance;
      tmp_riskCoefficient = global_riskCoefficient;

      //Print("&&&&& ",Sym," comEquity=",DoubleToString(comEquity,5),";risk=",tmp_riskCoefficient);

      //The value of the current currency per pip to the deposit currency (USD)
      tickValue = SymbolInfoDouble(Sym, SYMBOL_TRADE_TICK_VALUE);
      bidcorr = 0.0;
      if ( SymbolInfoDouble(Sym, SYMBOL_TRADE_TICK_SIZE) != 0.0 ) {
         bidcorr = SymbolInfoDouble(Sym, SYMBOL_BID) / SymbolInfoDouble(Sym, SYMBOL_TRADE_TICK_SIZE);
      }

      //Print("&&&&& ",Sym," bidcorr=",bidcorr);

      //Print(Sym," tmp_riskCoefficient=",DoubleToString(tmp_riskCoefficient,8),",comEquity=",comEquity,",bidcorr=",DoubleToString(bidcorr,5),",tickValue=",DoubleToString(tickValue,5));
      if ( bidcorr * tickValue == 0.0 ) {
         PrintFormat(Sym + " bidcorr*ValuePerPip==0");
         tmp_do_6 = 0.0;
      } else {
         //Print(Sym," comEquity=",comEquity,";BID整数=",bidcorr,";tickValue=",tickValue);
         //tmp_riskCoefficient: 1/15
         //Print(Sym," comEquity / (bidcorr * tickValue=",comEquity / (bidcorr * tickValue));
         tmp_do_6 = tmp_riskCoefficient * comEquity / (bidcorr * tickValue);
      }

      //Print("&&&&& ",Sym," tmp_do_6=",tmp_do_6,";global_symbolMulti=",global_symbolMulti);

      /*
      for(syLoc = 0; syLoc < ArraySize(LstSymbol); syLoc++){
         if (0 ==StringCompare(Sym,LstSymbol[syLoc])){
            break;
         }
      }
      */
      local_comLot = tmp_do_6 * global_symbolMulti ;

      //Print("&&&&& ",Sym," local_comLot=",local_comLot);
   } else {
      if ( FirstNumberp > 0 && LotsMartinp > 0.0 ) {
         local_comLot = Lots / MathPow(LotsMartinp, FirstNumberp);
      } else {
         local_comLot = Lots ;
      }
   }
   if ( pFormatFlag ) {
      local_comLot = NormalizeDouble(local_comLot, local_lotDigits) ;
   }
   return(local_comLot);
}


//Process an order
long CalcoloLivelliAperture(string Sym) {
   //long       local_1_in;
   double    local_lots;
   bool      NonAprire;
   long       local_ticket;
   long       local_otherMagicsCount = 0;
   long       local_otherSymbolsCount = 0;
   double     local_iRSI1 = 0.0;
   double     local_iRSI2 = 0.0;

   if ( !(fn_isExistOrder(Sym, -1, global_OrderMagic, 0, "")) ) {
      //Plan takes effect
      if ( !(fn_lineEnabled(Sym)) ) {
         global_orderLevel = 0 ;
         GlobalVariableSet(fn_isTestToStr() + "NUMBER" + Sym + string(global_lineCode), 0.0);
         GlobalVariableSet(fn_isTestToStr() + Sym + string(global_lineCode) + "peak", 0.0);
      } else {
         if ( isHolidays() != "" || FirstPositionp == NotOpen ) {
            GlobalVariableSet(fn_isTestToStr() + Sym + "0" + string(global_lineCode), 0.0);
            GlobalVariableSet(fn_isTestToStr() + Sym + "1" + string(global_lineCode), 0.0);
            global_orderLevel = 0 ;
            GlobalVariableSet(fn_isTestToStr() + "NUMBER" + Sym + string(global_lineCode), 0.0);
            GlobalVariableSet(fn_isTestToStr() + Sym + string(global_lineCode) + "peak", 0.0);
         }
      }
   }

   // calcolo la Distanza se non l'ho già fatto
   if ( global_PriceDist == 0.0 ) {
      //Find long orders
      if ( fn_isExistOrder(Sym, ORDER_TYPE_BUY, global_OrderMagic, 0, "") ) {
         Global_iStdDev_Pips = (long)((global_iMaiStdDevAdd - global_iMA) / Global_Point_Price) ;
         // calcolo la distanza tra la StdDev e il minore tra C_1 e Bid
         global_PriceDist = (Global_Spread_Points - Global_iStdDev_Pips) * Global_Point_Price + MathMin(iClose(Sym, PERIOD_CURRENT, 1), Global_Bid_Price) ;
         global_PriceDist = NormalizeDouble(global_PriceDist, global_priceDigits);
         GlobalVariableSet(fn_isTestToStr() + "Distance_Price" + Sym + string(global_lineCode), global_PriceDist);
         //Create planning lines
////         CreateModifyLine_G();
      }
      //Find short orders
      if ( fn_isExistOrder(Sym, ORDER_TYPE_SELL, global_OrderMagic, 0, "") ) {
         Global_iStdDev_Pips = (long)((global_iMaiStdDevAdd - global_iMA) / Global_Point_Price) ;
         // calcolo la distanza tra la StdDev e il maggiore tra C_1 e Bid
         global_PriceDist = Global_iStdDev_Pips * Global_Point_Price + MathMax(iClose(Sym, PERIOD_CURRENT, 1), Global_Bid_Price) ;
         global_PriceDist = NormalizeDouble(global_PriceDist, global_priceDigits);
         GlobalVariableSet(fn_isTestToStr() + "Distance_Price" + Sym + string(global_lineCode), global_PriceDist);
         //Create planning lines
////         CreateModifyLine_G();
      }
   }
   if ( !(GlobalVariableCheck(fn_isTestToStr() + "NUMBER" + Sym + string(global_lineCode))) ) {
      SetNUMBER( Sym, -1, global_OrderMagic);
   }
   local_lots = 0.0 ;
   NonAprire = false ;
   Global_Spread_Points = (double)SymbolInfoInteger(Sym, SYMBOL_SPREAD) ;
   Global_Spread_Price = (double)SymbolInfoInteger(Sym, SYMBOL_SPREAD) * SymbolInfoDouble(Sym, SYMBOL_TRADE_TICK_SIZE) ;
   Global_Ask_Price = SymbolInfoDouble(Sym, SYMBOL_ASK) ;
   Global_Bid_Price = SymbolInfoDouble(Sym, SYMBOL_BID) ;
   Global_Point_Price = SymbolInfoDouble(Sym, SYMBOL_TRADE_TICK_SIZE) ;
   Global_Bid_Su_ClosePrec = 0.0 ;
   if ( iClose(Sym, PERIOD_CURRENT, 1) > 0.0 ) {
      Global_Bid_Su_ClosePrec = (MathAbs(Global_Bid_Price / iClose(Sym, PERIOD_CURRENT, 1) - 1.0)) * 10000.0 ;
   }
   local_ticket = 0 ;
   if ( global_PriceDist != 0.0 ) {
      // se la PriceDist è diversa da zero
      if ( DELAYtime(Sym, -1, global_OrderMagic, "HS", iTime(Sym, PERIOD_CURRENT, 0)) > Global_Indic_Period * Global_Mult_Period * PeriodSeconds(PERIOD_CURRENT) && Global_Bid_Su_ClosePrec < 20.0 ) {
         // la distanza temporle dall'ultimo ordine HS > del periodo indicatore e il bid/close sia < 20
         if ( ( fn_isExistOrder(Sym, ORDER_TYPE_BUY, global_OrderMagic, 0, "") || Get_BuySell_Enabled(Sym, ORDER_TYPE_BUY) )) {
            // verifico ci sia un buy o che sia abilitato il buy
            if ( Global_Ask_Price <= global_PriceDist ) {
               // Ask inferiore alla distanza
               NonAprire = false ;
               local_lots = NormalizeDouble(fn_comBaseLots(Sym, false) * MathPow(global_lotsMartinp, MathMin(global_maxLotLevel, global_orderLevel + 1)), global_lotsDigits) ;
               //Print("==+++",Sym," comBaseLots=",fn_comBaseLots(false,Sym),";level=",global_orderLevel + 1,";local_lots=",local_lots);
               if ( FirstNumberp > global_orderLevel + 1 || (global_maxLevel <  global_orderLevel + 1 && global_maxLevel >  0) ) {
                  NonAprire = true ;
                  local_ticket = -1 ;
                  Print("9 ", Sym + " " + string(global_OrderMagic) + " The opened grid level(", global_orderLevel + 1, ") is less than the minimum level(", FirstNumberp, "). The deal is virtualized");
               } else {
                  if ( local_lots < global_minLots ) {
                     NonAprire = true ;
                     local_ticket = -1 ;
                     Print(Sym + " 10 " + string(global_OrderMagic) + " Current lot(", local_lots, ") < ", DoubleToString(global_minLots, global_lotsDigits), ". The average deal is virtualized");
                  } else {
                     if (!(fn_isExistOrder(Sym, ORDER_TYPE_BUY, global_OrderMagic, 0, ""))) {
                        if (MaxOtherMagics >  0 ) {
                           local_otherMagicsCount = fn_getOtherMagicsCount("", global_OrderMagic);
                           //Print("&&&&4MaxOtherMagics=",MaxOtherMagics,";local_otherMagicsCount=",local_otherMagicsCount);
                           if ( local_otherMagicsCount >= MaxOtherMagics ) {
                              NonAprire = true ;
                              local_ticket = -1 ;
                              Print("11 ", Sym + " " + string(global_OrderMagic) + " GetOtherMagicsCount(", local_otherMagicsCount, ") >= MaxOtherMagics(", MaxOtherMagics, "). The deal is virtualized");
                              if ( FirstNumberp <= global_orderLevel + 1 ) {
                                 global_orderLevel --;
                              }
                           }
                        }
                        if ( MaxOtherSymbols >  0 ) {
                           local_otherSymbolsCount = fn_GetOtherSymbolsCount(Sym);
                           //Print("&&&&14MaxOtherSymbols=",MaxOtherSymbols,";local_otherSymbolsCount=",local_otherSymbolsCount,
                           //   ";local_otherSymbolsCount_old=",fn_GetOtherSymbolsCount_old(Sym));
                           if ( local_otherSymbolsCount >= MaxOtherSymbols ) {
                              NonAprire = true ;
                              local_ticket = -1 ;
                              Print("12 ", Sym + " " + string(global_OrderMagic) + " GetOtherSymbolsCount(", local_otherSymbolsCount, ") >= MaxOtherSymbols(", MaxOtherSymbols, "). The deal is virtualized");
                              if ( FirstNumberp <= global_orderLevel + 1 ) {
                                 global_orderLevel --;
                              }
                           }
                        }

                        //Add control related currency types
                        if (false == NonAprire && false == Related) {
                           if (fn_existSymbol(Sym)) {
                              NonAprire = true ;
                              local_ticket = -1 ;
                              if ( FirstNumberp <= global_orderLevel + 1 ) {
                                 global_orderLevel --;
                              }
                              Print("123 ", Sym + " exists in the orders. The deal is virtualized");
                           }
                        }
                     }

                     if (false == NonAprire) {
                        tmp_rise = (int)AutoMM;
                        if (tmp_rise == 0) {
                           tmp_rise = 3000;
                        }
                        if (AbsoluteProhibition || global_floatProfitPre <= (-0.2) * 3000 / tmp_rise - 0.05) {
                           FastClose = true;
                           FirstPositionp = NotOpen;
                           global_maxLevel = 6 ;
                           global_maxLotLevel = 6 ;
                           NonAprire = true ;
                           local_ticket = -1 ;
                           //AbsoluteProhibition = true;

                           if ( FirstNumberp <= global_orderLevel + 1 ) {
                              global_orderLevel --;
                           }

                           //Set stop loss
                           if (StopLessFlag) {
                              //PrintFormat("22222 %s %d 设置止损",Sym,global_OrderMagic);
                              fn_ModifyStopLoss(Sym, global_OrderMagic);
                           }

                           Print("122 " + Sym + " " + string(global_OrderMagic) + " Floatting profit(", DoubleToString(global_floatProfitPre * 100, 2), "%) is more than the floatting profit(", DoubleToString(((-0.2) * 3000 / tmp_rise - 0.05) * 100, 2), "%). The deal is virtualized");
                        } else if (TopGrid + 1 <= global_orderLevel + 1) {
                           FastClose = true;
                           FirstPositionp = NotOpen;
                           global_maxLevel = 6 ;
                           global_maxLotLevel = 6 ;
                           NonAprire = true ;
                           local_ticket = -1 ;
                           Print("121 " + Sym + " " + string(global_OrderMagic) + " The opened grid level(", global_orderLevel + 1, ") is more than the maximum level(", TopGrid, "). The deal is virtualized");
                        } else if (global_topFlag) {
                           NonAprire = true ;
                           local_ticket = -1 ;
                           Print(Sym + " " + string(global_OrderMagic) + " The order grid level has reached the maximum grid level(6). The deal is virtualized(122)");
                        } else {
                           local_ticket = fn_createOrder(Sym, ORDER_TYPE_BUY, local_lots, 0.0, 0.0, global_OrderMagic, LevelFirst + IntegerToString(global_orderLevel + 1, 0, 32), global_PriceDist) ;
                           if ( local_ticket >  0 ) {
                              GlobalVariableSet(fn_isTestToStr() + Sym + "0" + string(global_lineCode), 0.0);
                              NonAprire = true ;
                           }
                        }
                     }

                  }
               }
               if ( NonAprire ) {
                  global_orderLevel ++;
                  //lizong80(local_ticket);
                  GlobalVariableSet(fn_isTestToStr() + "NUMBER" + Sym + string(global_lineCode), global_orderLevel);
                  Global_iStdDev_Pips = (long)((global_iMaiStdDevAdd - global_iMA) / Global_Point_Price) ;
                  global_PriceDist =  MathMin(iClose(Sym, PERIOD_CURRENT, 1), Global_Bid_Price) +
                                      (Global_Spread_Points - Global_iStdDev_Pips) * Global_Point_Price  ;
                  global_PriceDist = NormalizeDouble(global_PriceDist, global_priceDigits);
                  GlobalVariableSet(fn_isTestToStr() + "Distance_Price" + Sym + string(global_lineCode), global_PriceDist);
                  //Create planning lines
////                  CreateModifyLine_G();
               }
            }
         } else {
            if ( ( fn_isExistOrder(Sym, ORDER_TYPE_SELL, global_OrderMagic, 0, "") || Get_BuySell_Enabled(Sym, ORDER_TYPE_SELL) ) && Global_Bid_Price >= global_PriceDist ) {
               NonAprire = false ;
               local_lots = NormalizeDouble(fn_comBaseLots(Sym, false) * MathPow(global_lotsMartinp, MathMin(global_maxLotLevel, global_orderLevel + 1)), global_lotsDigits) ;
               //Print("==---",Sym," comBaseLots=",fn_comBaseLots(false,Sym),";level=",global_orderLevel + 1,";local_lots=",local_lots);
               if ( FirstNumberp > global_orderLevel + 1 || (global_maxLevel <  global_orderLevel + 1 && global_maxLevel >  0)) {
                  NonAprire = true ;
                  local_ticket = -1 ;
                  Print("13 ", Sym + " " + string(global_OrderMagic) + " The opened grid level(", global_orderLevel + 1, ") is less than the minimum level(", FirstNumberp, "). The deal is virtualized");
               } else {
                  if ( local_lots < global_minLots ) {
                     NonAprire = true ;
                     local_ticket = -1 ;
                     Print(Sym + " 14 " + string(global_OrderMagic) + " Current lot(", local_lots, ") < ", DoubleToString(global_minLots, global_lotsDigits), ". The average deal is virtualized");
                  } else {
                     if ( !(fn_isExistOrder(Sym, ORDER_TYPE_SELL, global_OrderMagic, 0, "")) ) {
                        if ( MaxOtherMagics >  0 ) {
                           local_otherMagicsCount = fn_getOtherMagicsCount("", global_OrderMagic);
                           //Print("&&&&5MaxOtherMagics=",MaxOtherMagics,";local_otherMagicsCount=",local_otherMagicsCount);
                           if ( local_otherMagicsCount >= MaxOtherMagics ) {
                              NonAprire = true ;
                              local_ticket = -1 ;
                              Print("15 ", Sym + " " + string(global_OrderMagic) + " GetOtherMagicsCount(", local_otherMagicsCount, ") >= MaxOtherMagics(", MaxOtherMagics, "). The deal is virtualized");
                              if ( FirstNumberp <= global_orderLevel + 1 ) {
                                 global_orderLevel --;
                              }
                           }
                        } else {
                           if ( MaxOtherSymbols >  0 ) {
                              local_otherSymbolsCount = fn_GetOtherSymbolsCount(Sym);
                              //Print("&&&&15MaxOtherSymbols=",MaxOtherSymbols,";local_otherSymbolsCount=",local_otherSymbolsCount,
                              //   ";local_otherSymbolsCount_old=",fn_GetOtherSymbolsCount_old(Sym));
                              if ( local_otherSymbolsCount >= MaxOtherSymbols ) {
                                 NonAprire = true ;
                                 local_ticket = -1 ;
                                 Print("16 ", Sym + " " + string(global_OrderMagic) + " GetOtherSymbolsCount(", local_otherSymbolsCount, ") >= MaxOtherSymbols(", MaxOtherSymbols, "). The deal is virtualized");
                                 if ( FirstNumberp <= global_orderLevel + 1 ) {
                                    global_orderLevel --;
                                 }
                              }
                           }
                        }

                        //Add control related currency types
                        if (false == NonAprire && false == Related) {
                           if (fn_existSymbol(Sym)) {
                              NonAprire = true ;
                              local_ticket = -1 ;
                              if ( FirstNumberp <= global_orderLevel + 1 ) {
                                 global_orderLevel --;
                              }
                              Print("163 ", Sym + " exists in the orders. The deal is virtualized");
                           }
                        }
                     }
                     if (false == NonAprire) {
                        tmp_rise = (int)AutoMM;
                        if (tmp_rise == 0) {
                           tmp_rise = 3000;
                        }
                        if (AbsoluteProhibition || global_floatProfitPre <= (-0.2) * 3000 / tmp_rise - 0.05) {
                           FastClose = true;
                           FirstPositionp = NotOpen;
                           global_maxLevel = 6 ;
                           global_maxLotLevel = 6 ;
                           NonAprire = true ;
                           local_ticket = -1 ;
                           //AbsoluteProhibition = true;

                           if ( FirstNumberp <= global_orderLevel + 1 ) {
                              global_orderLevel --;
                           }

                           //设置止损
                           if (StopLessFlag) {
                              //PrintFormat("22222 %s %d 设置止损",Sym,global_OrderMagic);
                              fn_ModifyStopLoss(Sym, global_OrderMagic);
                           }

                           Print("162 " + Sym + " " + string(global_OrderMagic) + " Floatting profit(", DoubleToString(global_floatProfitPre * 100, 2), "%) is more than the floatting profit(", DoubleToString(((-0.2) * 3000 / tmp_rise - 0.05) * 100, 2), "%). The deal is virtualized");
                        } else if (TopGrid + 1 <= global_orderLevel + 1) {
                           FastClose = true;
                           FirstPositionp = NotOpen;
                           global_maxLevel = 6 ;
                           global_maxLotLevel = 6 ;
                           NonAprire = true ;
                           local_ticket = -1 ;
                           //global_orderLevel --;
                           Print("161 " + Sym + " " + string(global_OrderMagic) + " The opened grid level(", global_orderLevel + 1, ") is more than the maximum level(", TopGrid, "). The deal is virtualized");
                        } else if (global_topFlag) {
                           NonAprire = true ;
                           local_ticket = -1 ;
                           Print(Sym + " " + string(global_OrderMagic) + " The order grid level has reached the maximum grid level(6). The deal is virtualized(122)");
                        } else {
                           ////====
                           local_ticket = fn_createOrder(Sym, ORDER_TYPE_SELL, local_lots, 0.0, 0.0, global_OrderMagic, LevelFirst + IntegerToString(global_orderLevel + 1, 0, 32), global_PriceDist) ;
                           if ( local_ticket >  0 ) {
                              GlobalVariableSet(fn_isTestToStr() + Sym + "1" + string(global_lineCode), 0.0);
                              NonAprire = true ;
                           }
                        }
                     }

                  }
               }
               if ( NonAprire ) {
                  global_orderLevel ++;
                  //lizong80( local_ticket);
                  GlobalVariableSet(fn_isTestToStr() + "NUMBER" + Sym + string(global_lineCode), global_orderLevel);
                  Global_iStdDev_Pips = (long)((global_iMaiStdDevAdd - global_iMA) / Global_Point_Price) ;
                  global_PriceDist = Global_iStdDev_Pips * Global_Point_Price + MathMax(iClose(Sym, PERIOD_CURRENT, 1), Global_Bid_Price) ;
                  global_PriceDist = NormalizeDouble(global_PriceDist, global_priceDigits);
                  GlobalVariableSet(fn_isTestToStr() + "Distance_Price" + Sym + string(global_lineCode), global_PriceDist);
                  //Create planning lines
////                  CreateModifyLine_G();
               }
            }
         }
      }
   }
   return(0);
}

//+------------------------------------------------------------------+
void zArrayAppend(T_Set & A[], T_Set & V) {
   int NewSize = ArraySize(A) + 1;
   ArrayResize(A, NewSize);
   A[NewSize - 1] = V;
}
//+------------------------------------------------------------------+
bool Get_BuySell_Enabled(string Sym, long BS) {
   if ( GlobalVariableGet(fn_isTestToStr() + Sym + string(BS) + string(global_lineCode)) == 1.0 ) {
      return(true);
   }
   return(false);//
}

//+------------------------------------------------------------------+
bool  fn_lineEnabled(string Sym) {
   if (GlobalVariableGet(fn_isTestToStr() + Sym + "0" + string(global_lineCode)) == 1.0 || GlobalVariableGet(fn_isTestToStr() + Sym + "1" + string(global_lineCode)) == 1.0 ) {
      return(true);
   }
   return(false);
}

//+------------------------------------------------------------------+
void Decodifica_Stringa_Parametro_01( string Stringa_Parametro_01, T_Set & ArrayDst[]) {
   string    Parti_Stringa_Parametro_01[];
   string    SubParti_Stringa_Parametro_01[];
   string    SubSubParti_Stringa_Parametro_01[];
   long        tmp_in_10 = 7318875;
   StringSplit(Stringa_Parametro_01, StringGetCharacter(";", 0), Parti_Stringa_Parametro_01);

   for (int I = 0 ; I <  ArraySize(Parti_Stringa_Parametro_01) ; I++) {
      StringTrimLeft(Parti_Stringa_Parametro_01[I]);
      StringTrimRight(Parti_Stringa_Parametro_01[I]);
      //Parti_Stringa_Parametro_01[I] = Parti_Stringa_Parametro_01[I];
   }
   int K = 0;
//   tmp_in_4 = ArrayRange(Parti_Stringa_Parametro_01, 0);
   while (K < MathMin(tmp_in_10, 9)) {
      StringTrimLeft(Parti_Stringa_Parametro_01[K]);
      StringTrimRight(Parti_Stringa_Parametro_01[K]);
      if ( Parti_Stringa_Parametro_01[K] != "" ) {
         ArrayResize(ArrayDst, K + 1, 0);
         ArrayDst[K].Descriz = "base";
         ArrayDst[K].Indic_Period = 0;
         ArrayDst[K].Mult_iStdDev = 0;
         ArrayDst[K].Mult1 = 0;
         ArrayDst[K].Base1_Pow = 0;
         ArrayDst[K].Numerator = 0;
         ArrayDst[K].Base2_Pow = 0;
         ArrayDst[K].Mult_Period = 0;

         PrintFormat("using set #" + IntegerToString(K + 1, 0, 32) + ": " + Parti_Stringa_Parametro_01[K]);
         StringSplit(Parti_Stringa_Parametro_01[K], StringGetCharacter(",", 0), SubParti_Stringa_Parametro_01);

         for (int I = 0 ; I < ArraySize(SubParti_Stringa_Parametro_01); I++) {
            StringTrimLeft(SubParti_Stringa_Parametro_01[I]);
            StringTrimRight(SubParti_Stringa_Parametro_01[I]);
            //SubParti_Stringa_Parametro_01[I] = SubParti_Stringa_Parametro_01[I];
         }
         for (int J = 0 ; J < ArrayRange(SubParti_Stringa_Parametro_01, 0) ; J++) {
            StringSplit(SubParti_Stringa_Parametro_01[J], StringGetCharacter("=", 0), SubSubParti_Stringa_Parametro_01);

            for (int JJ = 0 ; JJ < ArraySize(SubSubParti_Stringa_Parametro_01) ; JJ++) {
               StringTrimLeft(SubSubParti_Stringa_Parametro_01[JJ]);
               StringTrimRight(SubSubParti_Stringa_Parametro_01[JJ]);
               //SubSubParti_Stringa_Parametro_01[tmp_in_9] = SubSubParti_Stringa_Parametro_01[tmp_in_9];
            }
            if ( SubSubParti_Stringa_Parametro_01[0] == "s1" ) {
               ArrayDst[J].Descriz = SubSubParti_Stringa_Parametro_01[1];
            }
            if ( SubSubParti_Stringa_Parametro_01[0] == "s2" ) {
               ArrayDst[J].Indic_Period = (long)StringToInteger(SubSubParti_Stringa_Parametro_01[1]);
            }
            if ( SubSubParti_Stringa_Parametro_01[0] == "s3" ) {
               ArrayDst[J].Mult_iStdDev = StringToDouble(SubSubParti_Stringa_Parametro_01[1]);
            }
            if ( SubSubParti_Stringa_Parametro_01[0] == "s4" ) {
               ArrayDst[J].Mult1 = StringToDouble(SubSubParti_Stringa_Parametro_01[1]);
            }
            if ( SubSubParti_Stringa_Parametro_01[0] == "s5" ) {
               ArrayDst[J].Base1_Pow = StringToDouble(SubSubParti_Stringa_Parametro_01[1]);
            }
            if ( SubSubParti_Stringa_Parametro_01[0] == "s6" ) {
               ArrayDst[J].Numerator = StringToDouble(SubSubParti_Stringa_Parametro_01[1]);
            }
            if ( SubSubParti_Stringa_Parametro_01[0] == "s7" ) {
               ArrayDst[J].Base2_Pow = StringToDouble(SubSubParti_Stringa_Parametro_01[1]);
            }
            if ( SubSubParti_Stringa_Parametro_01[0] == "s8" ) {
               ArrayDst[J].Mult_Period = StringToDouble(SubSubParti_Stringa_Parametro_01[1]);
            }
         }
      }
      K = K + 1;
      tmp_in_10 = ArrayRange(Parti_Stringa_Parametro_01, 0);
   }
}


//Close order based on take profit price
void fn_orderClose_onTP(string Sym) {

   double local_tp = GlobalVariableGet(fn_isTestToStr() + Sym + string(global_lineCode) + "tp") ;

   //If long order
   if ( fn_isExistOrder(Sym, ORDER_TYPE_BUY, global_OrderMagic, 0, "")) {
      if(local_tp > 0.0 && Global_Bid_Price >= local_tp) {
         double local_avgPrice = fn_avgOrderOpenPrice(Sym, ORDER_TYPE_BUY, global_OrderMagic);
         if (Global_Ask_Price < local_avgPrice + MinProfit) {
            Print("++Alter:Global_Ask_Price < local_avgPrice + ", MinProfit, ",", Sym, " ", global_OrderMagic, " Global_Ask_Price:", DoubleToString(Global_Ask_Price, 5), ";local_avgPrice:", DoubleToString(local_avgPrice, 5));
         }
         if (local_avgPrice > 0 && Global_Bid_Price >= local_avgPrice + MinProfit) {
            //Print("#++",Sym," global_lineCode=",global_lineCode,";Global_Bid_Price=",DoubleToString(Global_Bid_Price,5),";tp=",DoubleToString(local_tp,5),";avgPrice=",DoubleToString(local_avgPrice,5));
            fn_orderCloseByPara(Sym, ORDER_TYPE_BUY, global_OrderMagic);
         }
      }
   }

   //short order
   if ( fn_isExistOrder(Sym, ORDER_TYPE_SELL, global_OrderMagic, 0, "")) {
      if (local_tp > 0.0 && Global_Ask_Price > 0.0 && Global_Ask_Price <= local_tp) {
         double local_avgPrice = fn_avgOrderOpenPrice(Sym, ORDER_TYPE_SELL, global_OrderMagic);
         if (Global_Ask_Price > local_avgPrice - MinProfit) {
            Print("--Alter:Global_Ask_Price > local_avgPrice - ", MinProfit, ",", Sym, " ", global_OrderMagic, " Global_Ask_Price:", DoubleToString(Global_Ask_Price, 5), ";local_avgPrice:", DoubleToString(local_avgPrice, 5));
         }
         if(local_avgPrice > 0 && Global_Ask_Price <= local_avgPrice - MinProfit) {
            //Print("#--",Sym," global_lineCode=",global_lineCode,";Global_Ask_Price=",DoubleToString(Global_Ask_Price,5),";tp=",DoubleToString(local_tp,5),";avgPrice=",DoubleToString(local_avgPrice,5));
            fn_orderCloseByPara(Sym, ORDER_TYPE_SELL, global_OrderMagic);
         }
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string trim(string & s1) {
   StringTrimLeft(s1);
   StringTrimRight(s1);
   return(s1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void  fn_splitSymbol(string  Sep, string  Sym, string &  Dst[]) {
   StringSplit(Sym, StringGetCharacter(Sep, 0), Dst);
   for (int I = 0 ; I < ArraySize(Dst) ; I++ ) {
      Dst[I] = trim(Dst[I]);
   }
}
//-----

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void fn_splitSymbolMulti(string & Org[], double & Dst[]) {
   ushort Sep = StringGetCharacter("*", 0);
   ArrayResize(Dst, ArraySize(Org), 0);
   ArrayResize(global_ArySymbolLotsDigits, ArraySize(Org), 0);
   ArrayResize(global_ArySymbolPriceDigits, ArraySize(Org), 0);
   for (int I = 0 ; I < ArraySize(Org) ; I++ ) {
      string V[];
      StringSplit(trim(Org[I]), Sep, V);
      Org[I] = V[0];

      Dst[I] = ( ArraySize(V) == 2 ) ? StringToDouble(V[1]) : global_defaultMulti;

      global_symbolMulti = Dst[I];

      //Calculate the number of decimal places in lot size
      global_minLots = SymbolInfoDouble(Org[I], SYMBOL_VOLUME_MIN);
      int nMinLot = (int)(1 / global_minLots);
      int nMinLot2 = -1;
      while(nMinLot != 0) {
         nMinLot2 = nMinLot2 + 1;
         nMinLot = nMinLot / 10;
      }
      global_ArySymbolLotsDigits[I] = nMinLot2;
      global_lotsDigits = global_ArySymbolLotsDigits[I];

      global_ArySymbolPriceDigits[I] = (int)SymbolInfoInteger(Org[I], SYMBOL_DIGITS);
      global_priceDigits = global_ArySymbolPriceDigits[I];

      Print(Org[I], " ", Dst[I], " LotsDigits:", global_ArySymbolLotsDigits[I], " PriceDigits:", global_ArySymbolPriceDigits[I]);
   }
}

//Close order
void fn_orderCloseByPara( string Sym, long pOrderType, long pOrdeMagic) {

   // Deleting Positions
   for (int P = PositionsTotal() - 1 ; P >= 0 ; P --) {
      ulong Tkt = (long)PositionGetTicket(P);
      if(!PositionSelectByTicket(Tkt)) {
         continue;
      }

      string P_Sym = PositionGetString(POSITION_SYMBOL);

      if ( ( P_Sym != Sym && Sym != "" ) ) {
         continue;
      }

      long P_Type = (long)PositionGetInteger(POSITION_TYPE);
      if ( ( pOrderType >= 0 && P_Type != pOrderType ) ) {
         continue;
      }

      long P_Magic = (long)PositionGetInteger(POSITION_MAGIC);
      if ( ( pOrdeMagic >= 0 && P_Magic != pOrdeMagic ) ) {
         continue;
      }

      for (int I = 1 ; I <= 20 ; I = I + 1) {

         double P_Lots = PositionGetDouble(POSITION_VOLUME);

//         if ( OrderCloseMQL4((ulong)Tkt, P_Sym, P_Type, P_Lots, 1, Clr) ) {
         if (Trade.PositionClose(Tkt)) {
            Print("OrderClose OK #", Tkt, " sy=", P_Sym, " lot=", P_Lots, " op=", P_Type, " mn=", P_Magic, ", try ", I);

            //Modify the magic code of the position order array to 0
            for(int OI = 0; OI < ArraySize(aryTardOrderInfo); OI++) {
               if (0 == aryTardOrderInfo[OI].orderMagic) {
                  continue;
               }

               if (Tkt == aryTardOrderInfo[OI].orderTicket) {
                  aryTardOrderInfo[OI].orderMagic = 0;
                  break;
               }
            }

            break;
         }

         // GESTIONE ERRORE

         long errCode = GetLastError();
         Print("Error(", errCode, ") opening position: ", (GetLastError()), ", try ", I);
         //invalid ticket
         if (ERR_TRADE_POSITION_NOT_FOUND == errCode) {
            //Modify the magic code of the position order array to 0
            for(int OI = 0; OI < ArraySize(aryTardOrderInfo); OI++) {
               if (0 == aryTardOrderInfo[OI].orderMagic) {
                  continue;
               }

               if (Tkt == aryTardOrderInfo[OI].orderTicket) {
                  aryTardOrderInfo[OI].orderMagic = 0;
                  break;
               }
            }

            return;
         }
      }
   }

   //Delete pending order
   for (int O = OrdersTotal() - 1 ; O >= 0 ; O --) {
      ulong Tkt = (long)OrderGetTicket(O);
      if(!OrderSelect(Tkt)) {
         continue;
      }

      string O_Sym = OrderGetString(ORDER_SYMBOL);

      if ( ( O_Sym != Sym && Sym != "" ) ) {
         continue;
      }

      long O_Type = (long)OrderGetInteger(ORDER_TYPE);
      if (ORDER_TYPE_BUY == pOrderType && O_Type != ORDER_TYPE_BUY_LIMIT) {
         continue;
      } else if (ORDER_TYPE_SELL == pOrderType && O_Type != ORDER_TYPE_SELL_LIMIT) {
         continue;
      }

      long O_Magic = (long)OrderGetInteger(ORDER_MAGIC);
      if ( ( pOrdeMagic >= 0 && O_Magic != pOrdeMagic ) ) {
         continue;
      }

      for (int I = 1 ; I <= 20 ; I = I + 1) {
         if (Trade.OrderDelete(Tkt)) {
//         if ( OrderDeleteMQL4((ulong)Tkt, O_Sym, Clr) ) {
            Print("OrderClose OK #", Tkt, " sy=", O_Sym, " op=", O_Type, " mn=", O_Magic, ", try ", I);

            //Modify the magic code of the position order array to 0
            for(int OI = 0; OI < ArraySize(aryTardOrderInfo); OI++) {
               if (0 == aryTardOrderInfo[OI].orderMagic) {
                  continue;
               }

               if (Tkt == aryTardOrderInfo[OI].orderTicket) {
                  aryTardOrderInfo[OI].orderMagic = 0;
                  break;
               }
            }

            break;
         }

         long errCode = GetLastError();
         Print("Error(", errCode, ") opening position: ", (GetLastError()), ", try ", I);
         //invalid ticket
         if (ERR_TRADE_POSITION_NOT_FOUND == errCode) {
            //Modify the magic code of the position order array to 0
            for(int OI = 0; OI < ArraySize(aryTardOrderInfo); OI++) {
               if (0 == aryTardOrderInfo[OI].orderMagic) {
                  continue;
               }

               if (Tkt == aryTardOrderInfo[OI].orderTicket) {
                  aryTardOrderInfo[OI].orderMagic = 0;
                  break;
               }
            }

            return;
         }
      }
   }
}



//Check if a currency pair is in MarketWatch
string fn_checkSymbol(string Sym ) {
   if ( StringLen(Sym)  <= 5 ) {
      Print("Symbol name " + Sym + " from LstSet is too short. Perhaps you made a mistake in writing.");
      return( "");
   }
   for (int I = 0 ; I < SymbolsTotal(true) ; I++ ) {
      string  S = SymbolName(I, true);
      StringToUpper(S);
      StringToUpper(Sym);
      if ( StringFind(S, Sym, 0) >= 0 ) {
         return(S );
      }
   }
   Print("Symbol " + Sym + " from LstSet not found in MarketWatch. Add this symbol to MarketWatch.");
   return( "");
}

//Find order <already optimized>
bool fn_isExistOrder(string Sym, long pOrderType, long pOrderMagic, ulong pOrderTicket, string pOrderComment ) {

   for (int I = 0 ; I <  ArraySize(aryTardOrderInfo) ; I++ ) {
      if (0 == aryTardOrderInfo[I].orderMagic) {
         continue;
      }
      if ( ( aryTardOrderInfo[I].orderSymbol != Sym && Sym != "" ) ) {
         continue;
      }
      if ( ( StringFind(aryTardOrderInfo[I].orderComment, pOrderComment, 0) <  0 && pOrderComment != "" ) ) {
         continue;
      }
      if ( ( pOrderType >= 0 && aryTardOrderInfo[I].orderType != pOrderType ) ) {
         continue;
      }
      if ( ( pOrderMagic >= 0 && aryTardOrderInfo[I].orderMagic != pOrderMagic ) ) {
         continue;
      }
      if ( ( pOrderTicket == aryTardOrderInfo[I].orderTicket || pOrderTicket == 0 ) ) {
         return(true);
      }
   }
   return(false);
}

//Calculate the total profit of open orders
double fn_orderProfitTotal (string Sym, long pOrderType, long pMagic ) {
   double    TotProfit = 0.0;

   for (int P = 0 ; P < PositionsTotal(); P++ ) {
      ulong Tkt = PositionGetTicket(P);

      if(!PositionSelectByTicket(Tkt)) continue;

      if ( ( PositionGetString(POSITION_SYMBOL) != Sym && Sym != "" ) ) {
         continue;
      }
      if ( pOrderType >= 0 && PositionGetInteger(POSITION_TYPE) != pOrderType ) {
         continue;
      }
      if ( ( PositionGetInteger(POSITION_TYPE) != 0 && PositionGetInteger(POSITION_TYPE) != 1 ) ) {
         continue;
      }
      if ( ( pMagic < 0 || PositionGetInteger(POSITION_MAGIC) == pMagic ) ) {
         TotProfit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP) - PositionGetDouble(POSITION_VOLUME) * 10 + TotProfit;
      }
   }
   return(TotProfit);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void fn_ModifyTakeprofit(string Sym, long pOrderType, long pOrderMagic, double pTakeprofit ) {

   for (int P = 0 ; P < PositionsTotal(); P++ ) {
      ulong Tkt = PositionGetTicket(P);

      if(!PositionSelectByTicket(Tkt)) {
         continue;
      }

      long PosType = (long)PositionGetInteger(POSITION_TYPE);
      if ( PosType >= 2 ) {
         continue;
      }
      if ( ( PositionGetString(POSITION_SYMBOL) != Sym && Sym != "" ) ) {
         continue;
      }
      if ( ( pOrderType >= 0 && PosType != pOrderType ) ) {
         continue;
      }
      if ( ( pOrderMagic >= 0 && PositionGetInteger(POSITION_MAGIC) != pOrderMagic ) ) {
         continue;
      }
      fn_ModifyCurOrder(Tkt, -1.0, -1.0, pTakeprofit, 0);
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void fn_ModifyStopLoss(string Sym, long pOrderMagic) {

   for (int P = 0 ; P < PositionsTotal() ; P++ ) {
      // Get the unique number of the order
      ulong Tkt = PositionGetTicket(P);

      // Select order
      if(!PositionSelectByTicket(Tkt)) {
         continue;
      }

      long PosType = (long)PositionGetInteger(POSITION_TYPE);
      if ( ( PositionGetString(POSITION_SYMBOL) != Sym && Sym != "" ) ) {
         continue;
      }

      if ( ( pOrderMagic >= 0 && PositionGetInteger(POSITION_MAGIC) != pOrderMagic ) ) {
         continue;
      }

      //Stop loss 100 pips
      double tmp_stopLoss = PositionGetDouble(POSITION_SL);
      if (0.0 == tmp_stopLoss) {
         tmp_stopLoss = PosType == POSITION_TYPE_BUY ?
                        SymbolInfoDouble(Sym, SYMBOL_BID) - 0.010 :
                        SymbolInfoDouble(Sym, SYMBOL_ASK) + 0.010;
         // Change Order
         fn_ModifyCurOrder(Tkt, -1.0, tmp_stopLoss, -1, 0);
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void fn_ModifyCurOrder(ulong pTicket, double pOpenPrice, double pStopLoss, double pTakeprofit, datetime pExpiration) {

   int       local_maxRunNum = 5;

   string Sym = PositionGetString(POSITION_SYMBOL); // 交易品种
   int NumDigits = (int)SymbolInfoInteger(Sym, SYMBOL_DIGITS); // 小数位数
   ulong  magic = PositionGetInteger(POSITION_MAGIC); // 持仓的幻数
   long local_errCode = 0 ;

   if ( pOpenPrice <= 0.0 ) {
      pOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN) ;
   }
   if ( pStopLoss < 0.0 ) {
      pStopLoss = PositionGetDouble(POSITION_SL) ;
   }
   if ( pTakeprofit < 0.0 ) {
      pTakeprofit = PositionGetDouble(POSITION_TP) ;
   }
   pOpenPrice = NormalizeDouble(pOpenPrice, NumDigits) ;
   pStopLoss = NormalizeDouble(pStopLoss, NumDigits) ;
   pTakeprofit = NormalizeDouble(pTakeprofit, NumDigits) ;
   double pOpenPriceNorm = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN), NumDigits) ;
   double pStopLossNorm = NormalizeDouble(PositionGetDouble(POSITION_SL), NumDigits) ;
   double pTakeprofitNorm = NormalizeDouble(PositionGetDouble(POSITION_TP), NumDigits) ;
   if ((pOpenPrice == pOpenPriceNorm) && (pStopLoss == pStopLossNorm) && (pTakeprofit == pTakeprofitNorm)) {
      return;
   }
   for (int RunNum = 1 ; RunNum <= local_maxRunNum ; RunNum ++) {
      //If it is not a test and the EA is not allowed to run or the EA stops running
      if (!(MQLInfoInteger(MQL_TESTER)) && ((!(AccountInfoInteger(ACCOUNT_TRADE_EXPERT))) || IsStopped()) ) {
         return;
      }

      //      local_1_bo = OrderModifyMQL4(local_ticket, Sym, magic, pOpenPrice, pStopLoss, pTakeprofit, pExpiration, -1) ;
      bool Esito = Trade.PositionModify(pTicket, pStopLoss, pTakeprofit);
      if ( Esito ) {
         PrintFormat("OrderModify OK %s #%I64d mg=%d op=%d pr=%.5f oldtp=%.5f tp=%.5f, try %d",
                     PositionGetString(POSITION_SYMBOL), pTicket,
                     PositionGetInteger(POSITION_MAGIC), PositionGetInteger(POSITION_TYPE),
                     pOpenPrice, pTakeprofitNorm,
                     pTakeprofit, RunNum
                    );
         return;
      }

      // GESTIONE ERRORE

      local_errCode = GetLastError() ;
      double Local_ASK = SymbolInfoDouble(Sym, SYMBOL_ASK) ;
      double Local_BID = SymbolInfoDouble(Sym, SYMBOL_BID) ;
      Print(Sym, " #", pTicket, " Error(" + string(local_errCode) + ") modifying order: " + (string)(local_errCode) + ", try " + string(RunNum));
      Print(Sym, " #", pTicket, " Ask=" + string(Local_ASK) + "  Bid=" + string(Local_BID) + "  sym=" + Sym + "  op=" + string(PositionGetInteger(POSITION_TYPE)) + "  pp=" + string(pOpenPrice) + "  sl=" + string(pStopLoss) + "  tp=" + string(pTakeprofit));

      if (ERR_TRADE_POSITION_NOT_FOUND == local_errCode) {
         //Modify the magic code of the position order array to 0
         for(int OI = 0; OI < ArraySize(aryTardOrderInfo); OI++) {
            if (0 == aryTardOrderInfo[OI].orderMagic) {
               continue;
            }

            if (pTicket == aryTardOrderInfo[OI].orderTicket) {
               aryTardOrderInfo[OI].orderMagic = 0;
               break;
            }
         }
         return;
      }
   }
}

//Create and modify orders
long fn_createOrder( string Sym, long pOrderType, double pOrderLots, double pOrderStoploss, double pOrderTakeprofit, long pOrderMagic, string pOrderComment, double pPriceDist) {
   double    local_price = 0.0;
   double    local_ask = 0.0;
   double    local_bid = 0.0;
   double    local_Spread = 0.0;
   int       local_digits = 0;
   long       local_errCode = 0;
   long       local_runNum = 0;
   long       local_orderTicket = 0;
   double    local_lot;
   //Number of lots placed
   double    local_sendedLots;
   //----- -----

   //add
   int        tmp_tradCount = 0;
   double     tmp_MinLots = 0;
   double     tmp_Step = 0;

   long ret_code = 0;
   int local_maxRunNum = 5;
   int        markeDcD = 1;

   local_lot = NormalizeDouble(pOrderLots, 2) ;
   local_sendedLots = 0.0 ;

   bool CanOpen;
   if ( AccountInfoInteger(ACCOUNT_LIMIT_ORDERS) == 0 ) {
      CanOpen = true;
   } else {
      CanOpen = PositionsTotal() < AccountInfoInteger(ACCOUNT_LIMIT_ORDERS);
   }
   if ( !(CanOpen) ) {
      PrintFormat("Amount of open and pending orders has reached the limit.");
      return(-1);
   }

   //global_MaxLots = SymbolInfoDouble(Sym,35) ;
   global_MaxLots = SymbolInfoDouble(Sym, SYMBOL_VOLUME_MAX) ;
   tmp_MinLots = SymbolInfoDouble(Sym, SYMBOL_VOLUME_MIN);
   tmp_Step = SymbolInfoDouble(Sym, SYMBOL_VOLUME_STEP);
   local_digits = (int)SymbolInfoInteger(Sym, SYMBOL_DIGITS) ;

   while (local_sendedLots != pOrderLots) {
      if ( pOrderLots > global_MaxLots) {
         local_lot = MathMin(pOrderLots - local_sendedLots, global_MaxLots) ;
      }

      string ErrString = "Correct volume";
      bool CanExec = true;
      if ( local_lot < tmp_MinLots ) {
         //ErrString = StringFormat("Volume is less than the minimum SYMBOL_VOLUME_MIN=%.2f",SymbolInfoDouble(Sym,SYMBOL_VOLUME_MIN));
         ErrString = StringFormat("%s Volume(%." + (string)global_lotsDigits + "f) is less than the minimum SYMBOL_VOLUME_MIN=%." + (string)global_lotsDigits + "f", Sym, local_lot, tmp_MinLots);
         CanExec = false;
      }
      //if ( local_lot > SymbolInfoDouble(Sym,35) ){
      //if ( local_lot > SymbolInfoDouble(Sym,SYMBOL_VOLUME_MAX) ){
      if ( local_lot > global_MaxLots ) {
         //ErrString = StringFormat("Volume is greater than the maximum allowed SYMBOL_VOLUME_MAX=%.2f",SymbolInfoDouble(Sym,SYMBOL_VOLUME_MAX));
         ErrString = StringFormat("%s Volume(%." + (string)global_lotsDigits + "f) is greater than the maximum allowed SYMBOL_VOLUME_MAX=%." + (string)global_lotsDigits + "f", Sym, local_lot, global_MaxLots);
         CanExec = false;
      }
      //if ( MathAbs(int(MathRound(local_lot / SymbolInfoDouble(Sym,36))) * SymbolInfoDouble(Sym,36) - local_lot)>0.0000001 ){
      if (MathAbs(int(MathRound(local_lot / tmp_Step)) * tmp_Step - local_lot) > 0.0000001 ) {
         ErrString = StringFormat("%s Volume(%." + (string)global_lotsDigits + "f) is not a multiple of the minimum gradation SYMBOL_VOLUME_STEP=%." + (string)global_lotsDigits + "f, nearest correct volume %." + (string)global_lotsDigits + "f", Sym, local_lot, tmp_Step, int(MathRound(local_lot / tmp_Step)) * tmp_Step);
         CanExec = false;
      }

      if ( !(CanExec) ) {
         PrintFormat(ErrString);
         return(-1);
      }
      for (local_runNum = 1 ; local_runNum <= local_maxRunNum ; local_runNum ++) {
         if ( ( !(MQLInfoInteger(MQL_TESTER)) && (!(AccountInfoInteger(ACCOUNT_TRADE_EXPERT)) || IsStopped() != 0) ) ) {
            break;
         }

         while (!(MQLInfoInteger(MQL_TRADE_ALLOWED))) {
            if ( MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_OPTIMIZATION) ) {
               continue;
            }
            ////Sleep(5000);
         }
         //RefreshRates();

         local_ask = SymbolInfoDouble(Sym, SYMBOL_ASK) ;
         local_bid = SymbolInfoDouble(Sym, SYMBOL_BID) ;
         local_Spread = SymbolInfoInteger(Sym, SYMBOL_SPREAD) * SymbolInfoDouble(Sym, SYMBOL_POINT) / local_bid * 10000.0 ;
         if ( pOrderType == ORDER_TYPE_BUY ) {
            local_price = local_ask ;
         } else {
            local_price = local_bid ;
         }
         local_price = NormalizeDouble(local_price, local_digits) ;
         //local_3_lo = TimeCurrent() ;

         if (pPriceDist <= 0.0 || local_ask <= 0.0 || local_bid <= 0.0) {
            Print("Price does not match the distance, try ", local_runNum);
            Print("Ask=", local_ask, " Bid=", local_bid, " sy=", Sym, " lot=", local_lot, " op=", pOrderType, " pp=", local_price, " sl=", pOrderStoploss, " tp=", pOrderTakeprofit, " mn=", pOrderMagic, " price_dist=", pPriceDist);

            if (local_runNum < local_maxRunNum) {
               ///Sleep(7700);
               continue;
            } else {
               return(-1);
            }
         }

         if ( pOrderType == ORDER_TYPE_BUY ) {
            local_price = local_ask ;
         } else {
            local_price = local_bid ;
         }
         local_price = NormalizeDouble(local_price, local_digits) ;
         //local_3_lo = TimeCurrent() ;

         if ((local_digits == 5) || (local_digits == 3) || (local_digits == 2))
            markeDcD = 10;
         if (ORDER_TYPE_BUY == pOrderType) {
            //Bid price
            if (local_price > pPriceDist + global_allowSlippagePips * markeDcD * Global_Point_Price) {
               //Change to pending buy order
               pOrderType = ORDER_TYPE_BUY_LIMIT;
               local_price = pPriceDist;
            }
         } else if (ORDER_TYPE_SELL == pOrderType) {
            //ask price
            if (local_price < pPriceDist - global_allowSlippagePips * markeDcD * Global_Point_Price) {
               //Change to pending sell order
               pOrderType = ORDER_TYPE_SELL_LIMIT;
               local_price = pPriceDist;
            }
         }

         if ( global_maxSpread > 0.0 && local_Spread > global_maxSpread ) {
            Print("The current spread is greater than the maximum, try ", local_runNum);
            Print("Ask=", local_ask, " Bid=", local_bid, " sy=", Sym, " lot=", local_lot, " op=", pOrderType, " pp=", local_price, " sl=", pOrderStoploss, " tp=", pOrderTakeprofit, " mn=", pOrderMagic, " price_dist=", pPriceDist, " max_spread=", global_maxSpread, " curr_spread=", local_Spread, " try ", local_runNum);
            //Sleep(7700);
            //continue;

            if (local_runNum < local_maxRunNum) {
               ////Sleep(7700);
               continue;
            } else {
               return(-1);
            }
         }

         //local_orderTicket = OrderSendMQL4(Sym, pOrderType, local_lot, local_price, global_slippage, 0.0, 0.0, DoubleToString(global_floatProfitPre * 100, 2) + "%|" + IntegerToString(global_lineSeq, 2, '0') + LevelSpace + pOrderComment, pOrderMagic, 0, pOrderColor) ;
         string cmt = DoubleToString(global_floatProfitPre * 100, 2) + "%|" + IntegerToString(global_lineSeq, 2, '0') + LevelSpace + pOrderComment;
         Trade.SetExpertMagicNumber(pOrderMagic);
         Trade.SetMarginMode();
         Trade.SetTypeFillingBySymbol(Sym);
         local_orderTicket = Trade.PositionOpen(Sym, (ENUM_ORDER_TYPE)pOrderType, local_lot, local_price, 0, 0, cmt);

         if ( local_orderTicket > 0 ) {
            PrintFormat("orderSend OK #%I64d Ask=%.5f Bid=%.5f sy=%s lot=%." + (string)global_lotsDigits + "f op=%d pp=%.5f mn=%d price_dist=%.5f, try %d", local_orderTicket, local_ask, local_bid, Sym, local_lot, pOrderType, local_price, pOrderMagic, pPriceDist, local_runNum);

            //Add position order array
            tmp_tradCount = ArraySize(aryTardOrderInfo);
            tmp_tradCount = tmp_tradCount + 1;
            ArrayResize(aryTardOrderInfo, tmp_tradCount, 0);
            aryTardOrderInfo[tmp_tradCount - 1].orderComment = BaseComment + "|" + IntegerToString(global_lineSeq, 2, '0') + LevelSpace + pOrderComment;
            aryTardOrderInfo[tmp_tradCount - 1].orderMagic = pOrderMagic;
            aryTardOrderInfo[tmp_tradCount - 1].orderSymbol = Sym;
            aryTardOrderInfo[tmp_tradCount - 1].orderTicket = (ulong)local_orderTicket;
            if (ORDER_TYPE_BUY == pOrderType || ORDER_TYPE_BUY_LIMIT == pOrderType) {
               aryTardOrderInfo[tmp_tradCount - 1].orderType = ORDER_TYPE_BUY;
            } else {
               aryTardOrderInfo[tmp_tradCount - 1].orderType = ORDER_TYPE_SELL;
            }

            //Change Order
            //Print("======3takeprofit=",pOrderTakeprofit);
            if(PositionSelectByTicket(local_orderTicket)) {
               //Print("增加订单 选中OK #",local_orderTicket);
               fn_ModifyCurOrder(local_orderTicket, -1.0, pOrderStoploss, pOrderTakeprofit, 0);
               aryTardOrderInfo[tmp_tradCount - 1].openTime = (datetime)PositionGetInteger(POSITION_TIME);
            } else {
               //Print("增加订单 选中Error #",local_orderTicket);
               aryTardOrderInfo[tmp_tradCount - 1].openTime = TimeCurrent();
            }

            local_sendedLots = local_sendedLots + local_lot ;
            break;
         }

         local_errCode = GetLastError() ;
         ret_code = local_orderTicket * (-1);
         local_orderTicket = 0;
         Print("Error(", local_errCode, ") ret_code=", ret_code, " opening position: ", (local_errCode), ", try ", local_runNum);
         Print("Ask=", local_ask, " Bid=", local_bid, " sy=", Sym,
               " lot=", local_lot, " op=", pOrderType, " pp=", local_price,
               " sl=", pOrderStoploss, " tp=", pOrderTakeprofit, " mn=", pOrderMagic);
         if ( local_ask == 0.0 && local_bid == 0.0 ) {
            Print("Check the Market Watch for the presence of the symbol " + Sym);
         }
         Print("Error " + string(local_errCode) + " Description " + (string)(local_errCode));
         if (
            //local_errCode == ERR_COMMON_ERROR ||
            //local_errCode == ERR_ACCOUNT_DISABLED ||
            //local_errCode == ERR_INVALID_ACCOUNT ||
            local_errCode == ERR_TRADE_DISABLED ) {
            break;
         }
         if ( local_errCode == ERR_WEBREQUEST_TIMEOUT
               || ret_code == TRADE_RETCODE_TIMEOUT
               //Parameter can be a dynamic array only
               // || local_errCode == 142
               //Use of "void" type is unacceptable
               // || local_errCode == 143
            ) {
            Sleep(66666);
         }
         if ( local_ask == 0.0 && local_bid == 0.0 ) {
            Alert("在市场调查中查看符号 " + Sym);
         }
         if (
            //local_errCode == ERR_COMMON_ERROR ||
            local_errCode == ERR_TRADE_DISABLED
            //local_errCode == ERR_INVALID_ACCOUNT ||
            //local_errCode == ERR_TRADE_DISABLED
         ) {
            break;
         }
         //if ( ( local_errCode == 4 || local_errCode == 131 || local_errCode == 132 ) ){
         if (
            //local_errCode == ERR_SERVER_BUSY ||
            ret_code == TRADE_RETCODE_INVALID_VOLUME ||
            ret_code == TRADE_RETCODE_MARKET_CLOSED ) {
            Sleep(30000);
            break;
         }
         //if ( local_errCode == 140 || local_errCode == 148 || local_errCode == 4110 || local_errCode == 4111 ){
         if (
            //local_errCode == ERR_LONG_POSITIONS_ONLY_ALLOWED ||
            ret_code == TRADE_RETCODE_LIMIT_ORDERS
            //local_errCode == ERR_LONGS_NOT_ALLOWED ||
            //local_errCode == ERR_SHORTS_NOT_ALLOWED
         ) {
            break;
         }
         //if ( local_errCode == 141 ){
         if ( ret_code == TRADE_RETCODE_TOO_MANY_REQUESTS ) {
            Sleep(100000);
         }
         //if ( local_errCode == 145 ){
         /*
         if ( local_errCode == ERR_TRADE_MODIFY_DENIED ){
            Sleep(17000);
         }
         */
         //if(local_errCode == 146 && IsTradeContextBusy()){
         /*
         if(local_errCode == TRADE_RETCODE_TOO_MANY_REQUESTS &&
            IsTradeContextBusy()){
            do{
               Sleep(500);
            }while(IsTradeContextBusy());
         }
         */
         //if ( local_errCode == 135 ){
         if ( ret_code == TRADE_RETCODE_PRICE_CHANGED ) {
            continue;
         }

         if ( ret_code == TRADE_RETCODE_REQUOTE ) {
            continue;
         }
         ////Sleep(7700);
      }


      /*
      if ( !(global_39_bo) ){
         break;
      }
      */
   }
   return(local_orderTicket);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string isHolidays() {
   datetime    DTT = TimeCurrent();
   long    T = 0;
   if ( Holidays == 0 ) {
      T = 15;
   } else if ( Holidays == 1 ) {
      T = 8;
   } else {
      T = 0;
   }

   if ( ( TimeDayOfYearMQL4(DTT) < T || TimeDayOfYearMQL4(DTT) >  358 ) ) {
      return("Christmas and NY Holidays");
   }
   return("");
}

// cerco l'ordine più recente e ritorno la distanza temporale
datetime DELAYtime(string Sym, long pOrderType, long pOrderMagic, string pOrderComment, datetime pOpenTime) {
   double   MaxOpenTime = 0;
   int   I = 0;
   int   N = ArraySize(aryTardOrderInfo);

   for (I = 0 ; I < N ; I++ ) {

      // Order magic non inserito
      if (0 == aryTardOrderInfo[I].orderMagic) {
         continue;
      }

      // symbol sbagliato
      if ( aryTardOrderInfo[I].orderSymbol != Sym && Sym != "" ) {
         continue;
      }

      //Print("===1pOpenTime=",pOpenTime);
      // order comment bagliato
      if ( ( StringFind(aryTardOrderInfo[I].orderComment, pOrderComment, 0) != -1 && pOrderComment != "" ) ) {
         continue;
      }

      //Print("===2pOpenTime=",pOpenTime);
      // order type sbagliato
      if ( ( pOrderType >= 0 && aryTardOrderInfo[I].orderType != pOrderType ) ) {
         continue;
      }

      //Print("===3pOpenTime=",pOpenTime,";aryTardOrderInfo[I].openTime=",aryTardOrderInfo[I].openTime);
      // order magic sbagliato
      if ( ( pOrderMagic >= 0 && aryTardOrderInfo[I].orderMagic != pOrderMagic && aryTardOrderInfo[I].orderMagic != global_OrderMagic ) ||
            (MaxOpenTime >= aryTardOrderInfo[I].openTime) ) {
         continue;
      }
      //Print("===4tmp_do_67=",MaxOpenTime);
      MaxOpenTime = (double)aryTardOrderInfo[I].openTime;
      //Print("===5tmp_do_67=",(datetime)MaxOpenTime);
   }
   pOpenTime = pOpenTime - datetime(MaxOpenTime);

   //Print("===6pOpenTime=",pOpenTime);

   return(pOpenTime);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string fn_isTestToStr() {
   if (MQLInfoInteger(MQL_TESTER)) {
      return "true";
   } else {
      return "false";
   }
}

//average cost price (prezzo di BE)
double fn_avgOrderOpenPrice(string Sym, long pOrderType, long pMagic) {

   double     PV = 0.0;
   double      V = 0.0;

   for (int I = PositionsTotal() - 1 ; I >= 0 ; I-- ) {
      // Get the unique number of the order
      ulong Tkt = (long)PositionGetTicket(I);

      // Select order
      if(!PositionSelectByTicket(Tkt)) continue;

      if ( PositionGetString(POSITION_SYMBOL) != Sym || PositionGetInteger(POSITION_MAGIC) != pMagic ) {
         continue;
      }
      if ( ( PositionGetInteger(POSITION_TYPE) != pOrderType && pOrderType != -1 ) || PositionGetInteger(POSITION_TYPE) > 1 ) {
         continue;
      }
      PV = PositionGetDouble(POSITION_PRICE_OPEN) * PositionGetDouble(POSITION_VOLUME) + PV;
      V = V + PositionGetDouble(POSITION_VOLUME);
   }
   if ( V == 0.0 ) {
      return(0.0);
   } else {
      return(NormalizeDouble(PV / V, Digits()));
   }
}
//Get the number of other currency pairs in the position excluding the specified currency pair
long fn_GetOtherSymbolsCount(string Sym) {

   string  Syms[];
   ArrayResize(Syms, 0, 0);
   for (int I = 0 ; I < ArraySize(aryTardOrderInfo) ; I++ ) {
      if (0 == aryTardOrderInfo[I].orderMagic) {
         continue;
      }
      if ( aryTardOrderInfo[I].orderSymbol == Sym ) {
         continue;
      }
      long    B = 0;
      for (int J = 0 ; J < ArraySize(Syms) ; J++ ) {
         if ( Syms[J] == aryTardOrderInfo[I].orderSymbol ) {
            B = 1;
            break;
         }
      }
      if ( B == 0 ) {
         ArrayResize(Syms, ArraySize(Syms) + 1, 0);
         Syms[ArraySize(Syms) - 1] = aryTardOrderInfo[I].orderSymbol;
      }
   }
   return( ArraySize(Syms));
}
long fn_getOtherMagicsCount(string Sym, long pOrderMagic) {

   long  Syms[];
   ArrayResize( Syms, 0, 0);
   for (    int  I = 0 ; I < ArraySize(aryTardOrderInfo) ; I++ ) {
      if (0 == aryTardOrderInfo[I].orderMagic) {
         continue;
      }
      if ( Sym != "" && aryTardOrderInfo[I].orderSymbol != Sym ) {
         continue;
      }
      if ( aryTardOrderInfo[I].orderMagic == pOrderMagic ) {
         continue;
      }
      long     B = 0;
      for (int J = 0 ; J < ArraySize(Syms) ; J++ ) {
         if ( Syms[J] == aryTardOrderInfo[I].orderMagic ) {
            B = 1;
            break;
         }
      }
      if ( B == 0 ) {
         ArrayResize(Syms, ArraySize(Syms) + 1, 0);
         Syms[ArraySize(Syms) - 1] = aryTardOrderInfo[I].orderMagic;
      }
   }
   return(ArraySize(Syms));
}

//Finds whether a position order exists for a currency in the specified currency pair
bool fn_existSymbol( string Sym) {

   string tmp_first = StringSubstr(Sym, 0, 3);
   string tmp_secod = StringSubstr(Sym, 3, 3);
   for (int I = 0 ; I < ArraySize(aryTardOrderInfo); I++ ) {
      if (0 == aryTardOrderInfo[I].orderMagic) {
         continue;
      }

      if (0 == StringCompare(Sym, aryTardOrderInfo[I].orderSymbol)) {
         continue;
      }

      if (-1 != StringFind(aryTardOrderInfo[I].orderSymbol, tmp_first)) {
         return true;
      }

      if (-1 != StringFind(aryTardOrderInfo[I].orderSymbol, tmp_secod)) {
         return true;
      }
   }
   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |


//Get currency number
string GetCurrencyNumber( string Cur) {

   if ( StringLen(Cur)  != 3 ) {
      return("9");
   }
   if ( Cur == "AUD" ) {
      return("1");
   }
   if ( Cur == "CAD" ) {
      return("2");
   }
   if ( Cur == "EUR" ) {
      return("3");
   }
   if ( Cur == "GBP" ) {
      return("4");
   }
   if ( Cur == "JPY" ) {
      return("5");
   }
   if ( Cur == "NZD" ) {
      return("6");
   }
   if ( Cur == "USD" ) {
      return("7");
   }
   return("9");
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Get_StrangeNumber(string Sym, int pOrderLevel, long iStdDevPeriod) {
   int      ID_Sym = 0;
   double   Mult = 0.0;
   double   Exp = 0.0;
   double   Bid = SymbolInfoDouble(Sym, SYMBOL_BID);
   if ( StringFind(Sym, "AUDCAD", 0) >= 0 ) {
      ID_Sym = 0;
   } else if ( StringFind(Sym, "AUDNZD", 0) >= 0 ) {
      ID_Sym = 1;
   } else if ( StringFind(Sym, "NZDCAD", 0) >= 0 ) {
      ID_Sym = 2;
   } else if ( StringFind(Sym, "GBPCAD", 0) >= 0 ) {
      ID_Sym = 3;
   } else if ( StringFind(Sym, "EURGBP", 0) >= 0 ) {
      ID_Sym = 4;
   } else {
      ID_Sym = 5;
   }
   if ( ( pOrderLevel < 0 || pOrderLevel > 4 || ID_Sym == -1 || Period() != 15 ) ) {
      return(-1.0);
   }
   Mult = MatrixStrangeNumber[ID_Sym][pOrderLevel][0];
   Exp = MatrixStrangeNumber[ID_Sym][pOrderLevel][1];

   return(Mult * MathPow(iStdDevPeriod, Exp) * Bid);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Init_Factor_for_StrangeNumber() {
   MatrixStrangeNumber[0][0][0] = 0.0000897;
   MatrixStrangeNumber[0][1][0] = 0.0001034;
   MatrixStrangeNumber[0][2][0] = 0.0001795;
   MatrixStrangeNumber[0][3][0] = 0.0002647;
   MatrixStrangeNumber[0][4][0] = 0.0002584;
   MatrixStrangeNumber[1][0][0] = 0.0000588;
   MatrixStrangeNumber[1][1][0] = 0.0000813;
   MatrixStrangeNumber[1][2][0] = 0.0001579;
   MatrixStrangeNumber[1][3][0] = 0.0003007;
   MatrixStrangeNumber[1][4][0] = 0.0004076;
   MatrixStrangeNumber[2][0][0] = 0.0000738;
   MatrixStrangeNumber[2][1][0] = 0.0000939;
   MatrixStrangeNumber[2][2][0] = 0.0001887;
   MatrixStrangeNumber[2][3][0] = 0.0003237;
   MatrixStrangeNumber[2][4][0] = 0.0003535;
   MatrixStrangeNumber[3][0][0] = 0.0000645;
   MatrixStrangeNumber[3][1][0] = 0.0000914;
   MatrixStrangeNumber[3][2][0] = 0.000148;
   MatrixStrangeNumber[3][3][0] = 0.0002208;
   MatrixStrangeNumber[3][4][0] = 0.00025;
   MatrixStrangeNumber[4][0][0] = 0.000054;
   MatrixStrangeNumber[4][1][0] = 0.0000639;
   MatrixStrangeNumber[4][2][0] = 0.0000964;
   MatrixStrangeNumber[4][3][0] = 0.0001486;
   MatrixStrangeNumber[4][4][0] = 0.0001765;
   MatrixStrangeNumber[5][0][0] = 0.000258;
   MatrixStrangeNumber[5][1][0] = 0.000221;
   MatrixStrangeNumber[5][2][0] = 0.000159;
   MatrixStrangeNumber[5][3][0] = 0.000221;
   MatrixStrangeNumber[5][4][0] = 0.000258;
   MatrixStrangeNumber[0][0][1] = 0.5292458;
   MatrixStrangeNumber[0][1][1] = 0.5154581;
   MatrixStrangeNumber[0][2][1] = 0.4603964;
   MatrixStrangeNumber[0][3][1] = 0.4371622;
   MatrixStrangeNumber[0][4][1] = 0.4761835;
   MatrixStrangeNumber[1][0][1] = 0.5749035;
   MatrixStrangeNumber[1][1][1] = 0.5317178;
   MatrixStrangeNumber[1][2][1] = 0.4514056;
   MatrixStrangeNumber[1][3][1] = 0.3911576;
   MatrixStrangeNumber[1][4][1] = 0.3704194;
   MatrixStrangeNumber[2][0][1] = 0.5909246;
   MatrixStrangeNumber[2][1][1] = 0.5569647;
   MatrixStrangeNumber[2][2][1] = 0.475178;
   MatrixStrangeNumber[2][3][1] = 0.4380521;
   MatrixStrangeNumber[2][4][1] = 0.4670035;
   MatrixStrangeNumber[3][0][1] = 0.5916496;
   MatrixStrangeNumber[3][1][1] = 0.5410278;
   MatrixStrangeNumber[3][2][1] = 0.4918849;
   MatrixStrangeNumber[3][3][1] = 0.461836;
   MatrixStrangeNumber[3][4][1] = 0.49;
   MatrixStrangeNumber[4][0][1] = 0.5956147;
   MatrixStrangeNumber[4][1][1] = 0.5731626;
   MatrixStrangeNumber[4][2][1] = 0.538971;
   MatrixStrangeNumber[4][3][1] = 0.513383;
   MatrixStrangeNumber[4][4][1] = 0.5309254;
   MatrixStrangeNumber[5][0][1] = 0.476184;
   MatrixStrangeNumber[5][1][1] = 0.461836;
   MatrixStrangeNumber[5][2][1] = 0.479234;
   MatrixStrangeNumber[5][3][1] = 0.461836;
   MatrixStrangeNumber[5][4][1] = 0.476184;
}



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
long TimeDayOfYearMQL4(datetime date) {
   MqlDateTime tm;
   TimeToStruct(date, tm);
   return(tm.day_of_year);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetSymbolNumber(string Sym) {
   if ( StringLen(Sym)  != 6 ) {
      return("99");
   }
   string w1 = StringSubstr(Sym, 0, 3);
   string w2 = StringSubstr(Sym, 3, 3);
   return( GetCurrencyNumber(w1) + GetCurrencyNumber(w2));
}

//Line ID
string GetMagic(string Sym) {
   string s1 = Sym;
   return( GetSymbolNumber(s1) + IntegerToString(NmbrThisServer, 2, 48) + Sym);
}
//There should be something wrong with this code
void SetNUMBER(string Sym, long pOrderType, long pMagic) {
   long  T = 0;
   /*
   long  tmp_in_58 = 0;
   long  tmp_in_59 = PositionsTotal();
   if ( Sym == "0" ){
      Sym = Sym;
   }
   for (tmp_in_58 = 0 ; tmp_in_58 < tmp_in_59 ; tmp_in_58++ ){
      if ( !(OrderSelect(tmp_in_58,SELECT_BY_POS,MODE_TRADES)) ){
         continue;
      }
      if ( ( Sym != "" && PositionGetString(POSITION_SYMBOL) != Sym) || StringFind(PositionGetString(POSITION_COMMENT),LevelSpace + LevelFirst,0) == -1 ){
         continue;
      }
      if ( ( PositionGetInteger(POSITION_TYPE) != 0 && PositionGetInteger(POSITION_TYPE) != 1 ) ){
         continue;
      }
      if ( ( pOrderType >= 0 && PositionGetInteger(POSITION_TYPE) != pOrderType ) ){
         continue;
      }
      if ( pMagic > 0 || PositionGetInteger(POSITION_MAGIC) == pMagic || PositionGetInteger(POSITION_MAGIC) == global_OrderMagic ){
         long tmp_do_60 = StringToInteger(StringSubstr(PositionGetString(POSITION_COMMENT),StringFind(PositionGetString(POSITION_COMMENT),LevelSpace + LevelFirst,0) + 2,0));
         T = ( tmp_do_60 <= T) ? tmp_do_60 : T  ;
      }
   }
   */

   GlobalVariableSet(fn_isTestToStr() + "NUMBER" + Sym + string(global_lineCode), T);
}




// Carica i dati del LstSet nelle variabili Globali
void fn_getEvnPara(string Sym, int pLineSeq) {
   //----- -----
   string     PairNumber; //currency pair code
   string     tmp_st_2;
   string     tmp_st_3;
   //global_lineSeq_st = IntegerToString(pLineSeq,2,48) ;
   global_lineSeq_st = IntegerToString(pLineSeq, 2, '0') ; //Line number
   if ( StringLen(Sym)  != 6 ) {
      PairNumber = "99";
   } else {
      PairNumber = GetCurrencyNumber(StringSubstr(Sym, 0, 3)) + GetCurrencyNumber(StringSubstr(Sym, 3, 3));
   }
   global_lineCode = (long)StringToInteger(PairNumber + global_lineSeq_st) ;
   //Print("--global_lineCode=",global_lineCode,";",Sym + string(global_lineCode));
   //Print("---global_OrderMagic=",GlobalVariableGet(fn_isTestToStr() + "Magic" + Sym + string(global_lineCode)));
   global_OrderMagic = (long)GlobalVariableGet(fn_isTestToStr() + "Magic" + Sym + string(global_lineCode)) ;
   global_lotsMartinp = LotsMartinp ;
   Global_Indic_Period = Global_Indic_Period_Default ;
   StringTrimLeft(Global_Stringa_Parametro_01);
   StringTrimRight(Global_Stringa_Parametro_01);
   if ( ( Global_Tipo_Inizializzazione != 1 || Global_Stringa_Parametro_01 != "" ) ) {
      int I = pLineSeq - 1;
      Global_Indic_Period = (int)LstSet[I].Indic_Period ;
      Golbal_Mult_iStdDev = LstSet[I].Mult_iStdDev ;
      Global_Mult1 = LstSet[I].Mult1 ;
      Global_Base1_Pow = LstSet[I].Base1_Pow ;
      Global_Numerator = (long)LstSet[I].Numerator ;
      Global_Base2_Pow = LstSet[I].Base2_Pow ;
      Global_Mult_Period = LstSet[I].Mult_Period ;
   }
   global_orderLevel = (int)GlobalVariableGet(fn_isTestToStr() + "NUMBER" + Sym + string(global_lineCode)) ;
   global_PriceDist = GlobalVariableGet(fn_isTestToStr() + "Distance_Price" + Sym + string(global_lineCode)) ;
   Global_Spread_Points = (double)SymbolInfoInteger(Sym, SYMBOL_SPREAD) ;
   Global_Spread_Price = SymbolInfoInteger(Sym, SYMBOL_SPREAD) * SymbolInfoDouble(Sym, SYMBOL_TRADE_TICK_SIZE) ;
   Global_Ask_Price = SymbolInfoDouble(Sym, SYMBOL_ASK) ;
   Global_Bid_Price = SymbolInfoDouble(Sym, SYMBOL_BID) ;
   Global_Point_Price = SymbolInfoDouble(Sym, SYMBOL_TRADE_TICK_SIZE) ;
   Global_Bid_Su_ClosePrec = 0.0 ;
   if ( iClose(Sym, PERIOD_CURRENT, 1) > 0.0 ) {
      Global_Bid_Su_ClosePrec = (MathAbs(Global_Bid_Price / iClose(Sym, PERIOD_CURRENT, 1) - 1.0)) * 10000.0 ;
   }
   Calc_StdDev(Sym);
   //Calcola l'indicatore medio dell'intervallo reale e ne restituisce il valore。
//   if ( iATRMQL4(Sym, PERIOD_D1, Global_ATR_Period, 1) / SymbolInfoDouble(Sym, SYMBOL_BID) > Global_ATR_MAX ) {
   if ( SymbolInfoDouble(Sym, SYMBOL_BID) == 0 || iATRMQL4(Sym, PERIOD_D1, Global_ATR_Period, 1) / SymbolInfoDouble(Sym, SYMBOL_BID) > Global_ATR_MAX ) {
      Global_ATR_underMAX = true ;
      return;
   }
   Global_ATR_underMAX = true ;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Calc_StdDev(string Sym) {
   //Calculate the standard deviation indicator and return its value.
   //Global_iStdDev_Price = iStdDevMQL4(Sym,0,Global_Indic_Period,1,3,0,-1) * Golbal_Mult_iStdDev;
   /*
      double iStdDev( string symbol, long timeframe, long ma_period, long ma_shift, long ma_method, long applied_price, long shift)
      A low StdDev reading indicates an inactive market, while a high reading indicates an active market.
      1. symbol specifies the currency pair, NULL is the default current currency pair
      2. timeframe time period, 0 is the current time period
      3. ma_period average period, usually 20
      4. ma_shiftMA offset, usually 0
      5. ma_methodMA method, usually MODE_EMA
      6. applied_price applies the price, usually PRICE_CLOSE
      7. Shift specifies the bar value, 0 is the current bar, 1 is the previous bar, and so on.
   */
   Global_iStdDev_Price = iStdDevMQL4(Sym, PERIOD_CURRENT, Global_Indic_Period, 1, MODE_LWMA, PRICE_CLOSE, -1) * Golbal_Mult_iStdDev ;
   if ( Use_StrangeNumber_for_iStdDev == true ) {
      double StrangeNUmber = Get_StrangeNumber(Sym, global_orderLevel, Global_Indic_Period) ;

      if ( StrangeNUmber > 0.0 ) {
         Global_iStdDev_Price = MathMax(Global_iStdDev_Price, StrangeNUmber) ;
      }
   }

   //Calculate the moving average indicator and return its value
   //Calculate the moving average indicator and return its value
   //global_iMA = iMA(Sym,0,Global_Indic_Period,1,3,0,-1);
   /*
      double iMA( string symbol, long timeframe, long period, long ma_shift, long ma_method, long applied_price, long shift)
      The iMA moving average indicator is a trend indicator and usually consists of three lines with different periods to form an indicator system.
      1. symbol specifies the currency pair, NULL is the default current currency pair
      2. timeframe time period, 0 is the current time period
      3. Period average line period, usually 7, 14, 28
      4. ma_shift offset, 0 is selected by default
      5. ma_methodMA method, usually MODE_EMA, MODE_LWMA (linear average)
      6. applied_price applies the price. The closing price PRICE_CLOSE is selected by default.
      7. Shift specifies the bar value, 0 is the current bar, 1 is the previous bar, and so on.
    */
   global_iMA = iMAMQL4(Sym, PERIOD_CURRENT, Global_Indic_Period, 1, MODE_LWMA, PRICE_CLOSE, -1) ;

   global_iMaiStdDevAdd = global_iMA + Global_iStdDev_Price ;
   global_iMaiStdDevSub = global_iMA - Global_iStdDev_Price ;
   //global_52_in = global_27_in ;
}

//+------------------------------------------------------------------+
double iStdDevMQL4(string symbol, int tf, int ma_period, int ma_shift, int method, int price, int shift) {
   ENUM_TIMEFRAMES timeframe = TFMigrate(tf);
   ENUM_MA_METHOD ma_method = MethodMigrate(method);
   ENUM_APPLIED_PRICE applied_price = PriceMigrate(price);
   int handle = iStdDev(symbol, timeframe, ma_period, ma_shift, ma_method, applied_price);
   if(handle < 0) {
      Print("This iStdDev object cannot be created: Error", GetLastError());
      return(-1);
   } else
      return(CopyBufferMQL4(handle, 0, shift));
}
//+------------------------------------------------------------------+
double iMAMQL4(string symbol, int tf, int period, int ma_shift, int method, int price, int shift) {
   ENUM_TIMEFRAMES timeframe = TFMigrate(tf);
   ENUM_MA_METHOD ma_method = MethodMigrate(method);
   ENUM_APPLIED_PRICE applied_price = PriceMigrate(price);
   int handle = iMA(symbol, timeframe, period, ma_shift, ma_method, applied_price);
   if(handle < 0) {
      Print("This iMA object cannot be created: Error", GetLastError());
      return(-1);
   } else
      return(CopyBufferMQL4(handle, 0, shift));
}
//+------------------------------------------------------------------+
double iATRMQL4(string symbol, int tf, int period, int shift) {
   ENUM_TIMEFRAMES timeframe = TFMigrate(tf);
   int handle = iATR(symbol, timeframe, period);
   if(handle < 0) {
      Print("This iATR object cannot be created: Error", GetLastError());
      return(-1);
   } else
      return(CopyBufferMQL4(handle, 0, shift));
}

//+------------------------------------------------------------------+
double CopyBufferMQL4(int handle, int index, int shift) {
   double buf[];
   switch(index) {
   case 0:
      if(CopyBuffer(handle, 0, shift, 1, buf) > 0)
         return(buf[0]);
      break;
   case 1:
      if(CopyBuffer(handle, 1, shift, 1, buf) > 0)
         return(buf[0]);
      break;
   case 2:
      if(CopyBuffer(handle, 2, shift, 1, buf) > 0)
         return(buf[0]);
      break;
   case 3:
      if(CopyBuffer(handle, 3, shift, 1, buf) > 0)
         return(buf[0]);
      break;
   case 4:
      if(CopyBuffer(handle, 4, shift, 1, buf) > 0)
         return(buf[0]);
      break;
   default:
      break;
   }
   return(EMPTY_VALUE);
}
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES TFMigrate(int tf) {
   switch(tf) {
   case 0:
      return(PERIOD_CURRENT);
   case 1:
      return(PERIOD_M1);
   case 5:
      return(PERIOD_M5);
   case 15:
      return(PERIOD_M15);
   case 30:
      return(PERIOD_M30);
   case 60:
      return(PERIOD_H1);
   case 240:
      return(PERIOD_H4);
   case 1440:
      return(PERIOD_D1);
   case 10080:
      return(PERIOD_W1);
   case 43200:
      return(PERIOD_MN1);

   case 2:
      return(PERIOD_M2);
   case 3:
      return(PERIOD_M3);
   case 4:
      return(PERIOD_M4);
   case 6:
      return(PERIOD_M6);
   case 10:
      return(PERIOD_M10);
   case 12:
      return(PERIOD_M12);
   case 16385:
      return(PERIOD_H1);
   case 16386:
      return(PERIOD_H2);
   case 16387:
      return(PERIOD_H3);
   case 16388:
      return(PERIOD_H4);
   case 16390:
      return(PERIOD_H6);
   case 16392:
      return(PERIOD_H8);
   case 16396:
      return(PERIOD_H12);
   case 16408:
      return(PERIOD_D1);
   case 32769:
      return(PERIOD_W1);
   case 49153:
      return(PERIOD_MN1);
   default:
      return(PERIOD_CURRENT);
   }
}
//+------------------------------------------------------------------+
ENUM_MA_METHOD MethodMigrate(int method) {
   switch(method) {
   case 0:
      return(MODE_SMA);
   case 1:
      return(MODE_EMA);
   case 2:
      return(MODE_SMMA);
   case 3:
      return(MODE_LWMA);
   default:
      return(MODE_SMA);
   }
}
//+------------------------------------------------------------------+
ENUM_APPLIED_PRICE PriceMigrate(int price) {
   switch(price) {
   case 1:
      return(PRICE_CLOSE);
   case 2:
      return(PRICE_OPEN);
   case 3:
      return(PRICE_HIGH);
   case 4:
      return(PRICE_LOW);
   case 5:
      return(PRICE_MEDIAN);
   case 6:
      return(PRICE_TYPICAL);
   case 7:
      return(PRICE_WEIGHTED);
   default:
      return(PRICE_CLOSE);
   }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
