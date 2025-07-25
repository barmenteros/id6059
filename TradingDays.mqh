﻿//+------------------------------------------------------------------+
//|                                                  TradingDays.mqh |
//|                                 Copyright © 2023, barmenteros FX |
//|                                          https://barmenteros.com |
//+------------------------------------------------------------------+
#include <Custom\Development\Logging.mqh>

bool tradingDays[7];

//+------------------------------------------------------------------+
//| Initialize the trading days based on input flags                  |
//+------------------------------------------------------------------+
void InitializeTradingDays(bool& trading_days[7])
{
    trading_days[0] = IN_IsTradingAllowedForSunday;
    trading_days[1] = IN_IsTradingAllowedForMonday;
    trading_days[2] = IN_IsTradingAllowedForTuesday;
    trading_days[3] = IN_IsTradingAllowedForWednesday;
    trading_days[4] = IN_IsTradingAllowedForThursday;
    trading_days[5] = IN_IsTradingAllowedForFriday;
    trading_days[6] = IN_IsTradingAllowedForSaturday;
}

//+------------------------------------------------------------------+
//| Check if trading is allowed on the current day
//+------------------------------------------------------------------+
ConditionStatus IsTradingAllowedOnDay(const datetime time, const bool& trading_days[7])
{
    // Static variable to store the last status
    static ConditionStatus lastStatus;

    ConditionStatus currentStatus;

    // Check if all trading days are set to false
    bool allDaysOff = true;
    for (int i = 0; i < 7; ++i) {
        if (trading_days[i]) {
            allDaysOff = false;
            break;
        }
    }

    if (allDaysOff) {
        currentStatus.message = "Trading Day: OFF";
        currentStatus.allowTrade = false;
    }
    else {
        currentStatus.message = "Trading Day: Yes";
        currentStatus.allowTrade = true;

        int day_of_week = TimeDayOfWeek(time);

        if (!trading_days[day_of_week]) {
            currentStatus.message = "Trading Day: No";
            currentStatus.allowTrade = false;
        }
    }

    // Compare the new status with the last status
    if (currentStatus.allowTrade != lastStatus.allowTrade ||
            StringCompare(currentStatus.message, lastStatus.message) != 0) {

        // The status has changed, so update the last status
        lastStatus = currentStatus;

        // Print the new status for debugging
        string msg = StringFormat("Trading Day Status Changed: %s", currentStatus.message);
        PrintLog(__FUNCTION__, msg);
    }

    return currentStatus;
}
//+------------------------------------------------------------------+
