﻿//+------------------------------------------------------------------+
//|                                              OrderManagement.mqh |
//|                                 Copyright © 2023, barmenteros FX |
//|                                          https://barmenteros.com |
//+------------------------------------------------------------------+
#ifndef __ORDER_MANAGEMENT__
#define __ORDER_MANAGEMENT__

#include <Custom\Development\Logging.mqh>
#include "HorizontalLineOperations.mqh"
#include "ArrowSignals.mqh"
#include "GlobalSettings.mqh"

struct OrderCounts {
    int              totalOrders;
    int              totalBuys;
    int              totalSells;
    int              totalBuystops;
    int              totalSellstops;
    int              totalBuylimits;
    int              totalSelllimits;
};
enum NewOrderDetected {
    NoNewOrder,
    MarketOrder,
    StopOrder,
    LimitOrder
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountOrdersInPool(const int orderPool = MODE_TRADES)
{
    return (orderPool == MODE_TRADES ? OrdersTotal() : OrdersHistoryTotal());
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsValidComment(const string comment,
                    const string commentSubstring,
                    const CommentCheckType commentCheckCondition)
{
// Early return if commentSubstring is empty
    if (commentSubstring == "") {
        return true;
    }

// Check for the inclusion of a substring
    if (commentCheckCondition == kMustIncludeString) {
        return StringFind(comment, commentSubstring) >= 0;
    }

// Check for the exclusion of a substring
    if (commentCheckCondition == kMustExcludeString) {
        return StringFind(comment, commentSubstring) < 0;
    }

// Default case, should not reach here
    return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsValidOrder(const int orderIndex,
                  const string symbolFilter = "",
                  const int magicNumberFilter = -1,
                  const string commentMatchString = "",
                  const CommentCheckType commentCheckCondition = kMustIncludeString,
                  const int orderPool = MODE_TRADES,
                  const int selectFlag = SELECT_BY_POS)
{
    if (!OrderSelect(orderIndex, selectFlag, orderPool)) {
        //printf("%s: Order selection failed", __FUNCTION__);
        return false;
    }

    if (symbolFilter != "" && StringFind(OrderSymbol(), symbolFilter) < 0) {
        //printf("%s: Symbol filter mismatch", __FUNCTION__);
        return false;
    }

    if (magicNumberFilter != -1 && OrderMagicNumber() != magicNumberFilter) {
        //printf("%s: Magic number filter mismatch", __FUNCTION__);
        return false;
    }

    if (!IsValidComment(OrderComment(), commentMatchString, commentCheckCondition)) {
        //printf("%s: Comment validation failed", __FUNCTION__);
        return false;
    }

    return true;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsOrderMatch(const int order_type_filter, const int order_type)
{
    switch(order_type_filter) {
    case ALL_ORDERS:
        return(true);
    case ONLY_MARKET:
        return(order_type < OP_BUYLIMIT);
    case ONLY_PENDING:
        return(order_type > OP_SELL);
    case ONLY_BUY_ANY:
        return(order_type % 2 == 0);
    case ONLY_SELL_ANY:
        return(order_type % 2 == 1);
    case OP_BUY:
    case OP_SELL:
    case OP_BUYLIMIT:
    case OP_SELLLIMIT:
    case OP_BUYSTOP:
    case OP_SELLSTOP:
        return(order_type == order_type_filter);
    default:
        printf(__FUNCTION__ + ": unknown order type filter");
        return(false);
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetLastOrder(const string comment_match_string = "",
                 const CommentCheckType comment_check_condition = kMustIncludeString,
                 const int order_type_filter = ALL_ORDERS,
                 const int order_pool = MODE_TRADES,
                 const int select_by = LAST_ORDER_BY_TICKET)
{

    datetime prev_order_time = 0;
    int prev_order_ticket = -1;
    int last_order_ticket = -1;

    for (int i = CountOrdersInPool(order_pool); i >= 0; i--) {

        if(!IsValidOrder(i, Symbol(), IN_MagicNumber, comment_match_string, comment_check_condition, order_pool)) continue;

        datetime order_open_time = OrderOpenTime();
        datetime order_close_time = OrderCloseTime();
        int order_ticket = OrderTicket();

        if(!IsOrderMatch(order_type_filter, OrderType())) continue;

        datetime order_time = (order_pool == MODE_TRADES ? order_open_time : order_close_time);

        switch(select_by) {
        case LAST_ORDER_BY_TIME:
            if(order_time <= prev_order_time) {
                continue;
            }
            else { //order_time > prev_order_time
                prev_order_time = order_time;
                last_order_ticket = order_ticket;
            }
            break;
        case LAST_ORDER_BY_TICKET:
            if(order_ticket < prev_order_ticket) {
                continue;
            }
            else { //order_ticket >= prev_order_ticket
                prev_order_ticket = order_ticket;
                last_order_ticket = order_ticket;
            }
            break;
        default:
            printf(__FUNCTION__ + ": wrong function parameter");
            break;
        }
    }

    return(last_order_ticket);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetASK(const string symbol, const int digits)
{
    double ask = -1.0;

    if (StringLen(symbol) == 0) {
        string msg = "Invalid or empty symbol.";
        PrintLog(__FUNCTION__, msg);
        return -1.0;
    }

// Requesting info from the current symbol
    if (symbol == NULL || symbol == _Symbol) {
        RefreshRates();
        ask = Ask;
    }

// Fail getting info
    if (ask < 0) {
        ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    }

// Normalize and check for errors
    ask = NormalizeDouble(ask, digits);
    if (ask <= NormalizeDouble(0.0, digits)) {
        string msg = StringFormat("Failed to get Ask price for %s.", symbol);
        PrintLog(__FUNCTION__, msg);
        ask = -1.0;
    }

    return ask;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetBID(const string symbol, const int digits)
{
    double bid = -1.0;

    if (StringLen(symbol) == 0) {
        string msg = "Invalid or empty symbol.";
        PrintLog(__FUNCTION__, msg);
        return -1.0;
    }

// Requesting info from the current symbol
    if (symbol == NULL || symbol == _Symbol) {
        RefreshRates();
        bid = Bid;
    }

// Fail getting info
    if (bid < 0) {
        bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    }

// Normalize and check for errors
    bid = NormalizeDouble(bid, digits);
    if (bid <= NormalizeDouble(0.0, digits)) {
        string msg = StringFormat("Failed to get Bid price for %s.", symbol);
        PrintLog(__FUNCTION__, msg);
        bid = -1.0;
    }

    return bid;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PrintErrorMsg(const string s_function_name, const string s_txt, int i_err = -1)
{
    string s_ErrorMsg = "";
    s_ErrorMsg = ErrorDescription (i_err < 0 ? GetLastError() : i_err);
    Print (s_function_name, ": ", s_txt, " (", s_ErrorMsg, ")");
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CustomOrdersTotal(int &ordersTotalArray[], const string symbolFilter = "",
                      const int magicNumberFilter = -1, const string commentFilter = "",
                      const int poolMode = MODE_TRADES)
{
// Define constants for array indices for better readability
    const int BUY_INDEX = 0, SELL_INDEX = 1, BUY_LIMIT_INDEX = 2,
              SELL_LIMIT_INDEX = 3, BUY_STOP_INDEX = 4, SELL_STOP_INDEX = 5;

// Initialize counters
    int totalCounter = 0;
    int orderTypeCounters[6];
    ArrayInitialize(orderTypeCounters, 0);

// Loop through each order in the pool
    for (int index = 0; index < CountOrdersInPool(poolMode); index++) {
        if (!IsValidOrder(index, symbolFilter, magicNumberFilter, commentFilter, true, poolMode)) {
            continue;
        }

        // Increment counters based on the order type
        switch (OrderType()) {
        case OP_BUY:
            orderTypeCounters[BUY_INDEX]++;
            break;
        case OP_SELL:
            orderTypeCounters[SELL_INDEX]++;
            break;
        case OP_BUYLIMIT:
            orderTypeCounters[BUY_LIMIT_INDEX]++;
            break;
        case OP_SELLLIMIT:
            orderTypeCounters[SELL_LIMIT_INDEX]++;
            break;
        case OP_BUYSTOP:
            orderTypeCounters[BUY_STOP_INDEX]++;
            break;
        case OP_SELLSTOP:
            orderTypeCounters[SELL_STOP_INDEX]++;
            break;
        default:
            printf("%s: unknown order type", __FUNCTION__);
            break;
        }

        // Increment total order counter
        totalCounter++;
    }

// Resize and populate the output array
    if (ArrayResize(ordersTotalArray, 6) == -1) {
        printf("%s: failed to resize output array", __FUNCTION__);
        return -1;
    }

    ArrayCopy(ordersTotalArray, orderTypeCounters);

// Return total order count
    return totalCounter;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
OrderCounts GetOrderCounts(const int magicNumber)
{
    OrderCounts counts;

    int ordersTotalArray[6];
    counts.totalOrders = CustomOrdersTotal(ordersTotalArray, Symbol(), magicNumber, "");

    counts.totalBuys = ordersTotalArray[0];
    counts.totalSells = ordersTotalArray[1];
    counts.totalBuylimits = ordersTotalArray[2];
    counts.totalSelllimits = ordersTotalArray[3];
    counts.totalBuystops = ordersTotalArray[4];
    counts.totalSellstops = ordersTotalArray[5];

    return counts;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsMajorCurrency(string symbol)
{
    string sa_MajorCurrencies[8] = {"USD", "EUR", "JPY", "GBP",
                                    "CHF", "CAD", "AUD", "NZD"
                                   };
    string sa_SuffPrefToAvoid[4] = {"DJ_", "BUND", "XAU", "XAG"};
    StringToUpper (symbol);
    int i = 0;
    for (i = 0; i < 8; i++) {
        if (StringFind (symbol, sa_MajorCurrencies[i]) >= 0)
            return (true);
    }
    /*
          for (i=0; i<4; i++) {
                if (StringFind (symbol, sa_SuffPrefToAvoid[i]) >= 0)
                      return (false);
          }
    */
    return (false);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double AdjustPoint1(const string _symbol, const int digits, const double point)
{
    double d_pip = -1.0;
    d_pip = point;
    bool b_IsMajorCurrency = true;
    b_IsMajorCurrency = IsMajorCurrency (_symbol);
    if (b_IsMajorCurrency &&
            (digits % 2) == 1)
        d_pip *= 10.0;
    if (!b_IsMajorCurrency)
        d_pip *= MathPow (10, digits);

    return (NormalizeDouble (d_pip, digits));
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double AdjustPoint2(const string _symbol, const int digits, const double point)
{
    double d_pip = -1.0;
    d_pip = point;
    bool b_IsMajorCurrency = true;
    b_IsMajorCurrency = IsMajorCurrency (_symbol);
    if (b_IsMajorCurrency &&
            (digits % 2) == 1)
        d_pip *= 0.1;
    if (!b_IsMajorCurrency)
        d_pip *= (1.0 / MathPow (10, digits));

    return (d_pip);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsTradeContextFree(int i_retries = 3)
{
    while (!IsTradeAllowed() &&
            i_retries > 0) {
        if (IsStopped()) {
            Print (__FUNCTION__, ": program commanded to stop");
            return (false);
        }
        RandomSleep (SLEEP_MEAN, SLEEP_MAX);
        i_retries--;
    }
    if (!IsTradeAllowed()) { //trade is not yet allowed
        Print (__FUNCTION__, ": trade context is busy at ", TimeCurrent());
        return (false);
    }
    return (true);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetMINLOT(const string symbol)
{
    double d_MinLotSize = -1.0;
    d_MinLotSize = SymbolInfoDouble (symbol, SYMBOL_VOLUME_MIN);
    d_MinLotSize = NormalizeDouble (d_MinLotSize, 2);
    if (d_MinLotSize < NormalizeDouble (0.0, 2))
        Print (__FUNCTION__, ": fail getting min. lot for ", symbol);
    return (NormalizeDouble (d_MinLotSize, 2));
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetMAXLOT(const string symbol)
{
    double d_MaxLotSize = -1.0;
    d_MaxLotSize = SymbolInfoDouble (symbol, SYMBOL_VOLUME_MAX);
    d_MaxLotSize = NormalizeDouble (d_MaxLotSize, 2);
    if (d_MaxLotSize < NormalizeDouble (0.0, 2))
        Print (__FUNCTION__, ": fail getting max. lot for ", symbol);
    return (NormalizeDouble (d_MaxLotSize, 2));
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetLOTSTEP(const string symbol)
{
    double d_LotStep = -1.0;
    d_LotStep = SymbolInfoDouble (symbol, SYMBOL_VOLUME_STEP);
    d_LotStep = NormalizeDouble (d_LotStep, 2);
    if (d_LotStep <= NormalizeDouble (0.0, 2)) {
        Print (__FUNCTION__, ": step not available for ", symbol);
        return (-1.0);
    }
    return (NormalizeDouble (d_LotStep, 2));
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetSTOPLEVEL(const string symbol, const int digits, const bool b_return_pip = true)
{
    double d_StopLevel = -1.0;
    d_StopLevel = (double)SymbolInfoInteger (symbol, SYMBOL_TRADE_STOPS_LEVEL);
    if (d_StopLevel < 0) {
        Print (__FUNCTION__, ": stop level not available for ", symbol);
        return (d_StopLevel);
    }
    if (b_return_pip)
        d_StopLevel = AdjustPoint2 (symbol, digits, d_StopLevel);
    return (d_StopLevel);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double ChkLots(const string symbol, double d_lots, int i_type_ord = -1, const bool b_recalc_mode = false )
{
    double d_MinLot = -1.0;
    d_MinLot = GetMINLOT (symbol);
    if (d_MinLot < 0)
        return (0.0);
    double d_MaxLot = -1.0;
    d_MaxLot = GetMAXLOT (symbol);
    if (d_MaxLot < 0)
        return (d_MinLot);
    double d_LotStep = -1.0;
    d_LotStep = GetLOTSTEP (symbol);
    if (d_LotStep < 0)
        return (d_MinLot);
//---- Adjust lot size
    d_lots = MathRound (d_lots / d_LotStep) * d_LotStep;
    d_lots = NormalizeDouble (d_lots, 2);

    if (d_lots < d_MinLot) {
        d_lots = d_MinLot;
        string logMsg = StringFormat("lots set to minimum (%s)", DoubleToStr(d_lots, 2));
        PrintLog(__FUNCTION__, logMsg, true);
    }
    if (d_lots > d_MaxLot) {
        d_lots = d_MaxLot;
        string logMsg = StringFormat("lots set to maximum (%s)", DoubleToStr(d_lots, 2));
        PrintLog(__FUNCTION__, logMsg, true);
    }
    if (!b_recalc_mode)
        return (NormalizeDouble (d_lots, 2));
//---- b_recalc_mode is enabled
    int i_PrevErr = 0;
    double d_MarginChk = 0.0;
    i_type_ord %= 2;
    d_MarginChk = AccountFreeMarginCheck (symbol, i_type_ord, d_lots);
    i_PrevErr = GetLastError();
    d_MarginChk = NormalizeDouble (d_MarginChk, 2);
    while (d_MarginChk <= NormalizeDouble (0.0, 2) ||
            i_PrevErr == 134) {
        if (IsStopped()) {
            PrintLog(__FUNCTION__, "program commanded to stop", true);
            return (0.0);
        }
        //---- Lots already in the minimum size
        if (d_lots <= d_MinLot) {
            string logMsg = StringFormat("free margin not enough to open minimum lot size (%s)", DoubleToStr(d_MinLot, 2));
            PrintLog(__FUNCTION__, logMsg, true);
            return (0.0);
        }
        //---- Lots can be further reduced to a minor size
        if (d_lots > d_MinLot) {
            string logMsg = StringFormat("free margin not enough to open %s lots)", DoubleToStr(d_lots, 2));
            PrintLog(__FUNCTION__, logMsg, true);
            d_lots -= d_LotStep;
            d_lots = NormalizeDouble (d_lots, 2);
            logMsg = StringFormat("trying a smaller lot size (%s)..)", DoubleToStr(d_lots, 2));
            PrintLog(__FUNCTION__, logMsg, true);
        }
        i_PrevErr = 0;
        d_MarginChk = AccountFreeMarginCheck (symbol, i_type_ord, d_lots);
        d_MarginChk = NormalizeDouble (d_MarginChk, 2);
        i_PrevErr = GetLastError();
    }
    return (NormalizeDouble (d_lots, 2));
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ChkLossProfitLvl(const string symbol, const int i_ord_type,
                      double &d_sl_lvl, double &d_tp_lvl,
                      const int digits, const double point, const double d_min_lvl,
                      const bool b_sl_level, const bool b_tp_level)
{
    double ask = 0.0,
           bid = 0.0,
           d_MinTPDist = 0.0,
           d_MinSLDist = 0.0;
    ask = GetASK (symbol, digits);
    bid = GetBID (symbol, digits);
    if (ask < 0 ||
            bid < 0)
        return;
    switch (i_ord_type) {
    case OP_BUY:
        //---- StopLoss
        if (b_sl_level) {
            d_MinSLDist = bid - (d_min_lvl * point);
            d_MinSLDist = NormalizeDouble (d_MinSLDist, digits);
            d_sl_lvl = NormalizeDouble (d_sl_lvl, digits);
            if (d_sl_lvl > NormalizeDouble (0.0, digits) &&
                    d_sl_lvl > d_MinSLDist)
                d_sl_lvl = d_MinSLDist;
        }
        //---- TakeProfit
        if(b_tp_level) {
            d_MinTPDist = ask + (d_min_lvl * point);
            d_MinTPDist = NormalizeDouble (d_MinTPDist, digits);
            d_tp_lvl = NormalizeDouble (d_tp_lvl, digits);
            if (d_tp_lvl > NormalizeDouble (0.0, digits) &&
                    d_tp_lvl < d_MinTPDist)
                d_tp_lvl = d_MinTPDist;
        }
        break;
    case OP_SELL:
        //---- StopLoss
        if(b_sl_level) {
            d_MinSLDist = ask + (d_min_lvl * point);
            d_MinSLDist = NormalizeDouble (d_MinSLDist, digits);
            d_sl_lvl = NormalizeDouble (d_sl_lvl, digits);
            if (d_sl_lvl > NormalizeDouble (0.0, digits) &&
                    d_sl_lvl < d_MinSLDist)
                d_sl_lvl = d_MinSLDist;
        }
        //---- TakeProfit
        if (b_tp_level) {
            d_MinTPDist = bid - (d_min_lvl * point);
            d_MinTPDist = NormalizeDouble (d_MinTPDist, digits);
            d_tp_lvl = NormalizeDouble (d_tp_lvl, digits);
            if (d_tp_lvl > NormalizeDouble (0.0, digits) &&
                    d_tp_lvl > d_MinTPDist)
                d_tp_lvl = d_MinTPDist;
        }
        break;
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ChkLossProfitPts(const string symbol, const int i_ord_type,
                      const double d_ord_price,
                      double &d_sl_pts, double &d_tp_pts,
                      const int digits, const double point, const double d_min_lvl,
                      const bool b_sl_level, const bool b_tp_level)
{
    double ask = 0.0,
           bid = 0.0,
           d_sl_lvl = 0.0,
           d_tp_lvl = 0.0,
           d_MinTPDist = 0.0,
           d_MinSLDist = 0.0;
    ask = GetASK (symbol, digits);
    bid = GetBID (symbol, digits);
    if (ask < 0 ||
            bid < 0)
        return;
    switch (i_ord_type) {
    case OP_BUY:
        //---- StopLoss
        if (!b_sl_level &&
                NormalizeDouble (d_sl_pts, 2) > NormalizeDouble (0.0, 2)) {
            d_sl_lvl = d_ord_price - (d_sl_pts * point);
            d_sl_lvl = NormalizeDouble (d_sl_lvl, digits);
            d_MinSLDist = bid - (d_min_lvl * point);
            d_MinSLDist = NormalizeDouble (d_MinSLDist, digits);
            if (d_sl_lvl > d_MinSLDist)
                d_sl_lvl = d_MinSLDist;
            d_sl_pts = d_sl_lvl;
        }
        //---- TakeProfit
        if (!b_tp_level &&
                NormalizeDouble (d_tp_pts, 2) > NormalizeDouble (0.0, 2)) {
            d_tp_lvl = d_ord_price + (d_tp_pts * point);
            d_tp_lvl = NormalizeDouble (d_tp_lvl, digits);
            d_MinTPDist = bid + (d_min_lvl * point);
            d_MinTPDist = NormalizeDouble (d_MinTPDist, digits);
            if (d_tp_lvl < d_MinTPDist)
                d_tp_lvl = d_MinTPDist;
            d_tp_pts = d_tp_lvl;
        }
        break;
    case OP_BUYLIMIT:
    case OP_BUYSTOP:
        //---- StopLoss
        if (!b_sl_level &&
                NormalizeDouble (d_sl_pts, 2) > NormalizeDouble (0.0, 2)) {
            if (d_min_lvl > 0 &&
                    d_sl_pts < d_min_lvl)
                d_sl_pts = d_min_lvl;
            d_sl_lvl = d_ord_price - (d_sl_pts * point);
            d_sl_pts = d_sl_lvl;
        }
        //---- TakeProfit
        if (!b_tp_level &&
                NormalizeDouble (d_tp_pts, 2) > NormalizeDouble (0.0, 2)) {
            if (d_min_lvl > 0 &&
                    d_tp_pts < d_min_lvl)
                d_tp_pts = d_min_lvl;
            d_tp_lvl = d_ord_price + (d_tp_pts * point);
            d_tp_pts = d_tp_lvl;
        }
        break;
    case OP_SELL:
        //---- StopLoss
        if (!b_sl_level &&
                NormalizeDouble (d_sl_pts, 2) > NormalizeDouble (0.0, 2)) {
            d_sl_lvl = d_ord_price + (d_sl_pts * point);
            d_sl_lvl = NormalizeDouble (d_sl_lvl, digits);
            d_MinSLDist = ask + (d_min_lvl * point);
            d_MinSLDist = NormalizeDouble (d_MinSLDist, digits);
            if (d_sl_lvl < d_MinSLDist)
                d_sl_lvl = d_MinSLDist;
            d_sl_pts = d_sl_lvl;
        }
        //---- TakeProfit
        if (!b_tp_level &&
                NormalizeDouble (d_tp_pts, 2) > NormalizeDouble (0.0, 2)) {
            d_tp_lvl = d_ord_price - (d_tp_pts * point);
            d_tp_lvl = NormalizeDouble (d_tp_lvl, digits);
            d_MinTPDist = ask - (d_min_lvl * point);
            d_MinTPDist = NormalizeDouble (d_MinTPDist, digits);
            if (d_tp_lvl > d_MinTPDist)
                d_tp_lvl = d_MinTPDist;
            d_tp_pts = d_tp_lvl;
        }
        break;
    case OP_SELLLIMIT:
    case OP_SELLSTOP:
        //---- StopLoss
        if (!b_sl_level &&
                NormalizeDouble (d_sl_pts, 2) > NormalizeDouble (0.0, 2)) {
            if (d_min_lvl > 0 &&
                    d_sl_pts < d_min_lvl)
                d_sl_pts = d_min_lvl;
            d_sl_lvl = d_ord_price + (d_sl_pts * point);
            d_sl_pts = d_sl_lvl;
        }
        //---- TakeProfit
        if (!b_tp_level &&
                NormalizeDouble (d_tp_pts, 2) > NormalizeDouble (0.0, 2)) {
            if (d_min_lvl > 0 &&
                    d_tp_pts < d_min_lvl)
                d_tp_pts = d_min_lvl;
            d_tp_lvl = d_ord_price - (d_tp_pts * point);
            d_tp_pts = d_tp_lvl;
        }
        break;
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SetSL_TP(const string s_Sym, const int order_type,
              const double order_open_price, const int i_Dig,
              const double d_Pt, const double d_stop_lvl,
              double &d_SL, const bool b_SL_level,
              double &d_TP, const bool b_TP_level)
{
    bool b_ModOrd = false;
    double d_LossLvl = 0.0,
           d_ProfLvl = 0.0,
           d_LossPts = 0.0,
           d_ProfPts = 0.0;
    if (d_SL > NormalizeDouble (0.0, i_Dig) ||
            d_TP > NormalizeDouble (0.0, i_Dig)) {
        //---- Levels (absolute price)
        if (b_SL_level ||
                b_TP_level) {
            ChkLossProfitLvl (s_Sym, order_type,
                              d_SL, d_TP, i_Dig, d_Pt, d_stop_lvl,
                              b_SL_level, b_TP_level);
            b_ModOrd = true;
        }
        //---- Points
        if (!b_SL_level ||
                !b_TP_level) {
            ChkLossProfitPts (s_Sym, order_type, order_open_price,
                              d_SL, d_TP, i_Dig, d_Pt, d_stop_lvl,
                              b_SL_level, b_TP_level);
            b_ModOrd = true;
        }
    }
    return (b_ModOrd);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CustomOrderModify(const int i_ord_ticket, double d_ord_price,
                       double d_ord_sl, double d_ord_tp,
                       const datetime dt_ord_exp, const int digits,
                       const color c_arrow_clr = clrNONE, int i_retries = 3)
{
    bool b_IsTesting = IsTesting(),
         b_ModifyOrd = false,
         b_OrdSelOK = false;
    b_OrdSelOK = OrderSelect (i_ord_ticket, SELECT_BY_TICKET);
    int order_type = -1;
    datetime dt_OrdExp = 0;
    double order_stoploss = 0.0,
           order_takeprofit = 0.0,
           order_open_price = 0.0;
    if (b_OrdSelOK) {
        if (OrderCloseTime() > 0) {
            //Print (__FUNCTION__,": order #",i_ord_ticket," is closed)");
            return (false);
        }
        //---- Chk trading context only if it's not testing
        if (!b_IsTesting)
            IsTradeContextFree();
        //---- Normalize parameters
        d_ord_price = NormalizeDouble (d_ord_price, digits);
        d_ord_sl = NormalizeDouble (d_ord_sl, digits);
        d_ord_tp = NormalizeDouble (d_ord_tp, digits);
        //---- Get order parameters
        order_type = OrderType();
        dt_OrdExp = OrderExpiration();
        order_stoploss = NormalizeDouble (OrderStopLoss(), digits);
        order_takeprofit = NormalizeDouble (OrderTakeProfit(), digits);
        order_open_price = NormalizeDouble (OrderOpenPrice(), digits);
        //---- Chk parameters
        b_ModifyOrd = false;
        if (d_ord_sl > 0 &&
                (order_stoploss == 0 ||
                 (order_stoploss > 0 &&
                  order_stoploss != d_ord_sl)))
            b_ModifyOrd = true;
        if (d_ord_tp > 0 &&
                (order_takeprofit == 0 ||
                 (order_takeprofit > 0 &&
                  order_takeprofit != d_ord_tp)))
            b_ModifyOrd = true;
        if (order_type > OP_SELL && //pending order
                (order_open_price != d_ord_price ||
                 dt_OrdExp != dt_ord_exp))
            b_ModifyOrd = true;
        if (!b_ModifyOrd)
            return (false);
    }
    if (!b_OrdSelOK) {
        PrintErrorMsg (__FUNCTION__, ": OrderSelect failed");
        return (false);
    }
//---- Modifying order
    if (b_ModifyOrd) {
        if (b_IsTesting)
            i_retries = 1;
        bool b_IsOrdModified = false;
        while (!b_IsOrdModified &&
                i_retries > 0) {
            b_IsOrdModified = OrderModify (i_ord_ticket, d_ord_price,
                                           d_ord_sl, d_ord_tp, dt_ord_exp, c_arrow_clr);
            i_retries--;
            if (!b_IsTesting)
                RandomSleep (SLEEP_MEAN, SLEEP_MAX);
        }
        if (!b_IsOrdModified) {
            PrintErrorMsg (__FUNCTION__,
                           ": failed modifying order #" + (string)i_ord_ticket);
            return (false);
        }
        return( true );
    }
    return (false);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GenerateOrderDescription(const int orderTicket)
{
    if (orderTicket <= 0) {
        return StringFormat("Invalid order ticket %d.", orderTicket);
    }

    if (OrderSelect(orderTicket, SELECT_BY_TICKET)) {
        // Fetch order details
        string orderType = GetOrderTypeString(OrderType());
        double orderLots = OrderLots();
        string orderSymbol = OrderSymbol();
        double orderOpenPrice = OrderOpenPrice();
        double orderStopLoss = OrderStopLoss();
        double orderTakeProfit = OrderTakeProfit();
        string orderComment = OrderComment();

        // Normalize lots to 2 decimal places
        string normalizedLots = StringFormat("%.2f", orderLots);

        // Normalize prices to the symbol's digits
        string normalizedOpenPrice = DoubleToStr(orderOpenPrice, Digits());
        string normalizedStopLoss = DoubleToStr(orderStopLoss, Digits());
        string normalizedTakeProfit = DoubleToStr(orderTakeProfit, Digits());

        // Generate the order description string
        string orderDescription = StringFormat("open #%d %s %s %s at %s sl:%s tp:%s c:\"%s\"",
                                               orderTicket, orderType, normalizedLots, orderSymbol,
                                               normalizedOpenPrice, normalizedStopLoss, normalizedTakeProfit, orderComment);

        return orderDescription;
    }
    else {
        return StringFormat("Order %d selection failed.", orderTicket);
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ExecuteOrderLogic(const string tradingSymbol, const int priceDigits, const double pipValue,
                      int orderType, double orderLots, double orderPrice, int slippage,
                      double stopLoss, double takeProfit, const bool useStopLevel, const bool useTakeProfitLevel,
                      const string orderComment, const int magicNumber, datetime orderExpiration,
                      const color arrowColor, int maxRetries, bool hiddenStopLoss, bool hiddenTakeProfit,
                      double calculatedStopLevel)
{
// Initialize variables
    bool isTesting = IsTesting();
    int lastError = 0;
    int retryCount = 0;
    int orderTicket = -1;
    double askPrice = 0.0;
    double bidPrice = 0.0;

// Logic for handling PENDING orders
    if (orderType > OP_SELL) {
        double minAllowedPrice = 0.0;
        retryCount = maxRetries;

        while (orderTicket < 1 && retryCount > 0) {
            if (IsStopped()) {
                printf(__FUNCTION__, ": program commanded to stop");
                return -1;
            }

            orderPrice = NormalizeDouble(orderPrice, priceDigits);

            switch (orderType) {
            case OP_BUYLIMIT:
                askPrice = GetASK(tradingSymbol, priceDigits);
                if (askPrice < 0)
                    return -1;
                minAllowedPrice = askPrice - (calculatedStopLevel * pipValue);
                minAllowedPrice = NormalizeDouble(minAllowedPrice, priceDigits);
                if (orderPrice <= 0 || orderPrice > minAllowedPrice)
                    orderPrice = minAllowedPrice;
                break;

            case OP_BUYSTOP:
                askPrice = GetASK(tradingSymbol, priceDigits);
                if (askPrice < 0)
                    return -1;
                minAllowedPrice = askPrice + (calculatedStopLevel * pipValue);
                minAllowedPrice = NormalizeDouble(minAllowedPrice, priceDigits);
                if (orderPrice <= 0 || orderPrice < minAllowedPrice)
                    orderPrice = minAllowedPrice;
                break;

            case OP_SELLLIMIT:
                bidPrice = GetBID(tradingSymbol, priceDigits);
                if (bidPrice < 0)
                    return -1;
                minAllowedPrice = bidPrice + (calculatedStopLevel * pipValue);
                minAllowedPrice = NormalizeDouble(minAllowedPrice, priceDigits);
                if (orderPrice <= 0 || orderPrice < minAllowedPrice)
                    orderPrice = minAllowedPrice;
                break;

            case OP_SELLSTOP:
                bidPrice = GetBID(tradingSymbol, priceDigits);
                if (bidPrice < 0)
                    return -1;
                minAllowedPrice = bidPrice - (calculatedStopLevel * pipValue);
                minAllowedPrice = NormalizeDouble(minAllowedPrice, priceDigits);
                if (orderPrice <= 0 || orderPrice > minAllowedPrice)
                    orderPrice = minAllowedPrice;
                break;
            }

            lastError = 0;

            orderTicket = OrderSend(tradingSymbol, orderType, orderLots, orderPrice, slippage, 0.0, 0.0, orderComment, magicNumber, orderExpiration, arrowColor);

            lastError = GetLastError();
            if (orderTicket < 1) {
                // Invalid stops
                if (lastError == 130) {
                    printf(__FUNCTION__, ": failed placing a pending order due to invalid stops (Error 130)");
                    break;
                }
                // Invalid price
                if (lastError == 129) {
                    printf(__FUNCTION__, ": failed placing a pending order due to invalid price (Error 129)");
                    // Optional: You can add specific logic to adjust the price and retry
                    retryCount--;
                    if (retryCount > 0) continue;
                    break;
                }
                // Expiration is denied by broker
                if (lastError == 147) {
                    orderExpiration = 0;
                    retryCount--;
                    if (retryCount > 0) continue;
                    break;
                }
                // Total orders reached the limit
                if (lastError == 148) {
                    printf(__FUNCTION__, ": failed placing a pending order due to order limit reached (Error 148)");
                    return -1;
                }
                // For other unknown errors
                printf(__FUNCTION__, ": failed placing a pending order due to unknown error (Error %d)", lastError);
                retryCount--;
                if (retryCount > 0) continue;
                break;
            }

            retryCount--;
        }

        if (orderTicket < 1) {
            printf(__FUNCTION__, ": failed placing a pending order (%d)", lastError);
        }
    }

// Logic for handling MARKET orders
    if (orderType < OP_BUYLIMIT) {
        retryCount = maxRetries;
        while (orderTicket < 1 && retryCount > 0) {
            if (IsStopped()) {
                printf(__FUNCTION__, ": program commanded to stop");
                return -1;
            }

            switch (orderType) {
            case OP_BUY:
                askPrice = GetASK(tradingSymbol, priceDigits);
                if (askPrice < 0)
                    return -1;
                orderPrice = askPrice;
                break;
            case OP_SELL:
                bidPrice = GetBID(tradingSymbol, priceDigits);
                if (bidPrice < 0)
                    return -1;
                orderPrice = bidPrice;
                break;
            }

            orderPrice = NormalizeDouble(orderPrice, priceDigits);
            lastError = 0;

            orderTicket = OrderSend(tradingSymbol, orderType, orderLots, orderPrice, slippage, 0.0, 0.0, orderComment, magicNumber, 0, arrowColor);

            lastError = GetLastError();
            if (orderTicket < 1) {
                if (lastError == 148 && !isTesting) {
                    RandomSleep(SLEEP_MEAN, SLEEP_MAX);
                }
            }
            retryCount--;
        }

        if (orderTicket < 1) {
            printf(__FUNCTION__, ": failed opening a market order (%d)", lastError);
            return -1;
        }
    }

// Logic for modifying the order
    if (OrderSelect(orderTicket, SELECT_BY_TICKET)) {
        orderPrice = NormalizeDouble(OrderOpenPrice(), priceDigits);
        retryCount = maxRetries;
        bool customOrderModified = false;

        while (!customOrderModified && retryCount > 0) {
            if (IsStopped()) {
                printf(__FUNCTION__, ": program commanded to stop");
                return -1;
            }

            // Set stop loss and take profit
            bool ModifyOrder = SetSL_TP(tradingSymbol, orderType, orderPrice, priceDigits,
                                        pipValue, calculatedStopLevel, stopLoss, useStopLevel,
                                        takeProfit, useTakeProfitLevel);

            if (!ModifyOrder) break;

            if (ModifyOrder) {
                stopLoss = NormalizeDouble(stopLoss, priceDigits);
                takeProfit = NormalizeDouble(takeProfit, priceDigits);

                HorizontalLine dummyHLStruct;  // Declare a dummy structure variable

                // Create a horizontal line for Stop Loss if hiddenStopLoss is true
                if (hiddenStopLoss && stopLoss > 0.0 && inputParams.IN_EnableStopLoss) {
                    string trailStopLineName = "";
                    color lineColor;

                    // Determine the trailStopLineName and lineColor based on orderType
                    if (orderType == OP_BUY || orderType == OP_BUYLIMIT || orderType == OP_BUYSTOP) {
                        trailStopLineName = StringFormat("%d%s%d", magicNumber, BUY_SL_LINE_SUFFIX, orderTicket);
                        lineColor = IN_BuyTrailStopLineColor;
                    }
                    else if (orderType == OP_SELL || orderType == OP_SELLLIMIT || orderType == OP_SELLSTOP) {
                        trailStopLineName = StringFormat("%d%s%d", magicNumber, SELL_SL_LINE_SUFFIX, orderTicket);
                        lineColor = IN_SellTrailStopLineColor;
                    }

                    if(trailStopLineName != "") {
                        CreateHorizontalLine(0,
                                             trailStopLineName,
                                             0,
                                             stopLoss,
                                             lineColor,
                                             OBJ_ALL_PERIODS,
                                             STYLE_DASH,
                                             1,
                                             false,
                                             false,
                                             false,
                                             0,
                                             dummyHLStruct,
                                             false);
                    }
                    stopLoss = 0.0; // Reset stopLoss to avoid setting it in the order
                }

                // Create a horizontal line for Take Profit if hiddenTakeProfit is true
                if (hiddenTakeProfit && takeProfit > 0.0 && (inputParams.IN_EnableManualTakeProfit || inputParams.IN_EnableMHMLTakeProfit)) {
                    string takeProfitLineName = "";

                    // Determine the takeProfitLineName based on orderType
                    if (orderType == OP_BUY || orderType == OP_BUYLIMIT || orderType == OP_BUYSTOP) {
                        takeProfitLineName = StringFormat("%d%s%d", magicNumber, BUY_TP_LINE_SUFFIX, orderTicket);
                    }
                    else if (orderType == OP_SELL || orderType == OP_SELLLIMIT || orderType == OP_SELLSTOP) {
                        takeProfitLineName = StringFormat("%d%s%d", magicNumber, SELL_TP_LINE_SUFFIX, orderTicket);
                    }

                    if(takeProfitLineName != "") {
                        CreateHorizontalLine(0,
                                             takeProfitLineName,
                                             0,
                                             takeProfit,
                                             clrLime,
                                             OBJ_ALL_PERIODS,
                                             STYLE_DASH,
                                             1,
                                             false,
                                             false,
                                             false,
                                             0,
                                             dummyHLStruct,
                                             false);
                    }
                    takeProfit = 0.0; // Reset takeProfit to avoid setting it in the order
                }

                // Call CustomOrderModify if either hiddenStopLoss or hiddenTakeProfit is false
                if (!hiddenStopLoss || !hiddenTakeProfit) {
                    customOrderModified = CustomOrderModify(orderTicket, orderPrice, stopLoss,
                                                            takeProfit, orderExpiration, priceDigits,
                                                            arrowColor, maxRetries);
                }
                else {
                    customOrderModified = true; // Skip CustomOrderModify if both hiddenStopLoss and hiddenTakeProfit are true
                }
            }
            retryCount--;
        }
    }

    return orderTicket;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OrderSendModule(const string tradingSymbol, const int priceDigits, const double pipValue,
                    int orderType, double orderLots, double orderPrice,
                    int slippage, double stopLoss, double takeProfit,
                    const bool useStopLevel = true, const bool useTakeProfitLevel = true,
                    const string orderComment = "", const int magicNumber = -1,
                    datetime orderExpiration = 0, const color arrowColor = clrNONE,
                    int maxRetries = 3, const bool hiddenStopLoss = false,
                    const bool hiddenTakeProfit = false)
{
    if (!IsTradeContextFree())
        return -1;

    if (orderType < OP_BUY || orderType > OP_SELLSTOP) {
        string logMessage = StringFormat("unknown order type (%d)", orderType);
        PrintLog(__FUNCTION__, logMessage);
        return -1;
    }

    slippage = (int)AdjustPoint1(tradingSymbol, priceDigits, slippage);
    orderLots = ChkLots(tradingSymbol, orderLots, orderType);

    if (orderLots <= NormalizeDouble(0.0, 2))
        return -1;

    double calculatedStopLevel = GetSTOPLEVEL(tradingSymbol, priceDigits);
    if (calculatedStopLevel < 0)
        return -1;

    return ExecuteOrderLogic(tradingSymbol, priceDigits, pipValue,
                             orderType, orderLots, orderPrice, slippage,
                             stopLoss, takeProfit, useStopLevel, useTakeProfitLevel,
                             orderComment, magicNumber, orderExpiration, arrowColor,
                             maxRetries, hiddenStopLoss, hiddenTakeProfit,
                             calculatedStopLevel);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OpenMultipleBuyOrders(const double initialVolume, const double stopLossPips, const double takeProfit,
                          const bool tpInPips = false, const string orderComment = "", const string orderReason = "")
{
// Initialize variables
    int maxRetries = 3;
    int lastSuccessfulOrderTicket = -1;

    bool hiddenStopLoss = false;
    bool hiddenTakeProfit = true;
// Hidden feature only makes sense if the EA is not running in optimization mode
// because in this mode the EA cannot create horizontal line objects
    if(IsOptimization()) {
        hiddenStopLoss = false;
        hiddenTakeProfit = false;
    }

// *** CENTRALIZED TP: Get unified take profit for buy orders ***
    double unifiedTP = GetUnifiedTakeProfit(OP_BUY, false);
    double finalTakeProfit = unifiedTP;

// Convert to price level if using manual TP
    if (IN_EnableManualTakeProfit && unifiedTP > 0) {
        finalTakeProfit = GetASK(Symbol(), Digits()) + (unifiedTP * Pip());
    }

    for (int i = 0; i < CurrentBuyOrderMultiplier; ++i) {
        // Open Buy Order with unified TP
        int orderTicket = OrderSendModule(Symbol(), Digits(), Pip(), OP_BUY, initialVolume, 0.0, 5,
                                          stopLossPips, finalTakeProfit,
                                          false, !IN_EnableManualTakeProfit, orderComment,
                                          IN_MagicNumber, 0, clrBlue, maxRetries, hiddenStopLoss, hiddenTakeProfit);

        // Handle unsuccessful order placement
        if (orderTicket < 1) {
            string logMessage = StringFormat("failed to open Buy Order (Iteration: %d)", i + 1);
            PrintLog(__FUNCTION__, logMessage);
        }
        else {
            lastSuccessfulOrderTicket = orderTicket;
            string formattedMessage = GenerateOrderDescription(lastSuccessfulOrderTicket);

            // Log with order reason if provided
            if (orderReason != "") {
                PrintLog(__FUNCTION__, orderReason + " -> " + formattedMessage, true);
            }
            else {
                PrintLog(__FUNCTION__, formattedMessage, false);
            }

            // Alert if enabled
            if (enableAlerts) {
                string alertMessage = StringFormat("BUY order%s at %s %s", orderComment != "" ? " " + orderComment : "", Symbol(), GetTimeframeName(Period()));
                Notify(alertMessage, true, false, false, false, "");
            }
        }
    }

    return lastSuccessfulOrderTicket;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OpenMultipleSellOrders(const double initialVolume, const double stopLossPips, const double takeProfit,
                           const bool tpInPips = false, const string orderComment = "", const string orderReason = "")
{
// Initialize variables
    int maxRetries = 3;
    int lastSuccessfulOrderTicket = -1;

    bool hiddenStopLoss = false;
    bool hiddenTakeProfit = true;
// Hidden feature only makes sense if the EA is not running in optimization mode
// because in this mode the EA cannot create horizontal line objects
    if(IsOptimization()) {
        hiddenStopLoss = false;
        hiddenTakeProfit = false;
    }

// *** CENTRALIZED TP: Get unified take profit for sell orders ***
    double unifiedTP = GetUnifiedTakeProfit(OP_SELL, false);
    double finalTakeProfit = unifiedTP;

// Convert to price level if using manual TP
    if (IN_EnableManualTakeProfit && unifiedTP > 0) {
        finalTakeProfit = GetBID(Symbol(), Digits()) - (unifiedTP * Pip());
    }

    for (int i = 0; i < CurrentSellOrderMultiplier; ++i) {
        // Open Sell Order with unified TP
        int orderTicket = OrderSendModule(Symbol(), Digits(), Pip(), OP_SELL, initialVolume, 0.0, 5,
                                          stopLossPips, finalTakeProfit,
                                          false, !IN_EnableManualTakeProfit, orderComment,
                                          IN_MagicNumber, 0, clrRed, maxRetries, hiddenStopLoss, hiddenTakeProfit);

        // Handle unsuccessful order placement
        if (orderTicket < 1) {
            string logMessage = StringFormat("failed to open Sell Order (Iteration: %d)", i + 1);
            PrintLog(__FUNCTION__, logMessage);
        }
        else {
            lastSuccessfulOrderTicket = orderTicket;
            string formattedMessage = GenerateOrderDescription(lastSuccessfulOrderTicket);

            // Log with order reason if provided
            if (orderReason != "") {
                PrintLog(__FUNCTION__, orderReason + " -> " + formattedMessage, true);
            }
            else {
                PrintLog(__FUNCTION__, formattedMessage, false);
            }

            // Alert if enabled
            if (enableAlerts) {
                string alertMessage = StringFormat("SELL order%s at %s %s", orderComment != "" ? " " + orderComment : "", Symbol(), GetTimeframeName(Period()));
                Notify(alertMessage, true, false, false, false, "");
            }
        }
    }

    return lastSuccessfulOrderTicket;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int PlaceMultipleBuyStopOrders(const double breakeven_price,
                               const double initialVolume,
                               const double stopLossPips,
                               const double takeProfit,
                               const bool tpInPips = false,
                               const string orderComment = "",
                               const string orderReason = "")
{
// Initialize variables
    int maxRetries = 3;
    int lastSuccessfulOrderTicket = -1;
    double entryPrice = breakeven_price + (IN_PendingBuyDeviationFromBE * Pip());

    bool hiddenStopLoss = false;
    bool hiddenTakeProfit = true;
// Hidden feature only makes sense if the EA is not running in optimization mode
// because in this mode the EA cannot create horizontal line objects
    if(IsOptimization()) {
        hiddenStopLoss = false;
        hiddenTakeProfit = false;
    }

// *** CENTRALIZED TP: Get unified take profit for buy orders ***
    double unifiedTP = GetUnifiedTakeProfit(OP_BUY, false);
    double finalTakeProfit = unifiedTP;

// Convert to price level if using manual TP
    if (IN_EnableManualTakeProfit && unifiedTP > 0) {
        finalTakeProfit = entryPrice + (unifiedTP * Pip());
    }

    for (int i = 0; i < CurrentBuyOrderMultiplier; ++i) {
        // Open BuyStop Order with unified TP
        int orderTicket = OrderSendModule(Symbol(), Digits(), Pip(), OP_BUYSTOP, initialVolume,
                                          entryPrice,
                                          5, stopLossPips, finalTakeProfit,
                                          false, !IN_EnableManualTakeProfit, orderComment,
                                          IN_MagicNumber, 0, clrBlue, maxRetries, hiddenStopLoss, hiddenTakeProfit);

        // Handle unsuccessful order placement
        if (orderTicket < 1) {
            string logMessage = StringFormat("failed to open BuyStop Order (Iteration: %d)", i + 1);
            PrintLog(__FUNCTION__, logMessage);
        }
        else {
            lastSuccessfulOrderTicket = orderTicket;
            string formattedMessage = GenerateOrderDescription(lastSuccessfulOrderTicket);

            PrintLog(__FUNCTION__, formattedMessage, false);

            // Alert if enabled
            if (enableAlerts) {
                string alertMessage = StringFormat("BUYSTOP order%s at %s %s", orderComment != "" ? " " + orderComment : "", Symbol(), GetTimeframeName(Period()));
                Notify(alertMessage, true, false, false, false, "");
            }
        }
    }

    return lastSuccessfulOrderTicket;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int PlaceMultipleSellStopOrders(const double breakeven_price,
                                const double initialVolume,
                                const double stopLossPips,
                                const double takeProfit,
                                const bool tpInPips = false,
                                const string orderComment = "",
                                const string orderReason = "")
{
// Initialize variables
    int maxRetries = 3;
    int lastSuccessfulOrderTicket = -1;
    double entryPrice = breakeven_price - (IN_PendingSellDeviationFromBE * Pip());

    bool hiddenStopLoss = false;
    bool hiddenTakeProfit = true;
// Hidden feature only makes sense if the EA is not running in optimization mode
// because in this mode the EA cannot create horizontal line objects
    if(IsOptimization()) {
        hiddenStopLoss = false;
        hiddenTakeProfit = false;
    }

// *** CENTRALIZED TP: Get unified take profit for sell orders ***
    double unifiedTP = GetUnifiedTakeProfit(OP_SELL, false);
    double finalTakeProfit = unifiedTP;

// Convert to price level if using manual TP
    if (IN_EnableManualTakeProfit && unifiedTP > 0) {
        finalTakeProfit = entryPrice - (unifiedTP * Pip());
    }

    for (int i = 0; i < CurrentSellOrderMultiplier; ++i) {
        // Open SellStop Order with unified TP
        int orderTicket = OrderSendModule(Symbol(), Digits(), Pip(), OP_SELLSTOP, initialVolume,
                                          entryPrice,
                                          5, stopLossPips, finalTakeProfit,
                                          false, !IN_EnableManualTakeProfit, orderComment,
                                          IN_MagicNumber, 0, clrRed, maxRetries, hiddenStopLoss, hiddenTakeProfit);

        // Handle unsuccessful order placement
        if (orderTicket < 1) {
            string logMessage = StringFormat("failed to open SellStop Order (Iteration: %d)", i + 1);
            PrintLog(__FUNCTION__, logMessage);
        }
        else {
            lastSuccessfulOrderTicket = orderTicket;
            string formattedMessage = GenerateOrderDescription(lastSuccessfulOrderTicket);

            PrintLog(__FUNCTION__, formattedMessage, false);

            // Alert if enabled
            if (enableAlerts) {
                string alertMessage = StringFormat("SELLSTOP order%s at %s %s", orderComment != "" ? " " + orderComment : "", Symbol(), GetTimeframeName(Period()));
                Notify(alertMessage, true, false, false, false, "");
            }
        }
    }

    return lastSuccessfulOrderTicket;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckTakeProfitSettings(const bool manualTakeProfitEnabled, const bool mhmlTakeProfitEnabled)
{
// Print which take profit types are enabled
    if (manualTakeProfitEnabled && mhmlTakeProfitEnabled) {
        PrintLog(__FUNCTION__, "Both Manual TakeProfit and MH ML TakeProfit are enabled", true);
    }
    else if (manualTakeProfitEnabled) {
        PrintLog(__FUNCTION__, "Only Manual TakeProfit is enabled", true);
    }
    else if (mhmlTakeProfitEnabled) {
        PrintLog(__FUNCTION__, "Only MH ML TakeProfit is enabled", true);
    }
    else {
        PrintLog(__FUNCTION__, "No TakeProfit is enabled", true);
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PlaceTradingOrders(const SignalInfo &signalInfo,
                        const double breakevenPrice,
                        const OrderCounts &counts,
                        const bool enableBeReentry,
                        const bool enableReverseFilterBuys,
                        const bool enableReverseFilterSells,
                        const InputParameters &params)
{
    int lastSuccessfulOrderTicket = -1;  // Initialize to -1 to indicate no successful orders yet
    string orderReason = "";  // String to store the reason for opening orders

// Determine the ability to place a new buy order based on conditions
    bool canPlaceBuy = (signalInfo.buyEntry && CanPlaceReentryOrder(enableBeReentry, counts.totalBuys, counts.totalBuystops));

    if (signalInfo.buyEntry) {
        orderReason = "Buy signal from arrow indicator triggered";
        if (!CanPlaceReentryOrder(enableBeReentry, counts.totalBuys, counts.totalBuystops)) {
            orderReason += " but prevented by reentry settings";
        }
    }

    SignalInfo buySignalInfo = signalInfo;
    if (!signalInfo.buyEntry) {
        buySignalInfo.buyEntry = false;
        buySignalInfo.sellEntry = false;
    }

// Calculate the take profit level for Buy orders
    double buyTakeProfit = DetermineTakeProfit(
                               IN_EnableManualTakeProfit,
                               IN_TakeProfitInPips,
                               IN_EnableMHMLTakeProfit,
                               buySignalInfo,
                               IN_MHMLMarkerTakeProfitTimeframe,
                               IN_MHMLMarkerTakeProfitPerc,
                               false
                           );

// Convert take profit from pips to price level if using manual TP
    double buyTakeProfitPrice = 0.0;
    if (IN_EnableManualTakeProfit) {
        buyTakeProfitPrice = GetASK(Symbol(), Digits()) + (buyTakeProfit * Pip());
    }
    else {
        buyTakeProfitPrice = buyTakeProfit; // Already a price level from MHML
    }

// Check if trade should be allowed based on Maximum Entry Threshold
    bool allowBuyByThreshold = IsTradeAllowedByMaxEntryThreshold(
                                   EnableMaxEntryThreshold,
                                   MaxEntryThresholdPercent,
                                   OP_BUY,
                                   GetASK(Symbol(), Digits()), // Current price for buy
                                   buyTakeProfitPrice
                               );

    if (!allowBuyByThreshold && signalInfo.buyEntry) {
        orderReason += " but prevented by Maximum Entry Threshold - price too close to take profit";
    }

// Check if a buy order is allowed with the breakeven pivot filter
    PrintLog(__FUNCTION__, StringFormat("CALLING BUY FILTER: BuyFilterPercent=%.1f%% (as lowest), SellFilterPercent=%.1f%% (as highest)",
                                        params.IN_BuyBePivotFilterPercentage, params.IN_SellBePivotFilterPercentage), true);
    bool canBuy = IsBuyOrderAllowedWithBreakevenPivot(
                      params.IN_EnableBuyBePivotFilter,
                      counts.totalBuys + counts.totalBuystops,
                      params.IN_BuyBePivotFilterTimeframe,
                      params,
                      PROGRAM_ID,
                      0, //index
                      params.IN_BuyBePivotFilterPercentage, //lowestThresholdPercentage
                      params.IN_SellBePivotFilterPercentage, //highestThresholdPercentage
                      GetBID(Symbol(), Digits()));

    if (!canBuy && signalInfo.buyEntry) {
        orderReason += " but rejected by breakeven pivot filter";
    }

    double initialBuyLots = GetBuyCurrentLotSize();

// Open a buy order if conditions are met
    if (canPlaceBuy && canBuy && allowBuyByThreshold) {
        // Build complete order reason
        string finalBuyReason = orderReason;
        if (IN_OrdersToTrade == kMarketOrders) {
            finalBuyReason += " - Opening buy market orders";
        }
        else {
            finalBuyReason += " - Placing buy stop orders";
        }

        // Log the reason before placing orders
        PrintLog("ORDER_REASON", finalBuyReason, true);

        if (IN_OrdersToTrade == kMarketOrders) {
            // Open multiple market buy orders - NO LONGER PASS CALCULATED TP
            double entry_price = 0;
            double sl_price = 0;
            PositionInfo initialPosition = CalculateOrderLots(
                                               Buy_IN_LotSizingOptions,
                                               params.Buy_IN_PercentFreeMargin,
                                               params.Buy_IN_PercentEquity,
                                               initialBuyLots,
                                               OP_BUY,
                                               entry_price,
                                               sl_price,
                                               params.AC_Ratio_Limit,
                                               params.AC_Ratio_Actual);

            if(EnablePositiveEquityTarget || EnableNegativeEquityLimit) {
                initialPosition.LotSize = initialBuyLots;
            }

            // *** CENTRALIZED TP: Function will get unified TP internally ***
            lastSuccessfulOrderTicket = OpenMultipleBuyOrders(initialPosition.LotSize,
                                        IN_EnableStopLoss ? CalculateDynamicStopLossInPips(inputParams) : 0,
                                        0, // No longer pass calculated TP - function gets it internally
                                        false,
                                        "",
                                        finalBuyReason);
        }
        else if (IN_OrdersToTrade == kPendingOrders) {
            // Open multiple buy stop orders - NO LONGER PASS CALCULATED TP
            double entry_price = 0;
            double sl_price = 0;
            PositionInfo initialPosition = CalculateOrderLots(
                                               Buy_IN_LotSizingOptions,
                                               params.Buy_IN_PercentFreeMargin,
                                               params.Buy_IN_PercentEquity,
                                               initialBuyLots,
                                               OP_BUY,
                                               entry_price,
                                               sl_price,
                                               params.AC_Ratio_Limit,
                                               params.AC_Ratio_Actual);

            if(EnablePositiveEquityTarget || EnableNegativeEquityLimit) {
                initialPosition.LotSize = initialBuyLots;
            }

            // *** CENTRALIZED TP: Function will get unified TP internally ***
            lastSuccessfulOrderTicket = PlaceMultipleBuyStopOrders(breakevenPrice,
                                        initialPosition.LotSize,
                                        IN_EnableStopLoss ? CalculateDynamicStopLossInPips(inputParams) : 0,
                                        0, // No longer pass calculated TP - function gets it internally
                                        false,
                                        "",
                                        finalBuyReason);
        }

        // Additional logic after a successful buy order
        if (lastSuccessfulOrderTicket > 0) {
            resetBreakevenCounterForBuys();
            if (enableReverseFilterSells && OrderSelect(lastSuccessfulOrderTicket, SELECT_BY_TICKET) &&
                    IN_OrdersToTrade == kMarketOrders) {
                MoveHorizontalLine(0, sellReverseOrderLineName, OrderOpenPrice() - (IN_SellReverseEntryDeviation * Pip()), sellReverseOrderLineStruct);
                ShowHorizontalLine(0, sellReverseOrderLineName, sellReverseOrderLineStruct);
            }
        }
    }

// Determine the ability to place a new sell order based on conditions
    bool canPlaceSell = (signalInfo.sellEntry && CanPlaceReentryOrder(enableBeReentry, counts.totalSells, counts.totalSellstops));

    orderReason = "";  // Reset reason for sell orders
    if (signalInfo.sellEntry) {
        orderReason = "Sell signal from arrow indicator triggered";
        if (!CanPlaceReentryOrder(enableBeReentry, counts.totalSells, counts.totalSellstops)) {
            orderReason += " but prevented by reentry settings";
        }
    }

    SignalInfo sellSignalInfo = signalInfo;
    if (!signalInfo.sellEntry) {
        sellSignalInfo.buyEntry = false;
        sellSignalInfo.sellEntry = false;
    }
    else {
        // Ensure buyEntry is false when sellEntry is true
        sellSignalInfo.buyEntry = false;
    }

// Calculate the take profit level for Sell orders
    double sellTakeProfit = DetermineTakeProfit(
                                IN_EnableManualTakeProfit,
                                IN_TakeProfitInPips,
                                IN_EnableMHMLTakeProfit,
                                sellSignalInfo,
                                IN_MHMLMarkerTakeProfitTimeframe,
                                IN_MHMLMarkerTakeProfitPerc,
                                false
                            );

// Convert take profit from pips to price level if using manual TP
    double sellTakeProfitPrice = 0.0;
    if (IN_EnableManualTakeProfit) {
        sellTakeProfitPrice = GetBID(Symbol(), Digits()) - (sellTakeProfit * Pip());
    }
    else {
        sellTakeProfitPrice = sellTakeProfit; // Already a price level from MHML
    }

// Check if trade should be allowed based on Maximum Entry Threshold
    bool allowSellByThreshold = IsTradeAllowedByMaxEntryThreshold(
                                    EnableMaxEntryThreshold,
                                    MaxEntryThresholdPercent,
                                    OP_SELL,
                                    GetBID(Symbol(), Digits()), // Current price for sell
                                    sellTakeProfitPrice
                                );

    if (!allowSellByThreshold && signalInfo.sellEntry) {
        orderReason += " but prevented by Maximum Entry Threshold - price too close to take profit";
    }

// Check if a sell order is allowed with the breakeven pivot filter
    PrintLog(__FUNCTION__, StringFormat("CALLING SELL FILTER: SellFilterPercent=%.1f%% (as lowest), BuyFilterPercent=%.1f%% (as highest)",
                                        params.IN_SellBePivotFilterPercentage, params.IN_BuyBePivotFilterPercentage), true);
    bool canSell = IsSellOrderAllowedWithBreakevenPivot(
                       params.IN_EnableSellBePivotFilter,
                       counts.totalSells + counts.totalSellstops,
                       params.IN_SellBePivotFilterTimeframe,
                       params,
                       PROGRAM_ID,
                       0, //index
                       params.IN_SellBePivotFilterPercentage, //lowestThresholdPercentage
                       params.IN_BuyBePivotFilterPercentage, //highestThresholdPercentage
                       GetBID(Symbol(), Digits()));

    if (!canSell && signalInfo.sellEntry) {
        orderReason += " but rejected by breakeven pivot filter";
    }

    double initialSellLots = GetSellCurrentLotSize();

// Open a sell order if conditions are met
    if (canPlaceSell && canSell && allowSellByThreshold) {
        // Build complete order reason
        string finalSellReason = orderReason;
        if (IN_OrdersToTrade == kMarketOrders) {
            finalSellReason += " - Opening sell market orders";
        }
        else {
            finalSellReason += " - Placing sell stop orders";
        }

        // Log the reason before placing orders
        PrintLog("ORDER_REASON", finalSellReason, true);

        if (IN_OrdersToTrade == kMarketOrders) {
            // Open multiple market sell orders - NO LONGER PASS CALCULATED TP
            double entry_price = 0;
            double sl_price = 0;
            PositionInfo initialPosition = CalculateOrderLots(
                                               Sell_IN_LotSizingOptions,
                                               params.Sell_IN_PercentFreeMargin,
                                               params.Sell_IN_PercentEquity,
                                               initialSellLots,
                                               OP_SELL,
                                               entry_price,
                                               sl_price,
                                               params.AC_Ratio_Limit,
                                               params.AC_Ratio_Actual);

            if(EnablePositiveEquityTarget || EnableNegativeEquityLimit) {
                initialPosition.LotSize = initialSellLots;
            }

            // *** CENTRALIZED TP: Function will get unified TP internally ***
            lastSuccessfulOrderTicket = OpenMultipleSellOrders(initialPosition.LotSize,
                                        IN_EnableStopLoss ? CalculateDynamicStopLossInPips(inputParams) : 0,
                                        0, // No longer pass calculated TP - function gets it internally
                                        false,
                                        "",
                                        finalSellReason);
        }
        else if (IN_OrdersToTrade == kPendingOrders) {
            // Open multiple sell stop orders - NO LONGER PASS CALCULATED TP
            double entry_price = 0;
            double sl_price = 0;
            PositionInfo initialPosition = CalculateOrderLots(
                                               Sell_IN_LotSizingOptions,
                                               params.Sell_IN_PercentFreeMargin,
                                               params.Sell_IN_PercentEquity,
                                               initialSellLots,
                                               OP_SELL,
                                               entry_price,
                                               sl_price,
                                               params.AC_Ratio_Limit,
                                               params.AC_Ratio_Actual);

            if(EnablePositiveEquityTarget || EnableNegativeEquityLimit) {
                initialPosition.LotSize = initialSellLots;
            }

            // *** CENTRALIZED TP: Function will get unified TP internally ***
            lastSuccessfulOrderTicket = PlaceMultipleSellStopOrders(breakevenPrice,
                                        initialPosition.LotSize,
                                        IN_EnableStopLoss ? CalculateDynamicStopLossInPips(inputParams) : 0,
                                        0, // No longer pass calculated TP - function gets it internally
                                        false,
                                        "",
                                        finalSellReason);
        }

        // Additional logic after a successful sell order
        if (lastSuccessfulOrderTicket > 0) {
            resetBreakevenCounterForSells();
            if (enableReverseFilterBuys && OrderSelect(lastSuccessfulOrderTicket, SELECT_BY_TICKET) &&
                    IN_OrdersToTrade == kMarketOrders) {
                MoveHorizontalLine(0, buyReverseOrderLineName, OrderOpenPrice() + (IN_BuyReverseEntryDeviation * Pip()), buyReverseOrderLineStruct);
                ShowHorizontalLine(0, buyReverseOrderLineName, buyReverseOrderLineStruct);
            }
        }
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CanPlaceReentryOrder(const bool enableBeReentry, const int totalMarketOrders, const int totalPendingOrders)
{
    // In Continuous Mode, always allow new orders regardless of reentry setting
    if (IN_TradingMode == kSwingContinuousMode) {
        return true;
    }

    // In Single Mode, strictly enforce "one trade at a time" regardless of reentry setting
    if (IN_TradingMode == kSingleMode) {
        return (IN_OrdersToTrade == kMarketOrders && totalMarketOrders == 0) ||
               (IN_OrdersToTrade == kPendingOrders && totalMarketOrders == 0 && totalPendingOrders == 0);
    }

    // Fallback to original logic for any unknown trading mode
    return enableBeReentry ||
           (IN_OrdersToTrade == kMarketOrders && totalMarketOrders == 0) ||
           (IN_OrdersToTrade == kPendingOrders && totalMarketOrders == 0 && totalPendingOrders == 0);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void HandleLoopExit(int prevError, int retries, bool isTesting, bool shouldExitLoop)
{
    if (!shouldExitLoop) {
        printf("%s: %s - Retriable error (retrying closing)", __FUNCTION__, ErrorDescription(prevError));
        if (!isTesting) RandomSleep(SLEEP_MEAN, SLEEP_MAX);
    }

    if (shouldExitLoop && prevError != 0) {
        printf("%s: Oops.. a non-retriable error (#%d) has occurred", __FUNCTION__, prevError);
        if (retries < 1) printf("%s: Maximum retries reached", __FUNCTION__);
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int HandleOrderCloseFailure(int prevError, int orderTicket)
{
    printf("%s: Order #%d closing operation failed - Error code #%d", __FUNCTION__, orderTicket, prevError);
    return 0;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ClosePosition(const int orderTicket, const string symbol,
                  const int digits, const int slippage,
                  int retries = 3, const color arrowColor = clrNONE)
{
    if (!OrderSelect(orderTicket, SELECT_BY_TICKET)) return -1;
    if (OrderCloseTime() != 0) return 1;

    int orderType = OrderType();
    if (orderType > 1) return -1;

    double closePrice = 0.0;
    int maxLotDigits = 2;
    double orderLots = NormalizeDouble(OrderLots(), maxLotDigits);

    bool isTesting = IsTesting();
    bool shouldExitLoop = false;
    bool isOrderClosed = false;
    int prevError = 0;

    if (isTesting) retries = 1;

    while (!shouldExitLoop && retries > 0) {
        if (IsStopped()) {
            printf("%s: Program commanded to stop", __FUNCTION__);
            return -1;
        }

        if (!isTesting && !IsTradeContextFree()) continue;

        if(orderType == OP_BUY) {
            closePrice = GetBID(symbol, digits);
        }
        else if(orderType == OP_SELL) {
            closePrice = GetASK(symbol, digits);
        }

        isOrderClosed = OrderClose(orderTicket, orderLots, closePrice, slippage, arrowColor);
        prevError = GetLastError();
        if (isOrderClosed) shouldExitLoop = true;

        if (isOrderClosed) {
            shouldExitLoop = true;
            // Log the success of the order closure to the console
            string logMessage = StringFormat("Order #%d has been successfully closed.", orderTicket);
            PrintLog(__FUNCTION__, logMessage);
        }

        switch (prevError) {
        case 0:
            shouldExitLoop = true;
            break;
        case 135:
        case 138:
            continue;
        case 4:
        case 6:
        case 128:
        case 129:
        case 136:
        case 137:
        case 146:
            retries--;
            break;
        default:
            shouldExitLoop = true;
        }

        HandleLoopExit(prevError, retries, isTesting, shouldExitLoop);
    }

    return (isOrderClosed || prevError == 0) ? 1 : HandleOrderCloseFailure(prevError, orderTicket);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAll(const string symbol, const int digits, const int magicNumber, const int slippage,
              const string orderComment, int maxRetries = 1, const int orderTypeFilter = ONLY_MARKET,
              const color arrowColor = clrNONE)
{
// Initialize variables
    int totalOrders = 0;
    int orderCount[6] = {0};  // Array to hold order count by type
    int orderTicket = -1;
    int orderType = -1;

// Get the total number of valid orders
    totalOrders = CustomOrdersTotal(orderCount, symbol, magicNumber, orderComment);

// Loop through and close orders until no more valid orders or retries are exhausted
    while ((orderCount[0] + orderCount[1]) > 0 && maxRetries > 0) {
        // Check if the program is commanded to stop
        if (IsStopped()) {
            printf("%s: Program commanded to stop.", __FUNCTION__);
            return;
        }

        // Loop through orders in reverse to safely close them
        for (int i = CountOrdersInPool(MODE_TRADES) - 1; i >= 0; --i) {
            if (!IsValidOrder(i, symbol, magicNumber, orderComment)) continue;

            orderTicket = OrderTicket();
            orderType = OrderType();

            // Filter out orders that do not match the provided order type
            if (!IsOrderMatch(orderTypeFilter, orderType)) continue;

            // Close the position
            if (ClosePosition(orderTicket, symbol, digits, slippage, 3, arrowColor) == 1) {
                // Delete associated SL and TP lines
                DeleteStopLossLine(magicNumber, orderTicket, orderType);
                DeleteTakeProfitLine(magicNumber, orderTicket, orderType);
            }
        }

        CustomOrdersTotal(orderCount, symbol, magicNumber, orderComment);

        // Decrement retry counter
        maxRetries--;
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CloseAllLossesEfficiently(const string symbol, const int digits, const int magicNumber, const int slippage,
                               const string orderComment, int maxRetries = 1, const int orderTypeFilter = ONLY_MARKET,
                               const color arrowColor = clrNONE, const double targetLossPercentage = 1.0)
{
// Structure to store order information for sorting
    struct OrderLossInfo {
        int          ticket;
        double       loss;
    };

// Array to store losing orders
    OrderLossInfo lossOrders[];
    int lossOrderCount = 0;
    double totalLossAmount = 0.0;

// First, identify all losing orders and store them
    for (int i = 0; i < CountOrdersInPool(MODE_TRADES); i++) {
        if (!IsValidOrder(i, symbol, magicNumber, orderComment)) continue;

        // Get order details
        int orderTicket = OrderTicket();
        int orderType = OrderType();
        double orderProfit = OrderProfit() + OrderSwap() + OrderCommission();

        // Filter by order type
        if (!IsOrderMatch(orderTypeFilter, orderType)) continue;

        // Only consider losing orders
        if (orderProfit >= 0) continue;

        // Store losing order information
        ArrayResize(lossOrders, lossOrderCount + 1);
        lossOrders[lossOrderCount].ticket = orderTicket;
        lossOrders[lossOrderCount].loss = MathAbs(orderProfit); // Store as positive value for easier sorting
        totalLossAmount += lossOrders[lossOrderCount].loss;
        lossOrderCount++;
    }

// If no losing orders found, return false
    if (lossOrderCount == 0) {
        PrintLog(__FUNCTION__, "No losing orders found to close.", false);
        return false;
    }

// Sort orders by loss size (largest loss first)
    for (int i = 0; i < lossOrderCount - 1; i++) {
        for (int j = i + 1; j < lossOrderCount; j++) {
            if (lossOrders[j].loss > lossOrders[i].loss) {
                // Swap
                OrderLossInfo temp = lossOrders[i];
                lossOrders[i] = lossOrders[j];
                lossOrders[j] = temp;
            }
        }
    }

// Calculate the target loss amount to close (90-110% of the NegativeEquityLimit)
    double targetLossAmount = NegativeEquityLimit * targetLossPercentage;

// Log the total and target loss amounts
    string logMessage = StringFormat("Total loss: %.2f, Target loss: %.2f", totalLossAmount, targetLossAmount);
    PrintLog(__FUNCTION__, logMessage, false);

// Close losing orders sequentially until we reach the target
    double closedLossAmount = 0.0;
    bool anyOrderClosed = false;

    for (int i = 0; i < lossOrderCount; i++) {
        // Check if we've already reached or exceeded the target
        if (closedLossAmount >= targetLossAmount && i > 0) {
            break;
        }

        // Select the order
        if (!OrderSelect(lossOrders[i].ticket, SELECT_BY_TICKET)) {
            continue;
        }

        // Close the position
        if (ClosePosition(lossOrders[i].ticket, symbol, digits, slippage, maxRetries, arrowColor) == 1) {
            closedLossAmount += lossOrders[i].loss;
            anyOrderClosed = true;

            // Delete associated SL and TP lines
            DeleteStopLossLine(magicNumber, lossOrders[i].ticket, OrderType());
            DeleteTakeProfitLine(magicNumber, lossOrders[i].ticket, OrderType());

            logMessage = StringFormat("Closed order #%d with loss %.2f. Running total: %.2f",
                                      lossOrders[i].ticket, lossOrders[i].loss, closedLossAmount);
            PrintLog(__FUNCTION__, logMessage, false);
        }
    }

// Log the final amount closed
    double percentageOfTarget = (closedLossAmount / targetLossAmount) * 100.0;
    logMessage = StringFormat("Total closed: %.2f (%.1f%% of target)", closedLossAmount, percentageOfTarget);
    PrintLog(__FUNCTION__, logMessage, false);

    return anyOrderClosed;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsAnyBuyInProfit(const double price)
{
    int totalOrders = CountOrdersInPool(MODE_TRADES);
    for (int i = 0; i < totalOrders; ++i) {
        if (!IsValidOrder(i, Symbol(), IN_MagicNumber, "", kMustIncludeString, MODE_TRADES)) continue;
        if (!IsOrderMatch(OP_BUY, OrderType())) continue;

        double openPrice = OrderOpenPrice();
        if (openPrice <= 0) {
            printf("%s: Invalid open price for order.", __FUNCTION__);
            continue;
        }

        if (NormalizeDouble(price - openPrice, _Digits) > 0) {
            return true;
        }
    }
    return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsAnySellInProfit(const double price)
{
    int totalOrders = CountOrdersInPool(MODE_TRADES);
    for (int i = 0; i < totalOrders; ++i) {
        if (!IsValidOrder(i, Symbol(), IN_MagicNumber, "", kMustIncludeString, MODE_TRADES)) continue;
        if (!IsOrderMatch(OP_SELL, OrderType())) continue;

        double openPrice = OrderOpenPrice();
        if (openPrice <= 0) {
            printf("%s: Invalid open price for order.", __FUNCTION__);
            continue;
        }

        if (NormalizeDouble(openPrice - price, _Digits) > 0) {
            return true;
        }
    }
    return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseBuysAtBreakeven(const double currentPrice, const double breakevenPrice)
{
// Calculate the price difference and normalize it
    double priceDifference = NormalizeDouble(currentPrice - breakevenPrice, _Digits);

// Check if the price has reached or crossed the breakeven level
    if (priceDifference <= 0) {
        printf("%s: Activated. Closing all Buy orders at breakeven.", __FUNCTION__);
        const int slippage = 5;
        CloseAll(Symbol(), Digits(), IN_MagicNumber, slippage, "", 1, OP_BUY, clrGoldenrod);
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseSellsAtBreakeven(const double currentPrice, const double breakevenPrice)
{
// Calculate the price difference and normalize it
    double priceDifference = NormalizeDouble(currentPrice - breakevenPrice, _Digits);

// Check if the price has reached or crossed the breakeven level
    if (priceDifference >= 0) {
        printf("%s: Activated. Closing all Sell orders at breakeven.", __FUNCTION__);
        const int slippage = 5;
        CloseAll(Symbol(), Digits(), IN_MagicNumber, slippage, "", 1, OP_SELL, clrGoldenrod);
    }
}
//+------------------------------------------------------------------+
//| Closes orders at their breakeven price levels if specific conditions are met and it's not a new bar.
//| This function was modified in version 1.46 based on a customer email from April 22, 2:32 pm.
//+------------------------------------------------------------------+
bool CloseOrdersAtBreakevenIfNotNewBar(const bool onNewBar, const double currentPrice, const double breakevenPrice,
                                       const bool enableManualTakeProfit, const StopLossType stopLossType, const int totalBuys, const int totalSells)
{
// Initialize a variable to track whether orders were closed at breakeven
    bool didCloseAtBreakeven = false;

// Proceed only if it's NOT a new bar
    if (!onNewBar) {

        // Check if neither Take Profit nor Stop Loss is set to manual
        if (!enableManualTakeProfit && stopLossType != kManualSL) {

            // Close Buy orders at breakeven if any exist
            if (totalBuys > 0) {
                CloseBuysAtBreakeven(currentPrice, breakevenPrice);
                didCloseAtBreakeven = true;
            }

            // Close Sell orders at breakeven if any exist
            if (totalSells > 0) {
                CloseSellsAtBreakeven(currentPrice, breakevenPrice);
                didCloseAtBreakeven = true;
            }
        }
    }

    return didCloseAtBreakeven;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool DeletePosition(const int orderTicket, const color markerColor = clrNONE)
{
// Reset the last error code
    ResetLastError();

// Attempt to delete the order
    if (!OrderDelete(orderTicket, markerColor)) {

        // Log the failure and the associated error description
        printf("%s (Failed): %s", __FUNCTION__, ErrorDescription(GetLastError()));

        // Introduce a random sleep to prevent rapid-fire attempts
        RandomSleep(SLEEP_MEAN, SLEEP_MAX);

        return false;  // Indicate failure
    }
    else {
        // Log the success of the order deletion
        string logMessage = StringFormat("Order #%d has been successfully deleted.", orderTicket);
        PrintLog(__FUNCTION__, logMessage);
    }

    return true;  // Indicate success
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteAllTypePositions(const int orderTypeFilter)
{
// Initialize local variables
    int orderTicket = -1;
    int orderType = -1;
    int retries = 1;

// Loop until either all matching orders are deleted or retries run out
    while (retries > 0) {
        // Iterate through all orders
        for (int i = CountOrdersInPool(MODE_TRADES) - 1; i >= 0; --i) {
            // Validate the order's symbol and magic number
            if (!IsValidOrder(i, Symbol(), IN_MagicNumber))
                continue;

            // Fetch the order ticket and type
            orderTicket = OrderTicket();
            orderType = OrderType();

            // Check for matching order type
            if (!IsOrderMatch(orderTypeFilter, orderType))
                continue;

            // Skip already closed orders
            if (OrderCloseTime() > 0)
                continue;

            // Delete the order
            if (DeletePosition(orderTicket, clrGoldenrod)) {
                // Delete associated SL and TP lines
                DeleteStopLossLine(IN_MagicNumber, orderTicket, orderType);
                DeleteTakeProfitLine(IN_MagicNumber, orderTicket, orderType);
            }
        }

        // Decrement retry count
        retries--;
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MonitorStealthStopLossLevels(const int slippage, const string orderComment = "", const int orderTypeFilter = ONLY_MARKET)
{
// Exit early if stop loss is disabled
    if(!IN_EnableStopLoss) return;

// Exit early if the input setting for StopLossInPips is zero (meaning OFF)
    if (IN_StopLossType == kManualSL && IN_StopLossInPips == 0) return;
    if (IN_StopLossType == kATRSL && IN_StopLossATRMultiplier == 0) return;

// Hidden feature only makes sense if the EA is not running in optimization mode because in this mode the EA cannot create horizontal line objects
    if(IsOptimization()) return;

    int digits = Digits();
    double currentPrice = 0.0;
    string symbol = Symbol();
    string stopLossLineName;

    for (int i = 0; i < CountOrdersInPool(MODE_TRADES); ++i) {
        if (!IsValidOrder(i, symbol, IN_MagicNumber, orderComment)) continue;

        int orderTicket = OrderTicket();
        int orderType = OrderType();
        bool shouldCloseOrder = false;

        switch (orderType) {
        case OP_BUY:
            stopLossLineName = StringFormat("%d%s%d", IN_MagicNumber, BUY_SL_LINE_SUFFIX, orderTicket);
            currentPrice = GetBID(symbol, digits);
            break;

        case OP_SELL:
            stopLossLineName = StringFormat("%d%s%d", IN_MagicNumber, SELL_SL_LINE_SUFFIX, orderTicket);
            currentPrice = GetASK(symbol, digits);
            break;

        case OP_BUYLIMIT:
        case OP_SELLLIMIT:
        case OP_BUYSTOP:
        case OP_SELLSTOP:
            continue;

        default:
            printf("%s: Unknown order type.", __FUNCTION__);
            return;
        }

        double stealthStopLoss = 0.0;
        if (ObjectFind(0, stopLossLineName) > -1 && ObjectGetInteger(0, stopLossLineName, OBJPROP_TIMEFRAMES) != OBJ_NO_PERIODS) {
            stealthStopLoss = ObjectGetDouble(0, stopLossLineName, OBJPROP_PRICE);
        }

        stealthStopLoss = NormalizeDouble(stealthStopLoss, digits);
        currentPrice = NormalizeDouble(currentPrice, digits);

        if (stealthStopLoss <= 0.0) continue;

        if ((orderType == OP_BUY && currentPrice <= stealthStopLoss) ||
                (orderType == OP_SELL && currentPrice >= stealthStopLoss)) {
            shouldCloseOrder = true;
        }

        if (shouldCloseOrder) {
            // Convert stealthStopLoss to a string with appropriate number of digits
            string stealthStopLossStr = DoubleToString(stealthStopLoss, Digits());

            // Log that the order is about to be closed and the reason for closure
            string logMessage = StringFormat("Closing order #%d due to hitting stealth stop-loss level (%s).", orderTicket, stealthStopLossStr);
            PrintLog(__FUNCTION__, logMessage);

            ObjectDelete(0, stopLossLineName);
            int MaxAttempts = 3;
            ClosePosition(orderTicket, symbol, digits, slippage, MaxAttempts, clrGoldenrod);
        }
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MonitorStealthTakeProfitLevels(const int slippage, const string orderComment = "", const int orderTypeFilter = ONLY_MARKET)
{
// Exit early if take profit is disabled - check both settings that could enable take profit
    if(!IN_EnableManualTakeProfit && !IN_EnableMHMLTakeProfit) return;

// Exit early if the input setting for TakeProfitInPips is zero (meaning OFF)
    if (IN_EnableManualTakeProfit && IN_TakeProfitInPips == 0) return;
    if (IN_EnableMHMLTakeProfit && IN_MHMLMarkerTakeProfitPerc == 0) return;

// Hidden feature only makes sense if the EA is not running in optimization mode because in this mode the EA cannot create horizontal line objects
    if(IsOptimization()) return;

    int digits = Digits();
    double currentPrice = 0.0;
    string symbol = Symbol();
    string takeProfitLineName;

    for (int i = 0; i < CountOrdersInPool(MODE_TRADES); ++i) {
        if (!IsValidOrder(i, symbol, IN_MagicNumber, orderComment)) continue;

        int orderTicket = OrderTicket();
        int orderType = OrderType();
        bool shouldCloseOrder = false;

        switch (orderType) {
        case OP_BUY:
            takeProfitLineName = StringFormat("%d%s%d", IN_MagicNumber, BUY_TP_LINE_SUFFIX, orderTicket);
            currentPrice = GetBID(symbol, digits);
            break;

        case OP_SELL:
            takeProfitLineName = StringFormat("%d%s%d", IN_MagicNumber, SELL_TP_LINE_SUFFIX, orderTicket);
            currentPrice = GetASK(symbol, digits);
            break;

        case OP_BUYLIMIT:
        case OP_SELLLIMIT:
        case OP_BUYSTOP:
        case OP_SELLSTOP:
            continue;

        default:
            printf("%s: Unknown order type.", __FUNCTION__);
            return;
        }

        double stealthTakeProfit = 0.0;
        if (ObjectFind(0, takeProfitLineName) > -1 && ObjectGetInteger(0, takeProfitLineName, OBJPROP_TIMEFRAMES) != OBJ_NO_PERIODS) {
            stealthTakeProfit = ObjectGetDouble(0, takeProfitLineName, OBJPROP_PRICE);
        }

        stealthTakeProfit = NormalizeDouble(stealthTakeProfit, digits);
        currentPrice = NormalizeDouble(currentPrice, digits);

        if (stealthTakeProfit <= 0.0) continue;

        if ((orderType == OP_BUY && currentPrice >= stealthTakeProfit) ||
                (orderType == OP_SELL && currentPrice <= stealthTakeProfit)) {
            shouldCloseOrder = true;
        }

        if (shouldCloseOrder) {
            // Convert stealthTakeProfit to a string with appropriate number of digits
            string stealthTakeProfitStr = DoubleToString(stealthTakeProfit, Digits());

            // Log that the order is about to be closed and the reason for closure
            string logMessage = StringFormat("Closing order #%d due to hitting stealth take-profit level (%s).", orderTicket, stealthTakeProfitStr);
            PrintLog(__FUNCTION__, logMessage);

            ObjectDelete(0, takeProfitLineName);
            int MaxAttempts = 3;
            ClosePosition(orderTicket, symbol, digits, slippage, MaxAttempts, clrGoldenrod);
        }
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteHiddenLevelsByString(const string targetString)
{
    int objectCount = ObjectsTotal();
    for (int i = objectCount - 1; i >= 0; --i) {
        string objectName = ObjectName(i);

        // Skip objects with empty or invalid names
        if (StringLen(objectName) < 1) continue;

        // Process only horizontal line objects
        if (ObjectType(objectName) != OBJ_HLINE) continue;

        // Target only specified line objects
        if (StringFind(objectName, targetString) < 0) continue;

        int lineTicket = StrToInteger(GetStringBetween(objectName, targetString, NULL, 0));

        // Check if the corresponding order exists and is closed
        if (OrderSelect(lineTicket, SELECT_BY_TICKET) && OrderCloseTime() > 0) {
            // Delete the object
            ObjectDelete(0, objectName);
        }
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteStopLossLine(const int magicNumber, const int orderTicket, const int orderType)
{
// Determine the appropriate suffix based on order type
    string slLineSuffix;
    switch (orderType) {
    case OP_BUY:
    case OP_BUYLIMIT:
    case OP_BUYSTOP:
        slLineSuffix = BUY_SL_LINE_SUFFIX;
        break;

    case OP_SELL:
    case OP_SELLLIMIT:
    case OP_SELLSTOP:
        slLineSuffix = SELL_SL_LINE_SUFFIX;
        break;

    default:
        printf("%s: Invalid order type", __FUNCTION__);
        return;
    }

// Construct the line name
    string lineName = StringFormat("%d%s%d", magicNumber, slLineSuffix, orderTicket);

// Check if the line exists and delete it
    if (ObjectFind(0, lineName) != -1) {
        if (!ObjectDelete(0, lineName)) {
            printf("%s: Failed to delete line %s", __FUNCTION__, lineName);
        }
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteTakeProfitLine(const int magicNumber, const int orderTicket, const int orderType)
{
// Determine the appropriate suffix based on order type
    string tpLineSuffix;
    switch (orderType) {
    case OP_BUY:
    case OP_BUYLIMIT:
    case OP_BUYSTOP:
        tpLineSuffix = BUY_TP_LINE_SUFFIX;
        break;

    case OP_SELL:
    case OP_SELLLIMIT:
    case OP_SELLSTOP:
        tpLineSuffix = SELL_TP_LINE_SUFFIX;
        break;

    default:
        printf("%s: Invalid order type", __FUNCTION__);
        return;
    }

// Construct the line name
    string lineName = StringFormat("%d%s%d", magicNumber, tpLineSuffix, orderTicket);

// Check if the line exists and delete it
    if (ObjectFind(0, lineName) != -1) {
        if (!ObjectDelete(0, lineName)) {
            printf("%s: Failed to delete line %s", __FUNCTION__, lineName);
        }
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ModifyAllTypePositions(const double d_ord_sl, const double d_ord_tp,
                            const string s_sym, const int i_dig,
                            const int i_mag = -1, const string s_cmnt = "",
                            const int i_ord_type_fltr = ALL_ORDERS, const int i_atts = 1)
{
    double d_OrdSL = 0.0,
           d_OrdTP = 0.0;
    for (int i = 0; i < CountOrdersInPool(); i++) {
        if (!IsValidOrder (i, s_sym, i_mag, s_cmnt))
            continue;
        if (!IsOrderMatch (i_ord_type_fltr, OrderType()))
            continue;
        d_OrdSL = OrderStopLoss();
        if (d_ord_sl != 0.0) d_OrdSL = d_ord_sl;
        d_OrdTP = OrderTakeProfit();
        if (d_ord_tp != 0.0) d_OrdTP = d_ord_tp;
        CustomOrderModify (OrderTicket(), OrderOpenPrice(), d_OrdSL, d_OrdTP, OrderExpiration(), i_dig, clrNONE, i_atts);
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool HandleSwingContinuousNewOrderOnNewBar(const bool onNewBar)
{
    if (!onNewBar) {
        return false;
    }

// Check if the last closed candle is bullish or bearish
    bool isLastCandleBullish = NormalizeDouble(Close[1], Digits()) > NormalizeDouble(Open[1], Digits());
    bool isLastCandleBearish = NormalizeDouble(Close[1], Digits()) < NormalizeDouble(Open[1], Digits());

    int lastOrderTicket = GetLastOrder("reverse", kMustExcludeString, ONLY_MARKET, MODE_TRADES, LAST_ORDER_BY_TICKET);
    if (lastOrderTicket == -1 || !OrderSelect(lastOrderTicket, SELECT_BY_TICKET)) {
        return false;
    }

// Extract information from the last valid order
    int orderType = OrderType();
    double orderLots = OrderLots();

// Prepare the order reason
    string orderReason = "";

// Determine the suffix for the take-profit line based on the order type
    string takeProfitLineSuffix = GetTakeProfitSuffix(orderType);

// Validate the last candle's condition matches the order type
    if (IsValidCandleForOrderType(orderType, isLastCandleBullish, isLastCandleBearish)) {
        // Create reason based on candle pattern
        if (orderType == OP_BUY || orderType == OP_BUYLIMIT || orderType == OP_BUYSTOP) {
            orderReason = "Swing Continuous Mode - Bullish candle continuation pattern";
        }
        else {
            orderReason = "Swing Continuous Mode - Bearish candle continuation pattern";
        }

        // Handle the breakeven pivot filter for Buy and Sell orders
        if (!HandleBreakevenPivotFilter(orderType, isLastCandleBullish, isLastCandleBearish)) {
            PrintLog("ORDER_REASON", orderReason + " but rejected by breakeven pivot filter", true);
            return false;
        }

        // Get take-profit line name and price level
        string takeProfitLineName = StringFormat("%d%s%d", IN_MagicNumber, takeProfitLineSuffix, lastOrderTicket);
        double takeProfit = IsOptimization() ? OrderTakeProfit() : GetHorizontalLinePriceLevel(0, takeProfitLineName);

        // Adjust color for the new order
        color arrowColor = GetOrderTypeColor(orderType, clrBlue, clrRed);
        color newArrowColor = (color)(ColorToARGB(arrowColor) + 0x303030); // Making the color lighter

        // Log the reason before placing order
        PrintLog("ORDER_REASON", orderReason, true);

        // Place a new order with appropriate parameters
        int orderTicket = PlaceNewOrder(orderType, orderLots, takeProfit, newArrowColor, orderReason);

        // Handle order result and logging
        HandleOrderResult(orderTicket, orderType, orderReason);

        return (orderTicket > 0);
    }

    return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetTakeProfitSuffix(const int orderType)
{
    return (orderType == OP_BUY || orderType == OP_BUYLIMIT || orderType == OP_BUYSTOP) ?
           BUY_TP_LINE_SUFFIX : SELL_TP_LINE_SUFFIX;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsValidCandleForOrderType(const int orderType, const bool isBullish, const bool isBearish)
{
    return ((orderType == OP_BUY || orderType == OP_BUYLIMIT || orderType == OP_BUYSTOP) && isBullish) ||
           ((orderType == OP_SELL || orderType == OP_SELLLIMIT || orderType == OP_SELLSTOP) && isBearish);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool HandleBreakevenPivotFilter(const int orderType, const bool isBullish, const bool isBearish)
{
    if ((orderType == OP_BUY || orderType == OP_BUYLIMIT || orderType == OP_BUYSTOP) && isBullish) {
        PrintLog(__FUNCTION__, StringFormat("HANDLE BUY FILTER: BuyFilterPercent=%.1f%% (as lowest), SellFilterPercent=%.1f%% (as highest)",
                                            inputParams.IN_BuyBePivotFilterPercentage, inputParams.IN_SellBePivotFilterPercentage), true);
        return IsBuyOrderAllowedWithBreakevenPivot(
                   inputParams.IN_EnableBuyBePivotFilter,
                   2, // totalBuys + totalBuystops
                   inputParams.IN_BuyBePivotFilterTimeframe,
                   inputParams,
                   PROGRAM_ID,
                   0, // index
                   inputParams.IN_BuyBePivotFilterPercentage, // lowestThresholdPercentage
                   inputParams.IN_SellBePivotFilterPercentage, // highestThresholdPercentage
                   GetBID(Symbol(), Digits())
               );
    }

    if ((orderType == OP_SELL || orderType == OP_SELLLIMIT || orderType == OP_SELLSTOP) && isBearish) {
        PrintLog(__FUNCTION__, StringFormat("HANDLE SELL FILTER: SellFilterPercent=%.1f%% (as lowest), BuyFilterPercent=%.1f%% (as highest)",
                                            inputParams.IN_SellBePivotFilterPercentage, inputParams.IN_BuyBePivotFilterPercentage), true);
        return IsSellOrderAllowedWithBreakevenPivot(
                   inputParams.IN_EnableSellBePivotFilter,
                   2, // totalSells + totalSellstops
                   inputParams.IN_SellBePivotFilterTimeframe,
                   inputParams,
                   PROGRAM_ID,
                   0, // index
                   inputParams.IN_SellBePivotFilterPercentage, // lowestThresholdPercentage
                   inputParams.IN_BuyBePivotFilterPercentage, // highestThresholdPercentage
                   GetBID(Symbol(), Digits())
               );
    }

    return true;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int PlaceNewOrder(const int orderType, const double orderLots, const double takeProfit,
                  const color newArrowColor, const string orderReason = "")
{
    bool hiddenStopLoss = false;
    bool hiddenTakeProfit = true;

// Hidden feature only makes sense if the EA is not running in optimization mode
    if (IsOptimization()) {
        hiddenStopLoss = false;
        hiddenTakeProfit = false;
    }

// Form a meaningful comment based on order reason
    string orderComment = "";
    if (orderReason != "") {
        orderComment = "Swing-Continuous";
    }

// Log the reason separately (full detailed explanation)
    if (orderReason != "") {
        PrintLog("ORDER_REASON", orderReason + " - Placing " + GetOrderTypeString(orderType) + " order", true);
    }

// *** CENTRALIZED TP: Get unified take profit instead of using passed parameter ***
    double unifiedTP = GetUnifiedTakeProfit(orderType, false);
    double finalTakeProfit = unifiedTP;

// Convert to price level if using manual TP
    if (IN_EnableManualTakeProfit && unifiedTP > 0) {
        if (orderType == OP_BUY || orderType == OP_BUYLIMIT || orderType == OP_BUYSTOP) {
            finalTakeProfit = GetASK(Symbol(), Digits()) + (unifiedTP * Pip());
        }
        else {
            finalTakeProfit = GetBID(Symbol(), Digits()) - (unifiedTP * Pip());
        }
    }

// Place a new order with the unified TP
    return OrderSendModule(
               Symbol(),
               Digits(),
               Pip(),
               orderType,
               orderLots,
               0.0, 5,
               IN_EnableStopLoss ? CalculateDynamicStopLossInPips(inputParams) : 0,
               finalTakeProfit,
               false, !IN_EnableManualTakeProfit, orderComment,
               IN_MagicNumber,
               0,
               newArrowColor,
               3, // maxRetries
               hiddenStopLoss,
               hiddenTakeProfit
           );
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void HandleOrderResult(const int orderTicket, const int orderType, const string orderReason = "")
{
    string orderTypeStr = GetOrderTypeString(orderType);

    if (orderTicket < 1) {
        // Log and print unsuccessful order placement
        string logMessage = StringFormat("Failed to open %s order", orderTypeStr);
        if (orderReason != "") {
            logMessage += " (" + orderReason + ")";
        }
        PrintLog(__FUNCTION__, logMessage);
    }
    else {
        // Log and print successful order placement
        string formattedMessage = GenerateOrderDescription(orderTicket);

        // Include order reason if provided
        if (orderReason != "") {
            PrintLog(__FUNCTION__, orderReason + " -> " + formattedMessage, true);
        }
        else {
            PrintLog(__FUNCTION__, formattedMessage, false);
        }

        string successMessage = StringFormat("Order #%d was opened due to 'Swing Continuous Mode' feature.", orderTicket);
        PrintLog(__FUNCTION__, successMessage);

        // Notify user if alerts are enabled
        if (enableAlerts) {
            string alertMessage = StringFormat("%s order %d at %s %s", orderTypeStr, orderTicket, Symbol(), GetTimeframeName(Period()));
            Notify(alertMessage, true, false, false, false, "");
            PrintLog(__FUNCTION__, alertMessage, false);
        }
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string HandleTradingMode(const bool onNewBar, const TradingMode tradingMode)
{
    string comment = "";

    switch (tradingMode) {
    case kSingleMode:
        comment = "\nTrading Mode: Single Mode";
        break;

    case kSwingContinuousMode:
        comment = "\nTrading Mode: Swing Continuous Mode";
        HandleSwingContinuousNewOrderOnNewBar(onNewBar);
        break;

    default:
        comment = "\nTrading Mode: Unknown";
        break;
    }

    return comment;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetTradingModeString(const InputParameters &extParams)
{
    const string MODE_STRINGS[] = {
        "Single Mode",           // kSingleMode
        "Swing Continuous Mode"  // kSwingContinuousMode
    };

    return (extParams.IN_TradingMode >= 0 &&
            extParams.IN_TradingMode < ArraySize(MODE_STRINGS))
           ? MODE_STRINGS[extParams.IN_TradingMode]
           : "Unknown";
}

//+------------------------------------------------------------------+
//| Calculate and cache unified take profit for a given direction    |
//+------------------------------------------------------------------+
double GetUnifiedTakeProfit(const int orderDirection, bool forceRecalculate = false)
{
// Check if we need to recalculate (new bar or forced)
    datetime currentBarTime = Time[0];
    bool shouldRecalculate = forceRecalculate ||
                             (currentBarTime != LastTPCalculationTime) ||
                             (orderDirection == OP_BUY && GlobalBuyTakeProfit == 0.0) ||
                             (orderDirection == OP_SELL && GlobalSellTakeProfit == 0.0);

    if (!shouldRecalculate) {
        // Return cached value
        return (orderDirection == OP_BUY) ? GlobalBuyTakeProfit : GlobalSellTakeProfit;
    }

// Create appropriate signal info for TP calculation
    SignalInfo signalInfo;
    signalInfo.buyEntry = (orderDirection == OP_BUY);
    signalInfo.sellEntry = (orderDirection == OP_SELL);
    signalInfo.buyAllowed = false;
    signalInfo.sellAllowed = false;
    signalInfo.entrySignal = -1;
    signalInfo.message = "";

// Calculate the take profit using centralized function
    double calculatedTP = DetermineTakeProfit(
                              IN_EnableManualTakeProfit,
                              IN_TakeProfitInPips,
                              IN_EnableMHMLTakeProfit,
                              signalInfo,
                              IN_MHMLMarkerTakeProfitTimeframe,
                              IN_MHMLMarkerTakeProfitPerc,
                              false
                          );

// Cache the result and update timestamp
    if (orderDirection == OP_BUY) {
        GlobalBuyTakeProfit = calculatedTP;

        // Log the new unified TP for buy orders
        string logMessage = StringFormat("Unified Buy TP calculated: %.5f", calculatedTP);
        PrintLog(__FUNCTION__, logMessage, true);
    }
    else if (orderDirection == OP_SELL) {
        GlobalSellTakeProfit = calculatedTP;

        // Log the new unified TP for sell orders
        string logMessage = StringFormat("Unified Sell TP calculated: %.5f", calculatedTP);
        PrintLog(__FUNCTION__, logMessage, true);
    }

    LastTPCalculationTime = currentBarTime;

    return calculatedTP;
}

//+------------------------------------------------------------------+
//| Update all open orders of a direction to use unified TP         |
//+------------------------------------------------------------------+
void UpdateOrdersToUnifiedTP(const int orderDirection)
{
    double unifiedTP = GetUnifiedTakeProfit(orderDirection, false);
    if (unifiedTP <= 0.0) return;

    bool isBuyDirection = (orderDirection == OP_BUY);
    string directionStr = isBuyDirection ? "BUY" : "SELL";
    int ordersUpdated = 0;

// Convert to price level if using manual TP (pips to price)
    double takeProfitPrice = unifiedTP;
    if (IN_EnableManualTakeProfit) {
        if (isBuyDirection) {
            takeProfitPrice = GetASK(Symbol(), Digits()) + (unifiedTP * Pip());
        }
        else {
            takeProfitPrice = GetBID(Symbol(), Digits()) - (unifiedTP * Pip());
        }
    }

// Loop through all orders and update matching direction
    for (int i = 0; i < CountOrdersInPool(MODE_TRADES); i++) {
        if (!IsValidOrder(i, Symbol(), IN_MagicNumber, "", kMustIncludeString, MODE_TRADES)) continue;

        int orderType = OrderType();
        int orderTicket = OrderTicket();

        // Check if this order matches our target direction
        bool isMatchingOrder = false;
        if (isBuyDirection && (orderType == OP_BUY || orderType == OP_BUYLIMIT || orderType == OP_BUYSTOP)) {
            isMatchingOrder = true;
        }
        else if (!isBuyDirection && (orderType == OP_SELL || orderType == OP_SELLLIMIT || orderType == OP_SELLSTOP)) {
            isMatchingOrder = true;
        }

        if (!isMatchingOrder) continue;

        // Update the order's take profit (only if different from current)
        double currentTP = OrderTakeProfit();
        if (MathAbs(currentTP - takeProfitPrice) > Point()) {
            bool modified = CustomOrderModify(
                                orderTicket,
                                OrderOpenPrice(),
                                OrderStopLoss(),
                                takeProfitPrice,
                                OrderExpiration(),
                                Digits(),
                                clrNONE,
                                1
                            );

            if (modified) {
                ordersUpdated++;

                // Also update hidden TP line if it exists
                string tpLineSuffix = isBuyDirection ? BUY_TP_LINE_SUFFIX : SELL_TP_LINE_SUFFIX;
                string tpLineName = StringFormat("%d%s%d", IN_MagicNumber, tpLineSuffix, orderTicket);

                if (ObjectFind(0, tpLineName) != -1) {
                    ObjectSetDouble(0, tpLineName, OBJPROP_PRICE, takeProfitPrice);
                }
            }
        }
    }

    if (ordersUpdated > 0) {
        string logMessage = StringFormat("Updated %d %s orders to unified TP: %.5f",
                                         ordersUpdated, directionStr, takeProfitPrice);
        PrintLog(__FUNCTION__, logMessage, true);
    }
}

//+------------------------------------------------------------------+
//| Force recalculation and update of all unified take profits      |
//+------------------------------------------------------------------+
void RecalculateAllUnifiedTakeProfits()
{
// Force recalculation for both directions
    GetUnifiedTakeProfit(OP_BUY, true);
    GetUnifiedTakeProfit(OP_SELL, true);

// Update all existing orders to use the new unified TPs
    UpdateOrdersToUnifiedTP(OP_BUY);
    UpdateOrdersToUnifiedTP(OP_SELL);

    PrintLog(__FUNCTION__, "All unified take profits recalculated and applied", true);
}

#endif //__ORDER_MANAGEMENT__
//+------------------------------------------------------------------+
