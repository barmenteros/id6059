﻿//+------------------------------------------------------------------+
//|                                                   NewsFilter.mqh |
//|                                 Copyright © 2023, barmenteros FX |
//|                                          https://barmenteros.com |
//+------------------------------------------------------------------+
#include <Custom\Development\Logging.mqh>

// Global variables
string ar_symbol_[];
string ar_impact_[];
string ar_news_title_[];
string ar_time_[];
datetime diff_cur_news=0;
datetime last_load_date=0;
int mins_between_load=360;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool NewsFilterEC(string symbolToFound, bool UseHigh, int BeforeHigh, int AfterHigh,
                  bool UseMedium, int BeforeMedium, int AfterMedium,
                  bool UseLow, int BeforeLow, int AfterLow, string& text_to_comment)
{
    int between=ArraySize(ar_time_);
    datetime newstime=TimeLocal()-diff_cur_news;
    for(int z=0; z<ArraySize(ar_symbol_); z++) {

        datetime right_time=datetime(ar_time_[z]);
        datetime lefttime=0;
        if(z>=1)lefttime=datetime(ar_time_[z-1]);

        if(lefttime<newstime && newstime<=right_time)
            between=z;

    }
    text_to_comment+="----------------------------------------------------"+"\n";
    for(int z=MathMax(0, between); z<MathMin(ArraySize(ar_time_), MathMax(0, between)+NumberOfNewsToBePrinted); z++) {
        text_to_comment+=TimeToString(TimeLocal()+(datetime(ar_time_[z])-newstime), TIME_MINUTES|TIME_DATE)+
                         " "+ar_news_title_[z]+" "+ar_symbol_[z]+"\n";

    }
    text_to_comment+="----------------------------------------------------"+"\n";
    for(int z=MathMax(0, between-NumberOfNewsToBePrinted); z<between; z++) {
        text_to_comment+=TimeToString(TimeLocal()+(datetime(ar_time_[z])-newstime), TIME_MINUTES|TIME_DATE)+
                         " "+ar_news_title_[z]+" "+ar_symbol_[z]+"\n";

    }
    //PrintLog(__FUNCTION__, text_to_comment, false);

    for(int z=0; z<ArraySize(ar_symbol_); z++) {
        // Print(ar_impact_[z]);
        //  Print(ar_time_[z]);
        datetime norm_time=(datetime)ar_time_[z];

        if(norm_time>newstime) {
            int before=0;
            if(StringFind(ar_impact_[z], "High", 0)!=-1)
                before=BeforeHigh;
            if(StringFind(ar_impact_[z], "Moderate", 0)!=-1)
                before=BeforeMedium;
            if(StringFind(ar_impact_[z], "Low", 0)!=-1)
                before=BeforeLow;

            if(norm_time-newstime<before*60) {
                return true;
            }
        }
        if(norm_time<=newstime) {
            int after=0;
            if(StringFind(ar_impact_[z], "High", 0)!=-1)
                after=AfterHigh;
            if(StringFind(ar_impact_[z], "Moderate", 0)!=-1)
                after=AfterMedium;
            if(StringFind(ar_impact_[z], "Low", 0)!=-1)
                after=AfterLow;
            if(newstime-norm_time<after*60) {
                return true;
            }
        }
    }

    return false;
}
// ----------------------------------------------------------------------------
// Function: LoadData
// Status: Pending Review
// Note: The function stopped working with the original website as it seems to be
//       blocking EA access. We've switched to another website, but the data
//       obtained must be patched to extract useful information.
// ----------------------------------------------------------------------------
bool LoadData(string symbolToFound,
              bool UseHigh, int BeforeHigh, int AfterHigh,
              bool UseMedium, int BeforeMedium, int AfterMedium,
              bool UseLow, int BeforeLow, int AfterLow)
{
    // Initialize arrays
    ArrayResize(ar_symbol_, 0);
    ArrayResize(ar_impact_, 0);
    ArrayResize(ar_news_title_, 0);
    ArrayResize(ar_time_, 0);

    // Initialize variables
    string cookie = NULL, headers;
    char post[], result[], data[];
    int res;
//    string url = "http://ec.forexprostools.com/";
    string url = "https://sslecal2.forexprostools.com/";
    int timeout = 5000;

    // Reset last error
    ResetLastError();

    // Perform the WebRequest
//    res = WebRequest("GET", url, cookie, NULL, timeout, post, 0, result, headers);
    res = WebRequest("GET", url,
                     "Referer: https://www.investing.com/economic-calendar/\r\nUser-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 16_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.3 Mobile/15E148 Safari/604.1\r\n",
                     15000, data, result, headers);

    // Error Handling
    if (res == -1) {
        int error = GetLastError();
        if (error != 5203) printf("%s: Error in WebRequest. Error code = %d", __FUNCTION__, error);
        if (error == 4060) MessageBox("Add the address '" + url + "' in the list of allowed URLs on tab 'Expert Advisors'", "Error", MB_ICONINFORMATION);
        return false;
    }
    else {
        // Process HTML Data
        string HTML = CharArrayToString(result);
        //PrintLog(__FUNCTION__, HTML, false);
        string r="var currentDateTime = parseDateTime('";
        string l="')";
        string date1=GetHTMLElement(HTML, r, l);
        StringReplace(date1, "-", ".");
        datetime newstime=(datetime)date1;
        // Print(newstime);
        //first datetime
        //symbol
        //volatility
        //event
        string left_datetime="event_timestamp=\"";
        string right_datetime="\"";

        string left_symbol="</span>";
        string right_symbol="</td>";

        string left_impact="<td class=\"sentiment\" title=\"";
        string right_impact=" Volatility Expected";

        string left_title="<td class=\"left event\">";
        string right_title="</td>";
        int i=0;

        datetime temp=0;
        int date=0, time=0, symbol=0, impact=0, news_title=0;
        while(true) {
            string DateTime=ReturnResult1(HTML, date, left_datetime, right_datetime);
            StringReplace(DateTime, "-", ".");
            if(datetime(DateTime)<temp) {
                break;
            }
            temp=datetime(DateTime);
            string symbol_=ReturnResult1(HTML, date, left_symbol, right_symbol);
            // if(symbol_==""&&symbol!=-1)symbol_=ReturnResult(HTML,symbol,left_symbol,right_symbol);
            string impact_=ReturnResult1(HTML, date, left_impact, right_impact);
            string news_title_=ReturnResult1(HTML, date, left_title, right_title);
            if(StringFind(news_title_, "  ", 0)!=-1) {
                news_title_=StringSubstr(news_title_, 0, StringFind(news_title_, "  ", 0));
            }
            if(StringFind(news_title_, "&nbsp", 0)!=-1) {
                news_title_=StringSubstr(news_title_, 0, StringFind(news_title_, "&nbsp", 0));
            }
            if(symbol==-1 || news_title==-1 || impact==-1 || date==-1)break;

            // Print(i," ",news_title_," |||| ",symbol_," |||| ",DateTime," ||||",impact_);

            int shift=-1;
            bool sep_news=false;
            StringReplace(symbol_, " ", "");


            if(sep_news || (StringFind(symbolToFound, symbol_, 0)!=-1
                            && (
                                ((StringFind(impact_, "High", 0)!=-1 && UseHigh)
                                 || (StringFind(impact_, "Moderate", 0)!=-1 && UseMedium)
                                 || (StringFind(impact_, "Low", 0)!=-1 && UseLow))))) {
                Push(ar_symbol_, symbol_);
                Push(ar_impact_, impact_);
                Push(ar_news_title_, news_title_);
                Push(ar_time_, DateTime);
            }
            symbol++;
            impact++;
            time++;
            news_title++;
            i++;
            if(i>1000)break;

        }
        diff_cur_news=TimeLocal()-newstime;
        return true;
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string   GetHTMLElement(string HTML, string ElementStart, string ElementEnd)
{
    string   data=NULL;

// Find start and end position for element
    int s1 = StringFind(HTML, ElementStart) + StringLen(ElementStart);
    int e = StringFind(StringSubstr(HTML, s1), ElementEnd);

// Return element content
    if(e!=0) data=StringSubstr(HTML, s1, e);
    return(data);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Push(string &ar[], string val)
{
    ArrayResize(ar, ArraySize(ar)+1);
    ar[ArraySize(ar)-1]=val;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string ReturnResult1(string HTML, int &k,
                     string left_side, string right_side)
{
    k=StringFind(HTML, left_side, k);
    if(k==-1)return "";
    int end=StringFind(HTML, right_side, k+StringLen(left_side));
    string res=StringSubstr(HTML, k+StringLen(left_side),
                            end-k-StringLen(left_side));
    if(end-k-StringLen(left_side)==0)return "";
    return res;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckNewsFilter(const datetime time_current, string &text_news)
{
    bool news = false;

    if (!IsTesting() && UseNewsFilter) {

        // Check if it's time to reload the news data
        if (time_current - last_load_date >= mins_between_load * 60) {
            if (LoadData(Symbol(), UseHighImpact, HighPauseBefore, HighPauseAfter,
                         UseMediumImpact, MediumPause, MediumPause,
                         UseLowImpact, LowPause, LowPause)) {
                last_load_date = time_current;
            }
            else {
                return false; // Error in LoadData function, skip this tick
            }
        }

        // Perform the actual news filter check
        news = NewsFilterEC(Symbol(), UseHighImpact, HighPauseBefore, HighPauseAfter,
                            UseMediumImpact, MediumPause, MediumPause,
                            UseLowImpact, LowPause, LowPause, text_news);
    }

    return news;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ConditionStatus CheckNews(const datetime time_current)
{
    // Static variable to store the last status
    static ConditionStatus lastStatus;

    string text_news = "\n\n";
    ConditionStatus currentStatus;

    currentStatus.message = "\nNews Filter: OFF" + "\n" + text_news;
    currentStatus.allowTrade = true;

    if (UseNewsFilter) {
        if (CheckNewsFilter(time_current, text_news)) {
            currentStatus.message = "\nNews Filter: Trading Paused" + "\n" + text_news;
            currentStatus.allowTrade = false;
        }
        else {
            currentStatus.message = "\nNews Filter: Trading Active" + "\n" + text_news;
        }
    }

    // Compare the new status with the last status
    if (currentStatus.allowTrade != lastStatus.allowTrade ||
            StringCompare(currentStatus.message, lastStatus.message) != 0) {

        // The status has changed, so update the last status
        lastStatus = currentStatus;

        // Print the new status for debugging
        string msg = StringFormat("News Status Changed: %s", currentStatus.message);
        PrintLog(__FUNCTION__, msg);
    }

    return currentStatus;
}
//+------------------------------------------------------------------+
