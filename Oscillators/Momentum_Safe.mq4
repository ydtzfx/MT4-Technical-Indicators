//+------------------------------------------------------------------+
//|                                              Momentum_Safe.mq4    |
//|  动量指标 — 不含未来函数                                          |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  Momentum = Price[i] - Price[i + N]  (差值形式)                   |
//|  或        = 100 * Price[i] / Price[i + N]  (比率形式)            |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：Momentum从零轴下方上穿确认(bar[1])                       |
//|  - 卖出：Momentum从零轴上方下穿确认(bar[1])                       |
//|  - 100线穿越（比率模式）：上穿=多头，下穿=空头                    |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_level1 100

// 输入参数
input int InpMomPeriod = 14;   // 动量周期
input ENUM_PRICE_SAFE InpPriceType = PRICE_CLOSE; // 价格类型
input bool InpUseRatio = false;  // false=差值, true=比率*100

// 指标缓冲区
double momBuffer[];
double buySignal[];
double sellSignal[];
double strongBuy[];
double strongSell[];

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, clrDodgerBlue);
   SetIndexBuffer(0, momBuffer);
   SetIndexLabel(0, "Momentum");

   SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(1, buySignal);
   SetIndexArrow(1, ARROW_BUY);
   SetIndexEmptyValue(1, EMPTY_VALUE);

   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(2, sellSignal);
   SetIndexArrow(2, ARROW_SELL);
   SetIndexEmptyValue(2, EMPTY_VALUE);

   SetIndexStyle(3, DRAW_ARROW, STYLE_SOLID, 4, clrCyan);
   SetIndexBuffer(3, strongBuy);
   SetIndexArrow(3, ARROW_BUY);
   SetIndexLabel(3, "Strong Buy");
   SetIndexEmptyValue(3, EMPTY_VALUE);

   SetIndexStyle(4, DRAW_ARROW, STYLE_SOLID, 4, clrDeepPink);
   SetIndexBuffer(4, strongSell);
   SetIndexArrow(4, ARROW_SELL);
   SetIndexLabel(4, "Strong Sell");
   SetIndexEmptyValue(4, EMPTY_VALUE);

   IndicatorDigits(4);
   IndicatorShortName("Mom_Safe(" + IntegerToString(InpMomPeriod) + ")");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;
   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - InpMomPeriod * 2;
   if(limit < 0) limit = 0;

   for(int i = limit; i >= 0; i--)
   {
      double currPrice = GetPriceByType(i, InpPriceType);
      double prevPrice = GetPriceByType(i + InpMomPeriod, InpPriceType);

      if(prevPrice != 0 && InpUseRatio)
         momBuffer[i] = 100.0 * currPrice / prevPrice;
      else
         momBuffer[i] = currPrice - prevPrice;

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // 信号（bar[1]+确认）— 增强分级
   for(int i = limit; i >= 1; i--)
   {
      if(InpUseRatio)
      {
         bool momRising = (momBuffer[i] > momBuffer[i+1]);
         // 强买：深度穿越(>105) + 加速
         if(momBuffer[i+1] <= 100 && momBuffer[i] > 105) strongBuy[i] = momBuffer[i] - 0.2;
         else if(momBuffer[i+1] <= 100 && momBuffer[i] > 100) buySignal[i] = momBuffer[i] - 0.1;
         // 强卖：深度跌破(<95) + 加速
         if(momBuffer[i+1] >= 100 && momBuffer[i] < 95) strongSell[i] = momBuffer[i] + 0.2;
         else if(momBuffer[i+1] >= 100 && momBuffer[i] < 100) sellSignal[i] = momBuffer[i] + 0.1;
      }
      else
      {
         // 差值模式：0线穿越
         if(momBuffer[i+1] <= 0 && momBuffer[i] > 0)
         {
            if(momBuffer[i] > momBuffer[i+1] * 1.5) strongBuy[i] = momBuffer[i] - 0.0002;
            else buySignal[i] = momBuffer[i] - 0.0001;
         }
         if(momBuffer[i+1] >= 0 && momBuffer[i] < 0)
         {
            if(momBuffer[i] < momBuffer[i+1] * 1.5) strongSell[i] = momBuffer[i] + 0.0002;
            else sellSignal[i] = momBuffer[i] + 0.0001;
         }
      }
   }

   return(0);
}
//+------------------------------------------------------------------+
