﻿//+------------------------------------------------------------------+
//|                                            TradingConditions.mqh |
//|                                 Copyright © 2023, barmenteros FX |
//|                                          https://barmenteros.com |
//+------------------------------------------------------------------+
#include "NewsFilter.mqh"
#include "TradingDays.mqh"
#include "TimeManagement.mqh"
#include "SpreadManagement.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ConditionStatus CheckAllConditions(const datetime time_current, const bool& trading_days[7],
                                   ConditionStatus &tradingDayStatus, ConditionStatus &timeManagementStatus,
                                   ConditionStatus &spreadStatus, ConditionStatus &newsStatus)
{
    ConditionStatus result;

    string combinedMessage = "";

// Check News
    newsStatus = CheckNews(time_current);

// Check Trading Day
    tradingDayStatus = IsTradingAllowedOnDay(time_current, trading_days);
    combinedMessage += "\n" + tradingDayStatus.message;

// Check Time Management
    timeManagementStatus = GetTradingInfoWithTimeManagement(time_current);
    combinedMessage += "\n" + timeManagementStatus.message;

// Check Spread
    spreadStatus = GetSpreadInfo();
    combinedMessage += "\n" + spreadStatus.message;

// Add more condition checks here if needed

    combinedMessage += "\nCurrent time: " + TimeToString(time_current);

// Append newsStatus.message at the end for better visual representation in customer messages.
    combinedMessage += newsStatus.message;

// Central decision making
    result.allowTrade = newsStatus.allowTrade && tradingDayStatus.allowTrade &&
                        timeManagementStatus.allowTrade && spreadStatus.allowTrade;

    result.message = combinedMessage;

    return result;
}
//+------------------------------------------------------------------+
