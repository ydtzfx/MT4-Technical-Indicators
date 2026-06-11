//+------------------------------------------------------------------+
//|                                                   PSY_Safe.mq4    |
//|  心理线（PSY）— 不含未来函数                                      |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：PSY = 100 * N天内上涨天数 / N                               |
//|  衡量市场参与者在一定时期内的多空心理状态                          |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：PSY从25下方回升突破确认(bar[1])                          |
//|  - 卖出：PSY从75上方回落跌破确认(bar[1])                          |
//|  - 25-75区间为正常心理波动范围                                     |
//|  - PSY<16.67 极度悲观（超卖），PSY>83.33 极度乐观（超买）         |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 75
#property indicator_level2 25

// 输入参数
input int   InpPSYPeriod = 12;       // PSY周期（常用12或20）
input color InpPSYColor  = clrDodgerBlue; // PSY线颜色
input double InpOverbought = 75.0;   // 超买水平
input double InpOversold   = 25.0;   // 超卖水平

// 指标缓冲区
double psyBuffer[];     // PSY主线
double buySignal[];     // 买入信号
double sellSignal[];    // 卖出信号

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, InpPSYColor);
   SetIndexBuffer(0, psyBuffer);
   SetIndexLabel(0, "PSY");
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

   IndicatorDigits(2);
   IndicatorShortName("PSY_Safe(" + IntegerToString(InpPSYPeriod) + ")");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;

   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - InpPSYPeriod * 2;
   if(limit < 0) limit = 0;

   // --- 第1步：计算历史PSY ---
   for(int i = limit; i >= 1; i--)
   {
      int upDays = 0;  // 统计上涨天数

      for(int j = 0; j < InpPSYPeriod; j++)
      {
         double closeCurr = iClose(_Symbol, _Period, i + j);
         double closePrev = iClose(_Symbol, _Period, i + j + 1);

         // 今日收盘 > 昨日收盘 → 上涨日
         if(closeCurr > closePrev)
            upDays++;
      }

      // PSY = 100 * 上涨天数 / 总天数
      psyBuffer[i] = 100.0 * upDays / InpPSYPeriod;

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // --- 第2步：信号判断（bar[1]+确认）---
   for(int i = limit; i >= 1; i--)
   {
      // 从超卖区(悲观区)回升 → 买入：市场情绪从悲观转向乐观
      if(psyBuffer[i + 1] <= InpOversold && psyBuffer[i] > InpOversold)
         buySignal[i] = 20.0;

      // 从超买区(乐观区)回落 → 卖出：市场情绪从过度乐观回落
      if(psyBuffer[i + 1] >= InpOverbought && psyBuffer[i] < InpOverbought)
         sellSignal[i] = 80.0;

      // 极度悲观反转（PSY<16.67后回升）
      if(psyBuffer[i + 1] <= 16.67 && psyBuffer[i] > 16.67)
         buySignal[i] = 15.0;

      // 极度乐观反转（PSY>83.33后回落）
      if(psyBuffer[i + 1] >= 83.33 && psyBuffer[i] < 83.33)
         sellSignal[i] = 85.0;
   }

   // --- 第3步：刷新 bar[0] ---
   if(Bars > 0)
   {
      int up0 = 0;
      for(int j = 0; j < InpPSYPeriod; j++)
      {
         if(iClose(_Symbol, _Period, j) > iClose(_Symbol, _Period, j + 1))
            up0++;
      }
      psyBuffer[0] = 100.0 * up0 / InpPSYPeriod;
      buySignal[0]  = EMPTY_VALUE;
      sellSignal[0] = EMPTY_VALUE;
   }

   return(0);
}
//+------------------------------------------------------------------+
