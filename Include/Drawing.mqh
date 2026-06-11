//+------------------------------------------------------------------+
//|                                                  Drawing.mqh     |
//|  绘图工具 — 箭头、线条、文字标签的标准化管理                        |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"

#ifndef _DRAWING_MQH_
#define _DRAWING_MQH_

#include "Common.mqh"

//+------------------------------------------------------------------+
//| 核心原则：                                                        |
//| 所有图形对象命名规范化，便于批量清理                                |
//| 信号箭头只在 bar >= 1 的K线上绘制                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| 生成唯一的对象名称                                                 |
//+------------------------------------------------------------------+
string MakeObjName(string prefix, int barIndex)
{
   return(OBJ_PREFIX + prefix + "_" + IntegerToString(barIndex) + "_" +
          IntegerToString(GetTickCount()));
}

//+------------------------------------------------------------------+
//| 绘制买入箭头                                                       |
//| barIndex: 必须 >= 1                                                |
//+------------------------------------------------------------------+
void DrawBuyArrow(string symbol, int timeframe, int barIndex, double price,
                  color clr = CLR_BUY_SIGNAL, int arrowSize = 2)
{
   // 严格保护：不在 bar[0] 绘制信号箭头
   if(barIndex < 1) return;

   string objName = OBJ_PREFIX + "BUY_" + IntegerToString(barIndex);

   // 避免重复创建同一位置的箭头
   if(ObjectFind(objName) >= 0) return;

   ObjectCreate(objName, OBJ_ARROW, 0, iTime(symbol, timeframe, barIndex), price);
   ObjectSet(objName, OBJPROP_ARROWCODE, ARROW_BUY);
   ObjectSet(objName, OBJPROP_COLOR, clr);
   ObjectSet(objName, OBJPROP_WIDTH, arrowSize);
   ObjectSet(objName, OBJPROP_ANCHOR, ANCHOR_TOP);
}

//+------------------------------------------------------------------+
//| 绘制卖出箭头                                                       |
//| barIndex: 必须 >= 1                                                |
//+------------------------------------------------------------------+
void DrawSellArrow(string symbol, int timeframe, int barIndex, double price,
                   color clr = CLR_SELL_SIGNAL, int arrowSize = 2)
{
   if(barIndex < 1) return;

   string objName = OBJ_PREFIX + "SELL_" + IntegerToString(barIndex);

   if(ObjectFind(objName) >= 0) return;

   ObjectCreate(objName, OBJ_ARROW, 0, iTime(symbol, timeframe, barIndex), price);
   ObjectSet(objName, OBJPROP_ARROWCODE, ARROW_SELL);
   ObjectSet(objName, OBJPROP_COLOR, clr);
   ObjectSet(objName, OBJPROP_WIDTH, arrowSize);
   ObjectSet(objName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
}

//+------------------------------------------------------------------+
//| 绘制垂直线（标记关键bar）                                          |
//+------------------------------------------------------------------+
void DrawVerticalLine(string symbol, int timeframe, int barIndex,
                      color clr = clrYellow, int lineStyle = STYLE_DOT)
{
   if(barIndex < 1) return;

   string objName = OBJ_PREFIX + "VLINE_" + IntegerToString(barIndex);

   if(ObjectFind(objName) >= 0) return;

   ObjectCreate(objName, OBJ_VLINE, 0, iTime(symbol, timeframe, barIndex), 0);
   ObjectSet(objName, OBJPROP_COLOR, clr);
   ObjectSet(objName, OBJPROP_STYLE, lineStyle);
   ObjectSet(objName, OBJPROP_WIDTH, 1);
   ObjectSet(objName, OBJPROP_BACK, true);  // 背景绘制
}

//+------------------------------------------------------------------+
//| 绘制水平线                                                        |
//+------------------------------------------------------------------+
void DrawHorizontalLine(string symbol, int timeframe, double price,
                        string lineId, color clr = clrGray,
                        int lineStyle = STYLE_DASH)
{
   string objName = OBJ_PREFIX + "HLINE_" + lineId;

   if(ObjectFind(objName) >= 0)
   {
      // 已存在则更新价格
      ObjectSet(objName, OBJPROP_PRICE1, price);
      return;
   }

   ObjectCreate(objName, OBJ_HLINE, 0, 0, price);
   ObjectSet(objName, OBJPROP_COLOR, clr);
   ObjectSet(objName, OBJPROP_STYLE, lineStyle);
   ObjectSet(objName, OBJPROP_WIDTH, 1);
   ObjectSet(objName, OBJPROP_BACK, true);
}

//+------------------------------------------------------------------+
//| 绘制趋势线（连接两个点）                                           |
//+------------------------------------------------------------------+
void DrawTrendLine(string symbol, int timeframe,
                   int barIndex1, double price1,
                   int barIndex2, double price2,
                   string lineId, color clr = clrDodgerBlue,
                   int lineStyle = STYLE_SOLID, int lineWidth = 1)
{
   string objName = OBJ_PREFIX + "TLINE_" + lineId;

   if(ObjectFind(objName) >= 0)
   {
      ObjectDelete(objName);
   }

   ObjectCreate(objName, OBJ_TREND, 0,
                iTime(symbol, timeframe, barIndex1), price1,
                iTime(symbol, timeframe, barIndex2), price2);
   ObjectSet(objName, OBJPROP_COLOR, clr);
   ObjectSet(objName, OBJPROP_STYLE, lineStyle);
   ObjectSet(objName, OBJPROP_WIDTH, lineWidth);
   ObjectSet(objName, OBJPROP_RAY, false);  // 不延伸
}

//+------------------------------------------------------------------+
//| 绘制文字标签                                                       |
//+------------------------------------------------------------------+
void DrawTextLabel(string symbol, int timeframe, int barIndex, double price,
                   string text, color clr = clrWhite, int fontSize = 8,
                   double angle = 0.0)
{
   string objName = OBJ_PREFIX + "TEXT_" + IntegerToString(barIndex) + "_" + text;

   if(ObjectFind(objName) >= 0)
   {
      ObjectSetText(objName, text, fontSize, "Arial", clr);
      return;
   }

   ObjectCreate(objName, OBJ_TEXT, 0,
                iTime(symbol, timeframe, barIndex), price);
   ObjectSetText(objName, text, fontSize, "Arial", clr);
   ObjectSet(objName, OBJPROP_ANGLE, angle);
   ObjectSet(objName, OBJPROP_ANCHOR, ANCHOR_LEFT);
}

//+------------------------------------------------------------------+
//| 绘制矩形区域（高亮区间）                                           |
//+------------------------------------------------------------------+
void DrawRectangle(string symbol, int timeframe,
                   int startBar, double price1,
                   int endBar, double price2,
                   string rectId, color clr = clrYellow)
{
   string objName = OBJ_PREFIX + "RECT_" + rectId;

   if(ObjectFind(objName) >= 0)
   {
      ObjectDelete(objName);
   }

   ObjectCreate(objName, OBJ_RECTANGLE, 0,
                iTime(symbol, timeframe, startBar), price1,
                iTime(symbol, timeframe, endBar), price2);
   ObjectSet(objName, OBJPROP_COLOR, clr);
   ObjectSet(objName, OBJPROP_BACK, true);
   ObjectSet(objName, OBJPROP_STYLE, STYLE_DOT);
}

//+------------------------------------------------------------------+
//| 清除该指标创建的所有图形对象                                        |
//| 在 deinit() 中调用                                                |
//+------------------------------------------------------------------+
void RemoveAllObjects()
{
   int total = ObjectsTotal();
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(i);
      if(StringFind(name, OBJ_PREFIX) == 0)
      {
         ObjectDelete(name);
      }
   }
}

//+------------------------------------------------------------------+
//| 清除指定前缀的图形对象                                              |
//+------------------------------------------------------------------+
void RemoveObjectsByPrefix(string prefix)
{
   string fullPrefix = OBJ_PREFIX + prefix;
   int total = ObjectsTotal();
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(i);
      if(StringFind(name, fullPrefix) == 0)
      {
         ObjectDelete(name);
      }
   }
}

//+------------------------------------------------------------------+
//| 清除指定bar上的箭头信号对象                                         |
//+------------------------------------------------------------------+
void RemoveArrowsOnBar(int barIndex)
{
   string buyName = OBJ_PREFIX + "BUY_" + IntegerToString(barIndex);
   string sellName = OBJ_PREFIX + "SELL_" + IntegerToString(barIndex);

   if(ObjectFind(buyName) >= 0) ObjectDelete(buyName);
   if(ObjectFind(sellName) >= 0) ObjectDelete(sellName);
}

//+------------------------------------------------------------------+
//| 更新最新信号的箭头位置（跟随当前价格）                              |
//| 仅用于实时显示，不修改历史信号                                      |
//+------------------------------------------------------------------+
void UpdateLatestArrow(string symbol, int timeframe,
                       double &buyBuffer[], double &sellBuffer[])
{
   // 更新最新的买入信号箭头（bar[1]）
   if(buyBuffer[1] != EMPTY_VALUE)
   {
      string name = OBJ_PREFIX + "BUY_1";
      if(ObjectFind(name) >= 0)
      {
         ObjectSet(name, OBJPROP_PRICE1, buyBuffer[1]);
      }
   }

   // 更新最新的卖出信号箭头（bar[1]）
   if(sellBuffer[1] != EMPTY_VALUE)
   {
      string name = OBJ_PREFIX + "SELL_1";
      if(ObjectFind(name) >= 0)
      {
         ObjectSet(name, OBJPROP_PRICE1, sellBuffer[1]);
      }
   }
}

#endif // _DRAWING_MQH_
