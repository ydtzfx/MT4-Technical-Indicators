//+------------------------------------------------------------------+
//|                                                 StdDev_Safe.mq4   |
//|  标准差指标（Standard Deviation）— 不含未来函数                   |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  SMA = ΣPrice / N                                                  |
//|  StdDev = sqrt( Σ(Price_i - SMA)² / N )                            |
//|  衡量价格围绕均值的离散程度（波动性）                               |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 波动率突增（>2倍均波动率）+ 方向 = 突破方向确认(bar[1])       |
//|  - StdDev持续走低 → 盘整，即将变盘                                |
//|  - 不产生直接买卖信号，用作波动率预警                              |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3

input int    InpStdDevPeriod = 20;      // 标准差周期
input ENUM_PRICE_SAFE InpPriceType = PRICE_CLOSE; // 价格类型
input double InpVolThreshold = 2.0;     // 波动率爆发倍数

// 指标缓冲区
double sdBuffer[];      // 标准差主线
double buySignal[];     // 波动率突破+上涨=买入
double sellSignal[];    // 波动率突破+下跌=卖出

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, clrDodgerBlue);
   SetIndexBuffer(0, sdBuffer);
   SetIndexLabel(0, "StdDev(" + IntegerToString(InpStdDevPeriod) + ")");
   SetIndexEmptyValue(0, 0.0);

   SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(1, buySignal);
   SetIndexArrow(1, ARROW_BUY);
   SetIndexLabel(1, "Vol Breakout Up");
   SetIndexEmptyValue(1, EMPTY_VALUE);

   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(2, sellSignal);
   SetIndexArrow(2, ARROW_SELL);
   SetIndexLabel(2, "Vol Breakout Down");
   SetIndexEmptyValue(2, EMPTY_VALUE);

   IndicatorDigits(4);
   IndicatorShortName("StdDev_Safe(" + IntegerToString(InpStdDevPeriod) + ")");
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
   if(limit > Bars - 2) limit = Bars - InpStdDevPeriod * 2;
   if(limit < 0) limit = 0;

   // --- 第1步：计算标准差 ---
   for(int i = limit; i >= 1; i--)
   {
      // 计算SMA
      double sum = 0.0;
      for(int j = 0; j < InpStdDevPeriod; j++)
         sum += GetPriceByType(i + j, InpPriceType);
      double sma = sum / InpStdDevPeriod;

      // 计算方差和标准差
      double sumSqDiff = 0.0;
      for(int j = 0; j < InpStdDevPeriod; j++)
      {
         double diff = GetPriceByType(i + j, InpPriceType) - sma;
         sumSqDiff += diff * diff;
      }
      sdBuffer[i] = MathSqrt(sumSqDiff / InpStdDevPeriod);

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // --- 第2步：波动率爆发检测（需要足够的bar来计算均波动率）---
   for(int i = limit; i >= 20; i--)
   {
      // 计算近20根bar的平均标准差
      double avgStdDev = 0.0;
      for(int j = 0; j < 20; j++)
         avgStdDev += sdBuffer[i + j];
      avgStdDev /= 20.0;

      // 当前波动率 > 阈值 * 平均波动率 → 波动率爆发
      if(sdBuffer[i] > avgStdDev * InpVolThreshold)
      {
         double closeCurr = iClose(_Symbol, _Period, i);
         double closePrev = iClose(_Symbol, _Period, i + 1);

         // 波动率放大 + 价格上涨 → 突破买入
         if(closeCurr > closePrev)
            buySignal[i] = sdBuffer[i] * 0.8;
         // 波动率放大 + 价格下跌 → 突破卖出
         else
            sellSignal[i] = sdBuffer[i] * 1.2;
      }
   }

   // --- 第3步：刷新 bar[0] ---
   if(Bars > 0)
   {
      double s0 = 0.0;
      for(int j = 0; j < InpStdDevPeriod; j++)
         s0 += GetPriceByType(j, InpPriceType);
      double sma0 = s0 / InpStdDevPeriod;
      double ss0 = 0.0;
      for(int j = 0; j < InpStdDevPeriod; j++)
      {
         double d = GetPriceByType(j, InpPriceType) - sma0;
         ss0 += d * d;
      }
      sdBuffer[0] = MathSqrt(ss0 / InpStdDevPeriod);
      buySignal[0]  = EMPTY_VALUE;
      sellSignal[0] = EMPTY_VALUE;
   }

   return(0);
}
//+------------------------------------------------------------------+
