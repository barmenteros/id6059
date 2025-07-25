﻿//+------------------------------------------------------------------+
//|                                                ReverseFilter.mqh |
//|                                 Copyright © 2023, barmenteros FX |
//|                                          https://barmenteros.com |
//+------------------------------------------------------------------+
#ifndef __REVERSE_FILTER__
#define __REVERSE_FILTER__

#include <Custom\Development\Logging.mqh>
#include "HorizontalLineOperations.mqh"
#include "OrderManagement.mqh"

// Global variables for reverse counters
int reverseCounterForBuys;
int reverseCounterForSells;

// Implementing functions for setting, getting, and resetting reverse counters
void setReverseCounterForBuys(int value)
{
    reverseCounterForBuys = value;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void setReverseCounterForSells(int value)
{
    reverseCounterForSells = value;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getReverseCounterForBuys()
{
    return reverseCounterForBuys;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getReverseCounterForSells()
{
    return reverseCounterForSells;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void resetReverseCounterForBuys()
{
    reverseCounterForBuys = 0;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void resetReverseCounterForSells()
{
    reverseCounterForSells = 0;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool InitializeReverseLines()
{
    bool buyReverseOrderCreated = CreateHorizontalLine(0,
                                  buyReverseOrderLineName,
                                  0,
                                  Open[0],
                                  IN_BuyReverseOrderLineColor,
                                  OBJ_NO_PERIODS, //initially hidden
                                  STYLE_DOT,
                                  1,
                                  false,
                                  true,
                                  false,
                                  0,
                                  buyReverseOrderLineStruct);

    bool sellReverseOrderCreated = CreateHorizontalLine(0,
                                   sellReverseOrderLineName,
                                   0,
                                   Open[0],
                                   IN_SellReverseOrderLineColor,
                                   OBJ_NO_PERIODS, //initially hidden
                                   STYLE_DOT,
                                   1,
                                   false,
                                   true,
                                   false,
                                   0,
                                   sellReverseOrderLineStruct);

    return buyReverseOrderCreated && sellReverseOrderCreated;
}
/**
 * This function tracks and logs the number of times the current price touches or falls below a monitored level
 * after initially moving a specified number of pips above that level. The function maintains an internal counter
 * and a flag to track the state between function calls. When the current price meets the specified conditions,
 * the counter is incremented, and relevant details are logged.
 */
void TrackPriceTouchesAboveLevel(const double current_price, const double last_price, const double monitored_level, const int number_pips)
{
    static bool aboveThreshold = false;  // Static flag to indicate if the price has gone above the threshold

// Calculate and normalize the threshold price for monitoring
    double thresholdPrice = NormalizeDouble(monitored_level + (fabs(number_pips) * Pip()), _Digits);

// Normalize the current and last prices
    double normalizedCurrentPrice = NormalizeDouble(current_price, _Digits);
    double normalizedLastPrice = NormalizeDouble(last_price, _Digits);

// Check if the current price has gone above the threshold
    if (normalizedCurrentPrice >= thresholdPrice) {
        aboveThreshold = true;
    }

// Check if the current price has touched or fallen below the monitored level after going above the threshold
    if (normalizedCurrentPrice <= monitored_level && aboveThreshold) {
        int currentCounter = getReverseCounterForSells();
        currentCounter++; // Increment the counter
        setReverseCounterForSells(currentCounter);
        aboveThreshold = false;  // Reset the flag for the next cycle

        // Log and inform the user about the counter increment and other details
        string logMessage = StringFormat("Monitored level: %s, Number of pips: %d, Threshold: %s, Last Price: %s, Current Price: %s. Sell counter value: %d",
                                         DoubleToString(monitored_level, _Digits),
                                         number_pips,
                                         DoubleToString(thresholdPrice, _Digits),
                                         DoubleToString(normalizedLastPrice, _Digits),
                                         DoubleToString(normalizedCurrentPrice, _Digits),
                                         getReverseCounterForSells());
        PrintLog(__FUNCTION__, logMessage);
    }
}
/**
 * This function tracks and logs the number of times the current price touches or rises above a monitored level
 * after initially moving a specified number of pips below that level. The function maintains an internal counter
 * and a flag to track the state between function calls. When the current price meets the specified conditions,
 * the counter is incremented, and relevant details are logged.
 */
void TrackPriceTouchesBelowLevel(const double current_price, const double last_price, const double monitored_level, const int number_pips)
{
    static bool belowThreshold = false;  // Static flag to indicate if the price has gone below the threshold

// Calculate and normalize the threshold price for monitoring
    double thresholdPrice = NormalizeDouble(monitored_level - (fabs(number_pips) * Pip()), _Digits);

// Normalize the current and last prices
    double normalizedCurrentPrice = NormalizeDouble(current_price, _Digits);
    double normalizedLastPrice = NormalizeDouble(last_price, _Digits);

// Check if the current price has gone below the threshold
    if (normalizedCurrentPrice <= thresholdPrice) {
        belowThreshold = true;
    }

// Check if the current price has touched or risen above the monitored level after going below the threshold
    if (normalizedCurrentPrice >= monitored_level && belowThreshold) {
        int currentCounter = getReverseCounterForBuys();
        currentCounter++; // Increment the counter
        setReverseCounterForBuys(currentCounter);
        belowThreshold = false;  // Reset the flag for the next cycle

        // Log and inform the user about the counter increment and other details
        string logMessage = StringFormat("Monitored level: %s, Number of pips: %d, Threshold: %s, Last Price: %s, Current Price: %s. Buy counter value: %d",
                                         DoubleToString(monitored_level, _Digits),
                                         number_pips,
                                         DoubleToString(thresholdPrice, _Digits),
                                         DoubleToString(normalizedLastPrice, _Digits),
                                         DoubleToString(normalizedCurrentPrice, _Digits),
                                         getReverseCounterForBuys());
        PrintLog(__FUNCTION__, logMessage);
    }
}
//+------------------------------------------------------------------+
//| Updates a counter for tracking price touches below a "sell reverse order line"
//| after the price has moved a specific number of pips above it.
//+------------------------------------------------------------------+
void UpdateSellReverseFilterCounter(const double lastPrice, const double currentPrice)
{
// Check if the sell reverse order line is currently visible
    bool isShownSellReverseLine = IsHorizontalLineVisible(0, sellReverseOrderLineName, sellReverseOrderLineStruct);

// If the line is visible, proceed with further logic
    if (isShownSellReverseLine) {

        // Find the last buy order that does not include the string "reverse" in its comment
        int lastDeviationBuy = GetLastOrder("reverse", kMustExcludeString, OP_BUY, MODE_TRADES, LAST_ORDER_BY_TICKET);

        // If such a buy order exists, select it and proceed
        if (lastDeviationBuy > 0 && OrderSelect(lastDeviationBuy, SELECT_BY_TICKET)) {

            // Retrieve the open price of the last buy order
            double buyOpenPrice = OrderOpenPrice();

            // Get the price level of the sell reverse order line
            double sellReversePrice = GetHorizontalLinePriceLevel(0, sellReverseOrderLineName, sellReverseOrderLineStruct);

            // Calculate the number of pips above the sell reverse order line relative to the buy open price
            int pips_above_monitoring_level = (int) ((sellReversePrice - buyOpenPrice) / Pip());

            // Update the counter based on the current and last prices, and the calculated number of pips above the sell reverse order line
            TrackPriceTouchesAboveLevel(currentPrice, lastPrice, sellReversePrice, pips_above_monitoring_level);
        }
    }
}
//+------------------------------------------------------------------+
//| Updates a counter for tracking price touches above a "buy reverse order line"
//| after the price has moved a specific number of pips below it.
//+------------------------------------------------------------------+
void UpdateBuyReverseFilterCounter(const double lastPrice, const double currentPrice)
{
// Check if the buy reverse order line is currently visible
    bool isShownBuyReverseLine = IsHorizontalLineVisible(0, buyReverseOrderLineName, buyReverseOrderLineStruct);

// If the line is visible, proceed with further logic
    if (isShownBuyReverseLine) {

        // Find the last sell order that does not include the string "reverse" in its comment
        int lastDeviationSell = GetLastOrder("reverse", kMustExcludeString, OP_SELL, MODE_TRADES, LAST_ORDER_BY_TICKET);

        // If such a sell order exists, select it and proceed
        if (lastDeviationSell > 0 && OrderSelect(lastDeviationSell, SELECT_BY_TICKET)) {

            // Retrieve the open price of the last sell order
            double sellOpenPrice = OrderOpenPrice();

            // Get the price level of the buy reverse order line
            double buyReversePrice = GetHorizontalLinePriceLevel(0, buyReverseOrderLineName, buyReverseOrderLineStruct);

            // Calculate the number of pips below the buy reverse order line relative to the sell open price
            int pips_below_monitoring_level = (int) ((sellOpenPrice - buyReversePrice) / Pip());

            // Update the counter based on the current and last prices, and the calculated number of pips below the buy reverse order line
            TrackPriceTouchesBelowLevel(currentPrice, lastPrice, buyReversePrice, pips_below_monitoring_level);
        }
    }
}
//+------------------------------------------------------------------+
//| Evaluates and executes reverse buy orders based on set conditions.
//| If the reverse counter exceeds a specified threshold, the function
//| will either place multiple buy orders or hide the reverse buy line
//| and reset the counter, depending on the re-entry settings.
//+------------------------------------------------------------------+
string EvaluateAndExecuteReverseBuy(const double lastPrice,
                                    const double currentPrice,
                                    const InputParameters &params)
{
    string comment = "";

// Check and update the drawing of the reverse buy line
    CheckSellAndDrawReverseBuy();

// Update the counter for tracking price touches above the "buy reverse order line"
    UpdateBuyReverseFilterCounter(lastPrice, currentPrice);

// Retrieve the current value of the buy reverse filter counter
    int buyReverseFilterCounter = getReverseCounterForBuys();

// Append Reverse Filter status to comment
    comment = StringFormat("Reverse Buy Filter: %d out of %d", buyReverseFilterCounter, params.IN_ReverseBuyFilterCounter);

// Evaluate the counter against the configured threshold
    if (buyReverseFilterCounter >= params.IN_ReverseBuyFilterCounter) {

        // If reverse re-entry is enabled, attempt to open multiple buy orders
        if (params.IN_EnableReverseReentry) {
            double entry_price = 0;
            double sl_price = 0;
            PositionInfo initialPosition = CalculateOrderLots(
                                               Reverse_Buy_IN_LotSizingOptions,
                                               Reverse_Buy_IN_PercentFreeMargin,
                                               Reverse_Buy_IN_PercentEquity,
                                               Reverse_Buy_IN_InitialLots,
                                               OP_BUY,
                                               entry_price,
                                               sl_price,
                                               params.AC_Ratio_Limit,
                                               params.AC_Ratio_Actual);

            // Create detailed reason message
            string orderReason = StringFormat("Reverse buy filter counter (%d) reached threshold (%d) - Opening reverse buy orders",
                                              buyReverseFilterCounter, params.IN_ReverseBuyFilterCounter);

            // Log the reason
            PrintLog("ORDER_REASON", orderReason + " - Opening reverse buy orders", true);

            int ticket = OpenMultipleBuyOrders(initialPosition.LotSize, IN_ReverseBuyStopLoss, 0, false, "reverse", orderReason);

            // If the buy orders were not successfully opened, append to comment
            if (ticket <= 0) {
                return comment;
            }
        }

        // Common operations: Hide the reverse buy line and reset the counter
        HideHorizontalLine(0, buyReverseOrderLineName, buyReverseOrderLineStruct);
        resetReverseCounterForBuys();
    }

    return comment;
}
//+------------------------------------------------------------------+
//| Evaluates and executes reverse sell orders based on set conditions.
//| If the reverse counter exceeds a specified threshold, the function
//| will either place multiple sell orders or hide the reverse sell line
//| and reset the counter, depending on the re-entry settings.
//+------------------------------------------------------------------+
string EvaluateAndExecuteReverseSell(const double lastPrice,
                                     const double currentPrice,
                                     const InputParameters &params)
{
    string comment = "";

// Check and update the drawing of the reverse sell line
    CheckBuyAndDrawReverseSell();

// Update the counter for tracking price touches below the "sell reverse order line"
    UpdateSellReverseFilterCounter(lastPrice, currentPrice);

// Retrieve the current value of the sell reverse filter counter
    int sellReverseFilterCounter = getReverseCounterForSells();

// Append Reverse Filter status to comment
    comment = StringFormat("Reverse Sell Filter: %d out of %d", sellReverseFilterCounter, params.IN_ReverseSellFilterCounter);

// Evaluate the counter against the configured threshold
    if (sellReverseFilterCounter >= params.IN_ReverseSellFilterCounter) {

        // If reverse re-entry is enabled, attempt to open multiple sell orders
        if (params.IN_EnableReverseReentry) {
            double entry_price = 0;
            double sl_price = 0;
            PositionInfo initialPosition = CalculateOrderLots(
                                               Reverse_Sell_IN_LotSizingOptions,
                                               Reverse_Sell_IN_PercentFreeMargin,
                                               Reverse_Sell_IN_PercentEquity,
                                               Reverse_Sell_IN_InitialLots,
                                               OP_SELL,
                                               entry_price,
                                               sl_price,
                                               params.AC_Ratio_Limit,
                                               params.AC_Ratio_Actual);

            // Create detailed reason message
            string orderReason = StringFormat("Reverse sell filter counter (%d) reached threshold (%d) - Opening reverse sell orders",
                                              sellReverseFilterCounter, params.IN_ReverseSellFilterCounter);

            // Log the reason
            PrintLog("ORDER_REASON", orderReason + " - Opening reverse sell orders", true);

            int ticket = OpenMultipleSellOrders(initialPosition.LotSize, IN_ReverseSellStopLoss, 0, false, "reverse", orderReason);

            // If the sell orders were not successfully opened, append to comment
            if (ticket <= 0) {
                return comment;
            }
        }

        // Common operations: Hide the reverse sell line and reset the counter
        HideHorizontalLine(0, sellReverseOrderLineName, sellReverseOrderLineStruct);
        resetReverseCounterForSells();
    }

    return comment;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckBuyAndDrawReverseSell()
{
// Get the ticket number of the last buy order
    int last_buy_ticket = GetLastOrder("reverse", kMustExcludeString, OP_BUY, MODE_TRADES, LAST_ORDER_BY_TICKET);

// If a buy order exists with a valid ticket number
    if(last_buy_ticket > 0 && OrderSelect(last_buy_ticket, SELECT_BY_TICKET)) {

        // Get the open price of the buy order
        double order_open_price = OrderOpenPrice();

        // Get the ticket number of the last sell order with "reverse" in the comment field
        int last_sell_ticket = GetLastOrder("reverse", kMustIncludeString, OP_SELL, MODE_TRADES, LAST_ORDER_BY_TICKET);

        // If no sell order exists with "reverse" in the comment field
        if(last_sell_ticket <= 0) {

            // Calculate the price at which to draw the sell reverse order line
            double sell_order_price = order_open_price - (IN_SellReverseEntryDeviation * Pip());

            // Draw the sell reverse order line
            MoveHorizontalLine(0, sellReverseOrderLineName, sell_order_price, sellReverseOrderLineStruct);
            ShowHorizontalLine(0, sellReverseOrderLineName, sellReverseOrderLineStruct);
        }
        else if(OrderSelect(last_sell_ticket, SELECT_BY_TICKET)) {
            HideHorizontalLine(0, sellReverseOrderLineName, sellReverseOrderLineStruct);
            resetReverseCounterForSells();
        }
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckSellAndDrawReverseBuy()
{
// Get the ticket number of the last sell order
    int last_sell_ticket = GetLastOrder("reverse", kMustExcludeString, OP_SELL, MODE_TRADES, LAST_ORDER_BY_TICKET);

// If a sell order exists with a valid ticket number
    if(last_sell_ticket > 0 && OrderSelect(last_sell_ticket, SELECT_BY_TICKET)) {

        // Get the open price of the sell order
        double order_open_price = OrderOpenPrice();

        // Get the ticket number of the last buy order with "reverse" in the comment field
        int last_buy_ticket = GetLastOrder("reverse", kMustIncludeString, OP_BUY, MODE_TRADES, LAST_ORDER_BY_TICKET);

        // If no buy order exists with "reverse" in the comment field
        if(last_buy_ticket <= 0) {

            // Calculate the price at which to draw the buy reverse order line
            double buy_order_price = order_open_price + (IN_BuyReverseEntryDeviation * Pip());

            // Draw the buy reverse order line
            MoveHorizontalLine(0, buyReverseOrderLineName, buy_order_price, buyReverseOrderLineStruct);
            ShowHorizontalLine(0, buyReverseOrderLineName, buyReverseOrderLineStruct);
        }
        else if(OrderSelect(last_buy_ticket, SELECT_BY_TICKET)) {
            HideHorizontalLine(0, buyReverseOrderLineName, buyReverseOrderLineStruct);
            resetReverseCounterForBuys();
        }
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ManageReverseOrderLines(const int totalBuys, const int totalSells)
{
// Check if there are no open Buy orders
    if (totalBuys < 1) {
        // Hide the reverse sell line and reset the sell reverse counter
        HideHorizontalLine(0, sellReverseOrderLineName, sellReverseOrderLineStruct);
        resetReverseCounterForSells();
    }

// Check if there are no open Sell orders
    if (totalSells < 1) {
        // Hide the reverse buy line and reset the buy reverse counter
        HideHorizontalLine(0, buyReverseOrderLineName, buyReverseOrderLineStruct);
        resetReverseCounterForBuys();
    }
}

#endif  // __REVERSE_FILTER__
//+------------------------------------------------------------------+
