﻿//+------------------------------------------------------------------+
//|                                              MoneyManagement.mqh |
//|                                 Copyright © 2024, barmenteros FX |
//|                                          https://barmenteros.com |
//+------------------------------------------------------------------+
#include <Custom\Development\Logging.mqh>
#include "OrderManagement.mqh"

// Global constants for naming terminal Global Variables
const string GLOBAL_VAR_PAUSED = (IsTesting() ? "test_" : "") + Symbol() + "_TradingPaused";
const string GLOBAL_VAR_PAUSE_END_TIME = (IsTesting() ? "test_" : "") + Symbol() + "_PauseEndTime";

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetBuyCurrentLotSize()
{
    return Buy_CurrentLotSize;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetSellCurrentLotSize()
{
    return Sell_CurrentLotSize;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetBuyCurrentLotSize(const double newLotSize)
{
    Buy_CurrentLotSize = fmax(newLotSize, Buy_IN_InitialLots); // Make sure lot size is never below the initial value
    PrintLog(__FUNCTION__, StringFormat("Buy lot size updated to %.2f", Buy_CurrentLotSize));
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetSellCurrentLotSize(const double newLotSize)
{
    Sell_CurrentLotSize = fmax(newLotSize, Sell_IN_InitialLots); // Make sure lot size is never below the initial value
    PrintLog(__FUNCTION__, StringFormat("Sell lot size updated to %.2f", Sell_CurrentLotSize));
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/*
MONEY MANAGEMENT SYSTEM DOCUMENTATION
Initially coded according "THA KAD - ZARIUM CORE EA Money Management System.docx"
but later adjusted according "How Negative Equity Works.docx"
*/
void CheckEquityTargets(InputParameters &params)
{
// Get current account equity and initial balance
    const double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    const double initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);

    int slippage = 5;
    string symbol = Symbol();
    int digits = Digits();

// Initialize targets if they haven't been set yet
    if (nextPositiveEquityTarget == 0.0 && EnablePositiveEquityTarget) {
        nextPositiveEquityTarget = initialBalance + PositiveEquityTarget;
        PrintLog(__FUNCTION__, StringFormat("Initial positive equity target set to %.2f", nextPositiveEquityTarget));
    }

    if (nextNegativeEquityTarget == 0.0 && EnableNegativeEquityLimit) {
        nextNegativeEquityTarget = initialBalance - NegativeEquityLimit;
        PrintLog(__FUNCTION__, StringFormat("Initial negative equity target set to %.2f", nextNegativeEquityTarget));
    }

// Check if there are any actual open trades (not pending orders)
    int actualOpenTradesCount = 0;
    for (int i = 0; i < OrdersTotal(); i++) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if (OrderSymbol() == symbol && OrderMagicNumber() == IN_MagicNumber &&
                    (OrderType() == OP_BUY || OrderType() == OP_SELL)) {
                actualOpenTradesCount++;
            }
        }
    }

// Get the current order counts using the existing function
    OrderCounts counts = GetOrderCounts(IN_MagicNumber);

// Check if Positive Equity Target is enabled and current equity exceeds the next positive target
// Only proceed if there are actual market orders open
    if (EnablePositiveEquityTarget && currentEquity >= nextPositiveEquityTarget &&
            lastReachedPositiveTarget < nextPositiveEquityTarget &&
            (counts.totalBuys > 0 || counts.totalSells > 0)) {
        // Log the event
        PrintLog(__FUNCTION__, StringFormat("Positive equity target %.2f reached. Closing all trades.", nextPositiveEquityTarget));

        // Close/Delete all trades
        CloseAll(symbol, digits, IN_MagicNumber, slippage, "", 1, ALL_ORDERS, clrGoldenrod);
        DeleteAllTypePositions(ALL_ORDERS);

        // Get the broker's lot step size (usually 0.01 but can vary by broker)
        double lotStep = MarketInfo(symbol, MODE_LOTSTEP);

        // Increment the lot size when positive equity target is reached
        // Using the formula from the documentation: Current Lot Size + (LotStep × PositiveEquityLotSizeIncrement)
        SetBuyCurrentLotSize(GetBuyCurrentLotSize() + (lotStep * PositiveEquityLotSizeIncrement));
        SetSellCurrentLotSize(GetSellCurrentLotSize() + (lotStep * PositiveEquityLotSizeIncrement));

        PrintLog(__FUNCTION__, StringFormat("Lot sizes increased: Buy=%.2f, Sell=%.2f",
                                            GetBuyCurrentLotSize(), GetSellCurrentLotSize()));

        // Increment the multipliers when positive equity target is reached
        CurrentBuyOrderMultiplier += (int)MathRound(PositiveMultiplierIncrement);
        CurrentSellOrderMultiplier += (int)MathRound(PositiveMultiplierIncrement);

        PrintLog(__FUNCTION__, StringFormat("Multipliers increased: Buy=%d, Sell=%d",
                                            CurrentBuyOrderMultiplier, CurrentSellOrderMultiplier));

        // Store this target as reached
        lastReachedPositiveTarget = nextPositiveEquityTarget;

        // Update the next recurring positive target according to documentation:
        // - If recurring target is enabled, use that value for subsequent targets
        // - Otherwise use the regular positive target
        if (EnableRecurringPositiveTargetIncrement && RecurringPositiveTargetIncrement > 0) {
            nextPositiveEquityTarget += RecurringPositiveTargetIncrement;
        }
        else {
            nextPositiveEquityTarget += PositiveEquityTarget;
        }

        PrintLog(__FUNCTION__, StringFormat("Next positive equity target set to %.2f", nextPositiveEquityTarget));

        // Pause trading if reentry is not allowed
        if (!EquityTargetAllowReentry) {
            PauseTrading(EquityTargetPauseDuration);
        }
    }

// Check if Negative Equity Limit is enabled and current equity drops below the negative target
// Only proceed if there are actual market orders open
    if (EnableNegativeEquityLimit && currentEquity <= nextNegativeEquityTarget &&
            (counts.totalBuys > 0 || counts.totalSells > 0)) {
        // Log the event
        PrintLog(__FUNCTION__, StringFormat("Negative equity limit %.2f reached. Closing trades in loss.", nextNegativeEquityTarget));

        // Use the enhanced function to close losing trades efficiently
        // Target 100% of the NegativeEquityLimit with the acceptable range of 90-110%
        bool tradesClosedSuccessfully = CloseAllLossesEfficiently(
                                            symbol, digits, IN_MagicNumber, slippage, "", 1, ALL_ORDERS, clrGoldenrod, 1.0);

        // Only proceed with the lot size and multiplier adjustments if trades were actually closed
        if (tradesClosedSuccessfully) {
            // Get the broker's lot step size
            double lotStep = MarketInfo(symbol, MODE_LOTSTEP);
            double minLot = MarketInfo(symbol, MODE_MINLOT);

            // Calculate new lot sizes using the formula from the documentation:
            // Implementation for fixed lot size
            // Formula: Current Lot Size - (Negative Equity Lot Size Decrement × Initial Lot Size)
            double newBuyLotSize;
            double newSellLotSize;

            if (Buy_IN_LotSizingOptions == kManualLots) {
                // Fixed lot size calculation
                newBuyLotSize = MathMax(GetBuyCurrentLotSize() - (NegativeEquityLotSizeDecrement * Buy_IN_InitialLots), minLot);
            }
            else {
                // Percentage-based calculation for free margin or equity
                double currentPercentage = (Buy_IN_LotSizingOptions == kPercentFreeMargin) ?
                                           params.Buy_IN_PercentFreeMargin : params.Buy_IN_PercentEquity;
                double initialPercentage = (Buy_IN_LotSizingOptions == kPercentFreeMargin) ?
                                           Buy_IN_PercentFreeMargin : Buy_IN_PercentEquity;
                double newPercentage = MathMax(currentPercentage - (NegativeEquityLotSizeDecrement * initialPercentage), 0.0);

                // Store the adjusted percentage
                if (Buy_IN_LotSizingOptions == kPercentFreeMargin) {
                    params.Buy_IN_PercentFreeMargin = newPercentage;
                }
                else {
                    params.Buy_IN_PercentEquity = newPercentage;
                }

                // Calculate the equivalent lot size
                double entry_price = 0;
                double sl_price = 0;
                PositionInfo buyPosition = CalculateOrderLots(
                                               Buy_IN_LotSizingOptions,
                                               params.Buy_IN_PercentFreeMargin,
                                               params.Buy_IN_PercentEquity,
                                               Buy_IN_InitialLots,
                                               OP_BUY,
                                               entry_price,
                                               sl_price,
                                               AC_Ratio_Limit,
                                               AC_Ratio_Actual);

                newBuyLotSize = buyPosition.LotSize;
            }

            // Repeat the same logic for Sell lot size
            if (Sell_IN_LotSizingOptions == kManualLots) {
                newSellLotSize = MathMax(GetSellCurrentLotSize() - (NegativeEquityLotSizeDecrement * Sell_IN_InitialLots), minLot);
            }
            else {
                double currentPercentage = (Sell_IN_LotSizingOptions == kPercentFreeMargin) ?
                                           params.Sell_IN_PercentFreeMargin : params.Sell_IN_PercentEquity;
                double initialPercentage = (Sell_IN_LotSizingOptions == kPercentFreeMargin) ?
                                           Sell_IN_PercentFreeMargin : Sell_IN_PercentEquity;
                double newPercentage = MathMax(currentPercentage - (NegativeEquityLotSizeDecrement * initialPercentage), 0.0);

                if (Sell_IN_LotSizingOptions == kPercentFreeMargin) {
                    params.Sell_IN_PercentFreeMargin = newPercentage;
                }
                else {
                    params.Sell_IN_PercentEquity = newPercentage;
                }

                double entry_price = 0;
                double sl_price = 0;
                PositionInfo sellPosition = CalculateOrderLots(
                                                Sell_IN_LotSizingOptions,
                                                params.Sell_IN_PercentFreeMargin,
                                                params.Sell_IN_PercentEquity,
                                                Sell_IN_InitialLots,
                                                OP_SELL,
                                                entry_price,
                                                sl_price,
                                                AC_Ratio_Limit,
                                                AC_Ratio_Actual);

                newSellLotSize = sellPosition.LotSize;
            }

            SetBuyCurrentLotSize(newBuyLotSize);
            SetSellCurrentLotSize(newSellLotSize);

            PrintLog(__FUNCTION__, StringFormat("Lot sizes decreased: Buy=%.2f, Sell=%.2f",
                                                GetBuyCurrentLotSize(), GetSellCurrentLotSize()));

            // Decrement the multipliers but ensure at least one direction has a multiplier of at least 1
            int newBuyMultiplier = MathMax(CurrentBuyOrderMultiplier - (int)MathRound(NegativeMultiplierDecrement), 0);
            int newSellMultiplier = MathMax(CurrentSellOrderMultiplier - (int)MathRound(NegativeMultiplierDecrement), 0);

            // Ensure at least one direction has a multiplier of at least 1
            if (newBuyMultiplier == 0 && newSellMultiplier == 0) {
                // If both would be 0, decide which one to set to 1 based on context
                // For this implementation, we'll arbitrarily choose the buy multiplier
                newBuyMultiplier = 1;
            }

            CurrentBuyOrderMultiplier = newBuyMultiplier;
            CurrentSellOrderMultiplier = newSellMultiplier;

            PrintLog(__FUNCTION__, StringFormat("Multipliers decreased: Buy=%d, Sell=%d",
                                                CurrentBuyOrderMultiplier, CurrentSellOrderMultiplier));

            // Update the next negative target
            // We offset from the current equity to ensure consistent behavior
            nextNegativeEquityTarget = currentEquity - NegativeEquityLimit;
            PrintLog(__FUNCTION__, StringFormat("Next negative equity target set to %.2f", nextNegativeEquityTarget));

            // Pause trading if reentry is not allowed
            if (!EquityTargetAllowReentry) {
                PauseTrading(EquityTargetPauseDuration);
            }
        }
    }
}
//+------------------------------------------------------------------+
//| Function: PauseTrading                                            |
//| Purpose:  Pauses trading for a specified duration.                |
//+------------------------------------------------------------------+
void PauseTrading(const int minutes)
{
// Record the pause start time
    const datetime pauseStartTime = TimeCurrent();

// Calculate the pause end time
    const datetime pauseEndTime = pauseStartTime + (minutes * 60); // Ensure proper calculation

// Set global variables for trading pause state
    GlobalVariableSet(GLOBAL_VAR_PAUSED, 1);
    GlobalVariableSet(GLOBAL_VAR_PAUSE_END_TIME, pauseEndTime);

// Update TradingActive flag immediately
    TradingActive = false;

// Log the pause event
    PrintLog(__FUNCTION__, StringFormat("Trading paused for %d minutes. Will resume at %s.",
                                        minutes, TimeToString(pauseEndTime, TIME_DATE | TIME_MINUTES)));
}
//+------------------------------------------------------------------+
//| Function: ResumeTrading                                           |
//| Purpose:  Checks if trading can be resumed and updates state.     |
//+------------------------------------------------------------------+
bool ResumeTrading()
{
// If trading isn't paused, return true immediately
    if (GlobalVariableCheck(GLOBAL_VAR_PAUSED) == false || GlobalVariableGet(GLOBAL_VAR_PAUSED) != 1) {
        return true;
    }

// Get the current time
    datetime currentTime = TimeCurrent();
    datetime pauseEndTime = (datetime)GlobalVariableGet(GLOBAL_VAR_PAUSE_END_TIME);

// Check if the pause has ended
    if (currentTime >= pauseEndTime) {
        // Resume trading by clearing the paused state
        GlobalVariableSet(GLOBAL_VAR_PAUSED, 0);
        PrintLog(__FUNCTION__, StringFormat("Trading resumed at %s after pause.",
                                            TimeToString(currentTime, TIME_DATE | TIME_MINUTES)));
        return true; // Trading is active
    }

// Optional periodic logging (once per hour)
    static datetime lastLogTime = 0;
    if (currentTime - lastLogTime > 3600) { // Every hour
        PrintLog(__FUNCTION__, StringFormat("Trading paused. Current time: %s, Resume time: %s",
                                            TimeToString(currentTime, TIME_DATE | TIME_MINUTES),
                                            TimeToString(pauseEndTime, TIME_DATE | TIME_MINUTES)));
        lastLogTime = currentTime;
    }

    return false; // Still paused
}
//+------------------------------------------------------------------+
//| Function: CheckUnrealizedProfit                                   |
//| Purpose:  Closes individual trades when their unrealized profit   |
//|           reaches or exceeds the specified UnrealizedProfitExit   |
//|           value.                                                  |
//+------------------------------------------------------------------+
void CheckUnrealizedProfit()
{
// Check if the Unrealized Profit Exit feature is enabled
    if (!EnableUnrealizedProfitExit) return;

    int slippage = 5;
    string symbol = Symbol();
    int digits = Digits();

// Loop through all open orders
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue; // Skip if the order cannot be selected

        if (OrderType() > OP_SELL) continue; // Skip if the order is not a buy or sell order

        // Calculate the unrealized profit
        double unrealizedProfit = OrderProfit() + OrderSwap() + OrderCommission();

        // Check if the unrealized profit exceeds the exit threshold
        if (unrealizedProfit < UnrealizedProfitExit) continue; // Skip if the unrealized profit is below the threshold

        // Log the event
        PrintLog(__FUNCTION__, StringFormat("Closing trade %d as unrealized profit reached %.2f.", OrderTicket(), unrealizedProfit));

        // Close the trade
        const bool result = (ClosePosition(OrderTicket(), symbol, digits, slippage, 3, clrGoldenrod) == 1);

        // Handle close failure if needed
        if (!result) {
            PrintLog(__FUNCTION__, StringFormat("Failed to close order: %d. Error: %d", OrderTicket(), GetLastError()));
        }
    }
}
//+------------------------------------------------------------------+
