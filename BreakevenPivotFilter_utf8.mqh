//+------------------------------------------------------------------+
//|                                         BreakevenPivotFilter.mqh |
//|                                 Copyright © 2024, barmenteros FX |
//|                                          https://barmenteros.com |
//+------------------------------------------------------------------+

#ifndef __BREAKEVEN_PIVOT_FILTER__
#define __BREAKEVEN_PIVOT_FILTER__

#include <Custom\Development\Logging.mqh>

//+------------------------------------------------------------------+
//| Structure to hold higher and lower levels for a timeframe         |
//+------------------------------------------------------------------+
struct TimeframeLevels {
    double           higher_level; // Stores the higher level
    double           lower_level;  // Stores the lower level

    // Constructor to initialize the structure with default values
                     TimeframeLevels()
    {
        higher_level = -1.0;
        lower_level = -1.0;
    }
};
//+------------------------------------------------------------------+
//| Routine to check if the breakeven pivot filter allows a Buy order |
//| Arguments:                                                       |
//|  - isBreakevenPivotEnabled: Indicates if the breakeven pivot filter is enabled |
//|  - totalBuyOrders: Number of current buy orders                   |
//|  - timeframe: Timeframe to get levels for                        |
//|  - params: Input parameters structure used by the custom function |
//|  - customProgramID: Custom program identifier                     |
//|  - index: Bar index (0 for the current bar)                       |
//|  - lowestThresholdPercentage: Percentage for the lowest threshold |
//|  - highestThresholdPercentage: Percentage for the highest threshold|
//|  - price: Price to be checked                                     |
//| Returns true if the Buy order is allowed according to the filter, |
//| otherwise false.                                                  |
//+------------------------------------------------------------------+
bool IsBuyOrderAllowedWithBreakevenPivot(
    const bool isBreakevenPivotEnabled,
    const int totalBuyOrders,
    const ENUM_TIMEFRAMES timeframe,
    const InputParameters &params,
    const int customProgramID,
    const int index,
    const double lowestThresholdPercentage,
    const double highestThresholdPercentage,
    const double price)
{
// If breakeven pivot filter is disabled, allow buy order unconditionally
    if (!isBreakevenPivotEnabled) {
        PrintLog(__FUNCTION__, "BE Pivot Filter disabled - BUY allowed", true);
        return true;
    }

    PrintLog(__FUNCTION__, StringFormat("BUY ORDER CHECK: Price=%.5f, TotalBuyOrders=%d, LowestThreshold=%.1f%%, HighestThreshold=%.1f%%",
                                        price, totalBuyOrders, lowestThresholdPercentage, highestThresholdPercentage), true);

// If there are no current buy orders, check the price against the lowest threshold percentage
    if (totalBuyOrders < 1) {
        PrintLog(__FUNCTION__, StringFormat("No existing buy orders - checking against LOWEST threshold %.1f%%", lowestThresholdPercentage), true);
        bool inBuyZone = IsPriceInBuyZone(timeframe, params, customProgramID, index, lowestThresholdPercentage, price);
        PrintLog(__FUNCTION__, StringFormat("BUY decision (no existing orders): %s", inBuyZone ? "ALLOWED" : "BLOCKED"), true);
        return inBuyZone;
    }

// Adjust the highestThresholdPercentage for the Buy side using (100 - highestThresholdPercentage)
    double adjustedHighestThresholdPercentage = 100.0 - highestThresholdPercentage;
    PrintLog(__FUNCTION__, StringFormat("Existing buy orders detected - checking against ADJUSTED threshold %.1f%% (100-%%.1f)",
                                        adjustedHighestThresholdPercentage, highestThresholdPercentage), true);

// If there is at least one buy order, check the price against the adjusted highest threshold percentage
    bool inAdjustedBuyZone = IsPriceInBuyZone(timeframe, params, customProgramID, index, adjustedHighestThresholdPercentage, price);
    PrintLog(__FUNCTION__, StringFormat("BUY decision (with existing orders): %s", inAdjustedBuyZone ? "ALLOWED" : "BLOCKED"), true);
    return inAdjustedBuyZone;
}
//+------------------------------------------------------------------+
//| Routine to check if the breakeven pivot filter allows a Sell order |
//| Arguments:                                                        |
//|  - isBreakevenPivotEnabled: Indicates if the breakeven pivot filter is enabled |
//|  - totalSellOrders: Number of current sell orders                 |
//|  - timeframe: Timeframe to get levels for                         |
//|  - params: Input parameters structure used by the custom function |
//|  - customProgramID: Custom program identifier                     |
//|  - index: Bar index (0 for the current bar)                       |
//|  - lowestThresholdPercentage: Percentage for the lowest threshold |
//|  - highestThresholdPercentage: Percentage for the highest threshold|
//|  - price: Price to be checked                                     |
//| Returns true if the Sell order is allowed according to the filter, |
//| otherwise false.                                                  |
//+------------------------------------------------------------------+
bool IsSellOrderAllowedWithBreakevenPivot(
    const bool isBreakevenPivotEnabled,
    const int totalSellOrders,
    const ENUM_TIMEFRAMES timeframe,
    const InputParameters &params,
    const int customProgramID,
    const int index,
    const double lowestThresholdPercentage,
    const double highestThresholdPercentage,
    const double price)
{
// If breakeven pivot filter is disabled, allow sell order unconditionally
    if (!isBreakevenPivotEnabled) {
        PrintLog(__FUNCTION__, "BE Pivot Filter disabled - SELL allowed", true);
        return true;
    }

    PrintLog(__FUNCTION__, StringFormat("SELL ORDER CHECK: Price=%.5f, TotalSellOrders=%d, LowestThreshold=%.1f%%, HighestThreshold=%.1f%%",
                                        price, totalSellOrders, lowestThresholdPercentage, highestThresholdPercentage), true);

// If there are no current sell orders, check the price against the highest threshold percentage
    if (totalSellOrders < 1) {
        PrintLog(__FUNCTION__, StringFormat("No existing sell orders - checking against HIGHEST threshold %.1f%%", highestThresholdPercentage), true);
        bool inSellZone = IsPriceInSellZone(timeframe, params, customProgramID, index, highestThresholdPercentage, price);
        PrintLog(__FUNCTION__, StringFormat("SELL decision (no existing orders): %s", inSellZone ? "ALLOWED" : "BLOCKED"), true);
        return inSellZone;
    }

// Adjust the lowestThresholdPercentage for the Sell side using (100 - lowestThresholdPercentage)
    double adjustedLowestThresholdPercentage = 100.0 - lowestThresholdPercentage;
    PrintLog(__FUNCTION__, StringFormat("Existing sell orders detected - checking against ADJUSTED threshold %.1f%% (100-%.1f)",
                                        adjustedLowestThresholdPercentage, lowestThresholdPercentage), true);

// If there is at least one sell order, check the price against the adjusted lowest threshold percentage
    bool inAdjustedSellZone = IsPriceInSellZone(timeframe, params, customProgramID, index, adjustedLowestThresholdPercentage, price);
    PrintLog(__FUNCTION__, StringFormat("SELL decision (with existing orders): %s", inAdjustedSellZone ? "ALLOWED" : "BLOCKED"), true);
    return inAdjustedSellZone;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsPriceBelowOrEqual(const double price, const double level_price)
{
// Check if the price is below or equal to the level price
    return price <= level_price;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsPriceAboveOrEqual(const double price, const double level_price)
{
// Check if the price is above or equal to the level price
    return price >= level_price;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsPriceInBuyZone(const ENUM_TIMEFRAMES timeframe,
                      const InputParameters &params,
                      const int customProgramID,
                      const int index,
                      const double percentage,
                      const double price)
{
// Static variables to track last logging
    static datetime lastLogTime = 0;

// Get the higher and lower levels using the provided function
    TimeframeLevels levels = GetTimeframeLevels(timeframe, params, customProgramID, index);

    PrintLog(__FUNCTION__, StringFormat("BUY ZONE CHECK: Price=%.5f, Percentage=%.1f%%, Higher=%.5f, Lower=%.5f",
                                        price, percentage, levels.higher_level, levels.lower_level), true);

// Validate that the levels were fetched successfully (levels should not be -1)
    if(levels.higher_level <= 0.0 || levels.lower_level <= 0.0 ||
            levels.higher_level == EMPTY_VALUE || levels.lower_level == EMPTY_VALUE) {

        // Only log once per bar
        datetime currentBarTime = Time[0];
        if(currentBarTime != lastLogTime) {
            PrintLog(__FUNCTION__, StringFormat(": Invalid higher or lower levels: %.5f, %.5f",
                                                levels.higher_level, levels.lower_level), true);
            lastLogTime = currentBarTime;
        }
        return false; // Exit if levels are invalid
    }

// CORRECTED: Buy zone should be calculated from lower_level upward
    double percentage_level = levels.lower_level + ((levels.higher_level - levels.lower_level) * (percentage / 100.0));

    PrintLog(__FUNCTION__, StringFormat("BUY ZONE CALC: Range=%.5f, Distance=%.5f, ThresholdLevel=%.5f",
                                        (levels.higher_level - levels.lower_level),
                                        ((levels.higher_level - levels.lower_level) * (percentage / 100.0)),
                                        percentage_level), true);

// Check if the price is within the buy zone (below or equal to the percentage level)
    bool result = IsPriceBelowOrEqual(price, percentage_level);
    PrintLog(__FUNCTION__, StringFormat("BUY ZONE RESULT: Price %.5f %s ThresholdLevel %.5f = %s",
                                        price,
                                        (price <= percentage_level) ? "<=" : ">",
                                        percentage_level,
                                        result ? "IN BUY ZONE" : "NOT IN BUY ZONE"), true);
    return result;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsPriceInSellZone(const ENUM_TIMEFRAMES timeframe,
                       const InputParameters &params,
                       const int customProgramID,
                       const int index,
                       const double percentage,
                       const double price)
{
// Static variables to track last logging
    static datetime lastLogTime = 0;

// Get the higher and lower levels using the provided function
    TimeframeLevels levels = GetTimeframeLevels(timeframe, params, customProgramID, index);

    PrintLog(__FUNCTION__, StringFormat("SELL ZONE CHECK: Price=%.5f, Percentage=%.1f%%, Higher=%.5f, Lower=%.5f",
                                        price, percentage, levels.higher_level, levels.lower_level), true);

// Validate that the levels were fetched successfully (levels should not be -1)
    if(levels.higher_level <= 0.0 || levels.lower_level <= 0.0 ||
            levels.higher_level == EMPTY_VALUE || levels.lower_level == EMPTY_VALUE) {

        // Only log once per bar
        datetime currentBarTime = Time[0];
        if(currentBarTime != lastLogTime) {
            PrintLog(__FUNCTION__, StringFormat(": Invalid higher or lower levels: %.5f, %.5f",
                                                levels.higher_level, levels.lower_level), true);
            lastLogTime = currentBarTime;
        }
        return false; // Exit if levels are invalid
    }

// CORRECTED: Sell zone should be calculated from higher_level downward
    double percentage_level = levels.higher_level - ((levels.higher_level - levels.lower_level) * (percentage / 100.0));

    PrintLog(__FUNCTION__, StringFormat("SELL ZONE CALC: Range=%.5f, Distance=%.5f, ThresholdLevel=%.5f",
                                        (levels.higher_level - levels.lower_level),
                                        ((levels.higher_level - levels.lower_level) * (percentage / 100.0)),
                                        percentage_level), true);

// Check if the price is within the sell zone (above or equal to the percentage level)
    bool result = IsPriceAboveOrEqual(price, percentage_level);
    PrintLog(__FUNCTION__, StringFormat("SELL ZONE RESULT: Price %.5f %s ThresholdLevel %.5f = %s",
                                        price,
                                        (price >= percentage_level) ? ">=" : "<",
                                        percentage_level,
                                        result ? "IN SELL ZONE" : "NOT IN SELL ZONE"), true);
    return result;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
TimeframeLevels GetTimeframeLevels(const ENUM_TIMEFRAMES timeframe,
                                   const InputParameters &params,
                                   const int customProgramID,
                                   const int index)
{
    TimeframeLevels levels; // Initialize structure to hold the levels
    int higher_buffer = -1; // Buffer for higher levels
    int lower_buffer = -1;  // Buffer for lower levels

// Map the timeframe to the corresponding buffers for higher and lower levels
    switch(timeframe) {
    case PERIOD_M1:
        higher_buffer = 0;
        lower_buffer = 9;
        break;
    case PERIOD_M5:
        higher_buffer = 1;
        lower_buffer = 10;
        break;
    case PERIOD_M15:
        higher_buffer = 2;
        lower_buffer = 11;
        break;
    case PERIOD_M30:
        higher_buffer = 3;
        lower_buffer = 12;
        break;
    case PERIOD_H1:
        higher_buffer = 4;
        lower_buffer = 13;
        break;
    case PERIOD_H4:
        higher_buffer = 5;
        lower_buffer = 14;
        break;
    case PERIOD_D1:
        higher_buffer = 6;
        lower_buffer = 15;
        break;
    case PERIOD_W1:
        higher_buffer = 7;
        lower_buffer = 16;
        break;
    case PERIOD_MN1:
        higher_buffer = 8;
        lower_buffer = 17;
        break;
    default:
        Print(__FUNCTION__, ": Unsupported timeframe.");
        return levels; // Return default values if the timeframe is unsupported
    }

// Get the higher and lower levels using the GetMH_ML_Marker function
    levels.higher_level = GetMH_ML_Marker(params, customProgramID, higher_buffer, index);
    levels.lower_level = GetMH_ML_Marker(params, customProgramID, lower_buffer, index);

    return levels;
}
//+------------------------------------------------------------------+
//| Checks if a trade should be allowed based on Maximum Entry Threshold
//| Returns true if trade should be allowed, false otherwise
//+------------------------------------------------------------------+
bool IsTradeAllowedByMaxEntryThreshold(
    const bool enableMaxEntryThreshold,
    const double maxEntryThresholdPercent,
    const int orderType,
    const double currentPrice,
    const double takeProfitLevel)
{
// If the feature is disabled or take profit level is invalid, allow trade
    if (!enableMaxEntryThreshold || takeProfitLevel <= 0.0) {
        return true;
    }

// Normalize the price and take profit level
    double normalizedPrice = NormalizeDouble(currentPrice, _Digits);
    double normalizedTP = NormalizeDouble(takeProfitLevel, _Digits);

// For buy orders: ensure price isn't too close to or above take profit
    if (orderType == OP_BUY || orderType == OP_BUYSTOP || orderType == OP_BUYLIMIT) {
        // Calculate threshold where price is considered too close to take profit
        // TP must be higher than price for buy orders
        if (normalizedTP <= normalizedPrice) {
            return false; // TP is below current price, don't allow trade
        }

        // Calculate the threshold distance (price point beyond which trades shouldn't be opened)
        double thresholdPrice = normalizedTP - ((normalizedTP - normalizedPrice) * maxEntryThresholdPercent);

        // If current price is beyond threshold (too close to TP), don't allow trade
        return normalizedPrice < thresholdPrice;
    }
// For sell orders: ensure price isn't too close to or below take profit
    else if (orderType == OP_SELL || orderType == OP_SELLSTOP || orderType == OP_SELLLIMIT) {
        // Calculate threshold where price is considered too close to take profit
        // TP must be lower than price for sell orders
        if (normalizedTP >= normalizedPrice) {
            return false; // TP is above current price, don't allow trade
        }

        // Calculate the threshold distance (price point beyond which trades shouldn't be opened)
        double thresholdPrice = normalizedTP + ((normalizedPrice - normalizedTP) * maxEntryThresholdPercent);

        // If current price is beyond threshold (too close to TP), don't allow trade
        return normalizedPrice > thresholdPrice;
    }

    return true; // Default case for other order types
}

#endif  // __BREAKEVEN_PIVOT_FILTER__
//+------------------------------------------------------------------+
