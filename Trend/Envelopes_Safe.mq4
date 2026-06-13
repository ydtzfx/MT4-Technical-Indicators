//+------------------------------------------------------------------+
//|                                              Envelopes_Safe.mq4   |
//|  包络线指标 — 不含未来函数                                        |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  Upper Envelope = MA(Price, N) * (1 + Deviation%/100)              |
//|  Lower Envelope = MA(Price, N) * (1 - Deviation%/100)              |
//|                                                                   |
//|  与布林带的区别：用固定百分比代替标准差，更简单直观                |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：价格从下轨下方回升突破（bar[1]确认）                      |
//|  - 卖出：价格从上轨上方回落突破（bar[1]确认）                      |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 6

// 输入参数
input int    InpMAPeriod    = 14;         // MA周期
input double InpDeviation   = 0.5;        // 偏离百分比(%)
input ENUM_MA_METHOD_SAFE InpMAMethod = MA_SMA; // MA类型
input ENUM_PRICE_SAFE InpPriceType = PRICE_CLOSE; // 价格类型
input color  InpUpperColor  = clrRoyalBlue;  // 上轨颜色
input color  InpLowerColor  = clrRoyalBlue;  // 下轨颜色

// 指标缓冲区
double upperBand[];
double lowerBand[];
double buySignal[];
double sellSignal[];
double strongBuy[];
double strongSell[];

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 1, InpUpperColor);
   SetIndexBuffer(0, upperBand);
   SetIndexEmptyValue(0, EMPTY_VALUE);
   SetIndexLabel(0, "Envelope Upper");

   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1, InpLowerColor);
   SetIndexBuffer(1, lowerBand);
   SetIndexEmptyValue(1, EMPTY_VALUE);
   SetIndexLabel(1, "Envelope Lower");

   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(2, buySignal);
   SetIndexArrow(2, ARROW_BUY);
   SetIndexEmptyValue(2, EMPTY_VALUE);

   SetIndexStyle(3, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(3, sellSignal);
   SetIndexArrow(3, ARROW_SELL);
   SetIndexEmptyValue(3, EMPTY_VALUE);

   SetIndexStyle(4, DRAW_ARROW, STYLE_SOLID, 4, clrCyan);
   SetIndexBuffer(4, strongBuy);
   SetIndexArrow(4, ARROW_BUY);
   SetIndexLabel(4, "Strong Buy");
   SetIndexEmptyValue(4, EMPTY_VALUE);

   SetIndexStyle(5, DRAW_ARROW, STYLE_SOLID, 4, clrDeepPink);
   SetIndexBuffer(5, strongSell);
   SetIndexArrow(5, ARROW_SELL);
   SetIndexLabel(5, "Strong Sell");
   SetIndexEmptyValue(5, EMPTY_VALUE);

   IndicatorDigits(4);
   IndicatorShortName("Envelopes_Safe(" + IntegerToString(InpMAPeriod) + ")");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;
   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - 2;
   if(limit < 0) limit = 0;

   double deviationFactor = InpDeviation / 100.0;

   for(int i = limit; i >= 0; i--)
   {
      // 计算MA
      double prices[];
      ArrayResize(prices, InpMAPeriod * 2);
      for(int j = 0; j < InpMAPeriod * 2; j++)
         prices[j] = GetPriceByType(i + j, InpPriceType);

      double ma = CalculateMA(prices, InpMAPeriod, InpMAMethod, 0);

      upperBand[i] = ma * (1.0 + deviationFactor);
      lowerBand[i] = ma * (1.0 - deviationFactor);

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
      strongBuy[i]  = EMPTY_VALUE;
      strongSell[i] = EMPTY_VALUE;
   }

   // 信号：bar[1]+ 确认 — 增强分级
   for(int i = limit; i >= 1; i--)
   {
      double close_i    = iClose(_Symbol, _Period, i);
      double close_i1   = iClose(_Symbol, _Period, i + 1);
      double bandWidth  = (upperBand[i] - lowerBand[i]) / _Point;

      // 强买：价格深度跌破下轨后强势回升
      if(close_i1 <= lowerBand[i+1] * 0.998 && close_i > lowerBand[i] && bandWidth > 100)
         strongBuy[i] = iLow(_Symbol, _Period, i) - 8.0 * _Point;
      // 普通买：价格从下轨下方回升
      else if(close_i1 <= lowerBand[i+1] && close_i > lowerBand[i])
         buySignal[i] = iLow(_Symbol, _Period, i) - 5.0 * _Point;

      // 强卖：价格深度突破上轨后急剧回落
      if(close_i1 >= upperBand[i+1] * 1.002 && close_i < upperBand[i] && bandWidth > 100)
         strongSell[i] = iHigh(_Symbol, _Period, i) + 8.0 * _Point;
      // 普通卖：价格从上轨上方回落
      else if(close_i1 >= upperBand[i+1] && close_i < upperBand[i])
         sellSignal[i] = iHigh(_Symbol, _Period, i) + 5.0 * _Point;
   }

   return(0);
}
//+------------------------------------------------------------------+
