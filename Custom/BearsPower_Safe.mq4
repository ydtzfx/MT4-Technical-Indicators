//+------------------------------------------------------------------+
//|                                           BearsPower_Safe.mq4     |
//|  空头力量指标（Bears Power）— 不含未来函数                         |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  BearsPower = Low - EMA(Close, Period)                             |
//|  通常为负值，负值越小（绝对值越大）表示空方打压价格的能力越强       |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 卖出：BearsPower从正值转为负值（空方反攻, bar[1]确认）         |
//|  - 买入：底背离 — 价格创新低但BearsPower未创新低(bar[1]确认)      |
//|  - 与BullsPower配合：Bull>0且Bear<0=多头, Bull<0且Bear>0=空头     |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 6

input int    InpBPPeriod  = 13;           // EMA周期
input ENUM_PRICE_SAFE InpPriceType = PRICE_CLOSE;  // 价格类型

// 指标缓冲区
double bpBuffer[];      // Bears Power 主线（柱状图）
double maBuffer[];      // EMA参考线（隐藏）
double buySignal[];     // 买入信号
double sellSignal[];    // 卖出信号
double strongSell[];    // 强卖出信号
double strongBuy[];     // 强买入信号

//+------------------------------------------------------------------+
int init()
{
   // 主线柱状图
   SetIndexStyle(0, DRAW_HISTOGRAM, STYLE_SOLID, 2, clrTomato);
   SetIndexBuffer(0, bpBuffer);
   SetIndexLabel(0, "Bears Power");
   SetIndexEmptyValue(0, 0.0);

   // 零轴线（隐藏）
   SetIndexStyle(1, DRAW_NONE);
   SetIndexBuffer(1, maBuffer);
   SetIndexEmptyValue(1, EMPTY_VALUE);

   // 买入箭头
   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(2, buySignal);
   SetIndexArrow(2, ARROW_BUY);
   SetIndexLabel(2, "Buy Signal");
   SetIndexEmptyValue(2, EMPTY_VALUE);

   // 卖出箭头
   SetIndexStyle(3, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(3, sellSignal);
   SetIndexArrow(3, ARROW_SELL);
   SetIndexLabel(3, "Sell Signal");
   SetIndexEmptyValue(3, EMPTY_VALUE);

   // 强卖出箭头
   SetIndexStyle(4, DRAW_ARROW, STYLE_SOLID, 4, clrDeepPink);
   SetIndexBuffer(4, strongSell);
   SetIndexArrow(4, ARROW_SELL);
   SetIndexLabel(4, "Strong Sell");
   SetIndexEmptyValue(4, EMPTY_VALUE);

   // 强买入箭头
   SetIndexStyle(5, DRAW_ARROW, STYLE_SOLID, 4, clrCyan);
   SetIndexBuffer(5, strongBuy);
   SetIndexArrow(5, ARROW_BUY);
   SetIndexLabel(5, "Strong Buy");
   SetIndexEmptyValue(5, EMPTY_VALUE);

   IndicatorDigits(4);
   IndicatorShortName("BearsPower_Safe(" + IntegerToString(InpBPPeriod) + ")");
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
   if(limit > Bars - 2) limit = Bars - InpBPPeriod * 2;
   if(limit < 0) limit = 0;

   // --- 第1步：计算历史BearsPower值 ---
   for(int i = limit; i >= 1; i--)
   {
      double prices[];
      ArrayResize(prices, InpBPPeriod * 2);
      for(int j = 0; j < InpBPPeriod * 2; j++)
         prices[j] = GetPriceByType(i + j, InpPriceType);

      double ema = prices[InpBPPeriod * 2 - 1];
      double alpha = 2.0 / (InpBPPeriod + 1.0);
      for(int j = InpBPPeriod * 2 - 2; j >= 0; j--)
         ema = prices[j] * alpha + ema * (1.0 - alpha);

      maBuffer[i] = ema;
      bpBuffer[i] = iLow(_Symbol, _Period, i) - ema;  // 通常为负值

      buySignal[i]   = EMPTY_VALUE;
      sellSignal[i]  = EMPTY_VALUE;
      strongSell[i]  = EMPTY_VALUE;
      strongBuy[i]   = EMPTY_VALUE;
   }

   // --- 第2步：信号判断（bar[1]+确认）---
   for(int i = limit; i >= 3; i--)
   {
      // 卖出信号：BearsPower从正转负（从EMA上方跌到下方）
      if(bpBuffer[i + 1] > 0.0 && bpBuffer[i] < 0.0)
      {
         sellSignal[i] = bpBuffer[i] * 1.5;
      }

      // 强卖出：连续3根BearsPower柱扩大（负值越来越小）
      if(bpBuffer[i] < bpBuffer[i + 1] &&
         bpBuffer[i + 1] < bpBuffer[i + 2] &&
         bpBuffer[i + 2] < bpBuffer[i + 3] &&
         bpBuffer[i] < 0.0)
      {
         strongSell[i] = bpBuffer[i] * 1.7;
      }

      // 强买入：连续3根BearsPower柱收缩（负值越来越小，空头减弱）
      if(bpBuffer[i] > bpBuffer[i + 1] &&
         bpBuffer[i + 1] > bpBuffer[i + 2] &&
         bpBuffer[i + 2] > bpBuffer[i + 3] &&
         bpBuffer[i] < 0.0)
      {
         strongBuy[i] = bpBuffer[i] * 0.3;
      }

      // 底背离买入信号：价格创新低但BearsPower回升（绝对值缩小，即数值变大）
      double priceI  = iClose(_Symbol, _Period, i);
      double priceI3 = iClose(_Symbol, _Period, i + 3);
      double priceI5 = iClose(_Symbol, _Period, i + 5);

      if(priceI < priceI5 && bpBuffer[i] > bpBuffer[i + 5] &&
         bpBuffer[i] < 0.0)
      {
         buySignal[i] = bpBuffer[i] * 0.5;
      }

      // 严重底背离
      if(priceI < priceI3 && bpBuffer[i] > bpBuffer[i + 3] &&
         bpBuffer[i + 1] > bpBuffer[i + 4] && bpBuffer[i] < 0.0)
      {
         buySignal[i] = bpBuffer[i] * 0.3;
      }
   }

   // --- 第3步：刷新 bar[0] ---
   if(Bars > 0)
   {
      double p0[];
      ArrayResize(p0, InpBPPeriod * 2);
      for(int j = 0; j < InpBPPeriod * 2; j++)
         p0[j] = GetPriceByType(j, InpPriceType);
      double e0 = p0[InpBPPeriod * 2 - 1];
      double a0 = 2.0 / (InpBPPeriod + 1.0);
      for(int j = InpBPPeriod * 2 - 2; j >= 0; j--)
         e0 = p0[j] * a0 + e0 * (1.0 - a0);
      bpBuffer[0] = iLow(_Symbol, _Period, 0) - e0;
      buySignal[0]   = EMPTY_VALUE;
      sellSignal[0]  = EMPTY_VALUE;
      strongSell[0]  = EMPTY_VALUE;
      strongBuy[0]   = EMPTY_VALUE;
   }

   return(0);
}
//+------------------------------------------------------------------+
