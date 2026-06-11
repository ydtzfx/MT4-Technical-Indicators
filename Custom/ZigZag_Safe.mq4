//+------------------------------------------------------------------+
//|                                                 ZigZag_Safe.mq4   |
//|  之字转向指标 — 不含未来函数(确认后绘制)                            |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  当价格回撤超过设定百分比/点数时，确认一个转折点                    |
//|  连接相邻转折点形成之字线                                          |
//|                                                                   |
//|  防未来函数关键设计：                                              |
//|  ZigZag天然依赖未来数据（需要后续价格确认转折），                   |
//|  本版本采用延迟确认：转折点只有在其后N根bar确认后才绘制            |
//|  不在bar[0]上绘制任何线条，所有连接点都基于已完成的bar              |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 3

// 输入参数
input int    InpDepth     = 12;    // 回溯深度
input int    InpDeviation = 5;     // 偏离点数
input int    InpBackstep  = 3;     // 回退步数
input double InpMinPercent = 3.0;  // 最小转折百分比
input color  InpLineColor = clrYellow; // 线段颜色
input int    InpLineWidth = 2;     // 线段宽度

// 指标缓冲区
double zigzagBuffer[];    // ZigZag价格位置
double highPoints[];      // 高点标记
double lowPoints[];       // 低点标记

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_SECTION, STYLE_SOLID, InpLineWidth, InpLineColor);
   SetIndexBuffer(0, zigzagBuffer);
   SetIndexLabel(0, "ZigZag");
   SetIndexEmptyValue(0, 0.0);

   SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, 1, clrTomato);
   SetIndexBuffer(1, highPoints);
   SetIndexArrow(1, ARROW_SELL);
   SetIndexEmptyValue(1, EMPTY_VALUE);

   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 1, clrLimeGreen);
   SetIndexBuffer(2, lowPoints);
   SetIndexArrow(2, ARROW_BUY);
   SetIndexEmptyValue(2, EMPTY_VALUE);

   IndicatorDigits(4);
   IndicatorShortName("ZigZag_Safe");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;
   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - InpDepth * 4;
   if(limit < 0) limit = 0;

   // 初始化
   for(int i = limit; i >= 0; i--)
   {
      zigzagBuffer[i] = 0.0;
      highPoints[i] = EMPTY_VALUE;
      lowPoints[i]  = EMPTY_VALUE;
   }

   // ZigZag检测：寻找高点和低点
   // delayBars 根bar之后才确认转折点
   int delayBars = InpBackstep + 1;

   for(int i = limit; i >= InpDepth + delayBars; i--)
   {
      // 寻找 i+delayBars 处的极值（已确认的bar）
      int confirmedIdx = i + delayBars;

      // 检测是否是高点
      bool isHigh = true;
      double highVal = iHigh(_Symbol, _Period, confirmedIdx);

      for(int j = 1; j <= InpDepth; j++)
      {
         // 检查左右各Depth根bar
         if(confirmedIdx + j < Bars && iHigh(_Symbol, _Period, confirmedIdx + j) >= highVal)
            isHigh = false;
         if(confirmedIdx - j >= 0 && iHigh(_Symbol, _Period, confirmedIdx - j) >= highVal)
            isHigh = false;
      }

      if(isHigh)
      {
         // 检查偏离度
         double prevLow = 0;
         for(int j = confirmedIdx + 1; j < confirmedIdx + InpDepth; j++)
         {
            if(lowPoints[j] != EMPTY_VALUE)
            {
               prevLow = lowPoints[j];
               break;
            }
         }

         if(prevLow == 0 || (highVal - prevLow) / prevLow * 100.0 >= InpMinPercent)
         {
            highPoints[confirmedIdx] = highVal + InpDeviation * _Point;
            zigzagBuffer[confirmedIdx] = highVal;
         }
      }

      // 检测是否是低点
      bool isLow = true;
      double lowVal = iLow(_Symbol, _Period, confirmedIdx);

      for(int j = 1; j <= InpDepth; j++)
      {
         if(confirmedIdx + j < Bars && iLow(_Symbol, _Period, confirmedIdx + j) <= lowVal)
            isLow = false;
         if(confirmedIdx - j >= 0 && iLow(_Symbol, _Period, confirmedIdx - j) <= lowVal)
            isLow = false;
      }

      if(isLow)
      {
         double prevHigh = 999999;
         for(int j = confirmedIdx + 1; j < confirmedIdx + InpDepth; j++)
         {
            if(highPoints[j] != EMPTY_VALUE)
            {
               prevHigh = highPoints[j];
               break;
            }
         }

         if(prevHigh == 999999 || (prevHigh - lowVal) / prevHigh * 100.0 >= InpMinPercent)
         {
            lowPoints[confirmedIdx] = lowVal - InpDeviation * _Point;
            zigzagBuffer[confirmedIdx] = lowVal;
         }
      }
   }

   // 不在 bar[0] 和 bar[1] 上绘制（未确认）
   zigzagBuffer[0] = 0.0;
   zigzagBuffer[1] = 0.0;

   return(0);
}
//+------------------------------------------------------------------+
