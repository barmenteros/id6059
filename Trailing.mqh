﻿//+------------------------------------------------------------------+
//|                                                     Trailing.mqh |
//|                                 Copyright © 2023, barmenteros FX |
//|                                          https://barmenteros.com |
//+------------------------------------------------------------------+
#ifndef __TRAILING__
#define __TRAILING__

#include <Custom\Development\Logging.mqh>
#include <Custom\Development\Utils.mqh>
#include "OrderManagement.mqh"
#include "CommonFunctions.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
StopLossInfo FetchStopLoss(const int order_type, const int order_ticket, const bool hidden_stoploss, const double order_stoploss, const string stoploss_line_name)
{
// Initialize the StopLossInfo structure
    StopLossInfo stopLossInfo;
    stopLossInfo.order_stoploss = order_stoploss;
    stopLossInfo.order_stoploss_hidden = 0.0;

// Check for hidden stoploss and fetch it if present
    if (hidden_stoploss) {
        int objectHandle = ObjectFind(0, stoploss_line_name);
        if (objectHandle > -1) {
            double fetchedPrice = ObjectGetDouble(0, stoploss_line_name, OBJPROP_PRICE);
            if (fetchedPrice != 0.0) {
                stopLossInfo.order_stoploss = fetchedPrice;
                stopLossInfo.order_stoploss_hidden = fetchedPrice;
            }
            else {
                string logMessage = StringFormat("Failed to fetch valid price for object: %s", stoploss_line_name);
                PrintLog(__FUNCTION__, logMessage, true);
            }
        }
    }

// Normalize stoploss level
    stopLossInfo.order_stoploss = NormalizeDouble(stopLossInfo.order_stoploss, Digits());

    return stopLossInfo;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailingSL_Breakeven(const double trailing_stop, const double trailing_step, double breakeven, const string comment = "", bool hidden_stoploss = true)
{
// Validate trailing stop and step parameters
    if (trailing_stop < 0 || trailing_step < 0 || trailing_step > trailing_stop) {
        printf(__FUNCTION__ + ": Invalid parameters - trailing stop: %.1f, trailing step: %.1f", trailing_stop, trailing_step);
        return;
    }

// Adjust invalid breakeven value
    if (breakeven < 0) breakeven = 0.0;

// Hidden feature only makes sense if the EA is not running in optimization mode because in this mode the EA cannot create horizontal line objects
    if(IsOptimization()) {
        hidden_stoploss = false;
    }

// Retrieve trading meta-information
    int digits = Digits();
    string symbol = Symbol();

// Loop through all orders in trade pool
    for (int i = CountOrdersInPool(MODE_TRADES) - 1; i >= 0; i--) {
        if (!IsValidOrder (i, symbol, IN_MagicNumber, comment)) continue;

        // Retrieve existing order details
        int order_ticket = OrderTicket();
        int order_type = OrderType();
        datetime order_expiration = OrderExpiration();
        double order_stoploss = OrderStopLoss();
        double order_takeprofit = NormalizeDouble (OrderTakeProfit(), digits);
        double order_open_price = NormalizeDouble (OrderOpenPrice(), digits);

        // Generate stoploss line name
        string stoploss_line_name = StringFormat("%d%s%d", IN_MagicNumber, order_type == OP_BUY ? BUY_SL_LINE_SUFFIX : SELL_SL_LINE_SUFFIX, order_ticket);

        // Fetch stop-loss parameters from the function
        StopLossInfo stopLossParameters = FetchStopLoss(order_type, order_ticket, hidden_stoploss, order_stoploss, stoploss_line_name);

        // Assign the fetched stop-loss parameters to the respective variables
        order_stoploss = stopLossParameters.order_stoploss;
        double order_stoploss_hidden = stopLossParameters.order_stoploss_hidden;

        // Get stop level in points
        double stop_level_in_points = GetSTOPLEVEL(symbol, digits);
        if (stop_level_in_points < 0) continue;

        switch (order_type) {
        case OP_BUY: {
            double bid = GetBID(symbol, digits);
            if (bid < 0) {
                printf("%s: No bid price available for symbol %s", __FUNCTION__, symbol);
                return;
            }

            double threshold = order_open_price + (trailing_stop * Pip());

            // Check if bid price is below or equal to the initial threshold
            if (bid <= NormalizeDouble(threshold, digits)) {
                continue;
            }

            // Adjust threshold based on existing stop loss, if applicable
            if (order_stoploss >= order_open_price) {
                threshold = order_stoploss + (trailing_step * Pip()) + (trailing_stop * Pip());
            }

            // Update stop loss if bid price surpasses the adjusted threshold
            if (bid > NormalizeDouble(threshold, digits)) {
                if (order_stoploss < order_open_price && breakeven > -1) {
                    order_stoploss = order_open_price + (breakeven * Pip());
                }
                else {
                    order_stoploss += (trailing_step * Pip());
                }
            }

            // Normalize stop loss level
            order_stoploss = NormalizeDouble(order_stoploss, digits);

            double minimum_level = bid - (stop_level_in_points * Pip());

            // Ensure the stop loss is not set below the minimum allowable level
            if (order_stoploss > NormalizeDouble(minimum_level, digits))
                order_stoploss = minimum_level;

            // Prevent the stop loss from being set to a lower value if it is not hidden
            if (!hidden_stoploss && order_stoploss < NormalizeDouble(OrderStopLoss(), digits))
                order_stoploss = OrderStopLoss();

            // Prevent the stop loss from being set to a lower value if it is hidden
            if (hidden_stoploss && order_stoploss < NormalizeDouble(order_stoploss_hidden, digits))
                order_stoploss = order_stoploss_hidden;

            break;
        }

        case OP_SELL: {
            double ask = GetASK(symbol, digits);
            if (ask < 0) {
                printf("%s: No ask price available for symbol %s", __FUNCTION__, symbol);
                return;
            }

            double threshold = order_open_price - (trailing_stop * Pip());

            // Check if ask price is above or equal to the initial threshold
            if (ask >= NormalizeDouble(threshold, digits)) {
                return;
            }

            // Adjust threshold based on existing stop loss, if applicable
            if (order_stoploss <= order_open_price && IsNotZero(order_stoploss)) {
                threshold = order_stoploss - (trailing_step * Pip()) - (trailing_stop * Pip());
            }

            // Update stop loss if ask price is below the adjusted threshold
            if (ask < NormalizeDouble(threshold, digits)) {
                if (order_stoploss > order_open_price && breakeven > -1) {
                    order_stoploss = order_open_price - (breakeven * Pip());
                }
                else {
                    order_stoploss -= (trailing_step * Pip());
                }
            }

            // Normalize stop loss level
            order_stoploss = NormalizeDouble(order_stoploss, digits);

            double maximum_level = ask + (stop_level_in_points * Pip());

            // Ensure the stop loss is not set above the maximum allowable level
            if (order_stoploss < NormalizeDouble(maximum_level, digits))
                order_stoploss = maximum_level;

            // Prevent the stop loss from being set to a higher value if it is not hidden
            if (!hidden_stoploss && order_stoploss > NormalizeDouble(OrderStopLoss(), digits))
                order_stoploss = OrderStopLoss();

            // Prevent the stop loss from being set to a higher value if it is hidden
            if (hidden_stoploss && order_stoploss > NormalizeDouble(order_stoploss_hidden, digits))
                order_stoploss = order_stoploss_hidden;

            break;
        }

        case OP_BUYLIMIT:
        case OP_SELLLIMIT:
        case OP_BUYSTOP:
        case OP_SELLSTOP:
            continue;
        default:
            printf("%s: unknown order type", __FUNCTION__);
            return;
        }

        // Normalize the stop loss level
        order_stoploss = NormalizeDouble(order_stoploss, digits);

        // If the stop loss is not hidden, modify the order directly
        if (!hidden_stoploss) {
            CustomOrderModify(order_ticket, order_open_price, order_stoploss, order_takeprofit, order_expiration, digits, clrNONE, 1);
        }

        // If the stop loss is hidden, update the corresponding graphical object
        if (hidden_stoploss &&
                order_stoploss > 0 &&
                order_stoploss != NormalizeDouble(order_stoploss_hidden, digits)) {
            ObjectSetInteger(0, stoploss_line_name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
            ObjectMove(0, stoploss_line_name, 0, TimeCurrent(), order_stoploss);
            printf("%s: Modified order # %d, new SL: %s", __FUNCTION__, order_ticket, DoubleToString(order_stoploss, digits));
        }
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string ManageTrailingStop(InputParameters &extParams)
{
    bool enableTrailStop = extParams.IN_EnableTrailStop;
    TrailStopType trailStopType = extParams.IN_TrailStopType;

// Initialize comment string
    string comment = "";

// Check if trailing stop is enabled
    if (enableTrailStop) {
        double trailStopInPips = 0;
        double trailStepInPips = extParams.IN_TrailStepInPips;
        double breakevenShiftInPips = 0; // Remains 0 if ATR Trail Stop is enabled

        // Determine Trail Stop Type
        if (trailStopType == kATRTrailStop) {
            double atrValue = GetATR(TrailStopATRtimeframe, TrailStopATRPeriod, 1); // Calculate ATR for the previous bar
            trailStopInPips = atrValue * extParams.IN_TrailStopATRMultiplier;
            trailStepInPips = 1; // Setting the trail step to 1 pip for ATR Trail Stop
            comment = StringFormat("\nTrail stop: ON (ATR | multiplier: %g)", extParams.IN_TrailStopATRMultiplier);
        }
        else if (trailStopType == kManualTrailStop) {   // Manual Trail Stop
            trailStopInPips = extParams.IN_TrailStopInPips;
            comment = StringFormat("\nTrail stop: ON (Manual | stop: %g pips, step: %g pips)", trailStopInPips, trailStepInPips);
        }

        // Delete any obsolete hidden levels
        DeleteHiddenLevelsByString("_trail_stop_line@");

        // Execute trailing stop and breakeven logic
        TrailingSL_Breakeven(trailStopInPips, trailStepInPips, breakevenShiftInPips, "", false);
    }
    else {
        // Indicate that trailing stop is disabled
        comment = "\nTrail stop: OFF";
    }

// Return the comment indicating the status of the trailing stop
    return comment;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetTrailingStopStatus(const InputParameters &extParams)
{
    if (!extParams.IN_EnableTrailStop) {
        return "OFF";
    }

    if (extParams.IN_TrailStopType == kATRTrailStop) {
        return StringFormat("ON (ATR | multiplier: %g)", extParams.IN_TrailStopATRMultiplier);
    }

    return StringFormat("ON (Manual | stop: %g, step: %g)",
                        extParams.IN_TrailStopInPips,
                        extParams.IN_TrailStepInPips);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ProcessTimeframeLevelsFromArray(const TimeframeStatus &timeframes[],
                                     const InputParameters &params,
                                     const int customProgramID,
                                     const int index,
                                     double &higherLevels[],
                                     double &lowerLevels[])
{
// Clear the higher and lower levels arrays to avoid conflicts
    ArrayResize(higherLevels, 0);
    ArrayResize(lowerLevels, 0);

// Iterate over the provided timeframes array
    for (int i = 0; i < ArraySize(timeframes); i++) {
        if (!timeframes[i].isEnabled) {
            continue; // Skip if timeframe is not enabled
        }

        // Get the higher and lower levels for the enabled timeframe
        TimeframeLevels levels = GetTimeframeLevels(timeframes[i].timeframe, params, customProgramID, index);

        // Store the levels in their respective arrays
        ArrayResize(higherLevels, ArraySize(higherLevels) + 1);
        ArrayResize(lowerLevels, ArraySize(lowerLevels) + 1);

        higherLevels[ArraySize(higherLevels) - 1] = levels.higher_level;
        lowerLevels[ArraySize(lowerLevels) - 1] = levels.lower_level;
    }

// Sort higher levels in descending order
    ArraySort(higherLevels, WHOLE_ARRAY, 0, MODE_DESCEND);

// Sort lower levels in ascending order
    ArraySort(lowerLevels, WHOLE_ARRAY, 0, MODE_ASCEND);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double FindPreviousBuyLevel(const double price, const double &lowerLevels[])
{
// Ensure there are enough levels to process
    int arraySize = ArraySize(lowerLevels);
    if (arraySize < 2) {
        return -1; // Not enough levels to return a previous one
    }

    double previousLevel = -1; // Variable to store the previous level found
    bool foundPrevious = false; // Flag to track whether a valid previous level was found

// Iterate through the lower levels
    for (int i = 1; i < arraySize; i++) {
        // If the price is at or above the current level
        if (price >= lowerLevels[i]) {
            // Skip over levels that have the same value to handle duplicates
            if (!foundPrevious || lowerLevels[i - 1] != lowerLevels[i]) {
                previousLevel = lowerLevels[i - 1]; // Store the previous level
                foundPrevious = true; // Mark that a previous level was found
            }
        }
        else {
            break; // Exit loop as the current level is not reached or surpassed
        }
    }

    return foundPrevious ? previousLevel : -1; // Return the previous level, or -1 if none found
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double FindPreviousSellLevel(const double price, const double &higherLevels[])
{
// Ensure there are enough levels to process
    int arraySize = ArraySize(higherLevels);
    if (arraySize < 2) {
        return -1; // Not enough levels to return a previous one
    }

    double previousLevel = -1; // Variable to store the previous level found
    bool foundPrevious = false; // Flag to track whether a valid previous level was found

// Iterate through the higher levels
    for (int i = 1; i < arraySize; i++) {
        // If the price is at or below the current level
        if (price <= higherLevels[i]) {
            // Skip over levels that have the same value to handle duplicates
            if (!foundPrevious || higherLevels[i - 1] != higherLevels[i]) {
                previousLevel = higherLevels[i - 1]; // Store the previous level
                foundPrevious = true; // Mark that a previous level was found
            }
        }
        else {
            break; // Exit loop as the current level is not reached or surpassed
        }
    }

    return foundPrevious ? previousLevel : -1; // Return the previous level, or -1 if none found
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ProcessTrailingStopLossAndModifyPositions(
    const TrailStopType &trailStopType,
    const TimeframeStatus &timeframesMHMLMarker[],
    const InputParameters &params,
    const int programID,
    const int magicNumber,
    const string symbol)
{
    if(trailStopType != kLevelTrailStop) {
        return;
    }

// Declare dynamic arrays to store higher and lower levels
    double higherLevels[];
    double lowerLevels[];

// Process the timeframe levels and fill higher and lower levels arrays
    ProcessTimeframeLevelsFromArray(timeframesMHMLMarker, params, programID, 0, higherLevels, lowerLevels);

// Get the previous buy level from the lower levels array
    const double previousBuyLevel = FindPreviousBuyLevel(GetBID(symbol, Digits()), lowerLevels);

// Modify buy positions if a valid previous buy level is found
    if (previousBuyLevel != -1) {
        ModifyAllTypePositions(previousBuyLevel, 0, symbol, Digits(), magicNumber, "", OP_BUY);
    }

// Get the previous sell level from the higher levels array
    const double previousSellLevel = FindPreviousSellLevel(GetBID(symbol, Digits()), higherLevels);

// Modify sell positions if a valid previous sell level is found
    if (previousSellLevel != -1) {
        ModifyAllTypePositions(previousSellLevel, 0, symbol, Digits(), magicNumber, "", OP_SELL);
    }
}

#endif //__TRAILING__
//+------------------------------------------------------------------+
