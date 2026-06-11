//+------------------------------------------------------------------+
//|                                  ChaikinOscillator_Safe.mq4       |
//|  蔡金振荡器 — 不含未来函数                                        |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  CLV = ((Close - Low) - (High - Close)) / (High - Low)            |
//|  ADL = ADL_prev + CLV * Volume（累积派发线）                       |
//|  Chaikin Osc = EMA(ADL, Fast) - EMA(ADL, Slow)                     |
//|                                                                   |
//|  衡量资金流向的加速度：                                            |
//|  >0 = 资金加速流入，<0 = 资金加速流出                              |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：CHO从负转正（bar[1]确认）                                |
//|  - 卖出：CHO从正转负（bar[1]确认）                                |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3

input int InpFast = 3;     // 快EMA周期
input int InpSlow = 10;    // 慢EMA周期

// 指标缓冲区
double choBuffer[];     // Chaikin Oscillator 主线（柱状图）
double buySignal[];     // 买入信号
double sellSignal[];    // 卖出信号

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_HISTOGRAM, STYLE_SOLID, 2);
   SetIndexBuffer(0, choBuffer);
   SetIndexLabel(0, "Chaikin Osc(" + IntegerToString(InpFast) + "," + IntegerToString(InpSlow) + ")");
   SetIndexEmptyValue(0, 0.0);

   SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(1, buySignal);
   SetIndexArrow(1, ARROW_BUY);
   SetIndexLabel(1, "Buy Signal");
   SetIndexEmptyValue(1, EMPTY_VALUE);

   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(2, sellSignal);
   SetIndexArrow(2, ARROW_SELL);
   SetIndexLabel(2, "Sell Signal");
   SetIndexEmptyValue(2, EMPTY_VALUE);

   IndicatorDigits(0);
   IndicatorShortName("ChaikinOsc_Safe(" + IntegerToString(InpFast) + "," + IntegerToString(InpSlow) + ")");
   return(0);
}

//+------------------------------------------------------------------+
int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;

   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - InpSlow * 3;
   if(limit < 0) limit = 0;

   // --- 第1步：构建累积派发线（ADL）---
   double adl[];
   ArrayResize(adl, Bars);
   double cumulativeADL = 0.0;

   // 从最远bar开始累积
   for(int i = Bars - 2; i >= 0; i--)
   {
      double high  = iHigh(_Symbol, _Period, i);
      double low   = iLow(_Symbol, _Period, i);
      double close = iClose(_Symbol, _Period, i);
      long   volume = iVolume(_Symbol, _Period, i);

      double range = high - low;

      // Close Location Value (CLV): [-1, 1]
      // CLV=1 收盘在最高价；CLV=-1 收盘在最低价
      double clv = 0.0;
      if(MathAbs(range) > _Point)
         clv = ((close - low) - (high - close)) / range;

      // ADL = 累积的CLV*Volume
      cumulativeADL += clv * (double)volume;
      adl[i] = cumulativeADL;
   }

   // --- 第2步：计算EMA(ADL, Fast) - EMA(ADL, Slow) ---
   double alphaFast = 2.0 / (InpFast + 1.0);
   double alphaSlow = 2.0 / (InpSlow + 1.0);

   for(int i = limit; i >= 1; i--)
   {
      // 快EMA
      double emaFast = adl[i + InpSlow];
      for(int j = InpSlow - 1; j >= 0; j--)
         emaFast = adl[i + j] * alphaFast + emaFast * (1.0 - alphaFast);

      // 慢EMA
      double emaSlow = adl[i + InpSlow];
      for(int j = InpSlow - 1; j >= 0; j--)
         emaSlow = adl[i + j] * alphaSlow + emaSlow * (1.0 - alphaSlow);

      choBuffer[i] = emaFast - emaSlow;

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // --- 第3步：信号判断（bar[1]+确认）---
   for(int i = limit; i >= 1; i--)
   {
      // CHO上穿零轴 → 资金加速流入 → 买入
      if(choBuffer[i + 1] < 0.0 && choBuffer[i] > 0.0)
         buySignal[i] = choBuffer[i] * 0.5;

      // CHO下穿零轴 → 资金加速流出 → 卖出
      if(choBuffer[i + 1] > 0.0 && choBuffer[i] < 0.0)
         sellSignal[i] = choBuffer[i] * 1.5;
   }

   // --- 第4步：刷新 bar[0] ---
   if(Bars > 0)
   {
      choBuffer[0] = choBuffer[1];
      buySignal[0]  = EMPTY_VALUE;
      sellSignal[0] = EMPTY_VALUE;
   }

   return(0);
}
//+------------------------------------------------------------------+
