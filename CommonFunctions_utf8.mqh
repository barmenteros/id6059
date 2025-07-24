//+------------------------------------------------------------------+
//|                                              CommonFunctions.mqh |
//|                                 Copyright © 2023, barmenteros FX |
//|                                          https://barmenteros.com |
//+------------------------------------------------------------------+
#ifndef __COMMON_FUNCTIONS__
#define __COMMON_FUNCTIONS__

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetATR(const ENUM_TIMEFRAMES timeframe, const int period, const int index)
{
    return(iATR(NULL, timeframe, period, index));
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetMH_ML_Marker(const InputParameters &params, const int customProgramID, const int buffer, const int index)
{
// buffer 0 -> higher level M1
// buffer 1 -> higher level M5
// buffer 2 -> higher level M15
// buffer 3 -> higher level M30
// buffer 4 -> higher level H1
// buffer 5 -> higher level H4
// buffer 6 -> higher level D1
// buffer 7 -> higher level W1
// buffer 8 -> higher level MN

// buffer 9 -> lower level M1
// buffer 10 -> lower level M5
// buffer 11 -> lower level M15
// buffer 12 -> lower level M30
// buffer 13 -> lower level H1
// buffer 14 -> lower level H4
// buffer 15 -> lower level D1
// buffer 16 -> lower level W1
// buffer 17 -> lower level MN

/*
// Debug logging - create a structured log of all parameters
    string debugMsg = StringFormat("GetMH_ML_Marker called: buffer=%d, index=%d, customProgramID=%d",
                                   buffer, index, customProgramID);
    PrintLog(__FUNCTION__, debugMsg, true);

// Log timeframe settings
    PrintLog(__FUNCTION__, StringFormat("M1: Enable=%s, N=%d, Fibo2=%.2f, Fibo3=%.2f",
                                        params.Enable_1m ? "true" : "false",
                                        params.N_1m,
                                        params.InpFiboLevelValue2_1M,
                                        params.InpFiboLevelValue3_1M), true);
    PrintLog(__FUNCTION__, StringFormat("M5: Enable=%s, N=%d, Fibo2=%.2f, Fibo3=%.2f",
                                        params.Enable_5m ? "true" : "false",
                                        params.N_5m,
                                        params.InpFiboLevelValue2_5M,
                                        params.InpFiboLevelValue3_5M), true);
    PrintLog(__FUNCTION__, StringFormat("M15: Enable=%s, N=%d, Fibo2=%.2f, Fibo3=%.2f",
                                        params.Enable_15m ? "true" : "false",
                                        params.N_15m,
                                        params.InpFiboLevelValue2_15M,
                                        params.InpFiboLevelValue3_15M), true);
    PrintLog(__FUNCTION__, StringFormat("M30: Enable=%s, N=%d, Fibo2=%.2f, Fibo3=%.2f",
                                        params.Enable_30m ? "true" : "false",
                                        params.N_30m,
                                        params.InpFiboLevelValue2_30M,
                                        params.InpFiboLevelValue3_30M), true);
    PrintLog(__FUNCTION__, StringFormat("H1: Enable=%s, N=%d, Fibo2=%.2f, Fibo3=%.2f",
                                        params.Enable_1h ? "true" : "false",
                                        params.N_1h,
                                        params.InpFiboLevelValue2_1H,
                                        params.InpFiboLevelValue3_1H), true);
    PrintLog(__FUNCTION__, StringFormat("H4: Enable=%s, N=%d, Fibo2=%.2f, Fibo3=%.2f",
                                        params.Enable_4h ? "true" : "false",
                                        params.N_4h,
                                        params.InpFiboLevelValue2_4H,
                                        params.InpFiboLevelValue3_4H), true);
    PrintLog(__FUNCTION__, StringFormat("Daily: Enable=%s, N=%d, Fibo2=%.2f, Fibo3=%.2f",
                                        params.Enable_Daily ? "true" : "false",
                                        params.N_Daily,
                                        params.InpFiboLevelValue2_D,
                                        params.InpFiboLevelValue3_D), true);
    PrintLog(__FUNCTION__, StringFormat("Weekly: Enable=%s, N=%d, Fibo2=%.2f, Fibo3=%.2f",
                                        params.Enable_Weekly ? "true" : "false",
                                        params.N_Weekly,
                                        params.InpFiboLevelValue2_W,
                                        params.InpFiboLevelValue3_W), true);
    PrintLog(__FUNCTION__, StringFormat("Monthly: Enable=%s, N=%d, Fibo2=%.2f, Fibo3=%.2f",
                                        params.Enable_Monthly ? "true" : "false",
                                        params.N_Monthly,
                                        params.InpFiboLevelValue2_MN,
                                        params.InpFiboLevelValue3_MN), true);
*/
    double result = iCustom(NULL, 0, "MH_ML_TS_Checkpoint",
                            params.N_1m,
                            params.Enable_1m,
                            params.InpFiboLevelValue2_1M,
                            params.InpFiboLevelValue3_1M,
                            params.N_5m,
                            params.Enable_5m,
                            params.InpFiboLevelValue2_5M,
                            params.InpFiboLevelValue3_5M,
                            params.N_15m,
                            params.Enable_15m,
                            params.InpFiboLevelValue2_15M,
                            params.InpFiboLevelValue3_15M,
                            params.N_30m,
                            params.Enable_30m,
                            params.InpFiboLevelValue2_30M,
                            params.InpFiboLevelValue3_30M,
                            params.N_1h,
                            params.Enable_1h,
                            params.InpFiboLevelValue2_1H,
                            params.InpFiboLevelValue3_1H,
                            params.N_4h,
                            params.Enable_4h,
                            params.InpFiboLevelValue2_4H,
                            params.InpFiboLevelValue3_4H,
                            params.N_Daily,
                            params.Enable_Daily,
                            params.InpFiboLevelValue2_D,
                            params.InpFiboLevelValue3_D,
                            params.N_Weekly,
                            params.Enable_Weekly,
                            params.InpFiboLevelValue2_W,
                            params.InpFiboLevelValue3_W,
                            params.N_Monthly,
                            params.Enable_Monthly,
                            params.InpFiboLevelValue2_MN,
                            params.InpFiboLevelValue3_MN,
                            "",
                            customProgramID,
                            buffer, index);

// Log the result
//    PrintLog(__FUNCTION__, StringFormat("Result for buffer %d, index %d: %f", buffer, index, result), true);

    return result;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES GetActualTimeframe(const ENUM_TIMEFRAMES timeframe)
{
// If the timeframe is PERIOD_CURRENT, get the actual timeframe of the current chart
    if (timeframe == PERIOD_CURRENT) {
        return (ENUM_TIMEFRAMES)Period();
    }
    return timeframe;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool GetTimeframeBuffers(const ENUM_TIMEFRAMES timeframe, int &buffers[])
{
    switch(timeframe) {
    case PERIOD_M1:
        buffers[0] = 0;
        buffers[1] = 9;
        break;
    case PERIOD_M5:
        buffers[0] = 1;
        buffers[1] = 10;
        break;
    case PERIOD_M15:
        buffers[0] = 2;
        buffers[1] = 11;
        break;
    case PERIOD_M30:
        buffers[0] = 3;
        buffers[1] = 12;
        break;
    case PERIOD_H1:
        buffers[0] = 4;
        buffers[1] = 13;
        break;
    case PERIOD_H4:
        buffers[0] = 5;
        buffers[1] = 14;
        break;
    case PERIOD_D1:
        buffers[0] = 6;
        buffers[1] = 15;
        break;
    case PERIOD_W1:
        buffers[0] = 7;
        buffers[1] = 16;
        break;
    case PERIOD_MN1:
        buffers[0] = 8;
        buffers[1] = 17;
        break;
    default:
        return false;
    }
    return true;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void HandlePanelButtonClicks(const int id, const string sparam)
{
// Check if the event is a click on a panel object
    if (id != CHARTEVENT_OBJECT_CLICK) {
        return;
    }

    if(StringFind(sparam, g_mainPanelName + "_btn") < 0) {
        return;
    }

    int slippage = 5;
    string symbol = Symbol();
    int digits = Digits();

    string buttonText = ObjectGetString(0, sparam, OBJPROP_TEXT);
// Handle CloseBuysButton click
    if(buttonText == CLOSE_BUYS_TEXT) {
        printf("%s: Closing all BUY market and pending orders!", __FUNCTION__);
        CloseAll(symbol, digits, IN_MagicNumber, slippage, "", 1, OP_BUY, clrGoldenrod);
        DeleteAllTypePositions(OP_BUYSTOP);
    }
// Handle CloseSellsButton click
    else if(buttonText == CLOSE_SELLS_TEXT) {
        printf("%s: Closing all SELL market and pending orders!", __FUNCTION__);
        CloseAll(symbol, digits, IN_MagicNumber, slippage, "", 1, OP_SELL, clrGoldenrod);
        DeleteAllTypePositions(OP_SELLSTOP);
    }
// Handle CloseAllButton click
    else if(buttonText == CLOSE_ALL_TEXT) {
        printf("%s: Closing ALL market and pending orders!", __FUNCTION__);
        CloseAll(symbol, digits, IN_MagicNumber, slippage, "", 1, ALL_ORDERS, clrGoldenrod);
        DeleteAllTypePositions(ALL_ORDERS);
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetAccountRatioDisplay()
{
// Return formatted display string
    return StringFormat("Account Ratio: %d:%d (%.2f)",
                        AC_Ratio_Limit,
                        AC_Ratio_Actual,
                        UsableBalanceAmount);
}

#endif //__COMMON_FUNCTIONS__
//+------------------------------------------------------------------+
