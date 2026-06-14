#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                                    OBV_Safe.mq4   |
//|  能量潮指标 — 不含未来函数                                        |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  If Close > PrevClose: OBV = PrevOBV + Volume                     |
//|  If Close < PrevClose: OBV = PrevOBV - Volume                     |
//|  If Close = PrevClose: OBV = PrevOBV (不变)                       |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：OBV与价格底背离（价格新低但OBV未新低, bar[1]确认）       |
//|  - 卖出：OBV与价格顶背离（价格新高但OBV未新高, bar[1]确认）       |
//|  - OBV趋势变化先于价格趋势变化                                    |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5

// 输入参数
input ENUM_PRICE_SAFE InpPriceType = SAFE_PRICE_CLOSE;

// 指标缓冲区
double obvBuffer[];
double buySignal[];
double sellSignal[];
double strongBuy[];
double strongSell[];

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, clrDodgerBlue);
   SetIndexBuffer(0, obvBuffer);
   SetIndexEmptyValue(0, EMPTY_VALUE);
   SetIndexLabel(0, "OBV");

   SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(1, buySignal);
   SetIndexArrow(1, ARROW_BUY);
   SetIndexEmptyValue(1, EMPTY_VALUE);

   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(2, sellSignal);
   SetIndexArrow(2, ARROW_SELL);
   SetIndexEmptyValue(2, EMPTY_VALUE);

   SetIndexStyle(3, DRAW_ARROW, STYLE_SOLID, 4, clrCyan);
   SetIndexBuffer(3, strongBuy);
   SetIndexArrow(3, 233);
   SetIndexEmptyValue(3, EMPTY_VALUE);

   SetIndexStyle(4, DRAW_ARROW, STYLE_SOLID, 4, clrDeepPink);
   SetIndexBuffer(4, strongSell);
   SetIndexArrow(4, 234);
   SetIndexEmptyValue(4, EMPTY_VALUE);

   IndicatorDigits(0);
   IndicatorShortName("OBV_Safe");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;
   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - 2;
   if(limit < 0) limit = 0;

   // OBV从最远bar开始累加
   double cumulativeOBV = 0.0;
   int lastIndex = limit + 100 > Bars ? Bars - 1 : limit + 100;
   if(lastIndex < 0) lastIndex = Bars - 1;

   for(int i = lastIndex; i >= 0; i--)
   {
      if(i == lastIndex)
      {
         // 初始OBV = 当前成交量
         cumulativeOBV = (double)iVolume(_Symbol, _Period, i);
         obvBuffer[i] = cumulativeOBV;
         continue;
      }
      double closeCurr = GetPriceByType(i, InpPriceType);
      double closePrev = GetPriceByType(i + 1, InpPriceType);
      double volume    = (double)iVolume(_Symbol, _Period, i);

      if(closeCurr > closePrev)
         cumulativeOBV += volume;
      else if(closeCurr < closePrev)
         cumulativeOBV -= volume;

      obvBuffer[i] = cumulativeOBV;
      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
      strongBuy[i]  = EMPTY_VALUE;
      strongSell[i] = EMPTY_VALUE;
   }

   // 信号判断：背离检测（bar[1]+确认）
   for(i = limit; i >= 3; i--)
   {
      strongBuy[i]  = EMPTY_VALUE;
      strongSell[i] = EMPTY_VALUE;

      // 底背离：价格新低但OBV未新低
      double price_i   = GetPriceByType(i, InpPriceType);
      double price_i2  = GetPriceByType(i + 2, InpPriceType);
      double price_i4  = GetPriceByType(i + 4, InpPriceType);

      // 成交量激增检测（最近20根K线平均成交量）
      double avgVolume = 0;
      int volCount = 0;
      for(int j = i; j < i + 20 && j < Bars; j++)
      {
         avgVolume += (double)iVolume(_Symbol, _Period, j);
         volCount++;
      }
      if(volCount > 0) avgVolume /= volCount;
      bool volumeSurge = iVolume(_Symbol, _Period, i) > avgVolume * 1.5;

      // OBV极值检测（最近30根K线范围）
      double obvMax = obvBuffer[i];
      double obvMin = obvBuffer[i];
      for(int jj = i; j < i + 30 && j < Bars; j++)
      {
         if(obvBuffer[j] > obvMax) obvMax = obvBuffer[j];
         if(obvBuffer[j] < obvMin) obvMin = obvBuffer[j];
      }
      double obvRange = obvMax - obvMin;
      bool obvExtremeLow  = (obvRange > 0) && ((obvBuffer[i] - obvMin) < obvRange * 0.15);
      bool obvExtremeHigh = (obvRange > 0) && ((obvMax - obvBuffer[i]) < obvRange * 0.15);

      bool buyDivergence  = price_i < price_i4 && price_i < price_i2 && obvBuffer[i] > obvBuffer[i+4];
      bool sellDivergence = price_i > price_i4 && price_i > price_i2 && obvBuffer[i] < obvBuffer[i+4];

      // 强信号（多条件确认：背离 + 成交量激增 + OBV极值区域）
      if(buyDivergence && volumeSurge && obvExtremeLow)
         strongBuy[i] = obvBuffer[i] * 0.92;
      if(sellDivergence && volumeSurge && obvExtremeHigh)
         strongSell[i] = obvBuffer[i] * 1.08;

      // 普通信号
      if(buyDivergence)
         buySignal[i] = obvBuffer[i] * 0.95;
      if(sellDivergence)
         sellSignal[i] = obvBuffer[i] * 1.05;
   }

   // 确保bar[0]无信号
   strongBuy[0]  = EMPTY_VALUE;
   strongSell[0] = EMPTY_VALUE;

   return(0);
}
//+------------------------------------------------------------------+
