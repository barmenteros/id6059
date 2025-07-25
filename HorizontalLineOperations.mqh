﻿//+------------------------------------------------------------------+
//|                                     HorizontalLineOperations.mqh |
//|                                 Copyright © 2023, barmenteros FX |
//|                                          https://barmenteros.com |
//+------------------------------------------------------------------+
#ifndef __HORIZONTAL_LINE_OPERATIONS__
#define __HORIZONTAL_LINE_OPERATIONS__

#include <Custom\Development\Logging.mqh>
#include <Custom\Development\Utils.mqh>

struct HorizontalLine {
    double priceLevel;
    int visibility;
};

// This function abstracts the creation of a horizontal line in MetaTrader 4. It is designed to
// handle both live and optimization modes in the Strategy Tester. In live mode, it creates a graphical
// horizontal line on the chart, provided an object with the same name doesn't already exist.
// In optimization mode, it populates a data structure to emulate the horizontal line,
// as graphical objects are not allowed in this mode. This dual approach ensures compatibility
// and function regardless of the trading environment.
bool CreateHorizontalLine(const long chartId,
                          const string lineName,
                          const int subWindow,
                          const double priceLevel,
                          const color clr,
                          const int visibility,
                          const ENUM_LINE_STYLE style,
                          const int width,
                          const bool background,
                          const bool selectable,
                          const bool selected,
                          const int zOrder,
                          HorizontalLine &hlStruct,
                          const bool useStruct = true)
{
    if (IsOptimization()) {
        if (useStruct) {
            hlStruct.priceLevel = priceLevel;
            hlStruct.visibility = visibility;
        }
        return true;
    }
    else {
        // Check if object with the same name already exists
        if (ObjectFind(chartId, lineName) == -1) {
            return HLineCreate(chartId, lineName, subWindow, priceLevel, clr, visibility, style, width, background, selectable, selected, zOrder);
        }
        return true;  // Object already exists, so no need to create a new one
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetHorizontalLinePriceLevel(const long chartId, const string lineName, HorizontalLine &hlStruct)
{
    if (IsOptimization()) {
        return hlStruct.priceLevel;
    }
    else {
        if (ObjectFind(chartId, lineName) != -1) {
            double priceLevel = ObjectGetDouble(chartId, lineName, OBJPROP_PRICE);
            if (IsZero(priceLevel)) {
                string logMessage = StringFormat("Unable to fetch the price level of the line object '%s'.", lineName);
                PrintLog(__FUNCTION__, logMessage);
            }
            return priceLevel;
        }
        else {
            string logMessage = StringFormat("Object '%s' not found, unable to fetch the price level.", lineName);
            PrintLog(__FUNCTION__, logMessage);
            return 0.0;
        }
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetHorizontalLinePriceLevel(const long chartId, const string lineName)
{
    if (ObjectFind(chartId, lineName) != -1) {
        double priceLevel = ObjectGetDouble(chartId, lineName, OBJPROP_PRICE);
        if (IsZero(priceLevel)) {
            string logMessage = StringFormat("Unable to fetch the price level of the line object '%s'.", lineName);
            PrintLog(__FUNCTION__, logMessage);
        }
        return priceLevel;
    }
    else {
        string logMessage = StringFormat("Object '%s' not found, unable to fetch the price level.", lineName);
        PrintLog(__FUNCTION__, logMessage);
        return 0.0;
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MoveHorizontalLine(const long chartId,
                        const string lineName,
                        const double newPriceLevel,
                        HorizontalLine &hlStruct)
{
    if (IsOptimization()) {
        hlStruct.priceLevel = newPriceLevel;
        return true;
    }
    else {
        if (ObjectFind(chartId, lineName) != -1) {
            bool status = ObjectSetDouble(chartId, lineName, OBJPROP_PRICE, newPriceLevel);
            if (!status) {
                string logMessage = StringFormat("Unable to update the price level of the line object '%s'.", lineName);
                PrintLog(__FUNCTION__, logMessage);
            }
            return status;
        }
        else {
            string logMessage = StringFormat("Object '%s' not found, unable to move or update the price level.", lineName);
            PrintLog(__FUNCTION__, logMessage);
            return false;
        }
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ShowHorizontalLine(const long chartId, const string lineName, HorizontalLine &hlStruct)
{
    if (IsOptimization()) {
        hlStruct.visibility = OBJ_ALL_PERIODS;
        return true;
    }
    else {
        if (ObjectFind(chartId, lineName) != -1) {
            bool status = ObjectSetInteger(chartId, lineName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
            if (!status) {
                string logMessage = StringFormat("Unable to make the line object '%s' visible.", lineName);
                PrintLog(__FUNCTION__, logMessage);
            }
            return status;
        }
        else {
            string logMessage = StringFormat("Object '%s' not found, unable to make it visible.", lineName);
            PrintLog(__FUNCTION__, logMessage);
            return false;
        }
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool HideHorizontalLine(const long chartId, const string lineName, HorizontalLine &hlStruct)
{
    if (IsOptimization()) {
        hlStruct.visibility = OBJ_NO_PERIODS;
        return true;
    }
    else {
        if (ObjectFind(chartId, lineName) != -1) {
            bool status = ObjectSetInteger(chartId, lineName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
            if (!status) {
                string logMessage = StringFormat("Unable to hide the line object '%s'.", lineName);
                PrintLog(__FUNCTION__, logMessage);
            }
            return status;
        }
        else {
            string logMessage = StringFormat("Object '%s' not found, unable to hide it.", lineName);
            PrintLog(__FUNCTION__, logMessage);
            return false;
        }
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsHorizontalLineVisible(const long chartId, const string lineName, const HorizontalLine &hlStruct)
{
    if (IsOptimization()) {
        return (hlStruct.visibility == OBJ_ALL_PERIODS);
    }
    else {
        if (ObjectFind(chartId, lineName) != -1) {
            int visibility = (int)ObjectGetInteger(chartId, lineName, OBJPROP_TIMEFRAMES);
            bool status = (visibility == OBJ_ALL_PERIODS);
            //if (!status) {
            //    string logMessage = StringFormat("The line object '%s' is not visible.", lineName);
            //    PrintLog(__FUNCTION__, logMessage);
            //}
            return status;
        }
        else {
            string logMessage = StringFormat("Object '%s' not found, unable to determine its visibility.", lineName);
            PrintLog(__FUNCTION__, logMessage);
            return false;
        }
    }
}
//+------------------------------------------------------------------+
//| Create the horizontal line                                       |
//+------------------------------------------------------------------+
bool HLineCreate(const long            chart_ID=0,        // chart's ID
                 const string          name="HLine",      // line name
                 const int             sub_window=0,      // subwindow index
                 double                price=0,           // line price
                 const color           clr=clrRed,        // line color
                 const int             timeframes=OBJ_ALL_PERIODS,
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style
                 const int             width=1,           // line width
                 const bool            back=false,        // in the background
                 const bool            selectable=true,    // highlight to move
                 const bool            selected=true,
                 const bool            hidden=true,       // hidden in the object list
                 const long            z_order=0)         // priority for mouse click
{
//--- if the price is not set, set it at the current Bid price level
    if(!price)
        price=SymbolInfoDouble(Symbol(), SYMBOL_BID);
//--- reset the error value
    ResetLastError();
//--- create a horizontal line
    if(!ObjectCreate(chart_ID, name, OBJ_HLINE, sub_window, 0, price)) {
        string logMessage = StringFormat("failed to create a horizontal line! Error code = %d", GetLastError());
        PrintLog(__FUNCTION__, logMessage, false);
        return(false);
    }
    ObjectSetInteger(chart_ID, name, OBJPROP_TIMEFRAMES, timeframes);
//--- set line color
    ObjectSetInteger(chart_ID, name, OBJPROP_COLOR, clr);
//--- set line display style
    ObjectSetInteger(chart_ID, name, OBJPROP_STYLE, style);
//--- set line width
    ObjectSetInteger(chart_ID, name, OBJPROP_WIDTH, width);
//--- display in the foreground (false) or background (true)
    ObjectSetInteger(chart_ID, name, OBJPROP_BACK, back);
//--- enable (true) or disable (false) the mode of moving the line by mouse
    ObjectSetInteger(chart_ID, name, OBJPROP_SELECTABLE, selectable);
    ObjectSetInteger(chart_ID, name, OBJPROP_SELECTED, selected);
//--- hide (true) or display (false) graphical object name in the object list
    ObjectSetInteger(chart_ID, name, OBJPROP_HIDDEN, hidden);
//--- set the priority for receiving the event of a mouse click in the chart
    ObjectSetInteger(chart_ID, name, OBJPROP_ZORDER, z_order);
//--- successful execution
    return(true);
}
//+------------------------------------------------------------------+
//| Move horizontal line                                             |
//+------------------------------------------------------------------+
bool HLineMove(const long   chart_ID=0,   // chart's ID
               const string name="HLine", // line name
               double       price=0)      // line price
{
//--- if the line price is not set, move it to the current Bid price level
    if(!price)
        price=SymbolInfoDouble(Symbol(), SYMBOL_BID);
//--- reset the error value
    ResetLastError();
//--- move a horizontal line
    if(!ObjectMove(chart_ID, name, 0, 0, price)) {
        Print(__FUNCTION__,
              ": failed to move the horizontal line! Error code = ", GetLastError());
        return(false);
    }
//--- successful execution
    return(true);
}
//+------------------------------------------------------------------+
//| Delete a horizontal line                                         |
//+------------------------------------------------------------------+
bool HLineDelete(const long   chart_ID=0,   // chart's ID
                 const string name="HLine") // line name
{
//--- reset the error value
    ResetLastError();
//--- delete a horizontal line
    if(!ObjectDelete(chart_ID, name)) {
        Print(__FUNCTION__,
              ": failed to delete a horizontal line! Error code = ", GetLastError());
        return(false);
    }
//--- successful execution
    return(true);
}
// This function deletes a graphical horizontal line or resets the corresponding data structure.
// In live mode, it removes the graphical line from the chart. In optimization mode, it resets
// the data structure to an initial state. This function is typically called during the OnDeinit
// event to clean up resources.
bool DeleteHorizontalLine(const long chartId, const string lineName, HorizontalLine &hlStruct)
{
    if (IsOptimization()) {
        hlStruct.priceLevel = 0;
        hlStruct.visibility = 0;
        return true;
    }
    else {
        // Delete the graphical object if it exists
        if (ObjectFind(chartId, lineName) != -1) {
            return HLineDelete(chartId, lineName);
        }
        return true;  // Object doesn't exist, so no need for deletion
    }
}

#endif //__HORIZONTAL_LINE_OPERATIONS__
//+------------------------------------------------------------------+
