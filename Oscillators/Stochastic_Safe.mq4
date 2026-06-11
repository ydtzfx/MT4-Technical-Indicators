//+------------------------------------------------------------------+
//|                                            Stochastic_Safe.mq4    |
//|  随机指标（KD）— 不含未来函数                                     |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  %K = 100 * (Close - Lowest(N)) / (Highest(N) - Lowest(N))        |
//|  %D = SMA(%K, M)                                                   |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：%K从超卖区(<=20)上穿%D确认(bar[1])，或%K离开超卖区      |
//|  - 卖出：%K从超买区(>=80)下穿%D确认(bar[1])，或%K离开超买区      |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 80
#property indicator_level2 20

// 输入参数
input int InpKPeriod     = 5;   // %K周期
input int InpDPeriod     = 3;   // %D周期
input int InpSlowing     = 3;   // 平滑周期
input ENUM_MA_METHOD_SAFE InpMAMethod = MA_SMA; // %D平滑方式
input double InpOverbought = 80.0;
input double InpOversold   = 20.0;

// 指标缓冲区
double kBuffer[];
double dBuffer[];
double buySignal[];
double sellSignal[];

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 1, clrDodgerBlue);
   SetIndexBuffer(0, kBuffer);
   SetIndexLabel(0, "%K");

   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 2, clrRed);
   SetIndexBuffer(1, dBuffer);
   SetIndexLabel(1, "%D");

   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(2, buySignal);
   SetIndexArrow(2, ARROW_BUY);
   SetIndexEmptyValue(2, EMPTY_VALUE);

   SetIndexStyle(3, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(3, sellSignal);
   SetIndexArrow(3, ARROW_SELL);
   SetIndexEmptyValue(3, EMPTY_VALUE);

   IndicatorDigits(2);
   IndicatorShortName("Stoch_Safe(" + IntegerToString(InpKPeriod) + "," +
                      IntegerToString(InpDPeriod) + "," + IntegerToString(InpSlowing) + ")");
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

   // 计算原始%K
   double rawK[];
   ArrayResize(rawK, Bars);
   ArrayInitialize(rawK, 0.0);

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
      rawK[i] = (MathAbs(range) < 0.00000001) ? 50.0 : 100.0 * (close - lowest) / range;
   }

   // 平滑%K
   for(int i = limit; i >= 0; i--)
   {
      double sum = 0.0;
      for(int j = 0; j < InpSlowing; j++)
      {
         if(i + j < ArraySize(rawK))
            sum += rawK[i + j];
      }
      kBuffer[i] = sum / InpSlowing;
   }

   // 计算%D = MA of %K
   for(int i = limit; i >= 0; i--)
   {
      double kPrices[];
      ArrayResize(kPrices, InpDPeriod * 2);
      for(int j = 0; j < InpDPeriod * 2; j++)
         kPrices[j] = kBuffer[i + j];

      dBuffer[i] = CalculateMA(kPrices, InpDPeriod, InpMAMethod, 0);
      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // 信号判断（bar[1]+确认）
   for(int i = limit; i >= 1; i--)
   {
      // %K上穿%D 在超卖区
      if(kBuffer[i+1] <= dBuffer[i+1] && kBuffer[i] > dBuffer[i] &&
         kBuffer[i] < InpOversold)
         buySignal[i] = 5.0;

      // %K下穿%D 在超买区
      if(kBuffer[i+1] >= dBuffer[i+1] && kBuffer[i] < dBuffer[i] &&
         kBuffer[i] > InpOverbought)
         sellSignal[i] = 95.0;

      // 离开超卖区
      if(kBuffer[i+1] <= InpOversold && kBuffer[i] > InpOversold)
         buySignal[i] = 5.0;

      // 离开超买区
      if(kBuffer[i+1] >= InpOverbought && kBuffer[i] < InpOverbought)
         sellSignal[i] = 95.0;
   }

   return(0);
}
//+------------------------------------------------------------------+
