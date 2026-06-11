//+------------------------------------------------------------------+
//|                                             Fractals_Safe.mq4     |
//|  分形指标 — 不含未来函数                                          |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  上分形（卖出信号）：中间bar最高价 > 左右各N根bar的最高价           |
//|  下分形（买入信号）：中间bar最低价 < 左右各N根bar的最低价           |
//|                                                                   |
//|  防未来函数关键处理：                                              |
//|  分形确认需要等待右侧N根bar全部完成 → 信号延迟N根bar               |
//|  本指标严格要求右侧bar全部为历史bar（shift >= N），不提前预判       |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2

// 输入参数
input int   InpFractalBars = 2;   // 左右各N根bar（标准为2）
input color InpUpFractalColor   = clrLimeGreen;   // 上分形颜色
input color InpDownFractalColor = clrTomato;      // 下分形颜色

// 指标缓冲区
double upFractalBuffer[];    // 上分形（卖出信号位置）
double downFractalBuffer[];  // 下分形（买入信号位置）

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_ARROW, STYLE_SOLID, 2, InpDownFractalColor);
   SetIndexBuffer(0, downFractalBuffer);
   SetIndexLabel(0, "Down Fractal (Buy)");
   SetIndexArrow(0, ARROW_BUY);
   SetIndexEmptyValue(0, EMPTY_VALUE);

   SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, 2, InpUpFractalColor);
   SetIndexBuffer(1, upFractalBuffer);
   SetIndexLabel(1, "Up Fractal (Sell)");
   SetIndexArrow(1, ARROW_SELL);
   SetIndexEmptyValue(1, EMPTY_VALUE);

   IndicatorDigits(4);
   IndicatorShortName("Fractals_Safe");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;
   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - InpFractalBars * 3;
   if(limit < 0) limit = 0;

   // 初始化
   for(int i = limit; i >= 0; i--)
   {
      upFractalBuffer[i]   = EMPTY_VALUE;
      downFractalBuffer[i] = EMPTY_VALUE;
   }

   // 分形检测 — 中间bar必须有N根确认bar在其右侧（历史方向）
   // i 是中间bar的索引，右侧有 InpFractalBars 根更近期的bar
   // 要求：i >= InpFractalBars（右侧bar已完成）
   for(int i = limit; i >= InpFractalBars; i--)
   {
      double middleHigh = iHigh(_Symbol, _Period, i);
      double middleLow  = iLow(_Symbol, _Period, i);

      bool isUpFractal   = true;  // 上分形 = 最高点 = 潜在卖出
      bool isDownFractal = true;  // 下分形 = 最低点 = 潜在买入

      // 检查左右各N根bar
      for(int j = 1; j <= InpFractalBars; j++)
      {
         // 左侧（更早的bar）
         if(iHigh(_Symbol, _Period, i + j) >= middleHigh)
            isUpFractal = false;
         if(iLow(_Symbol, _Period, i + j) <= middleLow)
            isDownFractal = false;

         // 右侧（更近期的bar，需确认已完成）
         if(iHigh(_Symbol, _Period, i - j) >= middleHigh)
            isUpFractal = false;
         if(iLow(_Symbol, _Period, i - j) <= middleLow)
            isDownFractal = false;
      }

      // 严格模式：只检查严格大于/小于，不允许相等
      for(int j = 1; j <= InpFractalBars; j++)
      {
         if(iHigh(_Symbol, _Period, i + j) == middleHigh)
            isUpFractal = false;
         if(iLow(_Symbol, _Period, i + j) == middleLow)
            isDownFractal = false;
         if(iHigh(_Symbol, _Period, i - j) == middleHigh)
            isUpFractal = false;
         if(iLow(_Symbol, _Period, i - j) == middleLow)
            isDownFractal = false;
      }

      if(isUpFractal)
         upFractalBuffer[i] = middleHigh + 5.0 * _Point;

      if(isDownFractal)
         downFractalBuffer[i] = middleLow - 5.0 * _Point;
   }

   // bar[0] 永远不产生分形信号（右侧无确认bar）
   upFractalBuffer[0]   = EMPTY_VALUE;
   downFractalBuffer[0] = EMPTY_VALUE;

   return(0);
}
//+------------------------------------------------------------------+
