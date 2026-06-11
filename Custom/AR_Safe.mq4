//+------------------------------------------------------------------+
//|                                                    AR_Safe.mq4    |
//|  人气指标（AR）— 不含未来函数                                     |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  AR = 100 * Σ(High - Open, N) / Σ(Open - Low, N)                  |
//|  反映开盘价之后多空双方的力量对比                                   |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：AR从60下方回升突破确认(bar[1])                            |
//|  - 卖出：AR从120上方回落跌破确认(bar[1])                           |
//|  - AR在80-120之间为盘整平衡区                                      |
//|  - AR>150 多方极度强势，AR<50 空方极度强势                         |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum 0
#property indicator_level1 120
#property indicator_level2 60

// 输入参数
input int   InpARPeriod = 26;           // AR周期
input color InpARColor  = clrDodgerBlue; // AR线颜色

// 指标缓冲区
double arBuffer[];      // AR主线
double buySignal[];     // 买入信号
double sellSignal[];    // 卖出信号

//+------------------------------------------------------------------+
//| 指标初始化                                                         |
//+------------------------------------------------------------------+
int init()
{
   // AR主线
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, InpARColor);
   SetIndexBuffer(0, arBuffer);
   SetIndexLabel(0, "AR");
   SetIndexEmptyValue(0, 0.0);

   // 买入信号箭头
   SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(1, buySignal);
   SetIndexArrow(1, ARROW_BUY);
   SetIndexLabel(1, "Buy Signal");
   SetIndexEmptyValue(1, EMPTY_VALUE);

   // 卖出信号箭头
   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(2, sellSignal);
   SetIndexArrow(2, ARROW_SELL);
   SetIndexLabel(2, "Sell Signal");
   SetIndexEmptyValue(2, EMPTY_VALUE);

   IndicatorDigits(2);
   IndicatorShortName("AR_Safe(" + IntegerToString(InpARPeriod) + ")");

   return(0);
}

//+------------------------------------------------------------------+
//| 指标清理                                                           |
//+------------------------------------------------------------------+
int deinit()
{
   return(0);
}

//+------------------------------------------------------------------+
//| 指标计算                                                           |
//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;

   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - InpARPeriod * 2;
   if(limit < 0) limit = 0;

   // --- 第1步：计算历史AR值（bar[limit] 到 bar[1]）---
   for(int i = limit; i >= 1; i--)
   {
      double sumHigh = 0.0;  // 多方力量：High - Open (正值)
      double sumLow  = 0.0;  // 空方力量：Open - Low (正值)

      for(int j = 0; j < InpARPeriod; j++)
      {
         double open = iOpen(_Symbol, _Period, i + j);
         double high = iHigh(_Symbol, _Period, i + j);
         double low  = iLow(_Symbol, _Period, i + j);

         // 多方力量：最高价超过开盘价的部分
         sumHigh += MathMax(high - open, 0.0);
         // 空方力量：开盘价超过最低价的部分
         sumLow  += MathMax(open - low, 0.0);
      }

      // AR = 100 * 多方力量 / 空方力量
      arBuffer[i] = SafeDivide(100.0 * sumHigh, sumLow, 100.0);

      // 信号初始化
      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // --- 第2步：信号判断（仅 bar[1]+ 确认）---
   for(int i = limit; i >= 1; i--)
   {
      // 买入信号：AR从弱势区(<=60)回升，多方开始转强
      if(arBuffer[i + 1] <= 60.0 && arBuffer[i] > 60.0)
         buySignal[i] = 50.0;

      // 卖出信号：AR从强势区(>=120)回落，多方力量衰竭
      if(arBuffer[i + 1] >= 120.0 && arBuffer[i] < 120.0)
         sellSignal[i] = 130.0;

      // 极度超卖买入：AR<50后回升
      if(arBuffer[i + 1] <= 50.0 && arBuffer[i] > 50.0)
         buySignal[i] = 40.0;

      // 极度超买卖出：AR>150后回落
      if(arBuffer[i + 1] >= 150.0 && arBuffer[i] < 150.0)
         sellSignal[i] = 160.0;
   }

   // --- 第3步：刷新 bar[0]（仅显示，不生成信号）---
   if(Bars > 0)
   {
      double sumH0 = 0.0, sumL0 = 0.0;
      for(int j = 0; j < InpARPeriod; j++)
      {
         double o = iOpen(_Symbol, _Period, j);
         double h = iHigh(_Symbol, _Period, j);
         double l = iLow(_Symbol, _Period, j);
         sumH0 += MathMax(h - o, 0.0);
         sumL0 += MathMax(o - l, 0.0);
      }
      arBuffer[0] = SafeDivide(100.0 * sumH0, sumL0, 100.0);
      buySignal[0]  = EMPTY_VALUE;
      sellSignal[0] = EMPTY_VALUE;
   }

   return(0);
}
//+------------------------------------------------------------------+
