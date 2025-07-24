//+------------------------------------------------------------------+
//|                                     THA KAD - ZARIUM CORE EA.mq4 |
//|                                   Copyright © 2023, JLTHAKAD LLC |
//|                  Developed by barmenteros FX                     |
//|                  Website: https://barmenteros.com                |
//|                  Email: support.team@barmenteros.com             |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2023, JLTHAKAD LLC"
#property link      "jesse.fields92@gmail.com"
#define EA_NAME     "THA KAD - ZARIUM CORE EA"
#define EA_VERSION  "5.60"
#property version   EA_VERSION
#property strict

// TODO: SAVE ALL THE TP & SL LINES ON DEINIT & LOAD ALL THESE VALUES ON INIT (deleting the file).

//+------------------------------------------------------------------+
// Note: OnTimer event is intentionally not used in this EA.
// Reason: The client has specified that the EA must be compatible with the
// Strategy Tester, including running in optimization mode. The OnTimer event
// is not supported in the Strategy Tester environment. Therefore, to ensure
// full compatibility, OnTimer is not implemented in this EA.
//+------------------------------------------------------------------+

#import "stdlib.ex4"
string ErrorDescription (int error_code);
#import

#define COLOR_UP    clrTeal    // Angel/positive values
#define COLOR_DOWN  clrPurple  // Dragon/negative values
#define COLOR_BG    C'33,33,33' // Panel background
#define CLOSE_BUYS_TEXT   "CLOSE BUYS"
#define CLOSE_SELLS_TEXT   "CLOSE SELLS"
#define CLOSE_ALL_TEXT   "CLOSE ALL"

// Include Files
#include <Custom\Development\Logging.mqh>
#include <Custom\Development\Utils.mqh>
#include <Custom\Development\FileOperations.mqh>
#include <Custom\Development\PositionSizeCalculator.mqh>
#include "CommonInputParams.mqh"
#include "InputParametersHandler.mqh"
#include "HorizontalLineOperations.mqh"
#include "DebuggingTools.mqh"
#include "NewsFilter.mqh"
#include "TradingDays.mqh"
#include "TimeManagement.mqh"
#include "SpreadManagement.mqh"
#include "PositionSize.mqh"
#include "BreakevenFilter.mqh"
#include "BreakevenPivotFilter.mqh"
#include "ReverseFilter.mqh"
#include "ProfitCalculations.mqh"
#include "OrderManagement.mqh"
#include "TradingConditions.mqh"
#include "Trailing.mqh"
#include "InfoPanel.mqh"
#include "ArrowSignals.mqh"
#include "TakeProfit.mqh"
#include "StopLoss.mqh"
#include "MoneyManagement.mqh"
#include "GlobalSettings.mqh"
#include "CommonFunctions.mqh"
#include "ADXFilter.mqh"

SPanelSettings g_panelSettings;
string g_mainPanelName = "InfoPanel";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
// Initialize the log filename
    LogInit(__FUNCTION__, MAGIC_ID);

// Log all input parameters
    string inputParamsString = AssembleInputParamsString();
    PrintLog(__FUNCTION__, inputParamsString, false);

    AssignInputParametersToStruct(inputParams);
    customFileName = StringFormat("%d_%s%d", IN_MagicNumber, Symbol(), Period());
    SaveSettingsToFile(customFileName, inputParams);

// Initialize or reset the trading state
    TradingActive = true; // Start with trading active

    string outMessage = "";
    if(!CheckAutomatedTradingPermission(outMessage)) {
        Print("Initialization failed: ", outMessage);
        PrintLog("", outMessage, true);
        return INIT_FAILED;
    }

    if (!InitializeBreakevenLine() || !InitializeReverseLines()) {
        return INIT_FAILED;
    }

    InitializeTradingDays(tradingDays);

    InitializeOrderSettings();

    CurrentBuyOrderMultiplier = IN_BuyOrderMultiplier;
    CurrentSellOrderMultiplier = IN_SellOrderMultiplier;

// Initialize money management tracking variables
    lastReachedPositiveTarget = 0.0;

// Set initial targets based on current balance
    double initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    if (EnablePositiveEquityTarget) {
        nextPositiveEquityTarget = initialBalance + PositiveEquityTarget;
        PrintLog(__FUNCTION__, StringFormat("Initial positive equity target set to %.2f", nextPositiveEquityTarget));
    }

    if (EnableNegativeEquityLimit) {
        nextNegativeEquityTarget = initialBalance - NegativeEquityLimit;
        PrintLog(__FUNCTION__, StringFormat("Initial negative equity target set to %.2f", nextNegativeEquityTarget));
    }

// Initialize the Stop Loss types
    InitializeStopLossTypeInfo();

// The ExecuteSignals function is called in both OnInit and OnTick to ensure
// that all the necessary trading signals are updated at the start and
// continuously with each new market tick. This approach is critical for
// maintaining the responsiveness and accuracy of the trading strategy.
// In OnInit, it initializes the indicators, setting the stage for the EA's
// operation. In OnTick, it keeps the indicators updated in real-time, ensuring
// that the EA's decisions are based on the most current market data.
    ExecuteSignals();

    CheckTakeProfitSettings(IN_EnableManualTakeProfit, IN_EnableMHMLTakeProfit);

// Call the function to fill the array with the enabled statuses and timeframes
    FillTimeframeStatusArray(TimeframesMHMLMarker);

// Initialize money management tracking variables
    lastReachedPositiveTarget = 0.0;
    nextNegativeEquityTarget = NegativeEquityLimit;

    InitializeInfoPanel();

    return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Comment("");

    DeleteSettingsFile(customFileName);

    DeleteHorizontalLine(0, breakevenLineName, breakevenLineStruct);
    DeleteHorizontalLine(0, buyReverseOrderLineName, buyReverseOrderLineStruct);
    DeleteHorizontalLine(0, sellReverseOrderLineName, sellReverseOrderLineStruct);

// Clean up global variables if:
// 1. EA is being removed from the chart
// 2. Terminal is closing
// 3. We're in Strategy Tester (to prevent variables persisting between test runs)
    if(reason == REASON_REMOVE || reason == REASON_CLOSE || IsTesting()) {
        if(GlobalVariableCheck(GLOBAL_VAR_PAUSED))
            GlobalVariableDel(GLOBAL_VAR_PAUSED);
        if(GlobalVariableCheck(GLOBAL_VAR_PAUSE_END_TIME))
            GlobalVariableDel(GLOBAL_VAR_PAUSE_END_TIME);

        PrintLog(__FUNCTION__, "Trading pause global variables cleaned up", false);
    }

    DeinitializeInfoPanel();

    LogDeinit(__FUNCTION__, reason);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    /*
        static int iteration = 0;
        string logMsg = StringFormat("iteration=%d inputParams.IN_StopLossATRMultiplier=%d at %s", iteration, inputParams.IN_StopLossATRMultiplier, TimeToString(Time[0]));
        PrintLog(__FUNCTION__, logMsg, true);
        iteration++;
    */

// ---------------- Initialization ---------------- //

// Update the tradingActive status based on the resume logic
    TradingActive = ResumeTrading();

// Centralized Monitoring of Current and Last Price
//
// Rationale:
// Centralizing the tracking of 'currentPrice' and 'lastPrice' ensures that all
// functions within the script are using the same reference values for these
// variables. This eliminates the risk of discrepancies or errors that may arise
// if these variables were monitored separately within each function.
// Additionally, it improves maintainability by having a single point of update.
//
    static double lastPrice = 0;
    double currentPrice = Close[0];

// Create the lines if they have been deleted
// Useful in the case a template is used deleting the lines
    InitializeBreakevenLine();
    InitializeReverseLines();

// The ExecuteSignals function is called in both OnInit and OnTick to ensure
// that all the necessary trading signals are updated at the start and
// continuously with each new market tick. This approach is critical for
// maintaining the responsiveness and accuracy of the trading strategy.
// In OnInit, it initializes the indicators, setting the stage for the EA's
// operation. In OnTick, it keeps the indicators updated in real-time, ensuring
// that the EA's decisions are based on the most current market data.
//ExecuteSignals();

    ProcessTrailingStopLossAndModifyPositions(IN_TrailStopType, TimeframesMHMLMarker, inputParams, PROGRAM_ID, IN_MagicNumber, Symbol());

// Initialize the comment string to display EA details on the chart
    string comment = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";

// Append trading and take-profit type information to the comment
//comment += StringFormat("\nTrading: %s", (IN_OrdersToTrade == kMarketOrders ? "Market orders" : "Pending orders"));

// Updated as per customer's request to remove 'Closed Candle' and 'Breakeven' options.
// Future work will include 'Fixed Take Profit' in terms of percentage after indicator integration.
//comment += StringFormat("\nTake profit: Manual (%d pips)", IN_TakeProfitInPips);

//if(IN_EnableStopLoss) {
//    comment += GetStopLossComment(inputParams);
//}
//else {
//    comment += "\nStop Loss: OFF";
//}

// ---------------- Fetch Market Data ---------------- //

    datetime timeCurrent = TimeCurrent();
    double breakevenPrice = GetHorizontalLinePriceLevel(0, breakevenLineName, breakevenLineStruct);

// ---------------- Money Management ---------------- //
// Update the tradingActive status based on the resume logic
    TradingActive = ResumeTrading();

    CheckUnrealizedProfit();
    CheckEquityTargets(inputParams);

// ---------------- Handle New Bar ---------------- //

    bool onNewBar = OnNewBar(false);
    if (onNewBar) {
        double newPriceLevel = Open[0];
        MoveHorizontalLine(0, breakevenLineName, newPriceLevel, breakevenLineStruct);
        ChartRedraw();
        DeleteAllTypePositions(OP_BUYSTOP);
        DeleteAllTypePositions(OP_SELLSTOP);
    }

// Handle Trading Mode
//comment += HandleTradingMode(onNewBar, IN_TradingMode);
    HandleTradingMode(onNewBar, IN_TradingMode);

// Handle unified take profit updates on new bars (only if orders exist)
    if (onNewBar) {
        OrderCounts counts = GetOrderCounts(IN_MagicNumber);
        bool hasOpenOrders = (counts.totalBuys > 0 || counts.totalSells > 0 ||
                              counts.totalBuystops > 0 || counts.totalSellstops > 0 ||
                              counts.totalBuylimits > 0 || counts.totalSelllimits > 0);

        if (hasOpenOrders) {
            RecalculateAllUnifiedTakeProfits();
        }
        else {
            // Reset cached values when no orders exist
            GlobalBuyTakeProfit = 0.0;
            GlobalSellTakeProfit = 0.0;
        }
    }

// ---------------- Order Management ---------------- //

// Manage Hidden Stop Loss and Take Profit
    MonitorStealthStopLossLevels(5, "", ONLY_MARKET);
    MonitorStealthTakeProfitLevels(5, "", ONLY_MARKET);
    DeleteHiddenLevelsByString("_line@");

// Trailing Stop Management
//comment += ManageTrailingStop(inputParams);
    ManageTrailingStop(inputParams);

// ---------------- Order Status Checks ---------------- //

// Fetch Current Order Counts
    OrderCounts counts = GetOrderCounts(IN_MagicNumber);

// Manage Reverse Order Lines
    ManageReverseOrderLines(counts.totalBuys, counts.totalSells);

// Close Orders at Breakeven if Not New Bar
// This feature has been temporarily disabled. If you need to re-enable it in the future,
// simply uncomment the following lines.
//if(CloseOrdersAtBreakevenIfNotNewBar(onNewBar, currentPrice, breakevenPrice, IN_EnableManualTakeProfit, IN_StopLossType, counts.totalBuys, counts.totalSells)) {
//    counts = GetOrderCounts(IN_MagicNumber);
//}

// ---------------- Signal Evaluation ---------------- //

//IN_BreakevenAtGreyArrows

// Process entry signals and decide whether to proceed with an order
    string buyBETextToDisplay;
    string sellBETextToDisplay;
    SignalInfo signalInfo = UpdateAndEvaluateEntrySignals(
                                inputParams.IN_EnableBeFilter,
                                inputParams.IN_EnableBeReentry,
                                onNewBar,
                                lastPrice,
                                currentPrice,
                                breakevenPrice,
                                inputParams.IN_ReverseOrders,
                                buyBETextToDisplay,
                                sellBETextToDisplay);
//comment += signalInfo.message;

// ---------------- Trading Logic ---------------- //

//comment += currentOrderSettings.allowBuy ? "\nAllow Buys: ON" : "\nAllow Buys: OFF";
//comment += currentOrderSettings.allowSell ? "\nAllow Sells: ON" : "\nAllow Sells: OFF";

    string reverseBuyFilterTxt = "Reverse Buy Filter: --";
    if(currentOrderSettings.reverseBuy) {
        //comment += "\nBuy Reverse Filter: ON";
        //comment += IN_EnableReverseReentry ? "\nBuy Reverse Filter Reentry: ON" : "\nBuy Reverse Filter Reentry: OFF";
        reverseBuyFilterTxt = EvaluateAndExecuteReverseBuy(lastPrice, currentPrice, inputParams);
        //comment += "\n" + reverseBuyFilterTxt;
    }
//else {
//    comment += "\nBuy Reverse Filter: OFF";
//}

    string reverseSellFilterTxt = "Reverse Sell Filter: --";
    if(currentOrderSettings.reverseSell) {
        //comment += "\nSell Reverse Filter: ON";
        //comment += IN_EnableReverseReentry ? "\nSell Reverse Filter Reentry: ON" : "\nSell Reverse Filter Reentry: OFF";
        reverseSellFilterTxt = EvaluateAndExecuteReverseSell(lastPrice, currentPrice, inputParams);
        //comment += "\n" + reverseSellFilterTxt;
    }
//else {
//    comment += "\nSell Reverse Filter: OFF";
//}

// Check overall trading conditions
    ConditionStatus tradingDayStatus;
    ConditionStatus timeManagementStatus;
    ConditionStatus spreadStatus;
    ConditionStatus newsStatus;
    ConditionStatus overallStatus = CheckAllConditions(timeCurrent, tradingDays, tradingDayStatus, timeManagementStatus, spreadStatus, newsStatus);
    comment += newsStatus.message;

    /*
    // Log individual condition statuses before validation check
        string conditionStatuses = StringFormat(
                                       "Trading conditions: allowTrade=%s, TradingActive=%s, buyEntry=%s, sellEntry=%s",
                                       overallStatus.allowTrade ? "true" : "false",
                                       TradingActive ? "true" : "false",
                                       signalInfo.buyEntry ? "true" : "false",
                                       signalInfo.sellEntry ? "true" : "false"
                                   );
        PrintLog("TRADING_CONDITIONS", conditionStatuses, true);
    */

// Validate the overall trading conditions before proceeding
    if (overallStatus.allowTrade && TradingActive && (signalInfo.buyEntry || signalInfo.sellEntry)) {
        // Place trading orders based on the evaluated signals and conditions
        PlaceTradingOrders(signalInfo,
                           breakevenPrice,
                           counts,
                           IN_EnableBeReentry, currentOrderSettings.reverseBuy, currentOrderSettings.reverseSell,
                           inputParams);
    }

// Update lastPrice for the next tick
    lastPrice = currentPrice;

// ---------------- Finalize ---------------- //

// Display Consolidated Comments
    UpdateInfoPanel(buyBETextToDisplay, sellBETextToDisplay, currentOrderSettings,
                    reverseBuyFilterTxt, reverseSellFilterTxt, tradingDayStatus,
                    timeManagementStatus, spreadStatus, timeCurrent);
    Comment(comment);
}
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
{
    LogTester(__FUNCTION__);
    return 0.0;
}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
    HandlePanelButtonClicks(id, sparam);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ExecuteSignals()
{
    GetMH_ML_Marker(inputParams, PROGRAM_ID, 0, 0);
    GetArrowSignal(0, 0);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateMHMLMarkerTakeProfit(const ENUM_TIMEFRAMES timeframe, const double percentage,
                                     const int orderType, const bool debug = false)
{
    ENUM_TIMEFRAMES actualTimeframe = GetActualTimeframe(timeframe);

// Determine the correct buffers based on the actual timeframe
    int buffers[2];
    GetTimeframeBuffers(actualTimeframe, buffers);

    int higherBuffer = buffers[0];
    int lowerBuffer = buffers[1];

// Get the higher and lower levels for the given timeframe
    double higherLevel = GetMH_ML_Marker(inputParams, PROGRAM_ID, higherBuffer, 1);
    double lowerLevel = GetMH_ML_Marker(inputParams, PROGRAM_ID, lowerBuffer, 1);

// Debug output for levels
    if (debug) {
        string timeframeStr = EnumToString(actualTimeframe);
        PrintLog("DEBUG_TP", StringFormat("Timeframe: %s, Higher Level (MH): %.5f, Lower Level (ML): %.5f",
                                          timeframeStr, higherLevel, lowerLevel), true);
    }

// Check for valid levels
    if(higherLevel == 0 || higherLevel == EMPTY_VALUE || lowerLevel == 0 || lowerLevel == EMPTY_VALUE) {
        if (debug) {
            PrintLog("DEBUG_TP", "Invalid level values detected!", true);
        }
        PrintLog(__FUNCTION__, "Invalid level values.");
        return -1.0;
    }

// Special case for 50% - both buy and sell would have the same target
    if(MathAbs(percentage - 50.0) < 0.01) {
        double midPoint = (higherLevel + lowerLevel) / 2.0;
        if (debug) {
            PrintLog("DEBUG_TP", StringFormat("Using 50%% midpoint: %.5f", midPoint), true);
        }
        return midPoint;
    }

    double takeProfitPrice = 0.0;

// Different calculations for buy and sell orders
    if(orderType == OP_BUY) {
        // For buy orders, calculate from LOW to HIGH (target MH region)
        takeProfitPrice = lowerLevel + ((higherLevel - lowerLevel) * (percentage / 100.0));
        if (debug) {
            PrintLog("DEBUG_TP", StringFormat("BUY TP: %.5f (%.1f%% from Low to High)",
                                              takeProfitPrice, percentage), true);
        }
    }
    else if(orderType == OP_SELL) {
        // For sell orders, calculate from HIGH to LOW (target ML region)
        takeProfitPrice = higherLevel - ((higherLevel - lowerLevel) * (percentage / 100.0));
        if (debug) {
            PrintLog("DEBUG_TP", StringFormat("SELL TP: %.5f (%.1f%% from High to Low)",
                                              takeProfitPrice, percentage), true);
        }
    }
    else {
        if (debug) {
            PrintLog("DEBUG_TP", StringFormat("Invalid order type: %d", orderType), true);
        }
        PrintLog(__FUNCTION__, "Invalid order type for take profit calculation.");
        return -1.0;
    }

// Check for a valid takeprofit price
    if(takeProfitPrice == 0.0) {
        if (debug) {
            PrintLog("DEBUG_TP", "Invalid takeprofit calculation resulted in zero!", true);
        }
        PrintLog(__FUNCTION__, "Invalid takeprofit calculation.");
        return -1.0;
    }

    if (debug) {
        string orderTypeStr = (orderType == OP_BUY) ? "BUY" : "SELL";
        PrintLog("DEBUG_TP", StringFormat("Final %s TP: %.5f for percentage: %.1f%%",
                                          orderTypeStr, takeProfitPrice, percentage), true);
    }

    return takeProfitPrice;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteFile(string fileName)
{
// Check if the file exists
    if(FileIsExist(fileName)) {
        // Delete the file
        bool deleteResult = FileDelete(fileName);
        if (!deleteResult) {
            Print("Error deleting file: ", fileName);
        }
    }
    else {
        Print("File not found: ", fileName);
    }
}
//+-----------------------------------------------------------------------+
//| The function receives the number of bars that are displayed (visible) |
//| in the chart window.                                                  |
//+-----------------------------------------------------------------------+
int ChartVisibleBars(const long chart_ID = 0)
{
//--- prepare the variable to get the property value
    long result = -1;
//--- reset the error value
    ResetLastError();
//--- receive the property value
    if(!ChartGetInteger(chart_ID, CHART_VISIBLE_BARS, 0, result)) {
        //--- display the error message in Experts journal
        Print(__FUNCTION__ + ", Error Code = ", GetLastError());
    }
//--- return the value of the chart property
    return((int)result);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InitializeInfoPanel()
{
// Exit early if in optimization mode
    if(IsOptimization()) return;

    g_panelSettings.name = g_mainPanelName;
    g_panelSettings.corner = CORNER_LEFT_UPPER;
    g_panelSettings.x = 5;
    g_panelSettings.y = 20;
    g_panelSettings.width = 250;
    g_panelSettings.height = 445;
    g_panelSettings.bgColor = COLOR_BG;
    g_panelSettings.upColor = COLOR_UP;
    g_panelSettings.downColor = COLOR_DOWN;
    g_panelSettings.fontSize = 8;
    g_panelSettings.tabPadding = 20;
    g_panelSettings.buttonBgColor = COLOR_BG;
    g_panelSettings.buttonTextColor = COLOR_UP;
    g_panelSettings.buttonHeight = 25;
    g_panelSettings.buttonSpacing = 2;
    g_panelSettings.bottomMargin = 5;

    if(!CreateInfoPanel(g_panelSettings)) {
        Print("Failed to create info panel");
        return;
    }

    int yOffset = 10;
    int spacing = 15;

// Initial labels setup
    AddPanelLabel(g_mainPanelName, StringFormat("%s v%s", EA_NAME, EA_VERSION), yOffset, g_panelSettings);
    AddPanelLabel(g_mainPanelName, "Trading: Pending orders", yOffset += spacing, g_panelSettings);
    AddPanelLabel(g_mainPanelName, "Take profit: Manual", yOffset += spacing, g_panelSettings);
    AddPanelLabel(g_mainPanelName, GetStopLossComment(inputParams), yOffset += spacing, g_panelSettings);
    AddPanelLabel(g_mainPanelName, "Trading Mode: Swing Continuous Mode", yOffset += spacing, g_panelSettings);
    AddPanelLabel(g_mainPanelName, "Trail stop: OFF", yOffset += spacing, g_panelSettings);
    AddPanelLabel(g_mainPanelName, "BE Filter:", yOffset += spacing, g_panelSettings);
    AddPanelLabel(g_mainPanelName, "BE Filter Reentry:", yOffset += spacing, g_panelSettings);
    AddPanelLabel(g_mainPanelName, "BE Buy Filter:", yOffset += spacing, g_panelSettings);
    AddPanelLabel(g_mainPanelName, "BE Sell Filter:", yOffset += spacing, g_panelSettings);
    AddPanelLabel(g_mainPanelName, "Allow Buys: OFF", yOffset += spacing, g_panelSettings);
    AddPanelLabel(g_mainPanelName, "Allow Sells: OFF", yOffset += spacing, g_panelSettings);
    AddPanelLabel(g_mainPanelName, "Buy Reverse Filter: OFF", yOffset += spacing, g_panelSettings);
    AddPanelLabel(g_mainPanelName, "Buy Reverse Filter Reentry: OFF", yOffset += spacing, g_panelSettings);
    AddPanelLabel(g_mainPanelName, "Reverse Buy Filter:", yOffset += spacing, g_panelSettings);
    AddPanelLabel(g_mainPanelName, "Sell Reverse Filter: OFF", yOffset += spacing, g_panelSettings);
    AddPanelLabel(g_mainPanelName, "Sell Reverse Filter Reentry: OFF", yOffset += spacing, g_panelSettings);
    AddPanelLabel(g_mainPanelName, "Reverse Sell Filter:", yOffset += spacing, g_panelSettings);
    AddPanelLabel(g_mainPanelName, "Trading Day: OFF", yOffset += spacing, g_panelSettings);
    AddPanelLabel(g_mainPanelName, "Time Management: OFF", yOffset += spacing, g_panelSettings);
    AddPanelLabel(g_mainPanelName, "Spread: OFF", yOffset += spacing, g_panelSettings);
    AddPanelLabel(g_mainPanelName, StringFormat("Current time: %s", TimeToString(TimeCurrent())), yOffset += spacing, g_panelSettings);
    AddPanelLabel(g_mainPanelName, GetAccountRatioDisplay(), yOffset += spacing, g_panelSettings);
// Add buttons
    AddPanelButton(g_mainPanelName, CLOSE_ALL_TEXT, "Close all orders", g_panelSettings);
    AddPanelButton(g_mainPanelName, CLOSE_SELLS_TEXT, "Close sell orders", g_panelSettings);
    AddPanelButton(g_mainPanelName, CLOSE_BUYS_TEXT, "Close buy orders", g_panelSettings);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeinitializeInfoPanel()
{
// Exit early if in optimization mode
    if(IsOptimization()) return;

    RemoveInfoPanel(g_mainPanelName);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateInfoPanel(const string buyBETextToDisplay, const string sellBETextToDisplay, const OrderSettings &orderSettings,
                     const string reverseBuyFilterTxt, const string reverseSellFilterTxt, const ConditionStatus &tradingDayStatus,
                     const ConditionStatus &timeManagementStatus, const ConditionStatus &spreadStatus,
                     const datetime time_current)
{
// Exit early if in optimization mode
    if(IsOptimization()) return;

    UpdatePanelLabel(g_mainPanelName, 0, StringFormat("%s v%s", EA_NAME, EA_VERSION), true);
    UpdatePanelLabel(g_mainPanelName, 1, "Trading: " + (inputParams.IN_OrdersToTrade == kMarketOrders ? "Market orders" : "Pending orders"), true);
    UpdatePanelLabel(g_mainPanelName, 2, StringFormat("Take profit: Manual (%d)", inputParams.IN_TakeProfitInPips), true);
    UpdatePanelLabel(g_mainPanelName, 3, GetStopLossComment(inputParams), true);
    UpdatePanelLabel(g_mainPanelName, 4, "Trading Mode: " + GetTradingModeString(inputParams), true);
    UpdatePanelLabel(g_mainPanelName, 5, "Trail stop: " + GetTrailingStopStatus(inputParams), inputParams.IN_EnableTrailStop);
    UpdatePanelLabel(g_mainPanelName, 6, "BE Filter: " + (inputParams.IN_EnableBeFilter ? "ON" : "OFF"), inputParams.IN_EnableBeFilter);
    UpdatePanelLabel(g_mainPanelName, 7, "BE Filter Reentry: " + (inputParams.IN_EnableBeReentry ? "ON" : "OFF"), inputParams.IN_EnableBeReentry);
    UpdatePanelLabel(g_mainPanelName, 8, buyBETextToDisplay, true);
    UpdatePanelLabel(g_mainPanelName, 9, sellBETextToDisplay, true);
    UpdatePanelLabel(g_mainPanelName, 10, "Allow Buys: " + (orderSettings.allowBuy ? "ON" : "OFF"), orderSettings.allowBuy);
    UpdatePanelLabel(g_mainPanelName, 11, "Allow Sells: " + (orderSettings.allowSell ? "ON" : "OFF"), orderSettings.allowSell);
    UpdatePanelLabel(g_mainPanelName, 12, "Buy Reverse Filter: " + (orderSettings.reverseBuy ? "ON" : "OFF"), orderSettings.reverseBuy);
    UpdatePanelLabel(g_mainPanelName, 13, "Buy Reverse Filter Reentry: " + (inputParams.IN_EnableReverseReentry ? "ON" : "OFF"), inputParams.IN_EnableReverseReentry);
    UpdatePanelLabel(g_mainPanelName, 14, reverseBuyFilterTxt, inputParams.IN_EnableReverseReentry);
    UpdatePanelLabel(g_mainPanelName, 15, "Sell Reverse Filter: " + (orderSettings.reverseSell ? "ON" : "OFF"), orderSettings.reverseSell);
    UpdatePanelLabel(g_mainPanelName, 16, "Sell Reverse Filter Reentry: " + (inputParams.IN_EnableReverseReentry ? "ON" : "OFF"), inputParams.IN_EnableReverseReentry);
    UpdatePanelLabel(g_mainPanelName, 17, reverseSellFilterTxt, inputParams.IN_EnableReverseReentry);
    UpdatePanelLabel(g_mainPanelName, 18, tradingDayStatus.message, tradingDayStatus.allowTrade);
    UpdatePanelLabel(g_mainPanelName, 19, timeManagementStatus.message, timeManagementStatus.allowTrade);
    UpdatePanelLabel(g_mainPanelName, 20, spreadStatus.message, spreadStatus.allowTrade);
    UpdatePanelLabel(g_mainPanelName, 21, StringFormat("Current time: %s", TimeToString(time_current)), true);
    UpdatePanelLabel(g_mainPanelName, 22, GetAccountRatioDisplay(), true);
}
//+------------------------------------------------------------------+
