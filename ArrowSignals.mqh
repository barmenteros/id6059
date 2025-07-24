//+------------------------------------------------------------------+
//|                                                 ArrowSignals.mqh |
//|                                 Copyright © 2023, barmenteros FX |
//|                                          https://barmenteros.com |
//+------------------------------------------------------------------+
#ifndef __ARROW_SIGNALS__
#define __ARROW_SIGNALS__

#include <Custom\Development\Logging.mqh>
#include "BreakevenFilter.mqh"
#include "ADXFilter.mqh"

// Define a structure to hold order settings
struct OrderSettings {
    bool             allowBuy;
    bool             allowSell;
    bool             reverseBuy;
    bool             reverseSell;
};

// Global variables for tracking the last processed time for each signal
datetime lastProcessedTimeBuy = 0;
datetime lastProcessedTimeSell = 0;
datetime lastProcessedTimeGray = 0;

// Global variables for the current order settings
OrderSettings currentOrderSettings = {false, false, false, false};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InitializeOrderSettings()
{
    currentOrderSettings.allowBuy = false;
    currentOrderSettings.allowSell = false;
    currentOrderSettings.reverseBuy = IN_BuyEnableReverseFilter;
    currentOrderSettings.reverseSell = IN_SellEnableReverseFilter;
}
/**
 * This function is designed to fetch either an up or down arrow signal by calling the indicator with specific buffer indexes.
 * It utilizes the iCustom function to access the 'ArrowSignals_Jesse' indicator, passing predefined buffer numbers to
 * distinguish between up and down arrows. The indicator's input parameters are synchronized with the EA through
 * initialization from a file where the EA previously stores these values, ensuring consistency in the parameters used by both.
 * Because of this, iCustom uses the default indicator's parameters.
 *
 * Parameters:
 * - buffer: The buffer index indicating the type of arrow signal to retrieve.
 *           Buffer 0 corresponds to up arrows, and buffer 1 corresponds to down arrows.
 * - index: The bar index from which to retrieve the arrow signal.
 *
 * Returns:
 * The arrow signal value at the specified index and buffer.
 */
double GetArrowSignal(const int buffer, const int index)
{
// buffer 0 -> up arrow
// buffer 1 -> down arrow
    return iCustom(NULL, 0, "ArrowSignals_Jesse", buffer, index);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string BoolToString(const bool value)
{
    return value ? "true" : "false";
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void LogOrderSettings(const OrderSettings &settings, const string signalType, const datetime timeOfSignal)
{
    string message = StringFormat("Updated settings after %s arrow at %s: Allow Buy = %s, Allow Sell = %s, Reverse Buy = %s, Reverse Sell = %s",
                                  signalType, TimeToString(timeOfSignal, TIME_DATE | TIME_MINUTES),
                                  BoolToString(settings.allowBuy), BoolToString(settings.allowSell),
                                  BoolToString(settings.reverseBuy), BoolToString(settings.reverseSell));
    PrintLog("", message);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
OrderSettings ProcessBuyArrowSignal(OrderSettings &settings, const bool reverseOrdersEnabled)
{
    int index = 0;
    double arrowSignalBuy = GetArrowSignal(0, index);
    datetime timeOfSignal = Time[1];

// Commented out to avoid the log files getting cluttered
    /*
        if(IsNotZero(arrowSignalBuy) && arrowSignalBuy != EMPTY_VALUE) {
            string logMessage = StringFormat("arrowSignalBuy=%s at %s", DoubleToString(arrowSignalBuy, _Digits), TimeToString(timeOfSignal));
            PrintLog(__FUNCTION__, logMessage);
        }
    */

// Validate the signal and ensure it's only processed once per bar
    if (IsNotZero(arrowSignalBuy) && arrowSignalBuy != EMPTY_VALUE && timeOfSignal != lastProcessedTimeBuy) {
        lastProcessedTimeBuy = timeOfSignal; // Update the last processed time

        settings.allowBuy = true;
        settings.allowSell = false;
        settings.reverseSell = reverseOrdersEnabled;
        settings.reverseBuy = false;

        LogOrderSettings(settings, "Buy", timeOfSignal);
    }

    return settings;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
OrderSettings ProcessSellArrowSignal(OrderSettings &settings, const bool reverseOrdersEnabled)
{
    int index = 0;
    double arrowSignalSell = GetArrowSignal(1, index);
    datetime timeOfSignal = Time[1];

// Commented out to avoid the log files getting cluttered
    /*
        if(IsNotZero(arrowSignalSell) && arrowSignalSell != EMPTY_VALUE) {
            string logMessage = StringFormat("arrowSignalSell=%s at %s", DoubleToString(arrowSignalSell, _Digits), TimeToString(timeOfSignal));
            PrintLog(__FUNCTION__, logMessage);
        }
    */

// Validate the signal and ensure it's only processed once per bar
    if (IsNotZero(arrowSignalSell) && arrowSignalSell != EMPTY_VALUE && timeOfSignal != lastProcessedTimeSell) {
        lastProcessedTimeSell = timeOfSignal; // Update the last processed time

        settings.allowSell = true;
        settings.allowBuy = false;
        settings.reverseBuy = reverseOrdersEnabled;
        settings.reverseSell = false;

        LogOrderSettings(settings, "Sell", timeOfSignal);
    }

    return settings;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsBuyArrowPresent(int index)
{
    double arrowSignalBuy = GetArrowSignal(0, index);
    return IsNotZero(arrowSignalBuy) && arrowSignalBuy != EMPTY_VALUE;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsSellArrowPresent(int index)
{
    double arrowSignalSell = GetArrowSignal(1, index);
    return IsNotZero(arrowSignalSell) && arrowSignalSell != EMPTY_VALUE;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsBuyOrSellArrowPresent(int index)
{
    return IsBuyArrowPresent(index) || IsSellArrowPresent(index);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
SignalInfo UpdateAndEvaluateEntrySignals(
    const bool enableBeFilter,
    const bool enableBeReentry,
    const bool onNewBar,
    const double lastPrice,
    const double currentPrice,
    const double breakevenPrice,
    const bool reverseOrdersEnabled,
    string &buyBETextToDisplay,
    string &sellBETextToDisplay)
{
// Initialize currentOrderSettings to not allow trades by default
    currentOrderSettings.allowBuy = false;
    currentOrderSettings.allowSell = false;

// Process arrow signals based on the conditions
// Explanation:
// The arrow signal processing is executed if either `enableBeFilter` is true or a new bar has formed (`onNewBar` is true).
// This ensures that signals are always processed when the breakeven filter is enabled (even if not on a new bar),
// or only when a new bar is formed if the breakeven filter is disabled.
    if (enableBeFilter || onNewBar) {
        currentOrderSettings = ProcessBuyArrowSignal(currentOrderSettings, reverseOrdersEnabled);
        currentOrderSettings = ProcessSellArrowSignal(currentOrderSettings, reverseOrdersEnabled);
    }

// Check ADX filter first (proactive gate)
    bool adxAllowsBuy = IsTradeAllowedByADX(OP_BUY, 1);
    bool adxAllowsSell = IsTradeAllowedByADX(OP_SELL, 1);

// Log ADX status if enabled
    if (EnableADXForArrowConfirmation) {
        if (!adxAllowsBuy) {
            string adxStatus = GetADXFilterStatus(1);
            PrintLog(__FUNCTION__, StringFormat("Buy trades blocked by ADX Filter: %s", adxStatus), true);
        }
        if (!adxAllowsSell) {
            string adxStatus = GetADXFilterStatus(1);
            PrintLog(__FUNCTION__, StringFormat("Sell trades blocked by ADX Filter: %s", adxStatus), true);
        }
    }

// Only evaluate zone signals if ADX permits at least one direction
    SignalInfo signalInfo;
    if (adxAllowsBuy || adxAllowsSell) {
        signalInfo = EvaluateBreakevenFilterForSignals(enableBeFilter, enableBeReentry, onNewBar, lastPrice, currentPrice, breakevenPrice,
                     buyBETextToDisplay, sellBETextToDisplay);

        // Apply ADX restrictions to final results
        signalInfo.buyAllowed = signalInfo.buyAllowed && adxAllowsBuy;
        signalInfo.sellAllowed = signalInfo.sellAllowed && adxAllowsSell;

        // Log final ADX approval
        if (EnableADXForArrowConfirmation && (signalInfo.buyAllowed || signalInfo.sellAllowed)) {
            string adxStatus = GetADXFilterStatus(1);
            PrintLog(__FUNCTION__, StringFormat("Signal(s) approved by ADX Filter: %s", adxStatus), true);
        }
    }
    else {
        // No ADX permission for either direction - initialize empty signals
        signalInfo.buyAllowed = false;
        signalInfo.sellAllowed = false;
        signalInfo.buyEntry = false;
        signalInfo.sellEntry = false;
        if (EnableADXForArrowConfirmation) {
            PrintLog(__FUNCTION__, "All trades blocked by ADX Filter", true);
        }
    }

// Check if buy is allowed and set buyEntry accordingly
    if (currentOrderSettings.allowBuy) {
        signalInfo.buyEntry = signalInfo.buyAllowed;
        if (!signalInfo.buyAllowed) {
            string logMessage = StringFormat("Buy signal triggered by a valid arrow but dismissed by BE filter at %s", TimeToString(Time[1]));
            PrintLog(__FUNCTION__, logMessage);
        }
    }

// Check if sell is allowed and set sellEntry accordingly
    if (currentOrderSettings.allowSell) {
        signalInfo.sellEntry = signalInfo.sellAllowed;
        if (!signalInfo.sellAllowed) {
            string logMessage = StringFormat("Sell signal triggered by a valid arrow but dismissed by BE filter at %s", TimeToString(Time[1]));
            PrintLog(__FUNCTION__, logMessage);
        }
    }

    return signalInfo;
}
/**
 * Customer Requirement:
 * "2. Buy arrow = Turn OFF SELL and Reverse Buy, Allow Buy and Reverse Sell if I have both on.
 * In settings I may have the reverse orders off in which case the EA is only opening Sell."
 *
 * This requirement was specified by the customer in an email received on Fri, Oct 20, 2023, at 7:06 PM.
 *
 * The logic implemented below is based on this specific instruction and should be maintained or
 * altered only with subsequent customer approval or clarification.
 */
/*
SignalInfo HandleBuyArrowSignal(const bool reverseBuy, const bool allowBuy, const bool reverseOrders, const int totalOpenBuys)
{
   static datetime lastTimeBuy = 0; // Static variable to keep track of the last processed bar time for Buy
   SignalInfo signalInfo;                    // Initialize a default SignalInfo object

   // Get the time of the previous bar
   datetime timeOfSignal = Time[1];

   double arrowSignal = GetArrowSignal(8, 1);

   // Check if a Buy arrow signal is detected in the previous candle and if the candle hasn't been processed yet
   if(IsNotZero(arrowSignal) && arrowSignal != EMPTY_VALUE && timeOfSignal != lastTimeBuy) {
       // Update lastTimeBuy to the current signal's time so it's not processed again
       lastTimeBuy = timeOfSignal;

       // If Reverse Buy and Reverse Orders are enabled, close any existing Sell positions.
       if (reverseBuy && reverseOrders) {
           string logMessage = StringFormat("Closing/deleting all Sell positions as 'Reverse Buy' and 'Reverse Orders' are enabled.");
           PrintLog(__FUNCTION__, logMessage);
           const int slippage = 5;
           CloseAll(Symbol(), Digits(), IN_MagicNumber, slippage, "", 1, OP_SELL, clrGold);
           DeleteAllTypePositions(OP_SELLSTOP);
           DeleteAllTypePositions(OP_SELLLIMIT);
       }

       // If allowing new Buy positions, either because reversing is enabled, or there are no open Buy positions.
       if (allowBuy && (!reverseOrders || totalOpenBuys == 0)) {
           // Populate the signal information
           signalInfo.entrySignal = OP_BUY;
           signalInfo.message = StringFormat("%s: Buy signal detected at %s.", __FUNCTION__, TimeToString(timeOfSignal));
           // Log the signal detection
           PrintLog(__FUNCTION__, signalInfo.message);
       }
       else {
           // No Buy signal to issue
           signalInfo.entrySignal = -1;
           signalInfo.message = "";
       }
   }
   else {
       // No Buy signal to issue if no signal detected or if it's the same bar
       signalInfo.entrySignal = -1;
       signalInfo.message = "";
   }

   return signalInfo; // Return the populated SignalInfo object
}
*/
/**
 * Customer Requirement:
 * "1. Sell arrow = Turn OFF BUY and Reverse Sell, Allow Sell and Reverse Buy if I have both on.
 * In settings I may have the reverse orders off in which case the EA is only opening Sell."
 *
 * This requirement was specified by the customer in an email received on Fri, Oct 20, 2023, at 7:06 PM.
 *
 * The logic implemented below is based on this specific instruction and should be maintained or
 * altered only with subsequent customer approval or clarification.
 */
/*
SignalInfo HandleSellArrowSignal(const bool reverseSell, const bool allowSell, const bool reverseOrders, const int totalOpenSells)
{
   static datetime lastTimeSell = 0; // Static variable to keep track of the last processed bar time
   SignalInfo signalInfo;                     // Initialize a default SignalInfo object

   // Get the time of the previous bar
   datetime timeOfSignal = Time[1];

   double arrowSignal = GetArrowSignal(9, 1);

   // Check if a Sell arrow signal is detected in the previous candle and if the candle hasn't been processed yet
   if(IsNotZero(arrowSignal) && arrowSignal != EMPTY_VALUE && timeOfSignal != lastTimeSell) {
       // Update lastTimeSell to the current signal's time so it's not processed again
       lastTimeSell = timeOfSignal;

       // If Reverse Sell and Reverse Orders are enabled, close any existing Buy positions.
       if (reverseSell && reverseOrders) {
           string logMessage = StringFormat("Closing/deleting all Buy positions as 'Reverse Sell' and 'Reverse Orders' are enabled.");
           PrintLog(__FUNCTION__, logMessage);
           const int slippage = 5;
           CloseAll(Symbol(), Digits(), IN_MagicNumber, slippage, "", 1, OP_BUY, clrGoldenrod);
           DeleteAllTypePositions(OP_BUYSTOP);
           DeleteAllTypePositions(OP_BUYLIMIT);
       }

       // If allowing new Sell positions, either because reversing is enabled, or there are no open Sell positions.
       if (allowSell && (!reverseOrders || totalOpenSells == 0)) {
           // Populate the signal information
           signalInfo.entrySignal = OP_SELL;
           signalInfo.message = StringFormat("Sell signal detected at %s.", TimeToString(timeOfSignal));
           // Log the signal detection
           PrintLog(__FUNCTION__, signalInfo.message);
       }
       else {
           // No sell signal to issue
           signalInfo.entrySignal = -1;
           signalInfo.message = "";
       }
   }
   else {
       // No sell signal to issue if no signal detected or if it's the same bar
       signalInfo.entrySignal = -1;
       signalInfo.message = "";
   }

   return signalInfo; // Return the populated SignalInfo object
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
SignalInfo EvaluateArrowSignalsForEntries(
   const bool reverseBuy,
   const bool allowBuy,
   const bool reverseSell,
   const bool allowSell,
   const bool reverseOrders,
   const int totalOpenBuys,
   const int totalOpenSells)
{
   SignalInfo result;
   result.entrySignal = -1; // Default to no signal
   string comment = "";

   // Append the state of the settings to the comment
//    comment += StringFormat("\nAllow Buy: %s", allowBuy ? "ON" : "OFF");
   comment += StringFormat("\nReverse Sell: %s", reverseSell ? "ON" : "OFF");
//    comment += StringFormat("\nAllow Sell: %s", allowSell ? "ON" : "OFF");
   comment += StringFormat("\nReverse Buy: %s", reverseBuy ? "ON" : "OFF");
   comment += StringFormat("\nReverse Orders: %s", reverseOrders ? "ON" : "OFF");

   // Check for Buy Arrow Signal
   SignalInfo buySignalInfo = HandleBuyArrowSignal(reverseBuy, allowBuy, reverseOrders, totalOpenBuys);
   if (buySignalInfo.entrySignal == OP_BUY) {
       result.entrySignal = buySignalInfo.entrySignal;
   }

   // Check for Sell Arrow Signal
   SignalInfo sellSignalInfo = HandleSellArrowSignal(reverseSell, allowSell, reverseOrders, totalOpenSells);
   if (sellSignalInfo.entrySignal == OP_SELL) {
       result.entrySignal = sellSignalInfo.entrySignal;
   }

   // If no signals are found, append the settings to the default message
   result.message = comment;
   return result;
}
*/

#endif  // __ARROW_SIGNALS__
//+------------------------------------------------------------------+
