//+------------------------------------------------------------------+
//|                                              BreakevenFilter.mqh |
//|                                 Copyright © 2023, barmenteros FX |
//|                                          https://barmenteros.com |
//+------------------------------------------------------------------+
/**
 * Breakeven Filter Functionality Explanation:
 * 
 * The Breakeven Filter (controlled by 'enableBeFilter') and the associated counters 
 * ('IN_BeBuyFilterCounter' and 'IN_BeSellFilterCounter') play a crucial role in 
 * determining the trading strategy's responsiveness and risk profile.
 *
 * 1. IN_EnableBeFilter:
 *    - This flag controls an additional layer of filtering for trading decisions.
 *    - When true, it activates extra criteria (defined by the counters) before trades are executed, 
 *      making the strategy more conservative.
 *    - When false, the filter is bypassed, leading to more direct and potentially frequent trades, 
 *      suiting a more aggressive trading approach.
 *
 * 2. IN_BeBuyFilterCounter and IN_BeSellFilterCounter:
 *    - These counters set thresholds for the number of times buy/sell conditions must be met 
 *      (when 'IN_EnableBeFilter' is true) before executing a trade.
 *    - Higher counter values mean more confirmations are needed, reducing trade frequency but 
 *      potentially increasing reliability. This is preferable for cautious trading strategies.
 *    - Lower values (including zero) make the system react faster to market conditions, 
 *      favoring aggressive strategies. A counter of zero effectively disables the additional filter.
 *
 * Users should adjust these settings based on their individual trading strategy and risk tolerance. 
 * Conservative traders may opt for 'IN_EnableBeFilter' to be true with higher counter values, while 
 * aggressive traders might prefer lower counter values or disabling the filter.
 */

#ifndef __BREAKEVEN_FILTER__
#define __BREAKEVEN_FILTER__

#include <Custom\Development\Logging.mqh>
#include "HorizontalLineOperations.mqh"

struct SignalInfo {
    int              entrySignal;
    string           message;
    bool             buyAllowed;
    bool             sellAllowed;
    bool             buyEntry;
    bool             sellEntry;
};

// Global variables for breakeven counters
int breakevenCounterForBuys;
int breakevenCounterForSells;

// Implementing functions for setting, getting, and resetting breakeven counters
void setBreakevenCounterForBuys(int value)
{
    breakevenCounterForBuys = value;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void setBreakevenCounterForSells(int value)
{
    breakevenCounterForSells = value;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getBreakevenCounterForBuys()
{
    return breakevenCounterForBuys;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getBreakevenCounterForSells()
{
    return breakevenCounterForSells;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void resetBreakevenCounterForBuys()
{
    breakevenCounterForBuys = 0;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void resetBreakevenCounterForSells()
{
    breakevenCounterForSells = 0;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool InitializeBreakevenLine()
{
    return CreateHorizontalLine(0,
                                breakevenLineName,
                                0,
                                Open[0],
                                IN_BreakevenLineColor,
                                OBJ_ALL_PERIODS,
                                STYLE_DOT,
                                1,
                                false,
                                true,
                                false,
                                0,
                                breakevenLineStruct);
}
/**
 * The function counts the number of times the current price reaches or exceeds
 * a target price defined as breakeven_price + shift_pips within a single bar.
 * The counter resets when a new bar starts or when explicitly reset by the EA.
 *
 * Note: This function uses global counters managed through utility functions.
 */
void CountBreakevenReachesForBuy(const bool on_new_bar, const double last_price, const double current_price, const double breakeven_price, const int shift_pips)
{
// Automatically reset the counter when a new bar starts
    if (on_new_bar) {
        resetBreakevenCounterForBuys();
    }

// Calculate and normalize the target price to trigger the buy entry
    double targetPrice = NormalizeDouble(breakeven_price + (shift_pips * Pip()), _Digits);

// Normalize the current and last prices for accurate comparison
    double normalizedCurrentPrice = NormalizeDouble(current_price, _Digits);
    double normalizedLastPrice = NormalizeDouble(last_price, _Digits);

// Check if the current price has reached or exceeded the target price
    if (normalizedCurrentPrice >= targetPrice && normalizedLastPrice < targetPrice) {
        int breakevenCounter = getBreakevenCounterForBuys();
        breakevenCounter++;  // Increment the counter
        setBreakevenCounterForBuys(breakevenCounter);

        // Log and inform the user about the counter increment and other details
        string logMessage = StringFormat("Breakeven level: %s, Shift pips: %d, Threshold: %s, Last Price: %s, Current Price: %s. Counter value: %d",
                                         DoubleToString(breakeven_price, _Digits),
                                         shift_pips,
                                         DoubleToString(targetPrice, _Digits),
                                         DoubleToString(normalizedLastPrice, _Digits),
                                         DoubleToString(normalizedCurrentPrice, _Digits),
                                         breakevenCounter);
        //PrintLog(__FUNCTION__, logMessage);
    }
}
/**
 * The function counts the number of times the current price reaches or falls below
 * a target price defined as breakeven_price - shift_pips within a single bar.
 * The counter resets when a new bar starts or when explicitly reset by the EA.
 *
 * Note: This function uses a global counter managed through utility functions.
 */
void CountBreakevenReachesForSell(const bool on_new_bar, const double last_price, const double current_price, const double breakeven_price, const int shift_pips)
{
// Automatically reset the counter when a new bar starts
    if (on_new_bar) {
        resetBreakevenCounterForSells();
    }

// Calculate and normalize the target price to trigger the sell entry
    double targetPrice = NormalizeDouble(breakeven_price - (shift_pips * Pip()), _Digits);

// Normalize the current and last prices for accurate comparison
    double normalizedCurrentPrice = NormalizeDouble(current_price, _Digits);
    double normalizedLastPrice = NormalizeDouble(last_price, _Digits);

// Check if the current price has reached or fallen below the target price
    if (normalizedCurrentPrice <= targetPrice && normalizedLastPrice > targetPrice) {
        int breakevenCounter = getBreakevenCounterForSells();
        breakevenCounter++;  // Increment the counter
        setBreakevenCounterForSells(breakevenCounter);

        // Log and inform the user about the counter increment and other details
        string logMessage = StringFormat("Breakeven level: %s, Shift pips: %d, Threshold: %s, Last Price: %s, Current Price: %s. Counter value: %d",
                                         DoubleToString(breakeven_price, _Digits),
                                         shift_pips,
                                         DoubleToString(targetPrice, _Digits),
                                         DoubleToString(normalizedLastPrice, _Digits),
                                         DoubleToString(normalizedCurrentPrice, _Digits),
                                         breakevenCounter);
        //PrintLog(__FUNCTION__, logMessage);
    }
}
/**
 * The function checks if a buy signal should be issued based on the counter value
 * returned by CountBreakevenReachesForBuy. If the counter value matches a predefined
 * threshold (IN_BeBuyFilterCounter), a buy signal is issued, and the counter is reset.
 *
 * Returns:
 * A SignalInfo structure containing:
 * - entrySignal: An integer representing the entry signal (OP_BUY if the condition is met, -1 otherwise).
 * - message: A string detailing the current counter value and the predefined threshold.
 *
 */
SignalInfo CheckBuySignalOnBreakevenCountMatch(
    const bool on_new_bar,
    const double last_price,
    const double current_price,
    const double breakeven_price,
    const int shift_pips,
    const int BeBuyFilterCounter)
{
    SignalInfo result;  // Structure to store the output

// Update the current buy counter value
    CountBreakevenReachesForBuy(on_new_bar, last_price, current_price, breakeven_price, shift_pips);

// Get the current buy counter value
    int currentCount = getBreakevenCounterForBuys();

// Populate the message field in the result structure
    result.message = StringFormat("BE Buy Filter: %d out of %d", currentCount, BeBuyFilterCounter);

// Check if the current counter value matches the predefined threshold
    if (currentCount == BeBuyFilterCounter) {
        // Log and inform the user that a buy signal is being issued
        string logMessage = StringFormat("Buy signal issued. Count matches \'BE Buy Filter\': %d. Resetting buy counter", BeBuyFilterCounter);
        PrintLog(__FUNCTION__, logMessage);

        // Reset the counter in CountBreakevenReachesForBuy
        resetBreakevenCounterForBuys();

        result.entrySignal = OP_BUY;  // Set buy signal in the result structure
    }
    else {
        result.entrySignal = -1;  // Set no buy signal in the result structure
    }

    return result;  // Return the populated result structure
}
/**
 * Purpose:
 * The function checks if a sell signal should be issued based on the counter value
 * returned by CountBreakevenReachesForSell. If the counter value matches a predefined
 * threshold (BeSellFilterCounter), a sell signal is issued, and the counter is reset.
 *
 * Returns:
 * A SignalInfo structure containing:
 * - entrySignal: An integer representing the entry signal (OP_SELL if the condition is met, -1 otherwise).
 * - message: A string detailing the current counter value and the predefined threshold.
 */
SignalInfo CheckSellSignalOnBreakevenCountMatch(
    const bool on_new_bar,
    const double last_price,
    const double current_price,
    const double breakeven_price,
    const int shift_pips,
    const int BeSellFilterCounter)
{
    SignalInfo result;  // Structure to store the output

// Update the current sell counter value
    CountBreakevenReachesForSell(on_new_bar, last_price, current_price, breakeven_price, shift_pips);

// Get the current sell counter value
    int currentCount = getBreakevenCounterForSells();

// Populate the message field in the result structure
    result.message = StringFormat("BE Sell Filter: %d out of %d", currentCount, BeSellFilterCounter);

// Check if the current counter value matches the predefined threshold
    if (currentCount == BeSellFilterCounter) {
        // Log and inform the user that a sell signal is being issued
        string logMessage = StringFormat("Sell signal issued. Count matches 'BE Sell Filter': %d. Resetting sell counter", BeSellFilterCounter);
        PrintLog(__FUNCTION__, logMessage);

        // Reset the counter
        resetBreakevenCounterForSells();

        result.entrySignal = OP_SELL;  // Set sell signal in the result structure
    }
    else {
        result.entrySignal = -1;  // Set no sell signal in the result structure
    }

    return result;  // Return the populated result structure
}
/**
 * Function: EvaluateBreakevenFilterForSignals
 * Purpose: This function evaluates trading signals based on the Breakeven (BE) filter 
 * settings and corresponding counters. It primarily determines whether buying or selling 
 * is allowed under current market conditions.
 * 
 * Parameters:
 * - enableBeFilter: Toggles the additional BE filtering logic.
 * - enableBeReentry: Indicates if reentry is allowed once BE conditions are met.
 * - onNewBar, lastPrice, currentPrice, breakevenPrice: Market condition parameters.
 *
 * Functionality Overview:
 * 1. BE Filter Status:
 *    - The function starts by documenting the status of the BE filter and reentry option. 
 *      This is crucial for understanding the operational context in which the function is executing.
 *
 * 2. Counter Logic:
 *    - Based on 'enableBeFilter', counters (buy and sell) are set. If the filter is enabled, 
 *      the counters determine how many times a condition must be met before a trade is allowed. 
 *      If disabled, counters are set to 0, removing the additional filtering layer.
 *
 * 3. Initial Trade Allowance:
 *    - 'buyAllowed' and 'sellAllowed' flags are initially set based on the counter values. 
 *      A counter value of 0 (filter disabled or condition immediately met) allows the respective trade.
 *
 * 4. Conditional Signal Evaluation:
 *    - The function evaluates buy/sell signals only if the respective 'buyAllowed'/'sellAllowed' 
 *      flag is not already true. This optimization avoids redundant checks, improving efficiency.
 *    - It calls 'CheckBuySignalOnBreakevenCountMatch' and 'CheckSellSignalOnBreakevenCountMatch' 
 *      for further decision-making if necessary.
 *
 * 5. Result Compilation:
 *    - The final decision about allowing buy/sell trades, along with a detailed message, is compiled 
 *      into the 'SignalInfo' structure and returned.
 *
 * Decision Rationale:
 * - The approach taken in this function balances efficiency with responsiveness. By conditionally 
 *   evaluating signals and leveraging counters, it adapts to both conservative and aggressive trading strategies.
 * - The focus on setting 'buyAllowed'/'sellAllowed' flags directly, rather than relying solely on 
 *   'entrySignal', aligns with practical trading needs and future-proofs the function for evolving strategies.
 *
 * Future Programmers:
 * - When modifying this function, consider the interplay between BE filter settings and counter values.
 * - Pay attention to how changes might affect the conditional logic and overall trading strategy.
 */
SignalInfo EvaluateBreakevenFilterForSignals(
    const bool enableBeFilter,
    const bool enableBeReentry,
    const bool onNewBar,
    const double lastPrice,
    const double currentPrice,
    const double breakevenPrice,
    string &buyTextToDisplay,
    string &sellTextToDisplay)
{
    SignalInfo result;
    string comment = "";
    
// Append BE Filter status to the comment.
    comment += enableBeFilter ? "\nBE Filter: ON" : "\nBE Filter: OFF";
    comment += enableBeReentry ? "\nBE Filter Reentry: ON" : "\nBE Filter Reentry: OFF";

// Determine counters based on enableBeFilter.
    int counterForBuy = enableBeFilter ? IN_BeBuyFilterCounter : 0;
    int counterForSell = enableBeFilter ? IN_BeSellFilterCounter : 0;

// Initialize buyAllowed and sellAllowed based on the counter values.
    result.buyAllowed = (counterForBuy == 0);
    result.sellAllowed = (counterForSell == 0);
    
// Evaluate buy signal if buy is not already allowed
    if (!result.buyAllowed) {
        SignalInfo buySignalInfo = CheckBuySignalOnBreakevenCountMatch(onNewBar, lastPrice, currentPrice, breakevenPrice, IN_EntryGapInPips, counterForBuy);
        result.buyAllowed = (buySignalInfo.entrySignal == OP_BUY);
        comment += "\n" + buySignalInfo.message;
        buyTextToDisplay = buySignalInfo.message;
    }

// Evaluate sell signal if sell is not already allowed
    if (!result.sellAllowed) {
        SignalInfo sellSignalInfo = CheckSellSignalOnBreakevenCountMatch(onNewBar, lastPrice, currentPrice, breakevenPrice, IN_EntryGapInPips, counterForSell);
        result.sellAllowed = (sellSignalInfo.entrySignal == OP_SELL);
        comment += "\n" + sellSignalInfo.message;
        sellTextToDisplay = sellSignalInfo.message;
    }

// Set the overall message for the result.
    result.message = comment;
    return result;
}

#endif  // __BREAKEVEN_FILTER__
//+------------------------------------------------------------------+
