//+------------------------------------------------------------------+
//|                                               DebuggingTools.mqh |
//|                                 Copyright © 2023, barmenteros FX |
//|                                          https://barmenteros.com |
//+------------------------------------------------------------------+
#include <Custom\Development\Logging.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void LogGlobalLineStructures()
{
    string logMessage;

    // Log the breakeven line structure
    logMessage = StringFormat("Breakeven Line - Price Level: %f, Visibility: %d",
                              breakevenLineStruct.priceLevel,
                              breakevenLineStruct.visibility);
    PrintLog(__FUNCTION__, logMessage, false);

    // Log the buy reverse order line structure
    logMessage = StringFormat("Buy Reverse Order Line - Price Level: %f, Visibility: %d",
                              buyReverseOrderLineStruct.priceLevel,
                              buyReverseOrderLineStruct.visibility);
    PrintLog(__FUNCTION__, logMessage, false);

    // Log the sell reverse order line structure
    logMessage = StringFormat("Sell Reverse Order Line - Price Level: %f, Visibility: %d",
                              sellReverseOrderLineStruct.priceLevel,
                              sellReverseOrderLineStruct.visibility);
    PrintLog(__FUNCTION__, logMessage, false);
}
//+------------------------------------------------------------------+
