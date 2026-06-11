//+------------------------------------------------------------------+
//|                                                    ASI_Safe.mq4   |
//|  振动升降指数 — 不含未来函数(信号逻辑)                              |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明（简化版）：                                              |
//|  ASI = 累积振动指数，综合价格变动幅度和方向                        |
//|  使用Welles Wilder的累积摆动公式                                  |
//|                                                                   |
//|  注意：ASI本身是累积指标，不依赖未来函数                           |
//|  但信号确认使用 bar[1]+ 的数据                                    |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3

// 指标缓冲区
double asiBuffer[];
double buySignal[];
double sellSignal[];

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, clrDodgerBlue);
   SetIndexBuffer(0, asiBuffer);
   SetIndexLabel(0, "ASI");

   SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(1, buySignal);
   SetIndexArrow(1, ARROW_BUY);
   SetIndexEmptyValue(1, EMPTY_VALUE);

   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(2, sellSignal);
   SetIndexArrow(2, ARROW_SELL);
   SetIndexEmptyValue(2, EMPTY_VALUE);

   IndicatorDigits(0);
   IndicatorShortName("ASI_Safe");
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

   double cumulativeASI = 0.0;
   int startIdx = limit + 100 > Bars - 1 ? Bars - 1 : limit + 100;

   for(int i = startIdx; i >= 0; i--)
   {
      double close  = iClose(_Symbol, _Period, i);
      double open   = iOpen(_Symbol, _Period, i);
      double high   = iHigh(_Symbol, _Period, i);
      double low    = iLow(_Symbol, _Period, i);
      double prevClose = iClose(_Symbol, _Period, i + 1);
      double prevOpen  = iOpen(_Symbol, _Period, i + 1);

      // SI = 50 * (Close-PrevClose + 0.5*(Close-Open) + 0.25*(PrevClose-PrevOpen)) / R
      // 其中R是最大波动幅度
      double range = high - low;
      if(MathAbs(range) < 0.00000001) range = _Point;

      double maxMove1 = high - prevClose;
      double maxMove2 = low - prevClose;
      double maxMove  = MathMax(MathAbs(maxMove1), MathAbs(maxMove2));

      double si = 0.0;
      if(maxMove > 0)
      {
         double priceMove = close - prevClose;
         double intraMove = (close - open) * 0.5;
         double prevMove  = (prevClose - prevOpen) * 0.25;
         si = 50.0 * (priceMove + intraMove + prevMove) / maxMove * range / _Point;
      }

      if(i == startIdx)
      {
         cumulativeASI = si;
         asiBuffer[i] = cumulativeASI;
         continue;
      }

      cumulativeASI += si;
      asiBuffer[i] = cumulativeASI;

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // 信号：突破前高/前低（bar[1]+确认）
   for(int i = limit; i >= 3; i--)
   {
      // ASI新高 → 价格可能跟随上涨
      if(asiBuffer[i] > asiBuffer[i+1] && asiBuffer[i] > asiBuffer[i+2] &&
         asiBuffer[i] > asiBuffer[i+3])
         buySignal[i] = asiBuffer[i] * 0.95;

      // ASI新低 → 价格可能跟随下跌
      if(asiBuffer[i] < asiBuffer[i+1] && asiBuffer[i] < asiBuffer[i+2] &&
         asiBuffer[i] < asiBuffer[i+3])
         sellSignal[i] = asiBuffer[i] * 1.05;
   }

   return(0);
}
//+------------------------------------------------------------------+
