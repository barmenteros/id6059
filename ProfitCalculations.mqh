﻿//+------------------------------------------------------------------+
//|                                           ProfitCalculations.mqh |
//|                                 Copyright © 2023, barmenteros FX |
//|                                          https://barmenteros.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateProfitAmount(const double freeMarginPercentage)
{
// Validate input parameters
    if (freeMarginPercentage < 0.0) {
        string logMessage = "Invalid parameters. Returning 0.";
        PrintLog(__FUNCTION__, logMessage, false);
        return 0.0;
    }

    string logMessage = "";

// Calculate the free margin that remains after the specified order has been opened
    double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    logMessage = StringFormat("Free Margin: %.2f", freeMargin);
    PrintLog(__FUNCTION__, logMessage, false);

    if (freeMargin <= 0.0) {
        logMessage = "Not enough free margin. Returning 0.";
        PrintLog(__FUNCTION__, logMessage, false);
        return 0.0;
    }

// Calculate the profit target amount based on the free margin percentage
    double profitAmount = freeMargin * (freeMarginPercentage / 100.0);
    logMessage = StringFormat("Profit Amount (based on %.2f%% free margin): %.2f", freeMarginPercentage, profitAmount);
    PrintLog(__FUNCTION__, logMessage, false);

    return profitAmount;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateTakeProfitPoints(const int tradeDirection, const double lotSize, const double profitAmount)
{
// Validate input parameters
    if (profitAmount <= 0.0 || lotSize <= 0.0 || (tradeDirection != OP_BUY && tradeDirection != OP_SELL)) {
        string logMessage = "Invalid parameters. Returning 0.";
        PrintLog(__FUNCTION__, logMessage, false);
        return 0.0;
    }

    double takeProfitPoints = positionCalculator.CalculateIterativeTakeProfitDistance(lotSize, profitAmount, Symbol(), tradeDirection);
    string logMessage = StringFormat("Absolute value: %.2f", takeProfitPoints);
    PrintLog(__FUNCTION__, logMessage, false);

    return takeProfitPoints;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double DetermineTakeProfit(const bool enableManualTakeProfit,
                           const double tpInPips,
                           const bool enableMHMLTakeProfit,
                           const SignalInfo &signalInfo,
                           const ENUM_TIMEFRAMES tpTimeframe,
                           const double tpPerc,
                           const bool debug = false)
{
// Print debug info about input parameters
    if (debug) {
        string signalDebug = StringFormat("buyEntry=%s, sellEntry=%s",
                                          signalInfo.buyEntry ? "true" : "false",
                                          signalInfo.sellEntry ? "true" : "false");
        PrintLog("DEBUG_TP_DETERMINE", StringFormat("Inputs: manualTP=%s, MHMLTP=%s, tpPerc=%.1f, %s",
                 enableManualTakeProfit ? "true" : "false",
                 enableMHMLTakeProfit ? "true" : "false",
                 tpPerc, signalDebug), true);
    }

// Manual Take Profit
    if (enableManualTakeProfit) {
        if (debug) {
            PrintLog("DEBUG_TP_DETERMINE", StringFormat("Using manual TP: %.1f pips", tpInPips), true);
        }
        return tpInPips;
    }

// MHML Marker Level Take Profit
    else if (enableMHMLTakeProfit) {
        /*
            // Example of how you might calculate take profit points, this section is currently commented out
            double profitAmount = CalculateProfitAmount(percentFreeMargin);
            int takeProfitPoints = (int)CalculateTakeProfitPoints(entrySignal, lots, profitAmount);
            double takeProfitPips = takeProfitPoints * Point() / Pip();
            return takeProfitPips;
        */

        int entrySignal = -1;
        if(signalInfo.buyEntry) {
            entrySignal = OP_BUY;
            if (debug) {
                PrintLog("DEBUG_TP_DETERMINE", "Setting entrySignal=OP_BUY (0) from signalInfo.buyEntry", true);
            }
        }
        else if(signalInfo.sellEntry) {
            entrySignal = OP_SELL;
            if (debug) {
                PrintLog("DEBUG_TP_DETERMINE", "Setting entrySignal=OP_SELL (1) from signalInfo.sellEntry", true);
            }
        }
        else {
            if (debug) {
                PrintLog("DEBUG_TP_DETERMINE", "WARNING: Neither buyEntry nor sellEntry is true!", true);
            }
        }

        double takeProfit = CalculateMHMLMarkerTakeProfit(tpTimeframe, tpPerc, entrySignal, debug);

        if (debug) {
            PrintLog("DEBUG_TP_DETERMINE", StringFormat("Final calculated TP: %.5f", takeProfit), true);
        }

        return takeProfit;
    }

// If no valid take profit type is selected, return 0.0 and log an error
    if (debug) {
        PrintLog("DEBUG_TP_DETERMINE", "No valid TP type selected, returning 0.0", true);
    }
    return 0.0;
}
//+------------------------------------------------------------------+
