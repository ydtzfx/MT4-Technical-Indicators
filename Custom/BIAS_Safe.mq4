#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                                   BIAS_Safe.mq4   |
//|  乖离率（BIAS）— 不含未来函数                                     |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  BIAS = 100 * (Close - MA) / MA                                    |
//|  衡量价格与其移动平均线的偏离程度（乖离）                           |
//|  正值表示价格高于均线，负值表示低于均线                             |
//|                                                                   |
//|  提供3条BIAS线（短/中/长周期），信号逻辑：                         |
//|  - 买入：短线BIAS上穿长线BIAS且均在负值区（超跌反弹, bar[1]确认）  |
//|  - 卖出：短线BIAS下穿长线BIAS且均在正值区（超涨回落, bar[1]确认）  |
//|  - 三线同时从负翻正 → 趋势转多确认                                |
//|  - 三线同时从正翻负 → 趋势转空确认                                |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 7

// 输入参数
input int    InpBIAS1 = 6;           // 短线BIAS周期
input int    InpBIAS2 = 12;          // 中线BIAS周期
input int    InpBIAS3 = 24;          // 长线BIAS周期
input ENUM_MA_METHOD_SAFE InpMAMethod = MA_SMA; // 均线类型
input color  InpColor1 = clrLimeGreen;  // 短线颜色
input color  InpColor2 = clrYellow;     // 中线颜色
input color  InpColor3 = clrMagenta;    // 长线颜色

// 指标缓冲区
double bias1Buffer[];   // 短线BIAS
double bias2Buffer[];   // 中线BIAS
double bias3Buffer[];   // 长线BIAS
double buySignal[];     // 买入信号
double sellSignal[];    // 卖出信号
double strongBuy[];     // 强买入信号
double strongSell[];    // 强卖出信号

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 1, InpColor1);
   SetIndexBuffer(0, bias1Buffer);
   SetIndexEmptyValue(0, 0.0);
   SetIndexLabel(0, "BIAS(" + IntegerToString(InpBIAS1) + ")");

   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1, InpColor2);
   SetIndexBuffer(1, bias2Buffer);
   SetIndexEmptyValue(1, 0.0);
   SetIndexLabel(1, "BIAS(" + IntegerToString(InpBIAS2) + ")");

   SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 1, InpColor3);
   SetIndexBuffer(2, bias3Buffer);
   SetIndexEmptyValue(2, 0.0);
   SetIndexLabel(2, "BIAS(" + IntegerToString(InpBIAS3) + ")");

   SetIndexStyle(3, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(3, buySignal);
   SetIndexArrow(3, ARROW_BUY);
   SetIndexLabel(3, "Buy Signal");
   SetIndexEmptyValue(3, EMPTY_VALUE);

   SetIndexStyle(4, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(4, sellSignal);
   SetIndexArrow(4, ARROW_SELL);
   SetIndexLabel(4, "Sell Signal");
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
   IndicatorShortName("BIAS_Safe(" + IntegerToString(InpBIAS1) + "," +
                      IntegerToString(InpBIAS2) + "," + IntegerToString(InpBIAS3) + ")");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;

   int limit = Bars - counted_bars;
   int maxPeriod = MathMax(InpBIAS1, MathMax(InpBIAS2, InpBIAS3));
   if(limit > Bars - 2) limit = Bars - maxPeriod * 3;
   if(limit < 0) limit = 0;

   // --- 第1步：计算三条BIAS线 ---
   for(int i = limit; i >= 1; i--)
   {
      // 准备价格数组
      double prices[];
      int needSize = maxPeriod * 3;
      ArrayResize(prices, needSize);
      for(int j = 0; j < needSize; j++)
         prices[j] = iClose(_Symbol, _Period, i + j);

      // 计算三条移动平均线
      double ma1 = CalculateMA(prices, InpBIAS1, InpMAMethod, 0);
      double ma2 = CalculateMA(prices, InpBIAS2, InpMAMethod, 0);
      double ma3 = CalculateMA(prices, InpBIAS3, InpMAMethod, 0);

      double close = iClose(_Symbol, _Period, i);

      // BIAS = 100 * (Close - MA) / MA
      bias1Buffer[i] = (ma1 > 0.0) ? 100.0 * (close - ma1) / ma1 : 0.0;
      bias2Buffer[i] = (ma2 > 0.0) ? 100.0 * (close - ma2) / ma2 : 0.0;
      bias3Buffer[i] = (ma3 > 0.0) ? 100.0 * (close - ma3) / ma3 : 0.0;

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
      strongBuy[i]  = EMPTY_VALUE;
      strongSell[i] = EMPTY_VALUE;
   }

   // --- 第2步：信号判断（bar[1]+确认）---
   for(i = limit; i >= 1; i--)
   {
      double b1 = bias1Buffer[i],     b1p = bias1Buffer[i + 1];
      double b2 = bias2Buffer[i],     b2p = bias2Buffer[i + 1];
      double b3 = bias3Buffer[i],     b3p = bias3Buffer[i + 1];

      bool priceUp = iClose(_Symbol, _Period, i) > iClose(_Symbol, _Period, i + 3);
      // Strong Buy: 三线从负翻正 + 价格上涨确认
      if(b1p < 0.0 && b2p < 0.0 && b3p < 0.0 && b1 > 0.0 && priceUp)
         strongBuy[i] = b1 - 0.8;
      // Strong Sell: 三线从正翻负 + 价格下跌确认
      if(b1p > 0.0 && b2p > 0.0 && b3p > 0.0 && b1 < 0.0 && !priceUp)
         strongSell[i] = b1 + 0.8;

      // 三线同时从负翻正 → 趋势全面转多（强信号）
      if(b1p < 0.0 && b2p < 0.0 && b3p < 0.0 && b1 > 0.0 && strongBuy[i] == EMPTY_VALUE)
         buySignal[i] = b1 - 0.5;

      // 三线同时从正翻负 → 趋势全面转空（强信号）
      if(b1p > 0.0 && b2p > 0.0 && b3p > 0.0 && b1 < 0.0 && strongSell[i] == EMPTY_VALUE)
         sellSignal[i] = b1 + 0.5;

      // 短线BIAS上穿中线BIAS（在负值区=超跌反弹）
      if(b1p <= b2p && b1 > b2 && b1 < -5.0 && strongBuy[i] == EMPTY_VALUE)
         buySignal[i] = b1 - 0.5;

      // 短线BIAS下穿中线BIAS（在正值区=超涨回落）
      if(b1p >= b2p && b1 < b2 && b1 > 5.0 && strongSell[i] == EMPTY_VALUE)
         sellSignal[i] = b1 + 0.5;
   }

   // --- 第3步：刷新 bar[0] ---
   if(Bars > 0)
   {
      double p0[];
      ArrayResize(p0, maxPeriod * 3);
      for(int jj = 0; j < maxPeriod * 3; j++)
         p0[j] = iClose(_Symbol, _Period, j);
      double m1 = CalculateMA(p0, InpBIAS1, InpMAMethod, 0);
      double m2 = CalculateMA(p0, InpBIAS2, InpMAMethod, 0);
      double m3 = CalculateMA(p0, InpBIAS3, InpMAMethod, 0);
      double c0 = iClose(_Symbol, _Period, 0);
      bias1Buffer[0] = (m1 > 0.0) ? 100.0 * (c0 - m1) / m1 : 0.0;
      bias2Buffer[0] = (m2 > 0.0) ? 100.0 * (c0 - m2) / m2 : 0.0;
      bias3Buffer[0] = (m3 > 0.0) ? 100.0 * (c0 - m3) / m3 : 0.0;
      buySignal[0]  = EMPTY_VALUE;
      sellSignal[0] = EMPTY_VALUE;
      strongBuy[0]  = EMPTY_VALUE;
      strongSell[0] = EMPTY_VALUE;
   }

   return(0);
}
//+------------------------------------------------------------------+
