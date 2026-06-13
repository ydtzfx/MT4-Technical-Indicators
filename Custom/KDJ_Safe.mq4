//+------------------------------------------------------------------+
//|                                                    KDJ_Safe.mq4   |
//|  KDJ随机指标 — 不含未来函数                                       |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  RSV = 100 * (Close - Lowest(N)) / (Highest(N) - Lowest(N))        |
//|  %K = 2/3 * PrevK + 1/3 * RSV (或SMA平滑)                         |
//|  %D = 2/3 * PrevD + 1/3 * %K                                      |
//|  %J = 3 * %K - 2 * %D                                              |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：%J从0以下回升，或%K上穿%D在20以下(bar[1]确认)            |
//|  - 卖出：%J从100以上回落，或%K下穿%D在80以上(bar[1]确认)          |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 7
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 80
#property indicator_level2 20

// 输入参数
input int InpKPeriod = 9;    // KDJ周期
input int InpSlowing = 3;    // 平滑次数

// 指标缓冲区
double kBuffer[];
double dBuffer[];
double jBuffer[];
double buySignal[];
double sellSignal[];
double strongBuy[];
double strongSell[];

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 1, clrDodgerBlue);
   SetIndexBuffer(0, kBuffer);
   SetIndexEmptyValue(0, EMPTY_VALUE);
   SetIndexLabel(0, "%K");

   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1, clrOrange);
   SetIndexBuffer(1, dBuffer);
   SetIndexEmptyValue(1, EMPTY_VALUE);
   SetIndexLabel(1, "%D");

   SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 1, clrMagenta);
   SetIndexBuffer(2, jBuffer);
   SetIndexEmptyValue(2, EMPTY_VALUE);
   SetIndexLabel(2, "%J");

   SetIndexStyle(3, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(3, buySignal);
   SetIndexArrow(3, ARROW_BUY);
   SetIndexEmptyValue(3, EMPTY_VALUE);

   SetIndexStyle(4, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(4, sellSignal);
   SetIndexArrow(4, ARROW_SELL);
   SetIndexEmptyValue(4, EMPTY_VALUE);

   SetIndexStyle(5, DRAW_ARROW, STYLE_SOLID, 4, clrCyan);
   SetIndexBuffer(5, strongBuy);
   SetIndexArrow(5, ARROW_BUY);
   SetIndexLabel(5, "Strong Buy");
   SetIndexEmptyValue(5, EMPTY_VALUE);

   SetIndexStyle(6, DRAW_ARROW, STYLE_SOLID, 4, clrDeepPink);
   SetIndexBuffer(6, strongSell);
   SetIndexArrow(6, ARROW_SELL);
   SetIndexLabel(6, "Strong Sell");
   SetIndexEmptyValue(6, EMPTY_VALUE);

   IndicatorDigits(2);
   IndicatorShortName("KDJ_Safe(" + IntegerToString(InpKPeriod) + ")");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;
   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - InpKPeriod * 3;
   if(limit < 0) limit = 0;

   // 计算RSV
   double rsv[];
   ArrayResize(rsv, Bars);
   ArrayInitialize(rsv, 50.0);

   for(int i = limit; i >= 0; i--)
   {
      double highest = iHigh(_Symbol, _Period, i);
      double lowest  = iLow(_Symbol, _Period, i);

      for(int j = i; j < i + InpKPeriod; j++)
      {
         double h = iHigh(_Symbol, _Period, j);
         double l = iLow(_Symbol, _Period, j);
         if(h > highest) highest = h;
         if(l < lowest)  lowest  = l;
      }

      double close = iClose(_Symbol, _Period, i);
      double range = highest - lowest;
      if(MathAbs(range) < 0.00000001)
         rsv[i] = 50.0;
      else
         rsv[i] = 100.0 * (close - lowest) / range;
   }

   // KDJ递推（使用EMA平滑）
   for(int i = limit; i >= 0; i--)
   {
      double alpha = 1.0 / InpSlowing;

      // %K = (1-α) * PrevK + α * RSV
      if(i >= Bars - 2)
      {
         kBuffer[i] = rsv[i];  // 初始值
         dBuffer[i] = kBuffer[i];
      }
      else
      {
         // 从历史往当前递推
         kBuffer[i] = rsv[i] * alpha + kBuffer[i + 1] * (1.0 - alpha);
         dBuffer[i] = kBuffer[i] * alpha + dBuffer[i + 1] * (1.0 - alpha);
      }

      jBuffer[i] = 3.0 * kBuffer[i] - 2.0 * dBuffer[i];

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // 信号（bar[1]+确认）— 增强分级
   for(int i = limit; i >= 1; i--)
   {
      bool jCrossUp0   = (jBuffer[i+1] <= 0 && jBuffer[i] > 0);
      bool jCrossDn100 = (jBuffer[i+1] >= 100 && jBuffer[i] < 100);
      bool kCrossUpD   = (kBuffer[i+1] <= dBuffer[i+1] && kBuffer[i] > dBuffer[i]);
      bool kCrossDnD   = (kBuffer[i+1] >= dBuffer[i+1] && kBuffer[i] < dBuffer[i]);
      bool deepOS = (kBuffer[i] < 10);
      bool deepOB = (kBuffer[i] > 90);
      bool jAccelUp  = (jBuffer[i] > jBuffer[i+1] + 5);   // J加速上升
      bool jAccelDn  = (jBuffer[i] < jBuffer[i+1] - 5);   // J加速下降

      // 强买：J深跌反弹 + K金叉D + 超卖区
      if(jCrossUp0 && kCrossUpD && deepOS) strongBuy[i] = 2.0;
      // 普通买：J反弹或K金叉D
      else if(jCrossUp0 || (kCrossUpD && kBuffer[i] < 20)) buySignal[i] = 5.0;

      // 强卖：J深涨回落 + K死叉D + 超买区
      if(jCrossDn100 && kCrossDnD && deepOB) strongSell[i] = 98.0;
      // 普通卖：J回落或K死叉D
      else if(jCrossDn100 || (kCrossDnD && kBuffer[i] > 80)) sellSignal[i] = 95.0;
   }

   return(0);
}
//+------------------------------------------------------------------+
