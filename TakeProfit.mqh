﻿//+------------------------------------------------------------------+
//|                                                   TakeProfit.mqh |
//|                                 Copyright © 2023, barmenteros FX |
//|                                          https://barmenteros.com |
//+------------------------------------------------------------------+
#include <Custom\Development\Logging.mqh>
#include "ArrowSignals.mqh"

/**
 * The current implementation of this function is based on specifications
 * received from a customer email dated November 8, 2023, at 6:59 AM.
 */

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void HandleBuyPositionsOnMADownwardCrossover()
{
    const int index = 0;
    if(IsSellArrowPresent(index)) {
        string logMessage = StringFormat("Closing/deleting all Buy positions due to a valid sell arrow at %s", TimeToString(Time[index]));
        PrintLog(__FUNCTION__, logMessage, true);
        const int slippage = 5;
        CloseAll(Symbol(), Digits(), IN_MagicNumber, slippage, "", 1, OP_BUY, clrGoldenrod);
        DeleteAllTypePositions(OP_BUYSTOP);
        DeleteAllTypePositions(OP_BUYLIMIT);
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void HandleSellPositionsOnMAUpwardCrossover()
{
    const int index = 0;
    if(IsBuyArrowPresent(index)) {
        string logMessage = StringFormat("Closing/deleting all Sell positions due to a valid buy arrow at %s", TimeToString(Time[index]));
        PrintLog(__FUNCTION__, logMessage, true);
        const int slippage = 5;
        CloseAll(Symbol(), Digits(), IN_MagicNumber, slippage, "", 1, OP_SELL, clrGoldenrod);
        DeleteAllTypePositions(OP_SELLSTOP);
        DeleteAllTypePositions(OP_SELLLIMIT);
    }
}
//+------------------------------------------------------------------+
