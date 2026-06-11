//+------------------------------------------------------------------+
//|                                                    BR_Safe.mq4    |
//|  意愿指标（BR）— 不含未来函数                                     |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  BR = 100 * Σ(High - PrevClose, N) / Σ(PrevClose - Low, N)        |
//|  与AR的区别：AR用开盘价，BR用前收盘价作为基准                       |
//|  反映昨日收盘后多空双方继续博弈的意愿                               |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：BR从40下方回升突破确认(bar[1])                            |
//|  - 卖出：BR从300上方回落跌破确认(bar[1])                           |
//|  - BR<40 极度超卖，40-70 安全买入区域                             |
//|  - BR>300 极度超买，150-300 多方强势                               |
//|  - 通常与AR配合使用：AR+BR同时买入信号更可靠                       |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum 0
#property indicator_level1 300
#property indicator_level2 40

// 输入参数
input int   InpBRPeriod = 26;       // BR周期
input color InpBRColor  = clrOrange; // BR线颜色

// 指标缓冲区
double brBuffer[];      // BR主线
double buySignal[];     // 买入信号
double sellSignal[];    // 卖出信号

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, InpBRColor);
   SetIndexBuffer(0, brBuffer);
   SetIndexLabel(0, "BR");
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
   IndicatorShortName("BR_Safe(" + IntegerToString(InpBRPeriod) + ")");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;

   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - InpBRPeriod * 2;
   if(limit < 0) limit = 0;

   // --- 第1步：计算历史BR值 ---
   for(int i = limit; i >= 1; i--)
   {
      double sumHigh = 0.0;  // 多方意愿：High - PrevClose (正值)
      double sumLow  = 0.0;  // 空方意愿：PrevClose - Low (正值)

      for(int j = 0; j < InpBRPeriod; j++)
      {
         int shift = i + j;
         double prevClose = iClose(_Symbol, _Period, shift + 1); // 前收盘
         double high      = iHigh(_Symbol, _Period, shift);
         double low       = iLow(_Symbol, _Period, shift);

         // 多方意愿：今日最高价超过昨日收盘价
         sumHigh += MathMax(high - prevClose, 0.0);
         // 空方意愿：昨日收盘价高于今日最低价
         sumLow  += MathMax(prevClose - low, 0.0);
      }

      brBuffer[i] = SafeDivide(100.0 * sumHigh, sumLow, 100.0);

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // --- 第2步：信号判断（bar[1]+确认）---
   for(int i = limit; i >= 1; i--)
   {
      // 从极度超卖区回升 → 买入
      if(brBuffer[i + 1] <= 40.0 && brBuffer[i] > 40.0)
         buySignal[i] = 30.0;

      // 进入安全买入区域
      if(brBuffer[i + 1] <= 40.0 && brBuffer[i] > 40.0 && brBuffer[i] < 70.0)
         buySignal[i] = 25.0;

      // 从极度超买区回落 → 卖出
      if(brBuffer[i + 1] >= 300.0 && brBuffer[i] < 300.0)
         sellSignal[i] = 310.0;

      // 从强势区跌破150
      if(brBuffer[i + 1] >= 150.0 && brBuffer[i] < 150.0)
         sellSignal[i] = 160.0;
   }

   // --- 第3步：刷新 bar[0] ---
   if(Bars > 0)
   {
      double sH = 0.0, sL = 0.0;
      for(int j = 0; j < InpBRPeriod; j++)
      {
         double pc = iClose(_Symbol, _Period, j + 1);
         double h  = iHigh(_Symbol, _Period, j);
         double l  = iLow(_Symbol, _Period, j);
         sH += MathMax(h - pc, 0.0);
         sL += MathMax(pc - l, 0.0);
      }
      brBuffer[0] = SafeDivide(100.0 * sH, sL, 100.0);
      buySignal[0]  = EMPTY_VALUE;
      sellSignal[0] = EMPTY_VALUE;
   }

   return(0);
}
//+------------------------------------------------------------------+
