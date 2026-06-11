//+------------------------------------------------------------------+
//|                                                   OsMA_Safe.mq4   |
//|  移动平均振荡器 — 不含未来函数                                    |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  OsMA = MACD_Line - Signal_Line (即MACD的柱状图)                   |
//|  其实就是MACD Histogram的独立版本                                  |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：OsMA从负值转为正值（上穿0轴, bar[1]确认）                |
//|  - 卖出：OsMA从正值转为负值（下穿0轴, bar[1]确认）                |
//|  - 柱状图增长/缩短提供趋势强度信息                                  |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5

// 输入参数
input int InpFastEMA  = 12;   // 快EMA周期
input int InpSlowEMA  = 26;   // 慢EMA周期
input int InpSignalSMA = 9;   // 信号线周期
input ENUM_PRICE_SAFE InpPriceType = PRICE_CLOSE;

// 指标缓冲区
double osmaBuffer[];
double buySignal[];
double sellSignal[];
double strongBuy[];
double strongSell[];

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_HISTOGRAM, STYLE_SOLID, 2);
   SetIndexBuffer(0, osmaBuffer);
   SetIndexLabel(0, "OsMA");

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
   IndicatorShortName("OsMA_Safe(" + IntegerToString(InpFastEMA) + "," +
                      IntegerToString(InpSlowEMA) + "," + IntegerToString(InpSignalSMA) + ")");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;
   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - InpSlowEMA * 3;
   if(limit < 0) limit = 0;

   int histSize = InpSlowEMA * 3;

   for(int i = limit; i >= 0; i--)
   {
      if(i + histSize >= Bars)
      {
         osmaBuffer[i] = 0.0;
         buySignal[i]  = EMPTY_VALUE;
         sellSignal[i] = EMPTY_VALUE;
         continue;
      }

      // 计算快EMA和慢EMA
      double prices[];
      ArrayResize(prices, histSize);
      for(int j = 0; j < histSize; j++)
         prices[j] = GetPriceByType(i + j, InpPriceType);

      // 快EMA
      double fastEMA = prices[histSize - 1];
      for(int j = histSize - InpFastEMA; j >= 0; j--)
      {
         double alpha = 2.0 / (InpFastEMA + 1.0);
         fastEMA = prices[j] * alpha + fastEMA * (1.0 - alpha);
      }

      // 慢EMA
      double slowEMA = prices[histSize - 1];
      for(int j = histSize - InpSlowEMA; j >= 0; j--)
      {
         double alpha = 2.0 / (InpSlowEMA + 1.0);
         slowEMA = prices[j] * alpha + slowEMA * (1.0 - alpha);
      }

      double macdLine = fastEMA - slowEMA;
      osmaBuffer[i] = macdLine;
      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // 对MACD做Signal平滑
   for(int i = limit; i >= 1; i--)
   {
      double sigSum = 0.0;
      for(int j = 0; j < InpSignalSMA; j++)
         sigSum += osmaBuffer[i + j];
      double signalLine = sigSum / InpSignalSMA;
      osmaBuffer[i] = osmaBuffer[i] - signalLine;  // 变成真正的OsMA
      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // 信号（bar[1]+确认）— 增强分级
   for(int i = limit; i >= 1; i--)
   {
      bool crossUp   = (osmaBuffer[i+1] < 0 && osmaBuffer[i] > 0);
      bool crossDown = (osmaBuffer[i+1] > 0 && osmaBuffer[i] < 0);
      bool accelUp   = (osmaBuffer[i] > osmaBuffer[i+1] + osmaBuffer[i+1] * 0.5); // 加速50%+
      bool accelDown = (osmaBuffer[i] < osmaBuffer[i+1] + osmaBuffer[i+1] * 0.5); // 加速-50%+
      bool bigMove   = (MathAbs(osmaBuffer[i]) > MathAbs(osmaBuffer[i+5]) * 2);    // 两倍于5周期前

      // 强买：零轴穿越 + 加速 + 大幅扩张
      if(crossUp && accelUp && bigMove) strongBuy[i] = osmaBuffer[i] - 0.0002;
      // 普通买：零轴穿越
      else if(crossUp) buySignal[i] = osmaBuffer[i] - 0.0001;

      // 强卖：零轴穿越 + 加速 + 大幅扩张
      if(crossDown && accelDown && bigMove) strongSell[i] = osmaBuffer[i] + 0.0002;
      // 普通卖：零轴穿越
      else if(crossDown) sellSignal[i] = osmaBuffer[i] + 0.0001;
   }

   return(0);
}
//+------------------------------------------------------------------+
