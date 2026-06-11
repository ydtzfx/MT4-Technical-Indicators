//+------------------------------------------------------------------+
//|                                        Accelerator_Safe.mq4       |
//|  加速震荡指标（Accelerator Oscillator）— 不含未来函数             |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  AO = SMA(Median, 5) - SMA(Median, 34)                             |
//|  AC = AO - SMA(AO, 5)                                              |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：AC从负转正且连续上升 (bar[1]确认)                         |
//|  - 卖出：AC从正转负且连续下降 (bar[1]确认)                         |
//|  - AC领先于AO，是加速/减速的先行指标                               |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3

// 输入参数
input color InpUpColor   = clrLimeGreen;
input color InpDownColor = clrTomato;

// 指标缓冲区
double acBuffer[];
double buySignal[];
double sellSignal[];

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_HISTOGRAM, STYLE_SOLID, 2);
   SetIndexBuffer(0, acBuffer);
   SetIndexLabel(0, "AC");

   SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(1, buySignal);
   SetIndexArrow(1, ARROW_BUY);
   SetIndexEmptyValue(1, EMPTY_VALUE);

   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(2, sellSignal);
   SetIndexArrow(2, ARROW_SELL);
   SetIndexEmptyValue(2, EMPTY_VALUE);

   IndicatorDigits(4);
   IndicatorShortName("AC_Safe");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;
   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - 120;
   if(limit < 0) limit = 0;

   double aoBuffer[];  // 内部AO缓冲区
   ArrayResize(aoBuffer, Bars);
   ArrayInitialize(aoBuffer, 0.0);

   // 先计算AO
   for(int i = limit + 10; i >= 0; i--)
   {
      double sum5 = 0.0, sum34 = 0.0;
      for(int j = 0; j < 34; j++)
      {
         double median = (iHigh(_Symbol, _Period, i + j) + iLow(_Symbol, _Period, i + j)) / 2.0;
         sum34 += median;
         if(j < 5) sum5 += median;
      }
      aoBuffer[i] = sum5 / 5.0 - sum34 / 34.0;
   }

   // 计算AC = AO - SMA(AO, 5)
   for(int i = limit; i >= 0; i--)
   {
      double aoSum5 = 0.0;
      for(int j = 0; j < 5; j++)
         aoSum5 += aoBuffer[i + j];
      double smaAO5 = aoSum5 / 5.0;

      acBuffer[i] = aoBuffer[i] - smaAO5;

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // 信号（bar[1]+确认）
   for(int i = limit; i >= 3; i--)
   {
      // 连续上升且从负转正
      if(acBuffer[i] > acBuffer[i+1] && acBuffer[i+1] > acBuffer[i+2] &&
         acBuffer[i+1] < 0 && acBuffer[i] > 0)
         buySignal[i] = acBuffer[i] - MathAbs(acBuffer[i] * 0.3);

      // 连续下降且从正转负
      if(acBuffer[i] < acBuffer[i+1] && acBuffer[i+1] < acBuffer[i+2] &&
         acBuffer[i+1] > 0 && acBuffer[i] < 0)
         sellSignal[i] = acBuffer[i] + MathAbs(acBuffer[i] * 0.3);
   }

   return(0);
}
//+------------------------------------------------------------------+
