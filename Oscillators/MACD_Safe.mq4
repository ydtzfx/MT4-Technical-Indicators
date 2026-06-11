//+------------------------------------------------------------------+
//|                                                   MACD_Safe.mq4   |
//|  指数平滑异同移动平均线 — 不含未来函数                              |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  MACD Line  = EMA(Price, Fast) - EMA(Price, Slow)                 |
//|  Signal Line = EMA(MACD Line, Signal)                              |
//|  Histogram   = MACD Line - Signal Line                            |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：MACD线上穿Signal线 (金叉, bar[1]确认)                    |
//|  - 卖出：MACD线下穿Signal线 (死叉, bar[1]确认)                    |
//|  - 零轴穿越：MACD上穿/下穿0轴作为辅助信号                          |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 7

// 输入参数
input int    InpFastEMA   = 12;    // 快EMA周期
input int    InpSlowEMA   = 26;    // 慢EMA周期
input int    InpSignalSMA = 9;     // 信号线周期
input ENUM_PRICE_SAFE InpPriceType = PRICE_CLOSE; // 价格类型
input color  InpMACDColor    = clrDodgerBlue;  // MACD线颜色
input color  InpSignalColor  = clrRed;         // 信号线颜色
input color  InpHistUpColor  = clrLimeGreen;   // 多头柱颜色
input color  InpHistDownColor = clrTomato;     // 空头柱颜色

// 指标缓冲区
double macdBuffer[];     // MACD主线
double signalBuffer[];   // 信号线
double histBuffer[];     // 柱状图
double buySignal[];      // 买入信号
double sellSignal[];     // 卖出信号
double strongBuy[];      // 强买入（多条件+零轴确认）
double strongSell[];     // 强卖出

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 1, InpMACDColor);
   SetIndexBuffer(0, macdBuffer);
   SetIndexLabel(0, "MACD");

   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1, InpSignalColor);
   SetIndexBuffer(1, signalBuffer);
   SetIndexLabel(1, "Signal");

   SetIndexStyle(2, DRAW_HISTOGRAM, STYLE_SOLID, 2);
   SetIndexBuffer(2, histBuffer);
   SetIndexLabel(2, "Histogram");

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

   IndicatorDigits(4);
   IndicatorShortName("MACD_Safe(" + IntegerToString(InpFastEMA) + "," +
                      IntegerToString(InpSlowEMA) + "," + IntegerToString(InpSignalSMA) + ")");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
//| EMA计算辅助                                                        |
//+------------------------------------------------------------------+
double CalcEMAFromArray(double &prices[], int period)
{
   int size = ArraySize(prices);
   if(size < period) return(prices[0]);

   double ema = 0.0;
   // SMA种子
   for(int i = size - 1; i >= size - period; i--)
      ema += prices[i];
   ema /= period;

   double alpha = 2.0 / (period + 1.0);
   for(int i = size - period - 1; i >= 0; i--)
      ema = prices[i] * alpha + ema * (1.0 - alpha);

   return(ema);
}

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;
   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - InpSlowEMA * 3;
   if(limit < 0) limit = 0;

   // 需要足够的历史数据
   int histSize = InpSlowEMA * 3;

   for(int i = limit; i >= 0; i--)
   {
      if(i + histSize >= Bars) continue;

      double prices[];
      ArrayResize(prices, histSize);
      for(int j = 0; j < histSize; j++)
         prices[j] = GetPriceByType(i + j, InpPriceType);

      double fastEMA = CalcEMAFromArray(prices, InpFastEMA);
      double slowEMA = CalcEMAFromArray(prices, InpSlowEMA);

      macdBuffer[i] = fastEMA - slowEMA;
      histBuffer[i] = 0.0;
      signalBuffer[i] = 0.0;

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
      strongBuy[i]  = EMPTY_VALUE;
      strongSell[i] = EMPTY_VALUE;
   }

   // 计算Signal线（对MACD的EMA）
   int signalStart = Bars - InpSlowEMA * 3 - InpSignalSMA;
   for(int i = signalStart - 1; i >= 1; i--)
   {
      double macdVals[];
      ArrayResize(macdVals, InpSignalSMA * 2);
      int count = 0;
      for(int j = 0; j < InpSignalSMA * 2; j++)
      {
         if(i + j < ArraySize(macdBuffer))
            macdVals[count++] = macdBuffer[i + j];
      }
      if(count >= InpSignalSMA)
      {
         double ema = 0.0;
         for(int j = 0; j < InpSignalSMA; j++)
            ema += macdVals[j];
         ema /= InpSignalSMA;

         double alphaSig = 2.0 / (InpSignalSMA + 1.0);
         for(int j = InpSignalSMA; j < count; j++)
            ema = macdVals[j] * alphaSig + ema * (1.0 - alphaSig);

         signalBuffer[i] = ema;
         histBuffer[i] = macdBuffer[i] - ema;
      }
   }

   // 信号判断（bar[1]+确认，增强版：分级信号+零轴+柱状图趋势）
   for(int i = limit; i >= 3; i--)
   {
      // ===== 买入信号 =====
      int buyCond = 0;

      // 金叉
      bool goldenCross = (macdBuffer[i+1] <= signalBuffer[i+1] && macdBuffer[i] > signalBuffer[i]);
      if(goldenCross) { buySignal[i] = histBuffer[i] - 0.0001; buyCond++; }

      // 零轴附近金叉（更强）
      if(goldenCross && macdBuffer[i] > -0.0005 && macdBuffer[i] < 0.0005) buyCond+=2;

      // 柱状图连续扩大（加速）
      if(histBuffer[i] > histBuffer[i+1] && histBuffer[i+1] > histBuffer[i+2]) buyCond++;

      // MACD已经开始上升
      if(macdBuffer[i] > macdBuffer[i+1]) buyCond++;

      // 强买入：4+条件
      if(buyCond >= 4) strongBuy[i] = histBuffer[i] - 0.0002;

      // ===== 卖出信号 =====
      int sellCond = 0;

      // 死叉
      bool deathCross = (macdBuffer[i+1] >= signalBuffer[i+1] && macdBuffer[i] < signalBuffer[i]);
      if(deathCross) { sellSignal[i] = histBuffer[i] + 0.0001; sellCond++; }

      // 零轴附近死叉
      if(deathCross && macdBuffer[i] < 0.0005 && macdBuffer[i] > -0.0005) sellCond+=2;

      // 柱状图连续缩小（减速）
      if(histBuffer[i] < histBuffer[i+1] && histBuffer[i+1] < histBuffer[i+2]) sellCond++;

      // MACD已经开始下降
      if(macdBuffer[i] < macdBuffer[i+1]) sellCond++;

      if(sellCond >= 4) strongSell[i] = histBuffer[i] + 0.0002;

      // 零轴穿越（单独信号，级别较低）
      if(macdBuffer[i+1] < 0 && macdBuffer[i] > 0)
         { buySignal[i] = histBuffer[i] - 0.0001; if(macdBuffer[i] > 0.0002) strongBuy[i] = histBuffer[i] - 0.0002; }
      if(macdBuffer[i+1] > 0 && macdBuffer[i] < 0)
         { sellSignal[i] = histBuffer[i] + 0.0001; if(macdBuffer[i] < -0.0002) strongSell[i] = histBuffer[i] + 0.0002; }
   }

   return(0);
}
//+------------------------------------------------------------------+
