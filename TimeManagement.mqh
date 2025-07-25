﻿//+------------------------------------------------------------------+
//|                                               TimeManagement.mqh |
//|                                 Copyright © 2023, barmenteros FX |
//|                                          https://barmenteros.com |
//+------------------------------------------------------------------+
#include <Custom\Development\Logging.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsTradingTime(const string start_time, const string end_time, const string current_time)
{
    if(start_time == "" || end_time == "") {
        return true;
    }

    datetime startTime = StringToTime(start_time);
    datetime endTime = StringToTime(end_time);
    datetime currentTime = StringToTime(current_time);

    if(currentTime < startTime || currentTime >= endTime) {
        return false;
    }

    return true;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ConditionStatus GetTradingInfoWithTimeManagement(const datetime time_current)
{
    // Static variable to store the last status
    static ConditionStatus lastStatus;

    ConditionStatus currentStatus;

    // Default values
    currentStatus.message = "Time Management: OFF";
    currentStatus.allowTrade = true;

    if (IN_EnableTimeManagement) {
        string trading_start_time_txt = StringFormat("%d:%s", IN_TradingStartHour, IntegerToString(IN_TradingStartMinutes, 2, '0'));
        string trading_end_time_txt = StringFormat("%d:%s", IN_TradingEndHour, IntegerToString(IN_TradingEndMinutes, 2, '0'));

        if (IsTradingTime(trading_start_time_txt, trading_end_time_txt, TimeToString(time_current, TIME_MINUTES))) {
            currentStatus.message = "Time Management: Current trading hours";
            currentStatus.allowTrade = true;
        }
        else {
            currentStatus.message = "Time Management: Current non-trading hours";
            currentStatus.allowTrade = false;
        }
    }

    // Compare the new status with the last status
    if (currentStatus.allowTrade != lastStatus.allowTrade ||
            StringCompare(currentStatus.message, lastStatus.message) != 0) {

        // The status has changed, so update the last status
        lastStatus = currentStatus;

        // Print the new status for debugging
        string msg = StringFormat("Time Management Status Changed: %s", currentStatus.message);
        PrintLog(__FUNCTION__, msg);
    }

    return currentStatus;
}
//+------------------------------------------------------------------+
