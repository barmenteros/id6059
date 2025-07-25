﻿//+------------------------------------------------------------------+
//|                                                 PositionSize.mqh |
//|                                 Copyright © 2023, barmenteros FX |
//|                                          https://barmenteros.com |
//+------------------------------------------------------------------+
#include <Custom\Development\Logging.mqh>

struct PositionInfo {
    double           LotSize;
    string           lotSizingDescription;
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetAdjustedBalance(const double balance, const int ratioLimit, const int ratioActual)
{
// For all invalid cases, use most conservative valid ratio (2:100 = 2%)
// to protect against excessive position sizing
    if(ratioLimit < 2) {
        PrintLog(__FUNCTION__, "Ratio limit must be at least 2, using minimum 2:100", true);
        return (2.0 / 100.0) * balance;
    }

    if(ratioActual > 100) {
        PrintLog(__FUNCTION__, "Ratio actual cannot exceed 100, using 2:100", true);
        return (2.0 / 100.0) * balance;
    }

    if(ratioActual <= 0) {
        PrintLog(__FUNCTION__, "Invalid ratio actual value, using 2:100", true);
        return (2.0 / 100.0) * balance;
    }

// Normal case: calculate actual ratio
    return (ratioLimit / (double)ratioActual) * balance;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PositionInfo CalculateOrderLots(const LotSizingOptions _LotSizingOptions,
                                const double _PercentFreeMargin,
                                const double _PercentEquity,
                                const double _InitialLots,
                                const int order_type,
                                const double entry_price,
                                const double sl_price,
                                const int ratioLimit,
                                const int ratioActual)
{
    PositionInfo result;
    result.LotSize = 0.0;
    bool debug = true;

    if(_LotSizingOptions == kPercentFreeMargin) {
        double moneyToRisk = positionCalculator.CalculateMoneyToRisk(_PercentFreeMargin, kModeFreeMargin, 0);
        UsableBalanceAmount = GetAdjustedBalance(moneyToRisk, ratioLimit, ratioActual);
        result.LotSize = positionCalculator.CalculatePositionSize(order_type, entry_price, sl_price, Symbol(), UsableBalanceAmount, debug);
        result.lotSizingDescription = StringFormat("\nLot Sizing: Percent Free Margin (%s%%)", DoubleToString(_PercentFreeMargin, 2));
    }
    else if(_LotSizingOptions == kPercentEquity) {
        double moneyToRisk = positionCalculator.CalculateMoneyToRisk(_PercentEquity, kModeEquity, 0);
        UsableBalanceAmount = GetAdjustedBalance(moneyToRisk, ratioLimit, ratioActual);
        result.LotSize = positionCalculator.CalculatePositionSize(order_type, entry_price, sl_price, Symbol(), UsableBalanceAmount, debug);
        result.lotSizingDescription = StringFormat("\nLot Sizing: Percent Equity (%s%%)", DoubleToString(_PercentEquity, 2));
    }
    else {
        result.LotSize = _InitialLots;
        result.lotSizingDescription = StringFormat("\nLot Sizing: Manual (%s)", DoubleToString(_InitialLots, 2));
    }

    return result;
}
//+------------------------------------------------------------------+
