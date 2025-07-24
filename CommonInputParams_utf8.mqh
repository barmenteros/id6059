//+------------------------------------------------------------------+
//|                                            CommonInputParams.mqh |
//|                                 Copyright © 2023, barmenteros FX |
//|                                          https://barmenteros.com |
//+------------------------------------------------------------------+
#ifndef __COMMON_INPUT_PARAMS__
#define __COMMON_INPUT_PARAMS__

#define LOOKBACK_BARS 500

// Enums
enum OrdersToTrade {
    kMarketOrders, //Market
    kPendingOrders //Pending
};
enum LotSizingOptions {
    kManualLots,           // Manual
    kPercentFreeMargin,    // Percent Free Margin
    kPercentEquity,        // Percent Equity
//    kATRLots               // ATR
};
// -------------------------------------------------------------------
// Customer Requirements Update:
// Date: Oct 19, 2023, 5:13 PM
//
// 1. The customer has requested the removal of the 'Closed Candle'
//    option for Take Profit. This feature will not be used and
//    should be removed from the codebase.
// 2. The customer has also requested the removal of the 'Breakeven'
//    option for Stop Loss. This feature will not be used and should
//    be removed from the codebase.
// -------------------------------------------------------------------
enum StopLossType {
    kManualSL, //Manual
// kBreakevenSL //Breakeven [REMOVED as per customer's request]
    kATRSL //ATR
};
enum TrailStopType {
    kManualTrailStop,   // Manual trailing stop
    kATRTrailStop,      // ATR-based trailing stop
    kLevelTrailStop     // MHML-based trailing stop
};
enum CommentCheckType {
    kMustIncludeString,
    kMustExcludeString
};
// Swing Continuous Mode: Enables the EA to open trades on each candle,
// where all orders share the TP point of the original candle. This results in
// all orders hitting TP simultaneously. The mode is toggled via the "Trading
// Mode" input parameter and is independent of the "Take Profit Type" setting.
enum TradingMode {
    kSingleMode,          // Single Mode
    kSwingContinuousMode  // Swing Continuous Mode
};
enum VolumeAdjustmentDirection {
    VOLUME_INCREASE = 1,
    VOLUME_DECREASE = 2
};

// Structures
struct ConditionStatus {
    bool             allowTrade;
    string           message;
};
struct StopLossInfo {
    double           order_stoploss;
    double           order_stoploss_hidden;
};
//+------------------------------------------------------------------+
//| Structure to store timeframe and enabled status                  |
//+------------------------------------------------------------------+
struct TimeframeStatus {
    ENUM_TIMEFRAMES  timeframe; // Timeframe (ENUM_TIMEFRAMES type)
    bool             isEnabled; // Status indicating if the timeframe is enabled or not

    // Constructor for easy initialization
    TimeframeStatus(const ENUM_TIMEFRAMES tf = 0, const bool enabled = false)
    {
        timeframe = tf;
        isEnabled = enabled;
    }
};

struct InputParameters {
    // ===== GENERAL OPTIONS
    int              IN_MagicNumber;                           // Magic Number ID
    OrdersToTrade    IN_OrdersToTrade;               // Orders To Trade
    TradingMode      IN_TradingMode;                   // Trading Mode
    bool             IN_ReverseOrders;                        // Reverse Orders
    bool             IN_BreakevenAtGreyArrows;                // Breakeven At Grey Arrows

    // ===== BUY LOT SIZE OPTIONS
    LotSizingOptions Buy_IN_LotSizingOptions;     // Buy Lot Sizing Options
    double           Buy_IN_InitialLots;                    // Buy Lots
    double           Buy_IN_PercentFreeMargin;              // Buy Percent Free Margin
    double           Buy_IN_PercentEquity;                  // Buy Percent Equity

    // ===== SELL LOT SIZE OPTIONS
    LotSizingOptions Sell_IN_LotSizingOptions;    // Sell Lot Sizing Options
    double           Sell_IN_InitialLots;                   // Sell Lots
    double           Sell_IN_PercentFreeMargin;             // Sell Percent Free Margin
    double           Sell_IN_PercentEquity;                 // Sell Percent Equity

    // ===== ACCOUNT BALANCE RATIO OPTIONS
    int              AC_Ratio_Limit;      // Account Ratio Limit
    int              AC_Ratio_Actual;     // Account Ratio Actual

    // ===== BE FILTER OPTIONS
    bool             IN_EnableBeFilter;                       // Enable Be Filter
    int              IN_BeBuyFilterCounter;                    // BE Buy Filter
    int              IN_BeSellFilterCounter;                   // BE Sell Filter
    bool             IN_EnableBeReentry;                      // Enable Reentry

    // ===== BE PIVOT FILTER OPTIONS
    bool             IN_EnableBuyBePivotFilter;             //Enable Buy BE Pivot Filter
    ENUM_TIMEFRAMES  IN_BuyBePivotFilterTimeframe;          // Buy BE Pivot Filter Timeframe (from MH_ML_Marker)
    double           IN_BuyBePivotFilterPercentage;         // Buy BE Pivot Filter % (from MH_ML_Marker)
    bool             IN_EnableSellBePivotFilter;            //Enable Sell BE Pivot Filter
    ENUM_TIMEFRAMES  IN_SellBePivotFilterTimeframe;         // Sell BE Pivot Filter Timeframe (from MH_ML_Marker)
    double           IN_SellBePivotFilterPercentage;        // Sell BE Pivot Filter % (from MH_ML_Marker)

    // ===== REVERSE ENTRY
    int              IN_BuyReverseEntryDeviation;              // Buy Reverse Entry Deviation
    int              IN_SellReverseEntryDeviation;             // Sell Reverse Entry Deviation
    bool             IN_EnableReverseReentry;                 // Enable Reverse Reentry

    // ===== REVERSE FILTER
    int              IN_ReverseBuyFilterCounter;                // Reverse Buy Filter
    int              IN_ReverseSellFilterCounter;               // Reverse Sell Filter

    // ===== REVERSE BUY LOTS
    LotSizingOptions Reverse_Buy_IN_LotSizingOptions; // Reverse Buy Lot Sizing Options
    double           Reverse_Buy_IN_InitialLots;             // Reverse Buy Lots
    double           Reverse_Buy_IN_PercentFreeMargin;       // Reverse Buy % Free Margin
    double           Reverse_Buy_IN_PercentEquity;           // Reverse Buy % Equity

    // ===== REVERSE SELL LOTS
    LotSizingOptions Reverse_Sell_IN_LotSizingOptions; // Reverse Sell Lot Sizing Options
    double           Reverse_Sell_IN_InitialLots;           // Reverse Sell Lots
    double           Reverse_Sell_IN_PercentFreeMargin;     // Reverse Sell % Free Margin
    double           Reverse_Sell_IN_PercentEquity;         // Reverse Sell % Equity

    // ===== REVERSE SL
    int              IN_ReverseBuyStopLoss;                     // Reverse SL Buy
    int              IN_ReverseSellStopLoss;                    // Reverse SL Sell

    // ===== REVERSE TP
    int              IN_ReverseBuyTakeProfit;                   // Reverse TP Buy
    int              IN_ReverseSellTakeProfit;                  // Reverse TP Sell

    // ===== MULTIPLIER OPTIONS
    int              IN_BuyOrderMultiplier;                     // Buy Order Multiplier: 0 - X
    int              IN_SellOrderMultiplier;                    // Sell Order Multiplier: 0 - X

    // ===== PENDING STOP ORDER OPTIONS
    int              IN_PendingBuyDeviationFromBE;              // Pending Buy Deviation From BE
    int              IN_PendingSellDeviationFromBE;             // Pending Sell Deviation From BE

    // ===== TRAIL STOP OPTIONS
    bool             IN_EnableTrailStop;                   // Enable Trail Stop
    TrailStopType    IN_TrailStopType;            // Trail Stop Type
    double           IN_TrailStopInPips;                 // Trail Stop In Pips
    double           IN_TrailStepInPips;                 // Trail Step In Pips
    double           IN_TrailStopATRMultiplier;          // Trail Stop ATR Multiplier

    // ===== SPREAD OPTIONS
    bool             IN_EnableSpreadControl;               // Enable Spread Control
    int              IN_MaximumSpread;                      // Maximum Spread

    // ===== TAKE PROFIT OPTIONS
    bool             IN_EnableManualTakeProfit;            // Enable Manual Take Profit
    int              IN_TakeProfitInPips;                   // Take Profit In Pips
    bool             IN_EnableMHMLTakeProfit;              // Enable MH-ML Percentage Take Profit
    bool             IN_EnableMACrossTakeProfit;           // Enable MA Cross Take Profit
    bool             IN_EnableMACDTakeProfit;              // Enable MACD Take Profit
    bool             IN_EnablePSARTakeProfit;              // Enable PSAR Take Profit
    ENUM_TIMEFRAMES  IN_MHMLMarkerTakeProfitTimeframe;    // MH_ML_Marker level Timeframe
    double           IN_MHMLMarkerTakeProfitPerc;        // Percentage from level to calculate TakeProfit

    // ===== STOP LOSS OPTIONS
    bool             IN_EnableStopLoss;                    // Enable Stop Loss
    StopLossType     IN_StopLossType;              // Stop Loss Type
    int              IN_StopLossInPips;                     // Stop Loss In Pips
    int              IN_StopLossATRMultiplier;              // Stop Loss ATR Multiplier

    // ===== TRADING DAY OPTIONS
    bool             IN_IsTradingAllowedForSunday;         // Enable Trading On Sunday
    bool             IN_IsTradingAllowedForMonday;         // Enable Trading On Monday
    bool             IN_IsTradingAllowedForTuesday;        // Enable Trading On Tuesday
    bool             IN_IsTradingAllowedForWednesday;      // Enable Trading On Wednesday
    bool             IN_IsTradingAllowedForThursday;       // Enable Trading On Thursday
    bool             IN_IsTradingAllowedForFriday;         // Enable Trading On Friday
    bool             IN_IsTradingAllowedForSaturday;       // Enable Trading On Saturday

    // ===== TIME OPTIONS
    bool             IN_EnableTimeManagement;              // Enable Time Management
    int              IN_TradingStartHour;                   // Start Hours: 0 - 23
    int              IN_TradingStartMinutes;                // Start Minutes: 0 - 59
    int              IN_TradingEndHour;                     // End Hours: 0 - 23
    int              IN_TradingEndMinutes;                  // End Minutes: 0 - 59

    // ===== NEWS FILTER OPTIONS
    bool             UseNewsFilter;                        // Enable News Filter
    int              HighPauseBefore;                       // Pause Minutes Before News
    int              HighPauseAfter;                        // Resume Minutes After News

    // ===== LINES SETTINGS
    color            IN_BreakevenLineColor;               // Breakeven Line Color
    color            IN_BuyReverseOrderLineColor;         // Buy Reverse Order Line Color
    color            IN_SellReverseOrderLineColor;        // Sell Reverse Order Line Color
    color            IN_BuyTrailStopLineColor;            // Buy Trail Stop Line Color
    color            IN_SellTrailStopLineColor;           // Sell Trail Stop Line Color

    // ===== ALERTS
    bool             enableAlerts;                         // Enable Alert On Open Order

    // ===== INDICATORS SETTINGS
    // ADX Settings
    bool             EnableADXForArrowConfirmation;      // Enable ADX for Arrow Confirmation
    ENUM_TIMEFRAMES  TimeframeADX;            // ADX Timeframe
    int              ADXPeriod;                           // ADX Period
    int              ADXLevel;                            // ADX Level
    ENUM_APPLIED_PRICE Buy_ADX_Price;        // Buy ADX Applied Price
    ENUM_APPLIED_PRICE Sell_ADX_Price;       // Sell ADX Applied Price

    // Volume Choppiness Filter Settings
    bool             EnableChoppiness;                      // Enable Choppiness
    ENUM_TIMEFRAMES  TimeframeVolume;            // Volume Timeframe
    int              VolumeAnalysisCandleCount;              // Number of bars for volume analysis
    VolumeAdjustmentDirection MeanHighVolumeAdjustment;  // Mean High Adjustment Direction
    double           MeanHighAdjustmentPercent;           // Mean High Adjustment %
    VolumeAdjustmentDirection MeanLowVolumeAdjustment;   // Mean Low Adjustment Direction
    double           MeanLowAdjustmentPercent;            // Mean Low Adjustment %
    color            LowVolumeLevelColor;                  // Low Volume Level Color
    color            HighVolumeLevelColor;                 // High Volume Level Color

    // Buy Section Settings
    int              Buy_MinVolume;                          // Low Volume Level for Buy
    int              Buy_MaxVolume;                          // High Volume Level for Buy
    double           Buy_ChoppinessIndexThreshold;        // Choppiness Index Threshold for Buy

    // Sell Section Settings
    int              Sell_MinVolume;                         // Low Volume Level for Sell
    int              Sell_MaxVolume;                         // High Volume Level for Sell
    double           Sell_ChoppinessIndexThreshold;       // Choppiness Index Threshold for Sell

    // Choppiness Settings
    int              ChoppinessPeriod;                       // Number of bars to evaluation CI

    // MH ML Marker MultiTimeframe Settings
    // 1m MH ML Marker Settings
    int              N_1m;                                   // Bars for 1m MH and ML
    bool             Enable_1m;                             // Enable or disable 1m timeframe
    double           InpFiboLevelValue2_1M;               // Sell % level for 1M
    double           InpFiboLevelValue3_1M;               // Buy % level for 1M

    // 5m MH ML Marker Settings
    int              N_5m;                                   // Bars for 5m MH and ML
    bool             Enable_5m;                             // Enable or disable 5m timeframe
    double           InpFiboLevelValue2_5M;               // Sell % level for 5M
    double           InpFiboLevelValue3_5M;               // Buy % level for 5M

    // 15m MH ML Marker Settings
    int              N_15m;                                  // Bars for 15m MH and ML
    bool             Enable_15m;                            // Enable or disable 15m timeframe
    double           InpFiboLevelValue2_15M;              // Sell % level for 15M
    double           InpFiboLevelValue3_15M;              // Buy % level for 15M

    // 30m MH ML Marker Settings
    int              N_30m;                                  // Bars for 30m MH and ML
    bool             Enable_30m;                            // Enable or disable 30m timeframe
    double           InpFiboLevelValue2_30M;              // Sell % level for 30M
    double           InpFiboLevelValue3_30M;              // Buy % level for 30M

    // 1h MH ML Marker Settings
    int              N_1h;                                   // Bars for 1h MH and ML
    bool             Enable_1h;                             // Enable or disable 1h timeframe
    double           InpFiboLevelValue2_1H;               // Sell % level for 1H
    double           InpFiboLevelValue3_1H;               // Buy % level for 1H

    // 4h MH ML Marker Settings
    int              N_4h;                                   // Bars for 4h MH and ML
    bool             Enable_4h;                             // Enable or disable 4h timeframe
    double           InpFiboLevelValue2_4H;               // Sell % level for 4H
    double           InpFiboLevelValue3_4H;               // Buy % level for 4H

    // Daily MH ML Marker Settings
    int              N_Daily;                                // Bars for Daily MH and ML
    bool             Enable_Daily;                          // Enable or disable Daily timeframe
    double           InpFiboLevelValue2_D;                // Sell % level for Daily
    double           InpFiboLevelValue3_D;                // Buy % level for Daily

    // Weekly MH ML Marker Settings
    int              N_Weekly;                               // Bars for Weekly MH and ML
    bool             Enable_Weekly;                         // Enable or disable Weekly timeframe
    double           InpFiboLevelValue2_W;                // Sell % level for Weekly
    double           InpFiboLevelValue3_W;                // Buy % level for Weekly

    // Monthly MH ML Marker Settings
    int              N_Monthly;                              // Bars for Monthly MH and ML
    bool             Enable_Monthly;                        // Enable or disable Monthly timeframe
    double           InpFiboLevelValue2_MN;               // Sell % level for Monthly
    double           InpFiboLevelValue3_MN;               // Buy % level for Monthly
};

#endif // __COMMON_INPUT_PARAMS__
//+------------------------------------------------------------------+
