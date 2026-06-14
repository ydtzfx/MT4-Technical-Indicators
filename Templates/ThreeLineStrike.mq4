#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                           ThreeLineStrike.mq4     |
//|  三线出击模板 — 组合趋势+震荡指标综合信号                          |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  策略说明：                                                        |
//|  三线系统：                                                        |
//|  - 快线：EMA(Close, 5)  — 短期趋势                                |
//|  - 中线：EMA(Close, 20) — 中期趋势                                 |
//|  - 慢线：EMA(Close, 60) — 长期趋势                                 |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 强买：三线多头排列 + 快线上穿中线(bar[1]确认)                  |
//|  - 强卖：三线空头排列 + 快线下穿中线(bar[1]确认)                  |
//|  - 弱买/卖：仅有交叉但排列未完全确认                              |
//|                                                                   |
//|  所有信号基于 bar[1]+ 已完成K线                                    |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 6

// 输入参数
input int    InpFastPeriod = 5;     // 快线周期
input int    InpMidPeriod  = 20;    // 中线周期
input int    InpSlowPeriod = 60;    // 慢线周期
input color  InpFastColor  = clrLimeGreen;  // 快线颜色
input color  InpMidColor   = clrYellow;     // 中线颜色
input color  InpSlowColor  = clrRed;        // 慢线颜色

// 指标缓冲区
double fastBuffer[];
double midBuffer[];
double slowBuffer[];
double strongBuy[];
double strongSell[];
double weakSignal[];

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 1, InpFastColor);
   SetIndexBuffer(0, fastBuffer);
   SetIndexLabel(0, "Fast MA");

   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 2, InpMidColor);
   SetIndexBuffer(1, midBuffer);
   SetIndexLabel(1, "Mid MA");

   SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 3, InpSlowColor);
   SetIndexBuffer(2, slowBuffer);
   SetIndexLabel(2, "Slow MA");

   SetIndexStyle(3, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(3, strongBuy);
   SetIndexArrow(3, ARROW_BUY);
   SetIndexLabel(3, "Strong Buy");
   SetIndexEmptyValue(3, EMPTY_VALUE);

   SetIndexStyle(4, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(4, strongSell);
   SetIndexArrow(4, ARROW_SELL);
   SetIndexLabel(4, "Strong Sell");
   SetIndexEmptyValue(4, EMPTY_VALUE);

   SetIndexStyle(5, DRAW_ARROW, STYLE_SOLID, 1, clrGray);
   SetIndexBuffer(5, weakSignal);
   SetIndexArrow(5, ARROW_DOT);
   SetIndexLabel(5, "Weak Signal");
   SetIndexEmptyValue(5, EMPTY_VALUE);

   IndicatorDigits(4);
   IndicatorShortName("ThreeLine(" + IntegerToString(InpFastPeriod) + "," +
                      IntegerToString(InpMidPeriod) + "," + IntegerToString(InpSlowPeriod) + ")");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
double CalcEMAAt(double &prices[], int period, int shift)
{
   double ema = 0.0;
   int size = ArraySize(prices);
   if(size <= shift) return(prices[shift]);

   // SMA种子
   for(int i = size - 1 - shift; i >= size - period - shift && i >= 0; i--)
      ema += prices[i];
   ema /= period;

   double alpha = 2.0 / (period + 1.0);
   for(i = size - period - 1 - shift; i >= 0; i--)
      ema = prices[i] * alpha + ema * (1.0 - alpha);

   return(ema);
}

//+------------------------------------------------------------------+
int start()
{
   int i;
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;
   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - InpSlowPeriod * 3;
   if(limit < 0) limit = 0;

   int histSize = InpSlowPeriod * 3;

   for(i = limit; i >= 0; i--)
   {
      if(i + histSize >= Bars)
      {
         fastBuffer[i] = 0.0;
         midBuffer[i]  = 0.0;
         slowBuffer[i] = 0.0;
         strongBuy[i]  = EMPTY_VALUE;
         strongSell[i] = EMPTY_VALUE;
         weakSignal[i] = EMPTY_VALUE;
         continue;
      }

      double closes[];
      ArrayResize(closes, histSize);
      for(int j = 0; j < histSize; j++)
         closes[j] = iClose(_Symbol, _Period, i + j);

      fastBuffer[i] = CalcEMAAt(closes, InpFastPeriod, 0);
      midBuffer[i]  = CalcEMAAt(closes, InpMidPeriod, 0);
      slowBuffer[i] = CalcEMAAt(closes, InpSlowPeriod, 0);

      strongBuy[i]  = EMPTY_VALUE;
      strongSell[i] = EMPTY_VALUE;
      weakSignal[i] = EMPTY_VALUE;
   }

   // 信号（bar[1]+确认）
   for(i = limit; i >= 1; i--)
   {
      // 多头排列检查
      bool isBullishAlign = (fastBuffer[i] > midBuffer[i] && midBuffer[i] > slowBuffer[i]);
      bool isBearishAlign = (fastBuffer[i] < midBuffer[i] && midBuffer[i] < slowBuffer[i]);

      // 交叉检测
      bool fastCrossUp   = (fastBuffer[i+1] <= midBuffer[i+1] && fastBuffer[i] > midBuffer[i]);
      bool fastCrossDown = (fastBuffer[i+1] >= midBuffer[i+1] && fastBuffer[i] < midBuffer[i]);

      // 强买：多头排列 + 快线上穿中线
      if(isBullishAlign && fastCrossUp)
         strongBuy[i] = iLow(_Symbol, _Period, i) - 10.0 * _Point;

      // 强卖：空头排列 + 快线下穿中线
      if(isBearishAlign && fastCrossDown)
         strongSell[i] = iHigh(_Symbol, _Period, i) + 10.0 * _Point;

      // 弱信号：仅有交叉但排列不完全
      if(fastCrossUp && !isBullishAlign)
         weakSignal[i] = iLow(_Symbol, _Period, i) - 15.0 * _Point;

      if(fastCrossDown && !isBearishAlign)
         weakSignal[i] = iHigh(_Symbol, _Period, i) + 15.0 * _Point;
   }

   return(0);
}
//+------------------------------------------------------------------+
