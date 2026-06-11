//+------------------------------------------------------------------+
//|                                        BollingerBands_Safe.mq4    |
//|  布林带指标 — 不含未来函数                                        |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  Middle Band = SMA(Price, N)                                       |
//|  Upper Band  = Middle Band + K * StdDev(Price, N)                  |
//|  Lower Band  = Middle Band - K * StdDev(Price, N)                  |
//|  StdDev = sqrt( Σ(Price_i - SMA)² / N )                           |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：价格从下方触碰下轨后回升，或从下轨反弹确认(bar[1])        |
//|  - 卖出：价格从上方触碰上轨后回落，或从上轨受阻确认(bar[1])        |
//|  - 中轨交叉信号可作为辅助确认                                      |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 8

// 输入参数
input int    InpBBPeriod    = 20;          // 布林带周期
input double InpDeviations  = 2.0;         // 标准差倍数
input ENUM_PRICE_SAFE InpPriceType = PRICE_CLOSE; // 价格类型
input bool   InpShowSignals = true;        // 显示信号
input color  InpUpperColor  = clrRoyalBlue;  // 上轨颜色
input color  InpLowerColor  = clrRoyalBlue;  // 下轨颜色
input color  InpMiddleColor = clrOrange;     // 中轨颜色

// 指标缓冲区
double upperBand[];          // 上轨
double lowerBand[];          // 下轨
double middleBand[];         // 中轨
double buySignal[];          // 买入信号
double sellSignal[];         // 卖出信号
double bandwidthBuffer[];    // 带宽指示（收缩=小, 扩张=大）
double strongBuy[];          // 强买入
double strongSell[];         // 强卖出

//+------------------------------------------------------------------+
//| 指标初始化                                                         |
//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 1, InpUpperColor);
   SetIndexBuffer(0, upperBand);
   SetIndexLabel(0, "BB Upper");

   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1, InpLowerColor);
   SetIndexBuffer(1, lowerBand);
   SetIndexLabel(1, "BB Lower");

   SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 2, InpMiddleColor);
   SetIndexBuffer(2, middleBand);
   SetIndexLabel(2, "BB Middle");

   SetIndexStyle(3, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(3, buySignal);
   SetIndexLabel(3, "Buy Signal");
   SetIndexArrow(3, ARROW_BUY);
   SetIndexEmptyValue(3, EMPTY_VALUE);

   SetIndexStyle(4, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(4, sellSignal);
   SetIndexLabel(4, "Sell Signal");
   SetIndexArrow(4, ARROW_SELL);
   SetIndexEmptyValue(4, EMPTY_VALUE);

   // 带宽缓冲区（隐藏，用于计算）
   SetIndexStyle(5, DRAW_NONE);
   SetIndexBuffer(5, bandwidthBuffer);
   SetIndexLabel(5, "Bandwidth (hidden)");

   SetIndexStyle(6, DRAW_ARROW, STYLE_SOLID, 4, clrCyan);
   SetIndexBuffer(6, strongBuy);
   SetIndexArrow(6, ARROW_BUY);
   SetIndexLabel(6, "Strong Buy");
   SetIndexEmptyValue(6, EMPTY_VALUE);

   SetIndexStyle(7, DRAW_ARROW, STYLE_SOLID, 4, clrDeepPink);
   SetIndexBuffer(7, strongSell);
   SetIndexArrow(7, ARROW_SELL);
   SetIndexLabel(7, "Strong Sell");
   SetIndexEmptyValue(7, EMPTY_VALUE);

   IndicatorDigits(4);
   IndicatorShortName("BB_Safe(" + IntegerToString(InpBBPeriod) + ")");

   return(0);
}

//+------------------------------------------------------------------+
int deinit() { return(0); }

//+------------------------------------------------------------------+
//| 指标计算                                                           |
//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;
   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - 2;
   if(limit < 0) limit = 0;

   // 计算历史
   for(int i = limit; i >= 0; i--)
   {
      // 获取价格数组
      double prices[];
      ArrayResize(prices, InpBBPeriod);
      for(int j = 0; j < InpBBPeriod; j++)
         prices[j] = GetPriceByType(i + j, InpPriceType);

      // 计算SMA（中轨）
      double sum = 0.0;
      for(int j = 0; j < InpBBPeriod; j++)
         sum += prices[j];
      double sma = sum / InpBBPeriod;
      middleBand[i] = sma;

      // 计算标准差
      double sumSqDiff = 0.0;
      for(int j = 0; j < InpBBPeriod; j++)
      {
         double diff = prices[j] - sma;
         sumSqDiff += diff * diff;
      }
      double stdDev = MathSqrt(sumSqDiff / InpBBPeriod);

      upperBand[i] = sma + InpDeviations * stdDev;
      lowerBand[i] = sma - InpDeviations * stdDev;

      // 带宽 = (上轨-下轨)/中轨 * 100，衡量波动率
      bandwidthBuffer[i] = SafeDivide((upperBand[i] - lowerBand[i]) * 100, sma, 0);

      // 信号判断（仅 bar[1]+）
      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
      strongBuy[i]  = EMPTY_VALUE;
      strongSell[i] = EMPTY_VALUE;
   }

   // 信号计算（仅在 bar >= 1 上产生信号，增强版：带宽收缩预警 + 信号分级）
   if(InpShowSignals)
   {
      for(int i = limit; i >= 3; i--)
      {
         double low_i    = iLow(_Symbol, _Period, i);
         double low_i1   = iLow(_Symbol, _Period, i + 1);
         double high_i   = iHigh(_Symbol, _Period, i);
         double high_i1  = iHigh(_Symbol, _Period, i + 1);
         double close_i  = iClose(_Symbol, _Period, i);
         double close_i1 = iClose(_Symbol, _Period, i + 1);

         // 带宽挤压检测
         bool isSqueeze = true;
         for(int j=1;j<=20;j++) {
            if(bandwidthBuffer[i] > bandwidthBuffer[i+j]) { isSqueeze = false; break; }
         }
         bool tightSqueeze = (isSqueeze && bandwidthBuffer[i] < 2.0);

         // 强买：带宽极度收缩后中轨突破（高概率真突破）
         if(tightSqueeze && close_i1 <= middleBand[i+1] && close_i > middleBand[i])
            strongBuy[i] = low_i - 10.0 * _Point;
         // 强卖：带宽极度收缩后中轨跌破
         if(tightSqueeze && close_i1 >= middleBand[i+1] && close_i < middleBand[i])
            strongSell[i] = high_i + 10.0 * _Point;

         // 普通买：价格触碰下轨后回升
         if(low_i1 <= lowerBand[i+1] && close_i > lowerBand[i])
            buySignal[i] = low_i - 5.0 * _Point;

         // 普通卖：价格触碰上轨后回落
         if(high_i1 >= upperBand[i+1] && close_i < upperBand[i])
            sellSignal[i] = high_i + 5.0 * _Point;

         // 中等信号：普通带宽收缩（宽度不是历史极值但仍在收缩）
         if(isSqueeze && !tightSqueeze) {
            if(close_i1 <= middleBand[i+1] && close_i > middleBand[i])
               buySignal[i] = low_i - 7.0 * _Point;
            if(close_i1 >= middleBand[i+1] && close_i < middleBand[i])
               sellSignal[i] = high_i + 7.0 * _Point;
         }
      }
   }

   return(0);
}
//+------------------------------------------------------------------+
