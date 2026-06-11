//+------------------------------------------------------------------+
//|                                           BullsPower_Safe.mq4     |
//|  多头力量指标（Bulls Power）— 不含未来函数                         |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  BullsPower = High - EMA(Close, Period)                            |
//|  正值越大表示多方推动价格超越均线的能力越强                         |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：BullsPower从负值转为正值（多方反攻, bar[1]确认）         |
//|  - 卖出：顶背离 — 价格创新高但BullsPower未创新高(bar[1]确认)      |
//|  - 与BearsPower配合：Bull>0且Bear<0=多头市场                      |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5

input int    InpBPPeriod  = 13;           // EMA周期
input ENUM_PRICE_SAFE InpPriceType = PRICE_CLOSE;  // 价格类型

// 指标缓冲区
double bpBuffer[];      // Bulls Power 主线（柱状图）
double maBuffer[];      // EMA参考线（隐藏）
double buySignal[];     // 买入信号
double sellSignal[];    // 卖出信号
double strongBuy[];     // 强买入信号

//+------------------------------------------------------------------+
int init()
{
   // 主线柱状图
   SetIndexStyle(0, DRAW_HISTOGRAM, STYLE_SOLID, 2, clrLimeGreen);
   SetIndexBuffer(0, bpBuffer);
   SetIndexLabel(0, "Bulls Power");
   SetIndexEmptyValue(0, 0.0);

   // 零轴线（隐藏）
   SetIndexStyle(1, DRAW_NONE);
   SetIndexBuffer(1, maBuffer);

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

   // 强买入箭头
   SetIndexStyle(4, DRAW_ARROW, STYLE_SOLID, 4, clrCyan);
   SetIndexBuffer(4, strongBuy);
   SetIndexArrow(4, ARROW_BUY);
   SetIndexLabel(4, "Strong Buy");
   SetIndexEmptyValue(4, EMPTY_VALUE);

   IndicatorDigits(4);
   IndicatorShortName("BullsPower_Safe(" + IntegerToString(InpBPPeriod) + ")");
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

   // --- 第1步：计算历史BullsPower值 ---
   for(int i = limit; i >= 1; i--)
   {
      // 收集价格数组计算EMA
      double prices[];
      ArrayResize(prices, InpBPPeriod * 2);
      for(int j = 0; j < InpBPPeriod * 2; j++)
         prices[j] = GetPriceByType(i + j, InpPriceType);

      // EMA计算
      double ema = prices[InpBPPeriod * 2 - 1];
      double alpha = 2.0 / (InpBPPeriod + 1.0);
      for(int j = InpBPPeriod * 2 - 2; j >= 0; j--)
         ema = prices[j] * alpha + ema * (1.0 - alpha);

      maBuffer[i] = ema;
      bpBuffer[i] = iHigh(_Symbol, _Period, i) - ema;

      // 信号初始化
      buySignal[i]   = EMPTY_VALUE;
      sellSignal[i]  = EMPTY_VALUE;
      strongBuy[i]   = EMPTY_VALUE;
   }

   // --- 第2步：信号判断（bar[1]+确认）---
   for(int i = limit; i >= 3; i--)
   {
      // 买入信号：BullsPower从负转正 + 前一根也在回升
      if(bpBuffer[i + 1] < 0.0 && bpBuffer[i] > 0.0 &&
         bpBuffer[i + 2] < bpBuffer[i + 1])
      {
         buySignal[i] = bpBuffer[i] * 0.5;
      }

      // 强买入：连续3根BullsPower柱上升
      if(bpBuffer[i] > bpBuffer[i + 1] &&
         bpBuffer[i + 1] > bpBuffer[i + 2] &&
         bpBuffer[i + 2] > bpBuffer[i + 3] &&
         bpBuffer[i] > 0.0)
      {
         strongBuy[i] = bpBuffer[i] * 0.3;
      }

      // 顶背离卖出信号：价格创新高但BullsPower未创新高
      double priceI  = iClose(_Symbol, _Period, i);
      double priceI3 = iClose(_Symbol, _Period, i + 3);
      double priceI5 = iClose(_Symbol, _Period, i + 5);

      if(priceI > priceI5 && bpBuffer[i] < bpBuffer[i + 5] &&
         bpBuffer[i] > 0.0)
      {
         sellSignal[i] = bpBuffer[i] * 1.5;
      }

      // 严重顶背离：连续价格上升但BullsPower持续下降
      if(priceI > priceI3 && bpBuffer[i] < bpBuffer[i + 3] &&
         bpBuffer[i + 1] < bpBuffer[i + 4] && bpBuffer[i] > 0.0)
      {
         sellSignal[i] = bpBuffer[i] * 1.8;
      }
   }

   // --- 第3步：刷新 bar[0]（仅显示，不生成信号）---
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
      bpBuffer[0] = iHigh(_Symbol, _Period, 0) - e0;
      buySignal[0]   = EMPTY_VALUE;
      sellSignal[0]  = EMPTY_VALUE;
      strongBuy[0]   = EMPTY_VALUE;
   }

   return(0);
}
//+------------------------------------------------------------------+
