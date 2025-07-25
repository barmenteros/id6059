﻿//+------------------------------------------------------------------+
//|                                       InputParametersHandler.mqh |
//|                                 Copyright © 2023, barmenteros FX |
//|                                          https://barmenteros.com |
//+------------------------------------------------------------------+
#include <Custom\Development\Logging.mqh>

/**
 * Safely appends a string to another string, ensuring the total length does not exceed a predefined limit.
 *
 * This function is designed to prevent issues related to exceeding the maximum string length limit in MQL4/MQL5.
 * String concatenation in trading scripts can often result in very long strings, especially when building
 * dynamic messages or logs. Since there's a practical limit to how long a string can be (due to memory constraints),
 * this function provides a safe way to append strings by checking the combined length before performing the concatenation.
 * If the combined length exceeds the maximum allowable limit, the function prints a warning and stops the append operation.
 * This prevents the creation of strings that are too long, which could lead to memory issues or truncation of the string
 * in the MetaTrader platform.
 *
 * @param baseString The string to which the new string will be appended.
 * @param appendStr The string to append to the base string.
 * @return Returns 'true' if the string was successfully appended, and 'false' if appending the string would exceed the length limit.
 */
bool SafeAppend(string &baseString, const string appendStr)
{
    const int MAX_STRING_LENGTH = 10000; // Maximum allowed string length. Adjust as needed based on testing.
    if(StringLen(baseString) + StringLen(appendStr) > MAX_STRING_LENGTH) {
        string logMessage = StringFormat("Warning: String length (%d) plus append length (%d) exceeds the maximum limit of %d characters.",
                                         StringLen(baseString), StringLen(appendStr), MAX_STRING_LENGTH);
        PrintLog(__FUNCTION__, logMessage, true);
        return false; // Do not append if it exceeds the limit.
    }
    baseString = StringConcatenate(baseString, appendStr);
    return true;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string AssembleInputParamsString()
{
    string paramsString = "";

// Retrieve broker and server names
    string serverName = AccountInfoString(ACCOUNT_SERVER);

    if(!SafeAppend(paramsString, StringFormat("\nServer: %s", serverName))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nEA Name: %s v%s", WindowExpertName(), EA_VERSION))) return paramsString;
    if(!SafeAppend(paramsString, "\n<inputs>")) return paramsString;

// Basic parameters
    if(!SafeAppend(paramsString, StringFormat("\nIN_MagicNumber=%d; ", IN_MagicNumber))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_OrdersToTrade=%s; ", EnumToString(IN_OrdersToTrade)))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_TradingMode=%s; ", EnumToString(IN_TradingMode)))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_ReverseOrders=%s; ", IN_ReverseOrders ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_BreakevenAtGreyArrows=%s; ", IN_BreakevenAtGreyArrows ? "true" : "false"))) return paramsString;
    
// Money Management Options
    if(!SafeAppend(paramsString, StringFormat("\nEnablePositiveEquityTarget=%s; ", EnablePositiveEquityTarget ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nPositiveEquityTarget=%.2f; ", PositiveEquityTarget))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nEnableNegativeEquityLimit=%s; ", EnableNegativeEquityLimit ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nNegativeEquityLimit=%.2f; ", NegativeEquityLimit))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nEnableRecurringPositiveTargetIncrement=%s; ", EnableRecurringPositiveTargetIncrement ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nRecurringPositiveTargetIncrement=%.2f; ", RecurringPositiveTargetIncrement))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nEnableUnrealizedProfitExit=%s; ", EnableUnrealizedProfitExit ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nUnrealizedProfitExit=%.2f; ", UnrealizedProfitExit))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nEquityTargetAllowReentry=%s; ", EquityTargetAllowReentry ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nEquityTargetPauseDuration=%d; ", EquityTargetPauseDuration))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nEnableMaxEntryThreshold=%s; ", EnableMaxEntryThreshold ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nMaxEntryThresholdPercent=%.2f; ", MaxEntryThresholdPercent))) return paramsString;

// Buy lot sizing options
    if(!SafeAppend(paramsString, StringFormat("\nBuy_IN_LotSizingOptions=%s; ", EnumToString(Buy_IN_LotSizingOptions)))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nBuy_IN_InitialLots=%.2f; ", Buy_IN_InitialLots))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nBuy_IN_PercentFreeMargin=%.1f; ", Buy_IN_PercentFreeMargin))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nBuy_IN_PercentEquity=%.1f; ", Buy_IN_PercentEquity))) return paramsString;

// Sell lot sizing options
    if(!SafeAppend(paramsString, StringFormat("\nSell_IN_LotSizingOptions=%s; ", EnumToString(Sell_IN_LotSizingOptions)))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nSell_IN_InitialLots=%.2f; ", Sell_IN_InitialLots))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nSell_IN_PercentFreeMargin=%.1f; ", Sell_IN_PercentFreeMargin))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nSell_IN_PercentEquity=%.1f; ", Sell_IN_PercentEquity))) return paramsString;

// BE Filter Options
    if(!SafeAppend(paramsString, StringFormat("\nIN_EnableBeFilter=%s; ", IN_EnableBeFilter ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_BeBuyFilterCounter=%d; ", IN_BeBuyFilterCounter))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_BeSellFilterCounter=%d; ", IN_BeSellFilterCounter))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_EnableBeReentry=%s; ", IN_EnableBeReentry ? "true" : "false"))) return paramsString;

// BE Pivot Filter Options
    if(!SafeAppend(paramsString, StringFormat("\nIN_EnableBuyBePivotFilter=%s; ", IN_EnableBuyBePivotFilter ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_BuyBePivotFilterTimeframe=%s; ", EnumToString(IN_BuyBePivotFilterTimeframe)))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_BuyBePivotFilterPercentage=%.2f; ", IN_BuyBePivotFilterPercentage))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_EnableSellBePivotFilter=%s; ", IN_EnableSellBePivotFilter ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_SellBePivotFilterTimeframe=%s; ", EnumToString(IN_SellBePivotFilterTimeframe)))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_SellBePivotFilterPercentage=%.2f; ", IN_SellBePivotFilterPercentage))) return paramsString;

// Reverse Entry
// Uncomment these lines if needed
// if(!SafeAppend(paramsString, StringFormat("\nIN_BuyEnableReverseFilter=%s; ", IN_BuyEnableReverseFilter ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_BuyReverseEntryDeviation=%d; ", IN_BuyReverseEntryDeviation))) return paramsString;
// if(!SafeAppend(paramsString, StringFormat("\nIN_SellEnableReverseFilter=%s; ", IN_SellEnableReverseFilter ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_SellReverseEntryDeviation=%d; ", IN_SellReverseEntryDeviation))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_EnableReverseReentry=%s; ", IN_EnableReverseReentry ? "true" : "false"))) return paramsString;

// Reverse Filter
    if(!SafeAppend(paramsString, StringFormat("\nIN_ReverseBuyFilterCounter=%d; ", IN_ReverseBuyFilterCounter))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_ReverseSellFilterCounter=%d; ", IN_ReverseSellFilterCounter))) return paramsString;

// Reverse Buy Lots Options
    if(!SafeAppend(paramsString, StringFormat("\nReverse_Buy_IN_LotSizingOptions=%s; ", EnumToString(Reverse_Buy_IN_LotSizingOptions)))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nReverse_Buy_IN_InitialLots=%.2f; ", Reverse_Buy_IN_InitialLots))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nReverse_Buy_IN_PercentFreeMargin=%.2f; ", Reverse_Buy_IN_PercentFreeMargin))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nReverse_Buy_IN_PercentEquity=%.2f; ", Reverse_Buy_IN_PercentEquity))) return paramsString;

// Reverse Sell Lots Options
    if(!SafeAppend(paramsString, StringFormat("\nReverse_Sell_IN_LotSizingOptions=%s; ", EnumToString(Reverse_Sell_IN_LotSizingOptions)))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nReverse_Sell_IN_InitialLots=%.2f; ", Reverse_Sell_IN_InitialLots))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nReverse_Sell_IN_PercentFreeMargin=%.2f; ", Reverse_Sell_IN_PercentFreeMargin))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nReverse_Sell_IN_PercentEquity=%.2f; ", Reverse_Sell_IN_PercentEquity))) return paramsString;

// Reverse SL
    if(!SafeAppend(paramsString, StringFormat("\nIN_ReverseBuyStopLoss=%d; ", IN_ReverseBuyStopLoss))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_ReverseSellStopLoss=%d; ", IN_ReverseSellStopLoss))) return paramsString;

// Reverse TP
    if(!SafeAppend(paramsString, StringFormat("\nIN_ReverseBuyTakeProfit=%d; ", IN_ReverseBuyTakeProfit))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_ReverseSellTakeProfit=%d; ", IN_ReverseSellTakeProfit))) return paramsString;

// Multiplier Options
    if(!SafeAppend(paramsString, StringFormat("\nIN_BuyOrderMultiplier=%d; ", IN_BuyOrderMultiplier))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_SellOrderMultiplier=%d; ", IN_SellOrderMultiplier))) return paramsString;

// Pending Stop Order Options
    if(!SafeAppend(paramsString, StringFormat("\nIN_PendingBuyDeviationFromBE=%d; ", IN_PendingBuyDeviationFromBE))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_PendingSellDeviationFromBE=%d; ", IN_PendingSellDeviationFromBE))) return paramsString;

// Trail Stop Options
    if(!SafeAppend(paramsString, StringFormat("\nIN_EnableTrailStop=%s; ", IN_EnableTrailStop ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_TrailStopType=%s; ", EnumToString(IN_TrailStopType)))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_TrailStopInPips=%.1f; ", IN_TrailStopInPips))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_TrailStepInPips=%.1f; ", IN_TrailStepInPips))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_TrailStopATRMultiplier=%d; ", IN_TrailStopATRMultiplier))) return paramsString;

// Spread Options
    if(!SafeAppend(paramsString, StringFormat("\nIN_EnableSpreadControl=%s; ", IN_EnableSpreadControl ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_MaximumSpread=%d; ", IN_MaximumSpread))) return paramsString;

// Take Profit Options
    if(!SafeAppend(paramsString, StringFormat("\nIN_EnableManualTakeProfit=%s; ", IN_EnableManualTakeProfit ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_TakeProfitInPips=%d; ", IN_TakeProfitInPips))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_EnableMHMLTakeProfit=%s; ", IN_EnableMHMLTakeProfit ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_MHMLMarkerTakeProfitTimeframe=%s; ", EnumToString(IN_MHMLMarkerTakeProfitTimeframe)))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_MHMLMarkerTakeProfitPerc=%.2f; ", IN_MHMLMarkerTakeProfitPerc))) return paramsString;

// Stop Loss Options
    if(!SafeAppend(paramsString, StringFormat("\nIN_EnableStopLoss=%s; ", IN_EnableStopLoss ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_StopLossType=%s; ", EnumToString(IN_StopLossType)))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_StopLossInPips=%d; ", IN_StopLossInPips))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_StopLossATRMultiplier=%d; ", IN_StopLossATRMultiplier))) return paramsString;

// Trading Day Options
    if(!SafeAppend(paramsString, StringFormat("\nIN_IsTradingAllowedForSunday=%s; ", IN_IsTradingAllowedForSunday ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_IsTradingAllowedForMonday=%s; ", IN_IsTradingAllowedForMonday ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_IsTradingAllowedForTuesday=%s; ", IN_IsTradingAllowedForTuesday ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_IsTradingAllowedForWednesday=%s; ", IN_IsTradingAllowedForWednesday ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_IsTradingAllowedForThursday=%s; ", IN_IsTradingAllowedForThursday ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_IsTradingAllowedForFriday=%s; ", IN_IsTradingAllowedForFriday ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_IsTradingAllowedForSaturday=%s; ", IN_IsTradingAllowedForSaturday ? "true" : "false"))) return paramsString;

// Time Options
    if(!SafeAppend(paramsString, StringFormat("\nIN_EnableTimeManagement=%s; ", IN_EnableTimeManagement ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_TradingStartHour=%d; ", IN_TradingStartHour))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_TradingStartMinutes=%d; ", IN_TradingStartMinutes))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_TradingEndHour=%d; ", IN_TradingEndHour))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nIN_TradingEndMinutes=%d; ", IN_TradingEndMinutes))) return paramsString;

// News Filter Options
    if(!SafeAppend(paramsString, StringFormat("\nUseNewsFilter=%s; ", UseNewsFilter ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nHighPauseBefore=%d; ", HighPauseBefore))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nHighPauseAfter=%d; ", HighPauseAfter))) return paramsString;

// Trading Alert Options
    if(!SafeAppend(paramsString, StringFormat("\nenableAlerts=%s; ", enableAlerts ? "true" : "false"))) return paramsString;

// ADX Parameters
    if(!SafeAppend(paramsString, StringFormat("\nEnableADXForArrowConfirmation=%s; ", EnableADXForArrowConfirmation ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nTimeframeADX=%s; ", EnumToString(TimeframeADX)))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nADXPeriod=%d; ", ADXPeriod))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nADXLevel=%d; ", ADXLevel))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nBuy_ADX_Price=%s; ", EnumToString(Buy_ADX_Price)))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nSell_ADX_Price=%s; ", EnumToString(Sell_ADX_Price)))) return paramsString;

// Volume Choppiness Filter Parameters
    if(!SafeAppend(paramsString, StringFormat("\nEnableChoppiness=%s; ", EnableChoppiness ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nTimeframeVolume=%s; ", EnumToString(TimeframeVolume)))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nVolumeAnalysisCandleCount=%d; ", VolumeAnalysisCandleCount))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nMeanHighVolumeAdjustment=%s; ", EnumToString(MeanHighVolumeAdjustment)))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nMeanHighAdjustmentPercent=%.2f; ", MeanHighAdjustmentPercent))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nMeanLowVolumeAdjustment=%s; ", EnumToString(MeanLowVolumeAdjustment)))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nMeanLowAdjustmentPercent=%.2f; ", MeanLowAdjustmentPercent))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nHighVolumeLevelColor=%s; ", ColorToString(HighVolumeLevelColor)))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nLowVolumeLevelColor=%s; ", ColorToString(LowVolumeLevelColor)))) return paramsString;

// Buy Parameters
    if(!SafeAppend(paramsString, StringFormat("\nBuy_MaxVolume=%d; ", Buy_MaxVolume))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nBuy_MinVolume=%d; ", Buy_MinVolume))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nBuy_ChoppinessIndexThreshold=%.2f; ", Buy_ChoppinessIndexThreshold))) return paramsString;

// Sell Parameters
    if(!SafeAppend(paramsString, StringFormat("\nSell_MaxVolume=%d; ", Sell_MaxVolume))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nSell_MinVolume=%d; ", Sell_MinVolume))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nSell_ChoppinessIndexThreshold=%.2f; ", Sell_ChoppinessIndexThreshold))) return paramsString;

// Choppiness Parameters
    if(!SafeAppend(paramsString, StringFormat("\nChoppinessPeriod=%d; ", ChoppinessPeriod))) return paramsString;

// MH ML Marker Multitimeframe Parameters
// For 1m Timeframe
    if(!SafeAppend(paramsString, StringFormat("\nN_1m=%d; ", N_1m))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nEnable_1m=%s; ", Enable_1m ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nInpFiboLevelValue2_1M=%.2f; ", InpFiboLevelValue2_1M))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nInpFiboLevelValue3_1M=%.2f; ", InpFiboLevelValue3_1M))) return paramsString;

// For 5m Timeframe
    if(!SafeAppend(paramsString, StringFormat("\nN_5m=%d; ", N_5m))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nEnable_5m=%s; ", Enable_5m ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nInpFiboLevelValue2_5M=%.2f; ", InpFiboLevelValue2_5M))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nInpFiboLevelValue3_5M=%.2f; ", InpFiboLevelValue3_5M))) return paramsString;

// For 15m Timeframe
    if(!SafeAppend(paramsString, StringFormat("\nN_15m=%d; ", N_15m))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nEnable_15m=%s; ", Enable_15m ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nInpFiboLevelValue2_15M=%.2f; ", InpFiboLevelValue2_15M))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nInpFiboLevelValue3_15M=%.2f; ", InpFiboLevelValue3_15M))) return paramsString;

// For 30m Timeframe
    if(!SafeAppend(paramsString, StringFormat("\nN_30m=%d; ", N_30m))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nEnable_30m=%s; ", Enable_30m ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nInpFiboLevelValue2_30M=%.2f; ", InpFiboLevelValue2_30M))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nInpFiboLevelValue3_30M=%.2f; ", InpFiboLevelValue3_30M))) return paramsString;

// For 1h Timeframe
    if(!SafeAppend(paramsString, StringFormat("\nN_1h=%d; ", N_1h))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nEnable_1h=%s; ", Enable_1h ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nInpFiboLevelValue2_1H=%.2f; ", InpFiboLevelValue2_1H))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nInpFiboLevelValue3_1H=%.2f; ", InpFiboLevelValue3_1H))) return paramsString;

// For 4h Timeframe
    if(!SafeAppend(paramsString, StringFormat("\nN_4h=%d; ", N_4h))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nEnable_4h=%s; ", Enable_4h ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nInpFiboLevelValue2_4H=%.2f; ", InpFiboLevelValue2_4H))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nInpFiboLevelValue3_4H=%.2f; ", InpFiboLevelValue3_4H))) return paramsString;

// For Daily Timeframe
    if(!SafeAppend(paramsString, StringFormat("\nN_Daily=%d; ", N_Daily))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nEnable_Daily=%s; ", Enable_Daily ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nInpFiboLevelValue2_D=%.2f; ", InpFiboLevelValue2_D))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nInpFiboLevelValue3_D=%.2f; ", InpFiboLevelValue3_D))) return paramsString;

// For Weekly Timeframe
    if(!SafeAppend(paramsString, StringFormat("\nN_Weekly=%d; ", N_Weekly))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nEnable_Weekly=%s; ", Enable_Weekly ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nInpFiboLevelValue2_W=%.2f; ", InpFiboLevelValue2_W))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nInpFiboLevelValue3_W=%.2f; ", InpFiboLevelValue3_W))) return paramsString;

// For Monthly Timeframe
    if(!SafeAppend(paramsString, StringFormat("\nN_Monthly=%d; ", N_Monthly))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nEnable_Monthly=%s; ", Enable_Monthly ? "true" : "false"))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nInpFiboLevelValue2_MN=%.2f; ", InpFiboLevelValue2_MN))) return paramsString;
    if(!SafeAppend(paramsString, StringFormat("\nInpFiboLevelValue3_MN=%.2f; ", InpFiboLevelValue3_MN))) return paramsString;

    if(!SafeAppend(paramsString, "\n</inputs>")) return paramsString;

    return paramsString;
}
//+------------------------------------------------------------------+
