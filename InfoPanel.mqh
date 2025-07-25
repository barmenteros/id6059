﻿//+------------------------------------------------------------------+
//|                                                    InfoPanel.mqh |
//+------------------------------------------------------------------+
#ifndef __INFOPANEL_
#define __INFOPANEL_

struct SPanelSettings {
    string           name;
    ENUM_BASE_CORNER corner;
    int              x;
    int              y;
    int              width;
    int              height;
    color            bgColor;
    color            upColor;
    color            downColor;
    int              fontSize;
    int              tabPadding;
    color            buttonBgColor;     // Added
    color            buttonTextColor;   // Added
    int              buttonHeight;      // Added
    int              buttonSpacing;     // Added
    int              bottomMargin;
};

struct SButtonInfo {
    string           name;
    string           text;
    string           tooltip;
};

struct SPanelObjects {
    string           background;
    string           labels[];
    string           buttons[];         // Added
    int              labelCount;
    int              buttonCount;       // Added
};

// Global storage for panel objects
SPanelObjects g_panels[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CreateInfoPanel(const SPanelSettings &settings)
{
    int panelIndex = ArraySize(g_panels);
    ArrayResize(g_panels, panelIndex + 1);

// Create background
    string bgName = settings.name + "_bg";
    if(!ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0)) {
        return false;
    }

    ObjectSetInteger(0, bgName, OBJPROP_CORNER, settings.corner);
    ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, settings.x);
    ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, settings.y);
    ObjectSetInteger(0, bgName, OBJPROP_XSIZE, settings.width);
    ObjectSetInteger(0, bgName, OBJPROP_YSIZE, settings.height);
    ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, settings.bgColor);
    ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, bgName, OBJPROP_ZORDER, 0);

    g_panels[panelIndex].background = bgName;
    g_panels[panelIndex].labelCount = 0;

    return true;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void RemoveInfoPanel(const string name)
{
    for(int i = 0; i < ArraySize(g_panels); i++) {
        if(StringFind(g_panels[i].background, name) >= 0) {
            ObjectDelete(0, g_panels[i].background);
            for(int j = 0; j < g_panels[i].labelCount; j++) {
                ObjectDelete(0, g_panels[i].labels[j]);
            }
            for(int j = 0; j < g_panels[i].buttonCount; j++) {    // Added
                ObjectDelete(0, g_panels[i].buttons[j]);
            }

            // Shift remaining elements
            for(int k = i; k < ArraySize(g_panels) - 1; k++) {
                g_panels[k] = g_panels[k + 1];
            }
            ArrayResize(g_panels, ArraySize(g_panels) - 1);
            break;
        }
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool AddPanelLabel(const string panelName, const string text, const int yOffset,
                   const SPanelSettings &settings)
{
    for(int i = 0; i < ArraySize(g_panels); i++) {
        if(StringFind(g_panels[i].background, panelName) >= 0) {
            string labelName = panelName + "_label" + IntegerToString(g_panels[i].labelCount);

            if(!ObjectCreate(0, labelName, OBJ_LABEL, 0, 0, 0)) {
                return false;
            }

            ObjectSetInteger(0, labelName, OBJPROP_CORNER, settings.corner);
            ObjectSetInteger(0, labelName, OBJPROP_XDISTANCE, settings.x + 5);
            ObjectSetInteger(0, labelName, OBJPROP_YDISTANCE, settings.y + yOffset);
            ObjectSetInteger(0, labelName, OBJPROP_COLOR, settings.upColor);
            ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, settings.fontSize);
            ObjectSetString(0, labelName, OBJPROP_TEXT, text);

            ArrayResize(g_panels[i].labels, g_panels[i].labelCount + 1);
            g_panels[i].labels[g_panels[i].labelCount] = labelName;
            g_panels[i].labelCount++;

            return true;
        }
    }
    return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool AddPanelButton(const string panelName, const string text, const string tooltip,
                    const SPanelSettings &settings)
{
    for(int i = 0; i < ArraySize(g_panels); i++) {
        if(StringFind(g_panels[i].background, panelName) >= 0) {
            string btnName = panelName + "_btn" + IntegerToString(g_panels[i].buttonCount);

            if(!ObjectCreate(0, btnName, OBJ_BUTTON, 0, 0, 0)) {
                return false;
            }

            int yPos = settings.y + settings.height - settings.bottomMargin -
                       ((g_panels[i].buttonCount + 1) * (settings.buttonHeight + settings.buttonSpacing));

            ObjectSetInteger(0, btnName, OBJPROP_CORNER, settings.corner);
            ObjectSetInteger(0, btnName, OBJPROP_XDISTANCE, settings.x + 5);
            ObjectSetInteger(0, btnName, OBJPROP_YDISTANCE, yPos);
            ObjectSetInteger(0, btnName, OBJPROP_XSIZE, settings.width - 10);
            ObjectSetInteger(0, btnName, OBJPROP_YSIZE, settings.buttonHeight);
            ObjectSetInteger(0, btnName, OBJPROP_BGCOLOR, settings.buttonBgColor);
            ObjectSetInteger(0, btnName, OBJPROP_COLOR, settings.buttonTextColor);
            ObjectSetInteger(0, btnName, OBJPROP_FONTSIZE, settings.fontSize);
            ObjectSetString(0, btnName, OBJPROP_TEXT, text);
            ObjectSetString(0, btnName, OBJPROP_TOOLTIP, tooltip);
            ObjectSetInteger(0, btnName, OBJPROP_STATE, false);
            ObjectSetInteger(0, btnName, OBJPROP_SELECTABLE, true);

            ArrayResize(g_panels[i].buttons, g_panels[i].buttonCount + 1);
            g_panels[i].buttons[g_panels[i].buttonCount] = btnName;
            g_panels[i].buttonCount++;

            return true;
        }
    }
    return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool UpdatePanelLabel(const string panelName, const int labelIndex, const string text, const bool isPositive)
{
    for(int i = 0; i < ArraySize(g_panels); i++) {
        if(StringFind(g_panels[i].background, panelName) >= 0) {
            if(labelIndex < g_panels[i].labelCount) {
                ObjectSetString(0, g_panels[i].labels[labelIndex], OBJPROP_TEXT, text);
                ObjectSetInteger(0, g_panels[i].labels[labelIndex], OBJPROP_COLOR,
                                 isPositive ? COLOR_UP : COLOR_DOWN);
                return true;
            }
        }
    }
    return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool UpdatePanelMetric(const string panelName, const int labelIndex,
                       const string label, const double value,
                       const bool isPercentage = false)
{
    string text = StringFormat("%s: %s%.*f%s",
                               label,
                               value >= 0 ? "+" : "",
                               isPercentage ? 2 : 1,
                               value,
                               isPercentage ? "%" : "");

    return UpdatePanelLabel(panelName, labelIndex, text, value >= 0);
}

#endif
//+------------------------------------------------------------------+
