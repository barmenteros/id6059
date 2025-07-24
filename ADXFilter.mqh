//+------------------------------------------------------------------+
//|                                                    ADXFilter.mqh |
//|                                 Copyright © 2023, barmenteros FX |
//|                                          https://barmenteros.com |
//+------------------------------------------------------------------+
#ifndef __ADX_FILTER__
#define __ADX_FILTER__

#include <Custom\Development\Logging.mqh>

// ADX Jesse Indicator Buffer Indices
#define ADX_BUY_SIGNAL_BUFFER           0    // ExtBuyADXSignalBuffer
#define ADX_BUY_DI_PLUS_ABOVE_MINUS     1    // ExtBuyDIPlusAboveDIMinusBuffer
#define ADX_BUY_DI_MINUS_ABOVE_PLUS     2    // ExtBuyDIMinusAboveDIPlusBuffer
#define ADX_SELL_SIGNAL_BUFFER          3    // ExtSellADXSignalBuffer
#define ADX_SELL_DI_PLUS_ABOVE_MINUS    4    // ExtSellDIPlusAboveDIMinusBuffer
#define ADX_SELL_DI_MINUS_ABOVE_PLUS    5    // ExtSellDIMinusAboveDIPlusBuffer
#define ADX_BUY_PLUS_DI_BUFFER          6    // ExtBuyADXPlusDiBuffer (hidden)
#define ADX_BUY_MINUS_DI_BUFFER         7    // ExtBuyADXMinusDiBuffer (hidden)
#define ADX_SELL_PLUS_DI_BUFFER         8    // ExtSellADXPlusDiBuffer (hidden)
#define ADX_SELL_MINUS_DI_BUFFER        9    // ExtSellADXMinusDiBuffer (hidden)

// ADX Signal Interpretation Enum
enum ADXSignalType {
    ADX_SIGNAL_ZERO,        // Zero value (no signal)
    ADX_SIGNAL_BUY,         // Buy strength (teal)
    ADX_SIGNAL_SELL,        // Sell strength (purple)
    ADX_SIGNAL_BELOW_ZERO   // Below threshold (gap/no trade)
};

//+------------------------------------------------------------------+
//| Get raw ADX data from Jesse indicator                            |
//+------------------------------------------------------------------+
double GetADXJesseValue(const int buffer, const int index = 0)
{
    return iCustom(NULL, 0, "ADX_Jesse",
                   TimeframeADX,
                   ADXPeriod,
                   ADXLevel,
                   Buy_ADX_Price,
                   Sell_ADX_Price,
                   " ",
                   ADXuserProgramID,
                   buffer, index);
}

//+------------------------------------------------------------------+
//| Check if main ADX level is below threshold (global rejection)    |
//+------------------------------------------------------------------+
bool IsADXBelowThreshold(const int index = 0)
{
// Get the main ADX line values from both buy and sell perspectives
// These represent the overall momentum (main ADX line), not directional components
    double buyMainADX = GetADXJesseValue(ADX_BUY_SIGNAL_BUFFER, index);     // MODE_MAIN with PRICE_LOW
    double sellMainADX = GetADXJesseValue(ADX_SELL_SIGNAL_BUFFER, index);   // MODE_MAIN with PRICE_HIGH

// Check for invalid values first
    if (buyMainADX == EMPTY_VALUE || sellMainADX == EMPTY_VALUE) {
        PrintLog(__FUNCTION__, StringFormat("Invalid ADX values at index %d: buyMainADX=%.4f, sellMainADX=%.4f",
                                            index, buyMainADX, sellMainADX), true);
        return true; // Reject trade if we can't get valid ADX readings
    }

// Global rejection: if EITHER main ADX value is below the threshold
// This represents "overall ADX indicator level drops below 0" (threshold)
    bool buyBelowThreshold = (buyMainADX < ADXLevel);
    bool sellBelowThreshold = (sellMainADX < ADXLevel);

// Log detailed threshold check for debugging
    if (buyBelowThreshold || sellBelowThreshold) {
        PrintLog(__FUNCTION__, StringFormat("ADX below threshold detected at index %d: buyMainADX=%.4f %s %.4f, sellMainADX=%.4f %s %.4f",
                                            index,
                                            buyMainADX, buyBelowThreshold ? "<" : ">=", (double)ADXLevel,
                                            sellMainADX, sellBelowThreshold ? "<" : ">=", (double)ADXLevel), true);
    }

// Return true if either ADX reading is below threshold (reject trade)
    return (buyBelowThreshold || sellBelowThreshold);
}

//+------------------------------------------------------------------+
//| Interpret Buy ADX strength signal                                |
//+------------------------------------------------------------------+
ADXSignalType GetBuyADXSignal(const int index = 0)
{
// Get the main buy ADX signal (MODE_MAIN value)
    double buySignal = GetADXJesseValue(ADX_BUY_SIGNAL_BUFFER, index);

// Get the directional buffers (these show when DI+ > DI- or DI- > DI+)
    double buyDIPlusAbove = GetADXJesseValue(ADX_BUY_DI_PLUS_ABOVE_MINUS, index);
    double buyDIMinusAbove = GetADXJesseValue(ADX_BUY_DI_MINUS_ABOVE_PLUS, index);

// Check for invalid/empty values first
    if (buySignal == EMPTY_VALUE) {
        return ADX_SIGNAL_ZERO; // Cannot interpret signal
    }

// Check if below threshold first (this creates the "gap")
    if (buySignal < ADXLevel) {
        return ADX_SIGNAL_BELOW_ZERO;
    }

// CORRECTED ZERO VALUE LOGIC:
// Based on ADX_Jesse code analysis:
// - ExtBuyDIPlusAboveDIMinusBuffer[i] = 0 (reset to default)
// - ExtBuyDIMinusAboveDIPlusBuffer[i] = 0 (reset to default)
// - Only gets main ADX value if DI+ > DI- or DI- > DI+
// - If neither condition is met, both remain 0
// This means "zero value" = when BOTH directional buffers are 0

    bool isPlusAboveZero = !IsZero(buyDIPlusAbove);
    bool isMinusAboveZero = !IsZero(buyDIMinusAbove);

// If BOTH are zero, this indicates no clear directional strength
    if (!isPlusAboveZero && !isMinusAboveZero) {
        return ADX_SIGNAL_ZERO; // "Zero value" - can't match up
    }

// Determine signal based on which DI relationship is active
    if (isPlusAboveZero) {
        return ADX_SIGNAL_BUY;    // +DI above -DI = buy strength (teal)
    }
    else if (isMinusAboveZero) {
        return ADX_SIGNAL_SELL;   // -DI above +DI = sell strength (purple)
    }

// Fallback (should not reach here given the logic above)
    return ADX_SIGNAL_ZERO;
}

//+------------------------------------------------------------------+
//| Interpret Sell ADX strength signal                               |
//+------------------------------------------------------------------+
ADXSignalType GetSellADXSignal(const int index = 0)
{
// Get the main sell ADX signal (MODE_MAIN value)
    double sellSignal = GetADXJesseValue(ADX_SELL_SIGNAL_BUFFER, index);

// Get the directional buffers (these show when DI+ > DI- or DI- > DI+)
    double sellDIPlusAbove = GetADXJesseValue(ADX_SELL_DI_PLUS_ABOVE_MINUS, index);
    double sellDIMinusAbove = GetADXJesseValue(ADX_SELL_DI_MINUS_ABOVE_PLUS, index);

// Check for invalid/empty values first
    if (sellSignal == EMPTY_VALUE) {
        return ADX_SIGNAL_ZERO; // Cannot interpret signal
    }

// Check if below threshold first (this creates the "gap")
    if (sellSignal < ADXLevel) {
        return ADX_SIGNAL_BELOW_ZERO;
    }

// CORRECTED ZERO VALUE LOGIC (same as buy logic):
    bool isPlusAboveZero = !IsZero(sellDIPlusAbove);
    bool isMinusAboveZero = !IsZero(sellDIMinusAbove);

// If BOTH are zero, this indicates no clear directional strength
    if (!isPlusAboveZero && !isMinusAboveZero) {
        return ADX_SIGNAL_ZERO; // "Zero value" - can't match up
    }

// Determine signal based on which DI relationship is active
    if (isPlusAboveZero) {
        return ADX_SIGNAL_BUY;    // +DI above -DI = buy strength (teal)
    }
    else if (isMinusAboveZero) {
        return ADX_SIGNAL_SELL;   // -DI above +DI = sell strength (purple)
    }

// Fallback (should not reach here given the logic above)
    return ADX_SIGNAL_ZERO;
}

//+------------------------------------------------------------------+
//| Check if any ADX component has zero value                        |
//+------------------------------------------------------------------+
bool HasADXZeroValue(const int index = 0)
{
// Get the interpreted signals (these now properly detect zero values)
    ADXSignalType buySignal = GetBuyADXSignal(index);
    ADXSignalType sellSignal = GetSellADXSignal(index);

// OR logic: if EITHER component has zero value, reject trade
    bool hasZeroValue = (buySignal == ADX_SIGNAL_ZERO || sellSignal == ADX_SIGNAL_ZERO);

// Enhanced logging for debugging
    if (hasZeroValue) {
        string buyStr = (buySignal == ADX_SIGNAL_ZERO) ? "ZERO" : "NON-ZERO";
        string sellStr = (sellSignal == ADX_SIGNAL_ZERO) ? "ZERO" : "NON-ZERO";
        PrintLog(__FUNCTION__, StringFormat("Zero value detected at index %d: Buy=%s, Sell=%s",
                                            index, buyStr, sellStr), true);
    }

    return hasZeroValue;
}

//+------------------------------------------------------------------+
//| Check for cross-directional rejection (conflicting signals)      |
//+------------------------------------------------------------------+
bool HasCrossDirectionalConflict(const int orderType, const int index = 0)
{
    ADXSignalType buySignal = GetBuyADXSignal(index);
    ADXSignalType sellSignal = GetSellADXSignal(index);

    if (orderType == OP_BUY || orderType == OP_BUYLIMIT || orderType == OP_BUYSTOP) {
        // Reject buy orders if any ADX signal shows sell strength
        return (buySignal == ADX_SIGNAL_SELL || sellSignal == ADX_SIGNAL_SELL);
    }
    else if (orderType == OP_SELL || orderType == OP_SELLLIMIT || orderType == OP_SELLSTOP) {
        // Reject sell orders if any ADX signal shows buy strength
        return (buySignal == ADX_SIGNAL_BUY || sellSignal == ADX_SIGNAL_BUY);
    }

    return false;
}

//+------------------------------------------------------------------+
//| Check if ADX signals agree for the given order direction         |
//+------------------------------------------------------------------+
bool DoADXSignalsAgree(const int orderType, const int index = 0)
{
    ADXSignalType buySignal = GetBuyADXSignal(index);
    ADXSignalType sellSignal = GetSellADXSignal(index);

    if (orderType == OP_BUY || orderType == OP_BUYLIMIT || orderType == OP_BUYSTOP) {
        // For buy orders: both signals should indicate buy strength
        return (buySignal == ADX_SIGNAL_BUY && sellSignal == ADX_SIGNAL_BUY);
    }
    else if (orderType == OP_SELL || orderType == OP_SELLLIMIT || orderType == OP_SELLSTOP) {
        // For sell orders: both signals should indicate sell strength
        return (buySignal == ADX_SIGNAL_SELL && sellSignal == ADX_SIGNAL_SELL);
    }

    return false;
}

//+------------------------------------------------------------------+
//| Main ADX filter function - returns true if trade is allowed      |
//+------------------------------------------------------------------+
bool IsTradeAllowedByADX(const int orderType, const int index = 0)
{
// If ADX filtering is disabled, allow all trades
    if (!EnableADXForArrowConfirmation) {
        return true;
    }

// Global rejection conditions
    if (IsADXBelowThreshold(index)) {
        return false;  // ADX level below threshold
    }

    if (HasADXZeroValue(index)) {
        return false;  // One or both ADX components have zero value
    }

    if (HasCrossDirectionalConflict(orderType, index)) {
        return false;  // Conflicting directional signals
    }

// Check for agreement between ADX components
    if (!DoADXSignalsAgree(orderType, index)) {
        return false;  // ADX signals don't agree on direction
    }

    return true;  // All checks passed, trade is allowed
}

//+------------------------------------------------------------------+
//| Enhanced: Direct zero value check for debugging                  |
//+------------------------------------------------------------------+
bool CheckDirectionalBuffersForZero(const int index = 0)
{
// Direct check of the directional buffers for debugging purposes
    double buyDIPlusAbove = GetADXJesseValue(ADX_BUY_DI_PLUS_ABOVE_MINUS, index);
    double buyDIMinusAbove = GetADXJesseValue(ADX_BUY_DI_MINUS_ABOVE_PLUS, index);
    double sellDIPlusAbove = GetADXJesseValue(ADX_SELL_DI_PLUS_ABOVE_MINUS, index);
    double sellDIMinusAbove = GetADXJesseValue(ADX_SELL_DI_MINUS_ABOVE_PLUS, index);

    bool buyBothZero = (IsZero(buyDIPlusAbove) && IsZero(buyDIMinusAbove));
    bool sellBothZero = (IsZero(sellDIPlusAbove) && IsZero(sellDIMinusAbove));

    PrintLog(__FUNCTION__, StringFormat("Index %d - Buy DI+:%.4f, DI-:%.4f (both zero:%s) | Sell DI+:%.4f, DI-:%.4f (both zero:%s)",
                                        index, buyDIPlusAbove, buyDIMinusAbove, buyBothZero ? "YES" : "NO",
                                        sellDIPlusAbove, sellDIMinusAbove, sellBothZero ? "YES" : "NO"), true);

    return (buyBothZero || sellBothZero);
}

//+------------------------------------------------------------------+
//| Get ADX filter status for display purposes                       |
//+------------------------------------------------------------------+
string GetADXFilterStatus(const int index = 0)
{
    if (!EnableADXForArrowConfirmation) {
        return "ADX Filter: OFF";
    }

    if (IsADXBelowThreshold(index)) {
        return "ADX Filter: BELOW THRESHOLD";
    }

    if (HasADXZeroValue(index)) {
        return "ADX Filter: ZERO VALUE";
    }

    ADXSignalType buySignal = GetBuyADXSignal(index);
    ADXSignalType sellSignal = GetSellADXSignal(index);

    string buyStr = (buySignal == ADX_SIGNAL_BUY) ? "BUY" :
                    (buySignal == ADX_SIGNAL_SELL) ? "SELL" :
                    (buySignal == ADX_SIGNAL_BELOW_ZERO) ? "BELOW" : "ZERO";

    string sellStr = (sellSignal == ADX_SIGNAL_BUY) ? "BUY" :
                     (sellSignal == ADX_SIGNAL_SELL) ? "SELL" :
                     (sellSignal == ADX_SIGNAL_BELOW_ZERO) ? "BELOW" : "ZERO";

    return StringFormat("ADX Filter: ON (Buy:%s, Sell:%s)", buyStr, sellStr);
}

//+------------------------------------------------------------------+
//| Helper function to convert ADX signal type to string             |
//+------------------------------------------------------------------+
string GetADXSignalTypeString(const ADXSignalType signalType)
{
    switch(signalType) {
    case ADX_SIGNAL_ZERO:
        return "ZERO";
    case ADX_SIGNAL_BUY:
        return "BUY";
    case ADX_SIGNAL_SELL:
        return "SELL";
    case ADX_SIGNAL_BELOW_ZERO:
        return "BELOW_ZERO";
    default:
        return "UNKNOWN";
    }
}

#endif //__ADX_FILTER__
//+------------------------------------------------------------------+
