﻿//+------------------------------------------------------------------+
//|                                             SpreadManagement.mqh |
//|                                 Copyright © 2023, barmenteros FX |
//|                                          https://barmenteros.com |
//+------------------------------------------------------------------+
#include <Custom\Development\Logging.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ConditionStatus GetSpreadInfo(void)
{
    // Static variable to store the last status
    static ConditionStatus lastStatus;

    ConditionStatus currentStatus;
    currentStatus.allowTrade = true;

    if (IN_EnableSpreadControl) {
        long spread_value = SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
        currentStatus.message = "Spread: " + IntegerToString(spread_value);

        if (spread_value > (int)IN_MaximumSpread) {
            currentStatus.allowTrade = false;
            string maxSpreadStr = IntegerToString(IN_MaximumSpread);
            currentStatus.message += " (above maximum allowed " + maxSpreadStr + ")";
        }
    }
    else {
        currentStatus.allowTrade = true;
        currentStatus.message = "Spread: OFF";
    }

    // Compare the new status with the last status
    if (currentStatus.allowTrade != lastStatus.allowTrade ||
            StringCompare(currentStatus.message, lastStatus.message) != 0) {

        // The status has changed, so update the last status
        lastStatus = currentStatus;

        // Only print the new status for debugging if spread_value is greater than the maximum allowed spread
        if (!currentStatus.allowTrade) {
            string msg = StringFormat("Spread Status Changed: %s", currentStatus.message);
            PrintLog(__FUNCTION__, msg, false);
        }
    }

    return currentStatus;
}
//+------------------------------------------------------------------+
