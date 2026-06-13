//+------------------------------------------------------------------+
//|                                            Awesome_Safe.mq4       |
//|  动量震荡指标（Awesome Oscillator）— 不含未来函数                  |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  Median = (High + Low) / 2                                         |
//|  AO = SMA(Median, 5) - SMA(Median, 34)                             |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入1：AO上穿零轴 (bar[1]确认)                                 |
//|  - 买入2：AO连续3根上升且从零下到零上（碟形买入）                  |
//|  - 卖出1：AO下穿零轴 (bar[1]确认)                                 |
//|  - 卖出2：AO连续3根下降且从零上到零下（碟形卖出）                  |
//|  - 强买入：零轴穿越 + 穿越前已在负区蓄力上涨（动量确认）           |
//|  - 强卖出：零轴穿越 + 穿越前已在正区蓄力下跌（动量确认）           |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5

// 输入参数
input color InpUpColor   = clrLimeGreen;
input color  InpDownColor = clrTomato;

// 指标缓冲区
double aoBuffer[];
double buySignal[];
double sellSignal[];
double strongBuy[];
double strongSell[];

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_HISTOGRAM, STYLE_SOLID, 2);
   SetIndexBuffer(0, aoBuffer);
   SetIndexLabel(0, "AO");

   SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(1, buySignal);
   SetIndexArrow(1, ARROW_BUY);
   SetIndexEmptyValue(1, EMPTY_VALUE);

   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(2, sellSignal);
   SetIndexArrow(2, ARROW_SELL);
   SetIndexEmptyValue(2, EMPTY_VALUE);

   SetIndexBuffer(3, strongBuy);
   SetIndexStyle(3, DRAW_ARROW, STYLE_SOLID, 4, clrCyan);
   SetIndexArrow(3, 233);
   SetIndexEmptyValue(3, EMPTY_VALUE);

   SetIndexBuffer(4, strongSell);
   SetIndexStyle(4, DRAW_ARROW, STYLE_SOLID, 4, clrDeepPink);
   SetIndexArrow(4, 234);
   SetIndexEmptyValue(4, EMPTY_VALUE);

   IndicatorDigits(4);
   IndicatorShortName("AO_Safe");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;
   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - 100;
   if(limit < 0) limit = 0;

   // Step 1: 计算历史数据 (bar[1]+)，清空信号缓冲区
   for(int i = limit; i >= 1; i--)
   {
      // 计算5周期SMA和34周期SMA
      double sum5 = 0.0, sum34 = 0.0;
      for(int j = 0; j < 34; j++)
      {
         double median = (iHigh(_Symbol, _Period, i + j) + iLow(_Symbol, _Period, i + j)) / 2.0;
         sum34 += median;
         if(j < 5) sum5 += median;
      }

      double sma5  = sum5 / 5.0;
      double sma34 = sum34 / 34.0;

      aoBuffer[i] = sma5 - sma34;

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
      strongBuy[i]  = EMPTY_VALUE;
      strongSell[i] = EMPTY_VALUE;
   }

   // Step 2: 信号生成（bar[1]+确认）— 多条件强信号优先
   for(int i = limit; i >= 3; i--)
   {
      // ---- 买入信号 ----
      bool crossUp    = (aoBuffer[i+1] < 0 && aoBuffer[i] > 0);
      bool saucerBuy  = (aoBuffer[i] > aoBuffer[i+1] && aoBuffer[i+1] > aoBuffer[i+2] &&
                         aoBuffer[i] > aoBuffer[i+3] &&
                         aoBuffer[i] < 0 && aoBuffer[i+1] < 0);

      if(crossUp)
      {
         // 强买入：零轴穿越 + 穿越前已在负区蓄力上涨
         if(aoBuffer[i+1] > aoBuffer[i+2] && aoBuffer[i+2] < 0)
            strongBuy[i] = aoBuffer[i] - MathAbs(aoBuffer[i] * 0.3);
         else
            buySignal[i] = aoBuffer[i] - MathAbs(aoBuffer[i] * 0.2);
      }
      else if(saucerBuy)
      {
         buySignal[i] = aoBuffer[i] - MathAbs(aoBuffer[i] * 0.2);
      }

      // ---- 卖出信号 ----
      bool crossDown  = (aoBuffer[i+1] > 0 && aoBuffer[i] < 0);
      bool saucerSell = (aoBuffer[i] < aoBuffer[i+1] && aoBuffer[i+1] < aoBuffer[i+2] &&
                         aoBuffer[i] < aoBuffer[i+3] &&
                         aoBuffer[i] > 0 && aoBuffer[i+1] > 0);

      if(crossDown)
      {
         // 强卖出：零轴穿越 + 穿越前已在正区蓄力下跌
         if(aoBuffer[i+1] < aoBuffer[i+2] && aoBuffer[i+2] > 0)
            strongSell[i] = aoBuffer[i] + MathAbs(aoBuffer[i] * 0.3);
         else
            sellSignal[i] = aoBuffer[i] + MathAbs(aoBuffer[i] * 0.2);
      }
      else if(saucerSell)
      {
         sellSignal[i] = aoBuffer[i] + MathAbs(aoBuffer[i] * 0.2);
      }
   }

   // Step 3: bar[0] — 只更新显示值，不产生任何信号
   if(Bars > 0)
   {
      double sum5_0 = 0.0, sum34_0 = 0.0;
      for(int j = 0; j < 34; j++)
      {
         double median0 = (iHigh(_Symbol, _Period, j) + iLow(_Symbol, _Period, j)) / 2.0;
         sum34_0 += median0;
         if(j < 5) sum5_0 += median0;
      }
      aoBuffer[0] = sum5_0 / 5.0 - sum34_0 / 34.0;
      buySignal[0]  = EMPTY_VALUE;
      sellSignal[0] = EMPTY_VALUE;
      strongBuy[0]  = EMPTY_VALUE;
      strongSell[0] = EMPTY_VALUE;
   }

   return(0);
}
//+------------------------------------------------------------------+
