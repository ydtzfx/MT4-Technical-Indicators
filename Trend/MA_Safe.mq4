//+------------------------------------------------------------------+
//|                                                    MA_Safe.mq4   |
//|  多类型移动平均线（SMA / EMA / SMMA / LWMA）                       |
//|  不含未来函数：信号基于 bar[1]+ 确认K线                             |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  SMA  = Sum(Price, N) / N                                         |
//|  EMA  = Price * α + EMA_prev * (1-α),  α = 2/(N+1)               |
//|  SMMA = (Price + SMMA_prev * (N-1)) / N                           |
//|  LWMA = Σ(Price_i * weight_i) / Σ(weight_i), weight递增            |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：收盘价从下方向上穿越MA (bar[1]确认)                       |
//|  - 卖出：收盘价从上方向下穿越MA (bar[1]确认)                       |
//|  - bar[0]仅用于当前MA值实时显示，不参与信号判断                     |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 6

// 输入参数
input int                  InpMAPeriod    = 14;         // MA周期
input ENUM_MA_METHOD_SAFE InpMAMethod    = MA_EMA;     // MA类型
input ENUM_PRICE_SAFE      InpPriceType   = PRICE_CLOSE; // 价格类型
input int                  InpMA2Period   = 50;         // 辅助长周期MA(0=不显示)
input color                InpLineColor   = clrDodgerBlue; // MA线颜色
input int                  InpLineWidth   = 2;          // MA线宽度
input bool                 InpShowSignals = true;       // 显示买卖信号

// 指标缓冲区
double maBuffer[];           // MA值缓冲区
double ma2Buffer[];          // 长周期MA
double buySignal[];          // 买入信号缓冲区
double sellSignal[];         // 卖出信号缓冲区
double strongBuy[], strongSell[];  // 强信号（双MA确认）

//+------------------------------------------------------------------+
//| 指标初始化                                                         |
//+------------------------------------------------------------------+
int init()
{
   // 主MA线
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, InpLineWidth, InpLineColor);
   SetIndexBuffer(0, maBuffer);
   SetIndexLabel(0, "MA(" + IntegerToString(InpMAPeriod) + ")");
   SetIndexEmptyValue(0, 0.0);

   // 长周期MA（辅助线）
   SetIndexStyle(1, DRAW_LINE, STYLE_DOT, 1, clrGray);
   SetIndexBuffer(1, ma2Buffer);
   SetIndexLabel(1, "MA2(" + IntegerToString(InpMA2Period) + ")");
   SetIndexEmptyValue(1, 0.0);

   // 买入信号箭头
   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(2, buySignal);
   SetIndexLabel(2, "Buy Signal");
   SetIndexArrow(2, ARROW_BUY);
   SetIndexEmptyValue(2, EMPTY_VALUE);

   SetIndexStyle(3, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(3, sellSignal);
   SetIndexLabel(3, "Sell Signal");
   SetIndexArrow(3, ARROW_SELL);
   SetIndexEmptyValue(3, EMPTY_VALUE);

   SetIndexStyle(4, DRAW_ARROW, STYLE_SOLID, 4, clrCyan);
   SetIndexBuffer(4, strongBuy);
   SetIndexLabel(4, "Strong Buy");
   SetIndexArrow(4, 233);
   SetIndexEmptyValue(4, EMPTY_VALUE);

   SetIndexStyle(5, DRAW_ARROW, STYLE_SOLID, 4, clrDeepPink);
   SetIndexBuffer(5, strongSell);
   SetIndexLabel(5, "Strong Sell");
   SetIndexArrow(5, 234);
   SetIndexEmptyValue(5, EMPTY_VALUE);

   IndicatorDigits(4);
   IndicatorShortName("MA_Safe(" + IntegerToString(InpMAPeriod) + ")");

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

   // 首次加载或数据不足时，计算所有历史
   if(counted_bars < 0) counted_bars = 0;
   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - 2;
   if(limit < 0) limit = 0;

   // --- 第1步：计算历史MA值（bar[limit-1] 到 bar[1]）---
   for(int i = limit; i >= 1; i--)
   {
      // 收集价格数据
      double prices[];
      ArrayResize(prices, InpMAPeriod * 2);
      for(int j = 0; j < InpMAPeriod * 2; j++)
         prices[j] = GetPriceByType(i + j, InpPriceType);

      // 计算MA
      maBuffer[i] = CalculateMA(prices, InpMAPeriod, InpMAMethod, 0);

      // 信号判断：检测收盘价与MA的交叉（使用 bar[i] 和 bar[i+1] 的收盘价）
      if(InpShowSignals)
      {
         double closeCurr  = iClose(_Symbol, _Period, i);
         double closePrev  = iClose(_Symbol, _Period, i + 1);
         double maCurr     = maBuffer[i];
         double maPrev     = maBuffer[i + 1];

         buySignal[i]  = EMPTY_VALUE;
         sellSignal[i] = EMPTY_VALUE;
         strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;

         if(maPrev > 0 && maCurr > 0)
         {
            // 金叉：收盘价从下方上穿MA
            if(closePrev <= maPrev && closeCurr > maCurr)
            {
               buySignal[i] = iLow(_Symbol, _Period, i) - 5.0 * _Point;
               // 强信号：价格同时突破长周期MA且MA在长MA上方
               if(InpMA2Period > 0 && closeCurr > ma2Buffer[i] && maBuffer[i] > ma2Buffer[i])
                  strongBuy[i] = iLow(_Symbol, _Period, i) - 10.0 * _Point;
            }
            // 死叉：收盘价从上方下穿MA
            else if(closePrev >= maPrev && closeCurr < maCurr)
            {
               sellSignal[i] = iHigh(_Symbol, _Period, i) + 5.0 * _Point;
               if(InpMA2Period > 0 && closeCurr < ma2Buffer[i] && maBuffer[i] < ma2Buffer[i])
                  strongSell[i] = iHigh(_Symbol, _Period, i) + 10.0 * _Point;
            }
         }
      }
      // 计算长周期MA（如果启用）
      if(InpMA2Period > 0)
      {
         double prices2[];
         ArrayResize(prices2, InpMA2Period * 2);
         for(int j = 0; j < InpMA2Period * 2; j++)
            prices2[j] = GetPriceByType(i + j, InpPriceType);
         ma2Buffer[i] = CalculateMA(prices2, InpMA2Period, InpMAMethod, 0);
      }
   }

   // --- 第2步：刷新 bar[0]（仅显示，不生成信号）---
   if(Bars > 0)
   {
      double prices0[];
      ArrayResize(prices0, InpMAPeriod * 2);
      for(int j = 0; j < InpMAPeriod * 2; j++)
         prices0[j] = GetPriceByType(j, InpPriceType);
      maBuffer[0] = CalculateMA(prices0, InpMAPeriod, InpMAMethod, 0);
      ma2Buffer[0] = (InpMA2Period > 0) ? ma2Buffer[1] : 0;
      buySignal[0]  = EMPTY_VALUE;
      sellSignal[0] = EMPTY_VALUE;
      strongBuy[0]=EMPTY_VALUE;strongSell[0]=EMPTY_VALUE;
   }

   return(0);
}
//+------------------------------------------------------------------+
