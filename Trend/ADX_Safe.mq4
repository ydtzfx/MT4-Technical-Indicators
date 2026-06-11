//+------------------------------------------------------------------+
//|                                                    ADX_Safe.mq4  |
//|  平均趋向指数 — 不含未来函数                                      |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  TR  = Max(H-L, |H-PrevC|, |L-PrevC|)                             |
//|  +DM = Max(H-PrevH, 0) if H-PrevH > PrevL-L else 0               |
//|  -DM = Max(PrevL-L, 0) if PrevL-L > H-PrevH else 0               |
//|  +DI = 100 * EMA(+DM, N) / EMA(TR, N)                             |
//|  -DI = 100 * EMA(-DM, N) / EMA(TR, N)                             |
//|  DX  = 100 * |+DI - -DI| / (+DI + -DI)                           |
//|  ADX = EMA(DX, N)                                                 |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - ADX > 25 且 +DI上穿-DI：趋势转多确认(bar[1])                   |
//|  - ADX > 25 且 -DI上穿+DI：趋势转空确认(bar[1])                   |
//|  - ADX下降：趋势减弱，可考虑平仓                                  |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 7
#property indicator_minimum 0
#property indicator_maximum 100

// 输入参数
input int   InpADXPeriod = 14;     // ADX周期
input color InpADXColor  = clrYellow;      // ADX线颜色
input color InpPlusDIColor  = clrLimeGreen;  // +DI线颜色
input color InpMinusDIColor = clrTomato;     // -DI线颜色

// 指标缓冲区
double adxBuffer[];      // ADX 主线
double plusDIBuffer[];   // +DI 线
double minusDIBuffer[];  // -DI 线
double buySignal[];      // 买入信号
double sellSignal[];     // 卖出信号
double strongBuy[];      // 强买入
double strongSell[];     // 强卖出

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, InpADXColor);
   SetIndexBuffer(0, adxBuffer);
   SetIndexLabel(0, "ADX");

   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1, InpPlusDIColor);
   SetIndexBuffer(1, plusDIBuffer);
   SetIndexLabel(1, "+DI");

   SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 1, InpMinusDIColor);
   SetIndexBuffer(2, minusDIBuffer);
   SetIndexLabel(2, "-DI");

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
   IndicatorShortName("ADX_Safe(" + IntegerToString(InpADXPeriod) + ")");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;
   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - InpADXPeriod * 3;
   if(limit < 0) limit = 0;

   for(int i = limit; i >= 0; i--)
   {
      // 收集TR, +DM, -DM序列
      double trVals[], plusDMVals[], minusDMVals[];
      ArrayResize(trVals, InpADXPeriod * 2);
      ArrayResize(plusDMVals, InpADXPeriod * 2);
      ArrayResize(minusDMVals, InpADXPeriod * 2);

      for(int j = 0; j < InpADXPeriod * 2; j++)
      {
         int shift = i + j;
         double high    = iHigh(_Symbol, _Period, shift);
         double low     = iLow(_Symbol, _Period, shift);
         double prevHigh = iHigh(_Symbol, _Period, shift + 1);
         double prevLow  = iLow(_Symbol, _Period, shift + 1);
         double prevClose = iClose(_Symbol, _Period, shift + 1);

         // True Range
         double tr1 = high - low;
         double tr2 = MathAbs(high - prevClose);
         double tr3 = MathAbs(low - prevClose);
         trVals[j] = MathMax(tr1, MathMax(tr2, tr3));

         // Directional Movement
         double upMove   = high - prevHigh;
         double downMove = prevLow - low;

         if(upMove > downMove && upMove > 0)
         {
            plusDMVals[j] = upMove;
            minusDMVals[j] = 0;
         }
         else if(downMove > upMove && downMove > 0)
         {
            plusDMVals[j] = 0;
            minusDMVals[j] = downMove;
         }
         else
         {
            plusDMVals[j] = 0;
            minusDMVals[j] = 0;
         }
      }

      // 计算EMA平滑的TR, +DM, -DM
      double emaTR = trVals[InpADXPeriod * 2 - 1];
      double emaPlusDM = plusDMVals[InpADXPeriod * 2 - 1];
      double emaMinusDM = minusDMVals[InpADXPeriod * 2 - 1];

      double alpha = 2.0 / (InpADXPeriod + 1.0);
      for(int j = InpADXPeriod * 2 - 2; j >= 0; j--)
      {
         emaTR      = trVals[j] * alpha + emaTR * (1.0 - alpha);
         emaPlusDM  = plusDMVals[j] * alpha + emaPlusDM * (1.0 - alpha);
         emaMinusDM = minusDMVals[j] * alpha + emaMinusDM * (1.0 - alpha);
      }

      // +DI, -DI
      double plusDI  = SafeDivide(100.0 * emaPlusDM, emaTR, 0.0);
      double minusDI = SafeDivide(100.0 * emaMinusDM, emaTR, 0.0);

      plusDIBuffer[i]  = plusDI;
      minusDIBuffer[i] = minusDI;

      // DX
      double dx = SafeDivide(100.0 * MathAbs(plusDI - minusDI), plusDI + minusDI, 0.0);

      // ADX = EMA of DX
      // 简化：取最近N个DX的EMA
      adxBuffer[i] = dx;  // 基础值，后续平滑

      // 信号初始化
      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
      strongBuy[i]  = EMPTY_VALUE;
      strongSell[i] = EMPTY_VALUE;
   }

   // ADX平滑（对DX数组做EMA）
   double alphaADX = 2.0 / (InpADXPeriod + 1.0);
   for(int i = Bars - InpADXPeriod * 3 - 1; i >= 1; i--)
   {
      double ema = adxBuffer[i + InpADXPeriod - 1];
      for(int j = InpADXPeriod - 2; j >= 0; j--)
      {
         ema = adxBuffer[i + j] * alphaADX + ema * (1.0 - alphaADX);
      }
      adxBuffer[i] = ema;
   }

   // 信号判断（bar[1]+确认）— 增强分级
   for(int i = limit; i >= 1; i--)
   {
      bool crossUp   = (plusDIBuffer[i+1] <= minusDIBuffer[i+1] && plusDIBuffer[i] > minusDIBuffer[i]);
      bool crossDown = (minusDIBuffer[i+1] <= plusDIBuffer[i+1] && minusDIBuffer[i] > plusDIBuffer[i]);
      bool strongTrend = (adxBuffer[i] > 40);     // ADX>40 强趋势
      bool validTrend  = (adxBuffer[i] > 25);     // ADX>25 有效趋势
      bool adxRising   = (adxBuffer[i] > adxBuffer[i+1]); // ADX上升=趋势加强

      // 强买：+DI上穿-DI + ADX>40 + ADX上升（强趋势启动）
      if(crossUp && strongTrend && adxRising)
         strongBuy[i] = 3.0;
      // 普通买：+DI上穿-DI + ADX>25
      else if(crossUp && validTrend)
         buySignal[i] = 5.0;

      // 强卖：-DI上穿+DI + ADX>40 + ADX上升（强空头趋势启动）
      if(crossDown && strongTrend && adxRising)
         strongSell[i] = 97.0;
      // 普通卖：-DI上穿+DI + ADX>25
      else if(crossDown && validTrend)
         sellSignal[i] = 95.0;
   }

   return(0);
}
//+------------------------------------------------------------------+
