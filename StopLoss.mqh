﻿//+------------------------------------------------------------------+
//|                                                     StopLoss.mqh |
//|                                 Copyright © 2023, barmenteros FX |
//|                                          https://barmenteros.com |
//+------------------------------------------------------------------+
#ifndef __STOPLOSS__
#define __STOPLOSS__

#include <Custom\Development\Logging.mqh>
#include "ArrowSignals.mqh"
#include "CommonFunctions.mqh"

struct StopLossTypeInfo {
    StopLossType     type;
    string           name;
    int              value;
};

StopLossTypeInfo stopLossTypes[2]; // Adjust size based on the number of Stop Loss types

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InitializeStopLossTypeInfo()
{
    stopLossTypes[0].type = kManualSL;
    stopLossTypes[0].name = "Manual";
    stopLossTypes[0].value = IN_StopLossInPips;

    stopLossTypes[1].type = kATRSL;
    stopLossTypes[1].name = "ATR";
    stopLossTypes[1].value = IN_StopLossATRMultiplier;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetStopLossComment(InputParameters &extParams)
{
    string comment = "\nStop Loss: ";
    for(int i = 0; i < ArraySize(stopLossTypes); i++) {
        if(stopLossTypes[i].type == extParams.IN_StopLossType) {
            comment += StringFormat("%s (%d)", stopLossTypes[i].name, stopLossTypes[i].value);
            return comment;
        }
    }

    return comment + "Unknown Type";
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateDynamicStopLossInPips(InputParameters &extParams)
{
    switch(extParams.IN_StopLossType) {
    case kManualSL:
        return extParams.IN_StopLossInPips;

    case kATRSL: {
        double atrValue = GetATR(StopLossATRtimeframe, StopLossATRPeriod, 1); // Calculate ATR for the previous bar
        return atrValue * extParams.IN_StopLossATRMultiplier / Pip();
    }

// Add additional Stop Loss types here

    default:
        Print("Unknown Stop Loss type");
        return 0; // Default or error value
    }
}

#endif //__STOPLOSS__
//+------------------------------------------------------------------+
