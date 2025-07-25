﻿//+------------------------------------------------------------------+
//|                                               GlobalSettings.mqh |
//|                                 Copyright © 2023, barmenteros FX |
//|                                          https://barmenteros.com |
//+------------------------------------------------------------------+
#include "CommonInputParams.mqh"

#define PROGRAM_ID 81664
#define MAGIC_ID 763926317

#define ALL_ORDERS    -1
#define ONLY_MARKET    -2 //include only market orders
#define ONLY_PENDING    -3 //include only pending orders
#define ONLY_BUY_ANY    -4 //include any buy order (market & pending)
#define ONLY_SELL_ANY    -5 //include any sell order (market & pending)
#define LAST_ORDER_BY_TICKET    0
#define LAST_ORDER_BY_TIME    1
#define BUY_SL_LINE_SUFFIX    "_buy_trail_stop_line@"
#define SELL_SL_LINE_SUFFIX    "_sell_trail_stop_line@"
#define BUY_TP_LINE_SUFFIX    "_buy_take_profit_line@"
#define SELL_TP_LINE_SUFFIX    "_sell_take_profit_line@"

// Input Parameters: General Options
input string gs_ = "===== GENERAL OPTIONS"; //.
input int IN_MagicNumber = MAGIC_ID; //Magic Number ID
input OrdersToTrade IN_OrdersToTrade = kPendingOrders; //Orders To Trade
int IN_EntryGapInPips = 1; //Entry Gap In Pips
input TradingMode IN_TradingMode = kSwingContinuousMode; //Trading Mode
input bool IN_ReverseOrders = true; //Reverse Orders
input bool IN_BreakevenAtGreyArrows = false; //Breakeven At Grey Arrows

input string mms_ = "===== MONEY MANAGEMENT OPTIONS"; //.
//--- Equity Management Settings
input bool EnablePositiveEquityTarget = true;                // Enable/Disable Positive Equity Target
input double PositiveEquityTarget = 20000.0;                 // Positive Equity Target
input bool EnableRecurringPositiveTargetIncrement = true;    // Enable/Disable Recurring Positive Target Increment
input double RecurringPositiveTargetIncrement = 20000.0;     // Recurring Positive Target Increment
input double PositiveEquityLotSizeIncrement = 1.0;           // Positive Equity Lot Size Increment
input double PositiveMultiplierIncrement = 1.0;              // Positive Multiplier Increment
input bool EnableNegativeEquityLimit = true;                 // Enable/Disable Negative Equity Limit
input double NegativeEquityLimit = 300.0;                    // Negative Equity Limit
input double NegativeEquityLotSizeDecrement = 1.0;           // Negative Equity Lot Size Decrement
input double NegativeMultiplierDecrement = 1.0;              // Negative Multiplier Decrement
// Variables for tracking equity targets
double lastReachedPositiveTarget = 0.0;    // Tracks the last positive target that was reached
double nextPositiveEquityTarget = 0.0;     // Tracks the next positive equity target
double nextNegativeEquityTarget = 0.0;     // Tracks the next negative equity target to reach

//--- Individual Trade Management Settings
input bool EnableUnrealizedProfitExit = true;                // Enable/Disable Individual Order Profit
input double UnrealizedProfitExit = 50.0;                    // Individual Order Profit
//--- Trading Pause Settings after Equity Target Hit
input bool EquityTargetAllowReentry = true;                  // Equity Target AllowReentry
input int EquityTargetPauseDuration = 1440;                  // Equity Target Pause Duration
//--- Entry Restriction Settings
input bool EnableMaxEntryThreshold = true;                   // Enable/Disable Maximum Entry Threshold Percent
input double MaxEntryThresholdPercent = 0.9;                 // Maximum Entry Threshold Percent

input string buy_lss_ = "===== BUY LOT SIZE OPTIONS"; //.
input LotSizingOptions Buy_IN_LotSizingOptions = kManualLots; //Buy Lot Sizing Options
input double Buy_IN_InitialLots = 0.01; //Buy Lots
double Buy_CurrentLotSize = Buy_IN_InitialLots; // Current Lot Size (updated dynamically)
input double Buy_IN_PercentFreeMargin = 2.0; //Buy Percent Free Margin
input double Buy_IN_PercentEquity = 2.0; //Buy Percent Equity
//int Buy_IN_UsableBalanceRatio = 10; //Buy Usable Balance Ratio 1:

input string sell_lss_ = "===== SELL LOT SIZE OPTIONS"; //.
input LotSizingOptions Sell_IN_LotSizingOptions = kManualLots; //Sell Lot Sizing Options
input double Sell_IN_InitialLots = 0.01; //Sell Lots
double Sell_CurrentLotSize = Sell_IN_InitialLots; // Current Lot Size (updated dynamically)
input double Sell_IN_PercentFreeMargin = 2.0; //Sell Percent Free Margin
input double Sell_IN_PercentEquity = 2.0; //Sell Percent Equity
//int Sell_IN_UsableBalanceRatio = 10; //Sell Usable Balance Ratio 1:

input string ratio_balance_ = "===== ACCOUNT RATIO BALANCE OPTIONS"; //.
input int AC_Ratio_Limit = 2; // Account Ratio Limit (min 2)
input int AC_Ratio_Actual = 10; // Account Ratio Actual (max 100)

input string bes_ = "===== BE FILTER OPTIONS"; //.
input bool IN_EnableBeFilter = true; //Enable BE Filter
input int IN_BeBuyFilterCounter = 3; //BE Buy Filter
input int IN_BeSellFilterCounter = 2; //BE Sell Filter
input bool IN_EnableBeReentry = false; //Enable Reentry

input string beps_ = "===== BE PIVOT FILTER OPTIONS"; //.
input bool IN_EnableBuyBePivotFilter = true; //Enable Buy BE Pivot Filter
input ENUM_TIMEFRAMES IN_BuyBePivotFilterTimeframe = PERIOD_H1; // Buy BE Pivot Filter Timeframe (from MH_ML_Marker)
input double IN_BuyBePivotFilterPercentage = 70.0; // Buy BE Pivot Filter % (from MH_ML_Marker)
input bool IN_EnableSellBePivotFilter = true; //Enable Sell BE Pivot Filter
input ENUM_TIMEFRAMES IN_SellBePivotFilterTimeframe = PERIOD_H1; // Sell BE Pivot Filter Timeframe (from MH_ML_Marker)
input double IN_SellBePivotFilterPercentage = 70.0; // Sell BE Pivot Filter % (from MH_ML_Marker)

input string res_ = "===== REVERSE ENTRY"; //.
bool IN_BuyEnableReverseFilter = false; //Buy Enable Reverse Filter
input int IN_BuyReverseEntryDeviation = 5; //Buy Reverse Entry Deviation
bool IN_SellEnableReverseFilter = false; //Sell Enable Reverse Filter
input int IN_SellReverseEntryDeviation = 5; //Sell Reverse Entry Deviation
input bool IN_EnableReverseReentry = false; //Enable Reverse Reentry

input string rfs_ = "===== REVERSE FILTER"; //.
input int IN_ReverseBuyFilterCounter = 3; //Reverse Buy Filter
input int IN_ReverseSellFilterCounter = 2; //Reverse Sell Filter

input string rbuyls_ = "===== REVERSE BUY LOTS"; //.
input LotSizingOptions Reverse_Buy_IN_LotSizingOptions = kManualLots; //Reverse Buy Lot Sizing Options
input double Reverse_Buy_IN_InitialLots = 0.01; //Reverse Buy Lots
input double Reverse_Buy_IN_PercentFreeMargin = 2.0; //Reverse Buy % Free Margin
input double Reverse_Buy_IN_PercentEquity = 2.0; //Reverse Buy % Equity

input string rsellls_ = "===== REVERSE SELL LOTS"; //.
input LotSizingOptions Reverse_Sell_IN_LotSizingOptions = kManualLots; //Reverse Sell Lot Sizing Options
input double Reverse_Sell_IN_InitialLots = 0.01; //Reverse Sell Lots
input double Reverse_Sell_IN_PercentFreeMargin = 2.0; //Reverse Sell % Free Margin
input double Reverse_Sell_IN_PercentEquity = 2.0; //Reverse Sell % Equity

input string rsls_ = "===== REVERSE SL"; //.
input int IN_ReverseBuyStopLoss = 25; //Reverse SL Buy
input int IN_ReverseSellStopLoss = 21; //Reverse SL Sell

input string rtps_ = "===== REVERSE TP"; //.
input int IN_ReverseBuyTakeProfit = 10; //Reverse TP Buy
input int IN_ReverseSellTakeProfit = 14; //Reverse TP Sell

input string ms_ = "===== MULTIPLIER OPTIONS"; //.
input int IN_BuyOrderMultiplier = 1; //Buy Order Multiplier: 0 - X
input int IN_SellOrderMultiplier = 1; //Sell Order Multiplier: 0 - X
int CurrentBuyOrderMultiplier = IN_BuyOrderMultiplier;   // Current Buy Order Multiplier
int CurrentSellOrderMultiplier = IN_SellOrderMultiplier; // Current Sell Order Multiplier

input string psos_ = "===== PENDING STOP ORDER OPTIONS"; //.
input int IN_PendingBuyDeviationFromBE = 5; //Pending Buy Deviation From BE
input int IN_PendingSellDeviationFromBE = 5; //Pending Sell Deviation From BE

input string tss_ = "===== TRAIL STOP OPTIONS"; //.
input bool IN_EnableTrailStop = false; //Enable Trail Stop
input TrailStopType IN_TrailStopType = kManualTrailStop; //Trail Stop Type
input double IN_TrailStopInPips = 12.0; //Trail Stop In Pips
input double IN_TrailStepInPips = 2.0; //Trail Step In Pips
input int IN_TrailStopATRMultiplier = 1; //Trail ATR Multiplier
ENUM_TIMEFRAMES TrailStopATRtimeframe = PERIOD_CURRENT;
int TrailStopATRPeriod = 14;

input string ss_ = "===== SPREAD OPTIONS"; //.
input bool IN_EnableSpreadControl = true; //Enable Spread Control
input int IN_MaximumSpread = 20; //Maximum Spread

input string tps_ = "===== TAKE PROFIT OPTIONS"; //.
input bool IN_EnableManualTakeProfit = true; //Enable Manual Take Profit
input int IN_TakeProfitInPips = 15; //Take Profit In Pips
input bool IN_EnableMHMLTakeProfit = false; //Enable MH-ML Percentage Take Profit
input ENUM_TIMEFRAMES IN_MHMLMarkerTakeProfitTimeframe = PERIOD_H1; // MH_ML_Marker level Timeframe
input double IN_MHMLMarkerTakeProfitPerc = 70.0; // Percentage from level to calculate TakeProfit

input string sls_ = "===== STOP LOSS OPTIONS"; //.
input bool IN_EnableStopLoss = true; //Enable Stop Loss
input StopLossType IN_StopLossType = kManualSL; //Stop Loss Type
input int IN_StopLossInPips = 15; //Stop Loss In Pips
input int IN_StopLossATRMultiplier = 2; //StopLoss ATR Multiplier
ENUM_TIMEFRAMES StopLossATRtimeframe = PERIOD_CURRENT;
int StopLossATRPeriod = 14;

input string tds_ = "===== TRADING DAY OPTIONS"; //.
input bool IN_IsTradingAllowedForSunday = true; //Enable Trading On Sunday
input bool IN_IsTradingAllowedForMonday = true; //Enable Trading On Monday
input bool IN_IsTradingAllowedForTuesday = true; //Enable Trading On Tuesday
input bool IN_IsTradingAllowedForWednesday = true; //Enable Trading On Wednesday
input bool IN_IsTradingAllowedForThursday = true; //Enable Trading On Thursday
input bool IN_IsTradingAllowedForFriday = true; //Enable Trading On Friday
input bool IN_IsTradingAllowedForSaturday = true; //Enable Trading On Saturday

input string tos_ = "===== TIME OPTIONS"; //.
input bool IN_EnableTimeManagement = false; //Enable Time Management
input int IN_TradingStartHour = 10; //Start Hours: 0 - 23
input int IN_TradingStartMinutes = 0; //Start Minutes: 0 - 59
input int IN_TradingEndHour = 19; //End Hours: 0 - 23
input int IN_TradingEndMinutes = 0; //End Minutes: 0 - 59

input string nfs_ = "===== NEWS FILTER OPTIONS"; //.
input bool UseNewsFilter = true; //Enable News Filter
bool UseHighImpact = true;
bool UseMediumImpact = true;
bool UseLowImpact = true;
input int HighPauseBefore = 15; //Pause Minutes Before News
input int HighPauseAfter = 15; //Resume Minutes After News
int MediumPause = 3;
int LowPause = 1;
int NumberOfNewsToBePrinted = 5;

// Input Parameters: Line Settings
input string ls_ = "===== LINES SETTINGS"; //.
input color IN_BreakevenLineColor = clrRed; //Breakeven Line Color
input color IN_BuyReverseOrderLineColor = clrMaroon; //Buy Reverse Order Line Color
input color IN_SellReverseOrderLineColor = clrMaroon; //Sell Reverse Order Line Color
input color IN_BuyTrailStopLineColor = clrRed; //Buy Trail Stop Line Color
input color IN_SellTrailStopLineColor = clrRed; //Sell Trail Stop Line Color

input string as_ = "===== ALERTS"; //.
string labelAlert = ""; //Label Alert
input bool enableAlerts = true; // Enable Alert On Open Order

input string cis_ = "===== INDICATORS SETTINGS"; //.
// ADX
input string ADXSectionHeader = "_____ ADX"; //|
bool EnableADXForThreshold = false;
input bool EnableADXForArrowConfirmation = true; //EnableADX
input ENUM_TIMEFRAMES TimeframeADX = PERIOD_CURRENT;  // ADX Timeframe
input int ADXPeriod = 9;
input int ADXLevel = 30;
input ENUM_APPLIED_PRICE Buy_ADX_Price = PRICE_LOW; //Buy Applied Price
input ENUM_APPLIED_PRICE Sell_ADX_Price = PRICE_HIGH; //Sell Applied Price
string ADXInternalSectionHeader = "_____ For internal use by EAs only. Do not modify"; //|
int ADXuserProgramID = PROGRAM_ID; //Custom Program ID
// VOLUME
input string VolumeChopSectionHeader = "_____ VOLUME CHOPPINESS FILTER"; //|
input bool EnableChoppiness = true; // Enable Choppiness
input ENUM_TIMEFRAMES TimeframeVolume = PERIOD_CURRENT;  // Volume Timeframe
input int VolumeAnalysisCandleCount = 100; // Number of bars for volume analysis
input VolumeAdjustmentDirection MeanHighVolumeAdjustment = VOLUME_INCREASE; // Mean High Adjustment Direction
input double MeanHighAdjustmentPercent = 0.0; // Mean High Adjustment %
input VolumeAdjustmentDirection MeanLowVolumeAdjustment = VOLUME_DECREASE; // Mean Low Adjustment Direction
input double MeanLowAdjustmentPercent = 0.0; // Mean Low Adjustment %
input color HighVolumeLevelColor = clrRed; // High Volume Level Color
input color LowVolumeLevelColor = clrBlue; // Low Volume Level Color
// Buy input parameters
input string BuySectionHeader = "_____ BUY"; //|
input int Buy_MaxVolume = 1000;                // High Volume Level for Buy
input int Buy_MinVolume = 500;                 // Low Volume Level for Buy
input double Buy_ChoppinessIndexThreshold = 60.0;   // Choppiness Index Threshold for Buy
// Sell input parameters
input string SellSectionHeader = "_____ SELL"; //|
input int Sell_MaxVolume = 1500;               // High Volume Level for Sell
input int Sell_MinVolume = 1000;               // Low Volume Level for Sell
input double Sell_ChoppinessIndexThreshold = 60.0;  // Choppiness Index Threshold for Sell
// Choppiness input parameters
input string ChoppinessSectionHeader = "_____ CHOPPINESS"; //|
input int ChoppinessPeriod = 14;         // Number of bars to evaluation CI
string VolChopInternalSectionHeader = "_____ For internal use by EAs only. Do not modify"; //|
int VolChopUserProgramID = PROGRAM_ID; //Custom Program ID

input string MHMLMarkerSectionHeader = "_____ MH ML TS CHECKPOINT"; //|
input int N_1m = 100; // Bars for 1m MH and ML
input bool Enable_1m = true; // Enable or disable 1m timeframe
double InpFiboLevelValue1_1M = 0.0; //Fibo Level Value 1 for 1M
color InpFiboLevelColor1_1M = clrDimGray; //Fibo Level Color 1 for 1M
ENUM_LINE_STYLE InpFiboLevelStyle1_1M = STYLE_DOT;
int InpFiboLevelWidth1_1M = 1;
input double InpFiboLevelValue2_1M = 70.0; //Sell % level for 1M
color InpFiboLevelColor2_1M = clrDimGray; //Fibo Level Color 2 for 1M
ENUM_LINE_STYLE InpFiboLevelStyle2_1M = STYLE_DOT;
int InpFiboLevelWidth2_1M = 1;
input double InpFiboLevelValue3_1M = 70.0; //Buy % level for 1M
color InpFiboLevelColor3_1M = clrDimGray; //Fibo Level Color 3 for 1M
ENUM_LINE_STYLE InpFiboLevelStyle3_1M = STYLE_DOT;
int InpFiboLevelWidth3_1M = 1;
double InpFiboLevelValue4_1M = 100.0; //Fibo Level Value 4 for 1M
color InpFiboLevelColor4_1M = clrDimGray; //Fibo Level Color 4 for 1M
ENUM_LINE_STYLE InpFiboLevelStyle4_1M = STYLE_DOT;
int InpFiboLevelWidth4_1M = 1;

// For 5 minute time frame
input int N_5m = 50; // Bars for 5m MH and ML
input bool Enable_5m = true; // Enable or disable 5m timeframe
double InpFiboLevelValue1_5M = 0.0; //Fibo Level Value 1 for 5M
color InpFiboLevelColor1_5M = clrDimGray; //Fibo Level Color 1 for 5M
ENUM_LINE_STYLE InpFiboLevelStyle1_5M = STYLE_DOT;
int InpFiboLevelWidth1_5M = 1;
input double InpFiboLevelValue2_5M = 70.0; //Sell % level for 5M
color InpFiboLevelColor2_5M = clrDimGray; //Fibo Level Color 2 for 5M
ENUM_LINE_STYLE InpFiboLevelStyle2_5M = STYLE_DOT;
int InpFiboLevelWidth2_5M = 1;
input double InpFiboLevelValue3_5M = 70.0; //Buy % level for 5M
color InpFiboLevelColor3_5M = clrDimGray; //Fibo Level Color 3 for 5M
ENUM_LINE_STYLE InpFiboLevelStyle3_5M = STYLE_DOT;
int InpFiboLevelWidth3_5M = 1;
double InpFiboLevelValue4_5M = 100.0; //Fibo Level Value 4 for 5M
color InpFiboLevelColor4_5M = clrDimGray; //Fibo Level Color 4 for 5M
ENUM_LINE_STYLE InpFiboLevelStyle4_5M = STYLE_DOT;
int InpFiboLevelWidth4_5M = 1;

// For 15 minute time frame
input int N_15m = 40; // Bars for 15m MH and ML
input bool Enable_15m = true; // Enable or disable 15m timeframe
double InpFiboLevelValue1_15M = 0.0; //Fibo Level Value 1 for 15M
color InpFiboLevelColor1_15M = clrDimGray; //Fibo Level Color 1 for 15M
ENUM_LINE_STYLE InpFiboLevelStyle1_15M = STYLE_DOT;
int InpFiboLevelWidth1_15M = 1;
input double InpFiboLevelValue2_15M = 70.0; //Sell % level for 15M
color InpFiboLevelColor2_15M = clrDimGray; //Fibo Level Color 2 for 15M
ENUM_LINE_STYLE InpFiboLevelStyle2_15M = STYLE_DOT;
int InpFiboLevelWidth2_15M = 1;
input double InpFiboLevelValue3_15M = 70.0; //Buy % level for 15M
color InpFiboLevelColor3_15M = clrDimGray; //Fibo Level Color 3 for 15M
ENUM_LINE_STYLE InpFiboLevelStyle3_15M = STYLE_DOT;
int InpFiboLevelWidth3_15M = 1;
double InpFiboLevelValue4_15M = 100.0; //Fibo Level Value 4 for 15M
color InpFiboLevelColor4_15M = clrDimGray; //Fibo Level Color 4 for 15M
ENUM_LINE_STYLE InpFiboLevelStyle4_15M = STYLE_DOT;
int InpFiboLevelWidth4_15M = 1;

// For 30 minute time frame
input int N_30m = 200; // Bars for 30m MH and ML
input bool Enable_30m = true; // Enable or disable 30m timeframe
double InpFiboLevelValue1_30M = 0.0; //Fibo Level Value 1 for 30M
color InpFiboLevelColor1_30M = clrDimGray; //Fibo Level Color 1 for 30M
ENUM_LINE_STYLE InpFiboLevelStyle1_30M = STYLE_DOT;
int InpFiboLevelWidth1_30M = 1;
input double InpFiboLevelValue2_30M = 70.0; //Sell % level for 30M
color InpFiboLevelColor2_30M = clrDimGray; //Fibo Level Color 2 for 30M
ENUM_LINE_STYLE InpFiboLevelStyle2_30M = STYLE_DOT;
int InpFiboLevelWidth2_30M = 1;
input double InpFiboLevelValue3_30M = 70.0; //Buy % level for 30M
color InpFiboLevelColor3_30M = clrDimGray; //Fibo Level Color 3 for 30M
ENUM_LINE_STYLE InpFiboLevelStyle3_30M = STYLE_DOT;
int InpFiboLevelWidth3_30M = 1;
double InpFiboLevelValue4_30M = 100.0; //Fibo Level Value 4 for 30M
color InpFiboLevelColor4_30M = clrDimGray; //Fibo Level Color 4 for 30M
ENUM_LINE_STYLE InpFiboLevelStyle4_30M = STYLE_DOT;
int InpFiboLevelWidth4_30M = 1;

// For 1 hour time frame
input int N_1h = 200; // Bars for 1h MH and ML
input bool Enable_1h = true; // Enable or disable 1h timeframe
double InpFiboLevelValue1_1H = 0.0; //Fibo Level Value 1 for 1H
color InpFiboLevelColor1_1H = clrDimGray; //Fibo Level Color 1 for 1H
ENUM_LINE_STYLE InpFiboLevelStyle1_1H = STYLE_DOT;
int InpFiboLevelWidth1_1H = 1;
input double InpFiboLevelValue2_1H = 70.0; //Sell % level for 1H
color InpFiboLevelColor2_1H = clrDimGray; //Fibo Level Color 2 for 1H
ENUM_LINE_STYLE InpFiboLevelStyle2_1H = STYLE_DOT;
int InpFiboLevelWidth2_1H = 1;
input double InpFiboLevelValue3_1H = 70.0; //Buy % level for 1H
color InpFiboLevelColor3_1H = clrDimGray; //Fibo Level Color 3 for 1H
ENUM_LINE_STYLE InpFiboLevelStyle3_1H = STYLE_DOT;
int InpFiboLevelWidth3_1H = 1;
double InpFiboLevelValue4_1H = 100.0; //Fibo Level Value 4 for 1H
color InpFiboLevelColor4_1H = clrDimGray; //Fibo Level Color 4 for 1H
ENUM_LINE_STYLE InpFiboLevelStyle4_1H = STYLE_DOT;
int InpFiboLevelWidth4_1H = 1;

// For 4 hour time frame
input int N_4h = 500; // Bars for 4h MH and ML
input bool Enable_4h = true; // Enable or disable 4h timeframe
double InpFiboLevelValue1_4H = 0.0; //Fibo Level Value 1 for 4H
color InpFiboLevelColor1_4H = clrDimGray; //Fibo Level Color 1 for 4H
ENUM_LINE_STYLE InpFiboLevelStyle1_4H = STYLE_DOT;
int InpFiboLevelWidth1_4H = 1;
input double InpFiboLevelValue2_4H = 70.0; //Sell % level for 4H
color InpFiboLevelColor2_4H = clrDimGray; //Fibo Level Color 2 for 4H
ENUM_LINE_STYLE InpFiboLevelStyle2_4H = STYLE_DOT;
int InpFiboLevelWidth2_4H = 1;
input double InpFiboLevelValue3_4H = 70.0; //Buy % level for 4H
color InpFiboLevelColor3_4H = clrDimGray; //Fibo Level Color 3 for 4H
ENUM_LINE_STYLE InpFiboLevelStyle3_4H = STYLE_DOT;
int InpFiboLevelWidth3_4H = 1;
double InpFiboLevelValue4_4H = 100.0; //Fibo Level Value 4 for 4H
color InpFiboLevelColor4_4H = clrDimGray; //Fibo Level Color 4 for 4H
ENUM_LINE_STYLE InpFiboLevelStyle4_4H = STYLE_DOT;
int InpFiboLevelWidth4_4H = 1;

// For Daily time frame
input int N_Daily = 700; // Bars for Daily MH and ML
input bool Enable_Daily = true; // Enable or disable Daily timeframe
double InpFiboLevelValue1_D = 0.0; //Fibo Level Value 1 for D
color InpFiboLevelColor1_D = clrDimGray; //Fibo Level Color 1 for D
ENUM_LINE_STYLE InpFiboLevelStyle1_D = STYLE_DOT;
int InpFiboLevelWidth1_D = 1;
input double InpFiboLevelValue2_D = 70.0; //Sell % level for D
color InpFiboLevelColor2_D = clrDimGray; //Fibo Level Color 2 for D
ENUM_LINE_STYLE InpFiboLevelStyle2_D = STYLE_DOT;
int InpFiboLevelWidth2_D = 1;
input double InpFiboLevelValue3_D = 70.0; //Buy % level for D
color InpFiboLevelColor3_D = clrDimGray; //Fibo Level Color 3 for D
ENUM_LINE_STYLE InpFiboLevelStyle3_D = STYLE_DOT;
int InpFiboLevelWidth3_D = 1;
double InpFiboLevelValue4_D = 100.0; //Fibo Level Value 4 for D
color InpFiboLevelColor4_D = clrDimGray; //Fibo Level Color 4 for D
ENUM_LINE_STYLE InpFiboLevelStyle4_D = STYLE_DOT;
int InpFiboLevelWidth4_D = 1;

// For Weekly time frame
input int N_Weekly = 800; // Bars for Weekly MH and ML
input bool Enable_Weekly = true; // Enable or disable Weekly timeframe
double InpFiboLevelValue1_W = 0.0; //Fibo Level Value 1 for W
color InpFiboLevelColor1_W = clrDimGray; //Fibo Level Color 1 for W
ENUM_LINE_STYLE InpFiboLevelStyle1_W = STYLE_DOT;
int InpFiboLevelWidth1_W = 1;
input double InpFiboLevelValue2_W = 70.0; //Sell % level for W
color InpFiboLevelColor2_W = clrDimGray; //Fibo Level Color 2 for W
ENUM_LINE_STYLE InpFiboLevelStyle2_W = STYLE_DOT;
int InpFiboLevelWidth2_W = 1;
input double InpFiboLevelValue3_W = 70.0; //Buy % level for W
color InpFiboLevelColor3_W = clrDimGray; //Fibo Level Color 3 for W
ENUM_LINE_STYLE InpFiboLevelStyle3_W = STYLE_DOT;
int InpFiboLevelWidth3_W = 1;
double InpFiboLevelValue4_W = 100.0; //Fibo Level Value 4 for W
color InpFiboLevelColor4_W = clrDimGray; //Fibo Level Color 4 for W
ENUM_LINE_STYLE InpFiboLevelStyle4_W = STYLE_DOT;
int InpFiboLevelWidth4_W = 1;

// For Monthly time frame
input int N_Monthly = 800; // Bars for Monthly MH and ML
input bool Enable_Monthly = true; // Enable or disable Monthly timeframe
double InpFiboLevelValue1_MN = 0.0; //Fibo Level Value 1 for MN
color InpFiboLevelColor1_MN = clrDimGray; //Fibo Level Color 1 for MN
ENUM_LINE_STYLE InpFiboLevelStyle1_MN = STYLE_DOT;
int InpFiboLevelWidth1_MN = 1;
input double InpFiboLevelValue2_MN = 70.0; //Sell % level for MN
color InpFiboLevelColor2_MN = clrDimGray; //Fibo Level Color 2 for MN
ENUM_LINE_STYLE InpFiboLevelStyle2_MN = STYLE_DOT;
int InpFiboLevelWidth2_MN = 1;
input double InpFiboLevelValue3_MN = 70.0; //Buy % level for MN
color InpFiboLevelColor3_MN = clrDimGray; //Fibo Level Color 3 for MN
ENUM_LINE_STYLE InpFiboLevelStyle3_MN = STYLE_DOT;
int InpFiboLevelWidth3_MN = 1;
double InpFiboLevelValue4_MN = 100.0; //Fibo Level Value 4 for MN
color InpFiboLevelColor4_MN = clrDimGray; //Fibo Level Color 4 for MN
ENUM_LINE_STYLE InpFiboLevelStyle4_MN = STYLE_DOT;
int InpFiboLevelWidth4_MN = 1;

//input string s9_="FIBO LEVELS"; //.
color InpFiboColor = clrDimGray; //Fibo Color
ENUM_LINE_STYLE InpFiboStyle = STYLE_SOLID; // Line style
int InpFiboWidth = 1;              // Line width
bool InpFiboBack = false;           // Background object
bool InpFiboSelection = false;       // Highlight to move
bool InpFiboRayRight = false;       // Object's continuation to the right
bool InpFiboHidden = true;          // Hidden in the object list
long InpFiboZOrder = 0;             // Priority for mouse click
color InpFiboLevelsColor = clrDimGray; //Fibo Levels Color

string InternalSectionHeader = "_____ For internal use by EAs only. Do not modify"; //|
// User-defined program ID to distinguish objects created by different instances of this indicator.
int userProgramID = 0; //Custom Program ID


// Global Variables
InputParameters inputParams;
PositionSizeCalculator positionCalculator;
HorizontalLine breakevenLineStruct;
HorizontalLine buyReverseOrderLineStruct;
HorizontalLine sellReverseOrderLineStruct;
const string breakevenLineName = IntegerToString(IN_MagicNumber) + "_breakeven_line";
const string buyReverseOrderLineName = IntegerToString(IN_MagicNumber) + "_buy_reverse_order_line";
const string sellReverseOrderLineName = IntegerToString(IN_MagicNumber) + "_sell_reverse_order_line";
string customFileName = "";

// Global variable to track whether trading is active or paused
bool TradingActive = true; // Assume trading is active at the start

double UsableBalanceAmount = 0.0;  // Calculated usable balance amount

// Global Take Profit Management
double GlobalBuyTakeProfit = 0.0;     // Unified TP for all buy orders
double GlobalSellTakeProfit = 0.0;    // Unified TP for all sell orders
datetime LastTPCalculationTime = 0;   // Track when TP was last calculated

// Declare an array to hold the TimeframeStatus data
TimeframeStatus TimeframesMHMLMarker[9];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void AssignInputParametersToStruct(InputParameters &params)
{
// Assigning GENERAL OPTIONS
    params.IN_MagicNumber = IN_MagicNumber;
    params.IN_OrdersToTrade = IN_OrdersToTrade;
    params.IN_TradingMode = IN_TradingMode;
    params.IN_ReverseOrders = IN_ReverseOrders;
    params.IN_BreakevenAtGreyArrows = IN_BreakevenAtGreyArrows;

// Assigning BUY LOT SIZE OPTIONS
    params.Buy_IN_LotSizingOptions = Buy_IN_LotSizingOptions;
    params.Buy_IN_InitialLots = Buy_IN_InitialLots;
    params.Buy_IN_PercentFreeMargin = Buy_IN_PercentFreeMargin;
    params.Buy_IN_PercentEquity = Buy_IN_PercentEquity;

// Assigning SELL LOT SIZE OPTIONS
    params.Sell_IN_LotSizingOptions = Sell_IN_LotSizingOptions;
    params.Sell_IN_InitialLots = Sell_IN_InitialLots;
    params.Sell_IN_PercentFreeMargin = Sell_IN_PercentFreeMargin;
    params.Sell_IN_PercentEquity = Sell_IN_PercentEquity;

// Assigning BUY RATIO BALANCE OPTIONS
    params.AC_Ratio_Limit = AC_Ratio_Limit;
    params.AC_Ratio_Actual = AC_Ratio_Actual;

// Assigning BE FILTER OPTIONS
    params.IN_EnableBeFilter = IN_EnableBeFilter;
    params.IN_BeBuyFilterCounter = IN_BeBuyFilterCounter;
    params.IN_BeSellFilterCounter = IN_BeSellFilterCounter;
    params.IN_EnableBeReentry = IN_EnableBeReentry;

// Assigning BE PIVOT FILTER OPTIONS
    params.IN_EnableBuyBePivotFilter = IN_EnableBuyBePivotFilter;
    params.IN_BuyBePivotFilterTimeframe = IN_BuyBePivotFilterTimeframe;
    params.IN_BuyBePivotFilterPercentage = IN_BuyBePivotFilterPercentage;
    params.IN_EnableSellBePivotFilter = IN_EnableSellBePivotFilter;
    params.IN_SellBePivotFilterTimeframe = IN_SellBePivotFilterTimeframe;
    params.IN_SellBePivotFilterPercentage = IN_SellBePivotFilterPercentage;

// Assigning REVERSE ENTRY
    params.IN_BuyReverseEntryDeviation = IN_BuyReverseEntryDeviation;
    params.IN_SellReverseEntryDeviation = IN_SellReverseEntryDeviation;
    params.IN_EnableReverseReentry = IN_EnableReverseReentry;

// Assigning REVERSE FILTER
    params.IN_ReverseBuyFilterCounter = IN_ReverseBuyFilterCounter;
    params.IN_ReverseSellFilterCounter = IN_ReverseSellFilterCounter;

// Assigning REVERSE BUY LOTS
    params.Reverse_Buy_IN_LotSizingOptions = Reverse_Buy_IN_LotSizingOptions;
    params.Reverse_Buy_IN_InitialLots = Reverse_Buy_IN_InitialLots;
    params.Reverse_Buy_IN_PercentFreeMargin = Reverse_Buy_IN_PercentFreeMargin;
    params.Reverse_Buy_IN_PercentEquity = Reverse_Buy_IN_PercentEquity;

// Assigning REVERSE SELL LOTS
    params.Reverse_Sell_IN_LotSizingOptions = Reverse_Sell_IN_LotSizingOptions;
    params.Reverse_Sell_IN_InitialLots = Reverse_Sell_IN_InitialLots;
    params.Reverse_Sell_IN_PercentFreeMargin = Reverse_Sell_IN_PercentFreeMargin;
    params.Reverse_Sell_IN_PercentEquity = Reverse_Sell_IN_PercentEquity;

// Assigning REVERSE SL
    params.IN_ReverseBuyStopLoss = IN_ReverseBuyStopLoss;
    params.IN_ReverseSellStopLoss = IN_ReverseSellStopLoss;

// Assigning REVERSE TP
    params.IN_ReverseBuyTakeProfit = IN_ReverseBuyTakeProfit;
    params.IN_ReverseSellTakeProfit = IN_ReverseSellTakeProfit;

// Assigning MULTIPLIER OPTIONS
    params.IN_BuyOrderMultiplier = IN_BuyOrderMultiplier;
    params.IN_SellOrderMultiplier = IN_SellOrderMultiplier;

// Assigning PENDING STOP ORDER OPTIONS
    params.IN_PendingBuyDeviationFromBE = IN_PendingBuyDeviationFromBE;
    params.IN_PendingSellDeviationFromBE = IN_PendingSellDeviationFromBE;

// Assigning TRAIL STOP OPTIONS
    params.IN_EnableTrailStop = IN_EnableTrailStop;
    params.IN_TrailStopType = IN_TrailStopType;
    params.IN_TrailStopInPips = IN_TrailStopInPips;
    params.IN_TrailStepInPips = IN_TrailStepInPips;
    params.IN_TrailStopATRMultiplier = IN_TrailStopATRMultiplier;

// Assigning SPREAD OPTIONS
    params.IN_EnableSpreadControl = IN_EnableSpreadControl;
    params.IN_MaximumSpread = IN_MaximumSpread;

// Assigning TAKE PROFIT OPTIONS
    params.IN_EnableManualTakeProfit = IN_EnableManualTakeProfit;
    params.IN_TakeProfitInPips = IN_TakeProfitInPips;
    params.IN_EnableMHMLTakeProfit = IN_EnableMHMLTakeProfit;
    params.IN_MHMLMarkerTakeProfitTimeframe = IN_MHMLMarkerTakeProfitTimeframe;
    params.IN_MHMLMarkerTakeProfitPerc = IN_MHMLMarkerTakeProfitPerc;

// Assigning STOP LOSS OPTIONS
    params.IN_EnableStopLoss = IN_EnableStopLoss;
    params.IN_StopLossType = IN_StopLossType;
    params.IN_StopLossInPips = IN_StopLossInPips;
    params.IN_StopLossATRMultiplier = IN_StopLossATRMultiplier;

// Assigning TRADING DAY OPTIONS
    params.IN_IsTradingAllowedForSunday = IN_IsTradingAllowedForSunday;
    params.IN_IsTradingAllowedForMonday = IN_IsTradingAllowedForMonday;
    params.IN_IsTradingAllowedForTuesday = IN_IsTradingAllowedForTuesday;
    params.IN_IsTradingAllowedForWednesday = IN_IsTradingAllowedForWednesday;
    params.IN_IsTradingAllowedForThursday = IN_IsTradingAllowedForThursday;
    params.IN_IsTradingAllowedForFriday = IN_IsTradingAllowedForFriday;
    params.IN_IsTradingAllowedForSaturday = IN_IsTradingAllowedForSaturday;

// Assigning TIME OPTIONS
    params.IN_EnableTimeManagement = IN_EnableTimeManagement;
    params.IN_TradingStartHour = IN_TradingStartHour;
    params.IN_TradingStartMinutes = IN_TradingStartMinutes;
    params.IN_TradingEndHour = IN_TradingEndHour;
    params.IN_TradingEndMinutes = IN_TradingEndMinutes;

// Assigning NEWS FILTER OPTIONS
    params.UseNewsFilter = UseNewsFilter;
    params.HighPauseBefore = HighPauseBefore;
    params.HighPauseAfter = HighPauseAfter;

// Assigning LINES SETTINGS
    params.IN_BreakevenLineColor = IN_BreakevenLineColor;
    params.IN_BuyReverseOrderLineColor = IN_BuyReverseOrderLineColor;
    params.IN_SellReverseOrderLineColor = IN_SellReverseOrderLineColor;
    params.IN_BuyTrailStopLineColor = IN_BuyTrailStopLineColor;
    params.IN_SellTrailStopLineColor = IN_SellTrailStopLineColor;

// Assigning ALERTS
    params.enableAlerts = enableAlerts;

// Assigning INDICATORS SETTINGS

// Assigning ADX Settings
    params.EnableADXForArrowConfirmation = EnableADXForArrowConfirmation;
    params.TimeframeADX = TimeframeADX;
    params.ADXPeriod = ADXPeriod;
    params.ADXLevel = ADXLevel;
    params.Buy_ADX_Price = Buy_ADX_Price;
    params.Sell_ADX_Price = Sell_ADX_Price;

// Assigning Volume Choppiness Filter Settings
    params.EnableChoppiness = EnableChoppiness;
    params.TimeframeVolume = TimeframeVolume;
    params.VolumeAnalysisCandleCount = VolumeAnalysisCandleCount;
    params.MeanHighVolumeAdjustment = MeanHighVolumeAdjustment;
    params.MeanHighAdjustmentPercent = MeanHighAdjustmentPercent;
    params.MeanLowVolumeAdjustment = MeanLowVolumeAdjustment;
    params.MeanLowAdjustmentPercent = MeanLowAdjustmentPercent;
    params.LowVolumeLevelColor = LowVolumeLevelColor;
    params.HighVolumeLevelColor = HighVolumeLevelColor;

// Assigning Buy and Sell Section Settings
    params.Buy_MinVolume = Buy_MinVolume;
    params.Buy_MaxVolume = Buy_MaxVolume;
    params.Buy_ChoppinessIndexThreshold = Buy_ChoppinessIndexThreshold;

    params.Sell_MinVolume = Sell_MinVolume;
    params.Sell_MaxVolume = Sell_MaxVolume;
    params.Sell_ChoppinessIndexThreshold = Sell_ChoppinessIndexThreshold;

// Assigning Choppiness Settings
    params.ChoppinessPeriod = ChoppinessPeriod;

// Assigning MH ML Marker MultiTimeframe Settings for each timeframe

// 1m MH ML Marker Settings
    params.N_1m = N_1m;
    params.Enable_1m = Enable_1m;
    params.InpFiboLevelValue2_1M = InpFiboLevelValue2_1M;
    params.InpFiboLevelValue3_1M = InpFiboLevelValue3_1M;

// 5m MH ML Marker Settings
    params.N_5m = N_5m;
    params.Enable_5m = Enable_5m;
    params.InpFiboLevelValue2_5M = InpFiboLevelValue2_5M;
    params.InpFiboLevelValue3_5M = InpFiboLevelValue3_5M;

// 15m MH ML Marker Settings
    params.N_15m = N_15m;
    params.Enable_15m = Enable_15m;
    params.InpFiboLevelValue2_15M = InpFiboLevelValue2_15M;
    params.InpFiboLevelValue3_15M = InpFiboLevelValue3_15M;

// 30m MH ML Marker Settings
    params.N_30m = N_30m;
    params.Enable_30m = Enable_30m;
    params.InpFiboLevelValue2_30M = InpFiboLevelValue2_30M;
    params.InpFiboLevelValue3_30M = InpFiboLevelValue3_30M;

// 1h MH ML Marker Settings
    params.N_1h = N_1h;
    params.Enable_1h = Enable_1h;
    params.InpFiboLevelValue2_1H = InpFiboLevelValue2_1H;
    params.InpFiboLevelValue3_1H = InpFiboLevelValue3_1H;

// 4h MH ML Marker Settings
    params.N_4h = N_4h;
    params.Enable_4h = Enable_4h;
    params.InpFiboLevelValue2_4H = InpFiboLevelValue2_4H;
    params.InpFiboLevelValue3_4H = InpFiboLevelValue3_4H;

// Daily MH ML Marker Settings
    params.N_Daily = N_Daily;
    params.Enable_Daily = Enable_Daily;
    params.InpFiboLevelValue2_D = InpFiboLevelValue2_D;
    params.InpFiboLevelValue3_D = InpFiboLevelValue3_D;

// Weekly MH ML Marker Settings
    params.N_Weekly = N_Weekly;
    params.Enable_Weekly = Enable_Weekly;
    params.InpFiboLevelValue2_W = InpFiboLevelValue2_W;
    params.InpFiboLevelValue3_W = InpFiboLevelValue3_W;

// Monthly MH ML Marker Settings
    params.N_Monthly = N_Monthly;
    params.Enable_Monthly = Enable_Monthly;
    params.InpFiboLevelValue2_MN = InpFiboLevelValue2_MN;
    params.InpFiboLevelValue3_MN = InpFiboLevelValue3_MN;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void FillTimeframeStatusArray(TimeframeStatus &timeframes[])
{
// Resize the array to hold 9 timeframes
    ArrayResize(timeframes, 9);

// Fill the array with the respective timeframes and their enabled statuses
    timeframes[0] = TimeframeStatus(PERIOD_M1, Enable_1m);
    timeframes[1] = TimeframeStatus(PERIOD_M5, Enable_5m);
    timeframes[2] = TimeframeStatus(PERIOD_M15, Enable_15m);
    timeframes[3] = TimeframeStatus(PERIOD_M30, Enable_30m);
    timeframes[4] = TimeframeStatus(PERIOD_H1, Enable_1h);
    timeframes[5] = TimeframeStatus(PERIOD_H4, Enable_4h);
    timeframes[6] = TimeframeStatus(PERIOD_D1, Enable_Daily);
    timeframes[7] = TimeframeStatus(PERIOD_W1, Enable_Weekly);
    timeframes[8] = TimeframeStatus(PERIOD_MN1, Enable_Monthly);
}
//+------------------------------------------------------------------+
