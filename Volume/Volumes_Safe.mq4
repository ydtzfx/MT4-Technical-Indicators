#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                                Volumes_Safe.mq4   |
//|  彩色成交量指标 — 不含未来函数                                    |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  将成交量按K线阴阳分别着色                                        |
//|  阳线（Close ≥ Open）= 绿色多方量                                 |
//|  阴线（Close < Open）= 红色空方量                                 |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 黄色圆点：巨量预警（当前成交量 > N倍均量）                     |
//|  - 巨量+阳线 = 可能突破向上                                       |
//|  - 巨量+阴线 = 可能破位向下                                       |
//|  - 缩量+阳线 = 温和上涨                                           |
//|  - 缩量+阴线 = 温和回调                                           |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3

input color  InpUpColor   = clrLimeGreen;   // 多方量颜色
input color  InpDownColor = clrTomato;      // 空方量颜色
input double InpVolRatio  = 3.0;            // 巨量倍数（相对于20日均量）
input int    InpMAPeriod  = 20;             // 均量计算周期

// 指标缓冲区
double volUpBuffer[];       // 多方量（绿柱）
double volDownBuffer[];     // 空方量（红柱）
double alertBuffer[];       // 巨量预警（黄点）

//+------------------------------------------------------------------+
int init()
{
   // 多方量柱
   SetIndexStyle(0, DRAW_HISTOGRAM, STYLE_SOLID, 3, InpUpColor);
   SetIndexBuffer(0, volUpBuffer);
   SetIndexLabel(0, "Volume Up (Bull)");
   SetIndexEmptyValue(0, 0);

   // 空方量柱
   SetIndexStyle(1, DRAW_HISTOGRAM, STYLE_SOLID, 3, InpDownColor);
   SetIndexBuffer(1, volDownBuffer);
   SetIndexLabel(1, "Volume Down (Bear)");
   SetIndexEmptyValue(1, 0);

   // 巨量预警点
   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 2, clrYellow);
   SetIndexBuffer(2, alertBuffer);
   SetIndexArrow(2, ARROW_DOT);
   SetIndexLabel(2, "Volume Spike Alert");
   SetIndexEmptyValue(2, EMPTY_VALUE);

   IndicatorDigits(0);
   IndicatorShortName("Volumes_Safe");
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
   if(limit > Bars - 2) limit = Bars - InpMAPeriod - 2;
   if(limit < 0) limit = 0;

   // --- 第1步：计算均量基准 ---
   long avgVolume = 0;
   int avgCount  = 0;
   for(int i = limit + InpMAPeriod; i >= limit; i--)
   {
      if(i < Bars)
      {
         avgVolume += iVolume(_Symbol, _Period, i);
         avgCount++;
      }
   }
   if(avgCount > 0) avgVolume /= avgCount;
   if(avgVolume < 1) avgVolume = 1;

   // --- 第2步：分色显示 + 巨量预警 ---
   for(i = limit; i >= 1; i--)
   {
      long   volume    = iVolume(_Symbol, _Period, i);
      double closeCurr = iClose(_Symbol, _Period, i);
      double openCurr  = iOpen(_Symbol, _Period, i);

      // 阳线（收盘 ≥ 开盘）→ 绿色多方量
      if(closeCurr >= openCurr)
      {
         volUpBuffer[i]   = (double)volume;
         volDownBuffer[i] = 0.0;
      }
      // 阴线（收盘 < 开盘）→ 红色空方量
      else
      {
         volDownBuffer[i] = (double)volume;
         volUpBuffer[i]   = 0.0;
      }

      // 巨量预警：当前量 > N倍均量
      if((double)volume > (double)avgVolume * InpVolRatio)
         alertBuffer[i] = (double)volume;
      else
         alertBuffer[i] = EMPTY_VALUE;
   }

   // --- 第3步：刷新 bar[0] ---
   if(Bars > 0)
   {
      // bar[0]不生成预警（当天未完成）
      volUpBuffer[0]   = 0.0;
      volDownBuffer[0] = 0.0;
      alertBuffer[0]   = EMPTY_VALUE;
   }

   return(0);
}
//+------------------------------------------------------------------+
