//+------------------------------------------------------------------+
//|                                                     AD_Safe.mq4   |
//|  累积/派发指标 — 不含未来函数                                     |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  CLV = ((Close - Low) - (High - Close)) / (High - Low)             |
//|  AD = PrevAD + CLV * Volume                                        |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：AD与价格底背离（价格新低AD未新低, bar[1]确认）           |
//|  - 卖出：AD与价格顶背离（价格新高AD未新高, bar[1]确认）           |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3

// 指标缓冲区
double adBuffer[];
double buySignal[];
double sellSignal[];

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, clrDodgerBlue);
   SetIndexBuffer(0, adBuffer);
   SetIndexLabel(0, "A/D");

   SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(1, buySignal);
   SetIndexArrow(1, ARROW_BUY);
   SetIndexEmptyValue(1, EMPTY_VALUE);

   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(2, sellSignal);
   SetIndexArrow(2, ARROW_SELL);
   SetIndexEmptyValue(2, EMPTY_VALUE);

   IndicatorDigits(0);
   IndicatorShortName("AD_Safe");
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

   double cumulativeAD = 0.0;
   int lastIndex = limit + 50 > Bars - 1 ? Bars - 1 : limit + 50;

   for(int i = lastIndex; i >= 0; i--)
   {
      double high  = iHigh(_Symbol, _Period, i);
      double low   = iLow(_Symbol, _Period, i);
      double close = iClose(_Symbol, _Period, i);
      long   vol   = iVolume(_Symbol, _Period, i);

      // CLV (Close Location Value)
      double range = high - low;
      double clv = 0.0;
      if(MathAbs(range) > 0.00000001)
         clv = ((close - low) - (high - close)) / range;

      if(i == lastIndex)
      {
         cumulativeAD = clv * vol;
         adBuffer[i] = cumulativeAD;
         continue;
      }

      cumulativeAD += clv * vol;
      adBuffer[i] = cumulativeAD;

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // 背离信号（bar[1]+确认）
   for(int i = limit; i >= 3; i--)
   {
      double close_i  = iClose(_Symbol, _Period, i);
      double close_i3 = iClose(_Symbol, _Period, i + 3);

      // 底背离
      if(close_i < close_i3 && adBuffer[i] > adBuffer[i+3])
         buySignal[i] = adBuffer[i] * 0.95;

      // 顶背离
      if(close_i > close_i3 && adBuffer[i] < adBuffer[i+3])
         sellSignal[i] = adBuffer[i] * 1.05;
   }

   return(0);
}
//+------------------------------------------------------------------+
