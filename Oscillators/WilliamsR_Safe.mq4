//+------------------------------------------------------------------+
//|                                              WilliamsR_Safe.mq4   |
//|  威廉指标 — 不含未来函数                                          |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  %R = -100 * (Highest(N) - Close) / (Highest(N) - Lowest(N))      |
//|  取值范围 [-100, 0]，-20以上为超买，-80以下为超卖                  |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：%R从-80下方回升突破确认(bar[1])                          |
//|  - 卖出：%R从-20上方回落跌破确认(bar[1])                          |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_minimum -100
#property indicator_maximum 0
#property indicator_level1 -20
#property indicator_level2 -80

// 输入参数
input int InpWPRPeriod = 14;   // Williams %R周期
input color InpWPRColor = clrDodgerBlue;

// 指标缓冲区
double wprBuffer[];
double buySignal[];
double sellSignal[];
double strongBuy[];
double strongSell[];

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, InpWPRColor);
   SetIndexBuffer(0, wprBuffer);
   SetIndexLabel(0, "Williams %R");

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

   IndicatorDigits(2);
   IndicatorShortName("WPR_Safe(" + IntegerToString(InpWPRPeriod) + ")");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;
   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - InpWPRPeriod * 2;
   if(limit < 0) limit = 0;

   for(int i = limit; i >= 0; i--)
   {
      double highest = iHigh(_Symbol, _Period, i);
      double lowest  = iLow(_Symbol, _Period, i);
      for(int j = i; j < i + InpWPRPeriod; j++)
      {
         double h = iHigh(_Symbol, _Period, j);
         double l = iLow(_Symbol, _Period, j);
         if(h > highest) highest = h;
         if(l < lowest)  lowest  = l;
      }

      double close  = iClose(_Symbol, _Period, i);
      double range  = highest - lowest;
      if(MathAbs(range) < 0.00000001)
         wprBuffer[i] = -50.0;
      else
         wprBuffer[i] = -100.0 * (highest - close) / range;

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // 信号（bar[1]+确认）— 增强分级
   for(int i = limit; i >= 1; i--)
   {
      bool exitDeepOS = (wprBuffer[i+1] <= -95 && wprBuffer[i] > -95);
      bool exitOS     = (wprBuffer[i+1] <= -80 && wprBuffer[i] > -80);
      bool exitOB     = (wprBuffer[i+1] >= -20 && wprBuffer[i] < -20);
      bool exitDeepOB = (wprBuffer[i+1] >= -5  && wprBuffer[i] < -5);
      bool wprRising  = (wprBuffer[i] > wprBuffer[i+1]);
      bool wprFalling = (wprBuffer[i] < wprBuffer[i+1]);

      // 强买：深度超卖(<-95)回升 + 加速
      if(exitDeepOS && wprRising) strongBuy[i] = -90.0;
      // 普通买：超卖(<-80)回升
      else if(exitOS && wprRising) buySignal[i] = -85.0;

      // 强卖：深度超买(>-5)回落 + 加速
      if(exitDeepOB && wprFalling) strongSell[i] = -10.0;
      // 普通卖：超买(>-20)回落
      else if(exitOB && wprFalling) sellSignal[i] = -15.0;
   }

   return(0);
}
//+------------------------------------------------------------------+
