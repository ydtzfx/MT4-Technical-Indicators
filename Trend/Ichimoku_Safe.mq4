//+------------------------------------------------------------------+
//|                                              Ichimoku_Safe.mq4    |
//|  一目均衡表（Ichimoku Kinko Hyo）— 不含未来函数                    |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  Tenkan-sen(转换线) = (Highest(N1) + Lowest(N1)) / 2               |
//|  Kijun-sen(基准线)  = (Highest(N2) + Lowest(N2)) / 2               |
//|  Senkou Span A(先行A) = (Tenkan + Kijun) / 2, 前移N2根             |
//|  Senkou Span B(先行B) = (Highest(N3) + Lowest(N3)) / 2, 前移N2根   |
//|  Chikou Span(滞后线)  = Close, 后移N2根                            |
//|                                                                   |
//|  防未来函数关键处理：                                              |
//|  - Senkou Span 本身定义了未来投影，这是指标特性而非未来函数        |
//|  - 信号确认只在 bar[1]+ 进行（已完成的K线）                        |
//|  - Chikou Span 的穿越判断延迟一根K线确认                           |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 9

// 输入参数
input int InpTenkan = 9;     // 转换线周期
input int InpKijun  = 26;    // 基准线周期
input int InpSenkou = 52;    // 先行Span B周期
input color InpTenkanColor = clrRed;         // 转换线颜色
input color InpKijunColor  = clrDodgerBlue;  // 基准线颜色
input color InpCloudUpColor = clrSandyBrown; // 云带上色
input color InpCloudDownColor = clrThistle;  // 云带下色
input color InpChikouColor = clrLime;        // 滞后线颜色

// 指标缓冲区
double tenkanBuffer[];       // 转换线
double kijunBuffer[];        // 基准线
double senkouABuffer[];      // 先行A（前移）
double senkouBBuffer[];      // 先行B（前移）
double chikouBuffer[];       // 滞后线（后移）
double buySignal[];          // 买入信号
double sellSignal[];         // 卖出信号
double strongBuy[];          // 强买入
double strongSell[];         // 强卖出

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 1, InpTenkanColor);
   SetIndexBuffer(0, tenkanBuffer);
   SetIndexLabel(0, "Tenkan-sen");

   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 2, InpKijunColor);
   SetIndexBuffer(1, kijunBuffer);
   SetIndexLabel(1, "Kijun-sen");

   // Senkou Span A — 绘制为填充区域的上边界
   SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 1, InpCloudUpColor);
   SetIndexBuffer(2, senkouABuffer);
   SetIndexLabel(2, "Senkou Span A");

   // Senkou Span B — 填充区域的下边界
   SetIndexStyle(3, DRAW_LINE, STYLE_SOLID, 1, InpCloudDownColor);
   SetIndexBuffer(3, senkouBBuffer);
   SetIndexLabel(3, "Senkou Span B");

   SetIndexStyle(4, DRAW_LINE, STYLE_SOLID, 1, InpChikouColor);
   SetIndexBuffer(4, chikouBuffer);
   SetIndexLabel(4, "Chikou Span");

   SetIndexStyle(5, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(5, buySignal);
   SetIndexArrow(5, ARROW_BUY);
   SetIndexEmptyValue(5, EMPTY_VALUE);

   SetIndexStyle(6, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(6, sellSignal);
   SetIndexArrow(6, ARROW_SELL);
   SetIndexEmptyValue(6, EMPTY_VALUE);

   SetIndexStyle(7, DRAW_ARROW, STYLE_SOLID, 4, clrCyan);
   SetIndexBuffer(7, strongBuy);
   SetIndexArrow(7, ARROW_BUY);
   SetIndexLabel(7, "Strong Buy");
   SetIndexEmptyValue(7, EMPTY_VALUE);

   SetIndexStyle(8, DRAW_ARROW, STYLE_SOLID, 4, clrDeepPink);
   SetIndexBuffer(8, strongSell);
   SetIndexArrow(8, ARROW_SELL);
   SetIndexLabel(8, "Strong Sell");
   SetIndexEmptyValue(8, EMPTY_VALUE);

   IndicatorDigits(4);
   IndicatorShortName("Ichimoku_Safe(" + IntegerToString(InpTenkan) + "," +
                      IntegerToString(InpKijun) + "," + IntegerToString(InpSenkou) + ")");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;
   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - InpSenkou * 2;
   if(limit < 0) limit = 0;

   // 先初始化全部为空值
   for(int i = limit + InpSenkou; i >= -InpKijun; i--)
   {
      if(i >= 0)
      {
         tenkanBuffer[i] = EMPTY_VALUE;
         kijunBuffer[i]  = EMPTY_VALUE;
         chikouBuffer[i] = EMPTY_VALUE;
         buySignal[i]    = EMPTY_VALUE;
         sellSignal[i]   = EMPTY_VALUE;
         strongBuy[i]    = EMPTY_VALUE;
         strongSell[i]   = EMPTY_VALUE;
      }
      senkouABuffer[i + InpKijun] = EMPTY_VALUE;
      senkouBBuffer[i + InpKijun] = EMPTY_VALUE;
   }

   for(int i = limit; i >= 0; i--)
   {
      // === Tenkan-sen: (Highest(N1) + Lowest(N1)) / 2 ===
      if(i + InpTenkan - 1 < Bars)
      {
         double highestT = iHigh(_Symbol, _Period, i);
         double lowestT  = iLow(_Symbol, _Period, i);
         for(int j = i; j < i + InpTenkan; j++)
         {
            double h = iHigh(_Symbol, _Period, j);
            double l = iLow(_Symbol, _Period, j);
            if(h > highestT) highestT = h;
            if(l < lowestT)  lowestT  = l;
         }
         tenkanBuffer[i] = (highestT + lowestT) / 2.0;
      }

      // === Kijun-sen: (Highest(N2) + Lowest(N2)) / 2 ===
      if(i + InpKijun - 1 < Bars)
      {
         double highestK = iHigh(_Symbol, _Period, i);
         double lowestK  = iLow(_Symbol, _Period, i);
         for(int j = i; j < i + InpKijun; j++)
         {
            double h = iHigh(_Symbol, _Period, j);
            double l = iLow(_Symbol, _Period, j);
            if(h > highestK) highestK = h;
            if(l < lowestK)  lowestK  = l;
         }
         kijunBuffer[i] = (highestK + lowestK) / 2.0;
      }

      // === Senkou Span A: (Tenkan + Kijun) / 2, 前移InpKijun根 ===
      double sa = (tenkanBuffer[i] + kijunBuffer[i]) / 2.0;
      int saIndex = i - InpKijun;
      if(saIndex >= 0)
         senkouABuffer[saIndex] = sa;

      // === Senkou Span B: (Highest(N3) + Lowest(N3)) / 2, 前移InpKijun根 ===
      if(i + InpSenkou - 1 < Bars)
      {
         double highestS = iHigh(_Symbol, _Period, i);
         double lowestS  = iLow(_Symbol, _Period, i);
         for(int j = i; j < i + InpSenkou; j++)
         {
            double h = iHigh(_Symbol, _Period, j);
            double l = iLow(_Symbol, _Period, j);
            if(h > highestS) highestS = h;
            if(l < lowestS)  lowestS  = l;
         }
         double sb = (highestS + lowestS) / 2.0;
         int sbIndex = i - InpKijun;
         if(sbIndex >= 0)
            senkouBBuffer[sbIndex] = sb;
      }

      // === Chikou Span: Close 后移InpKijun根 ===
      int chikouIndex = i + InpKijun;
      if(chikouIndex < Bars)
         chikouBuffer[chikouIndex] = iClose(_Symbol, _Period, chikouIndex);
   }

   // === 信号判断（bar[1]+确认）— 增强分级 ===
   for(int i = limit; i >= 1; i--)
   {
      bool crossUp   = (tenkanBuffer[i+1] <= kijunBuffer[i+1] && tenkanBuffer[i] > kijunBuffer[i]);
      bool crossDown = (tenkanBuffer[i+1] >= kijunBuffer[i+1] && tenkanBuffer[i] < kijunBuffer[i]);
      double close_i  = iClose(_Symbol, _Period, i);
      double close_i1 = iClose(_Symbol, _Period, i + 1);
      bool priceAboveCloud = (close_i > senkouABuffer[i] && close_i > senkouBBuffer[i]);
      bool priceBelowCloud = (close_i < senkouABuffer[i] && close_i < senkouBBuffer[i]);
      bool thickCloud = (MathAbs(senkouABuffer[i] - senkouBBuffer[i]) > iATR(_Symbol,_Period,14,i)*0.5);

      // 强买：Tenkan上穿Kijun + 价格在厚云上方（趋势确认充分）
      if(crossUp && priceAboveCloud && thickCloud)
         strongBuy[i] = iLow(_Symbol, _Period, i) - 15.0 * _Point;
      // 普通买：Tenkan上穿Kijun + 价格在云上方
      else if(crossUp && priceAboveCloud)
         buySignal[i] = iLow(_Symbol, _Period, i) - 10.0 * _Point;

      // 强卖：Tenkan下穿Kijun + 价格在厚云下方
      if(crossDown && priceBelowCloud && thickCloud)
         strongSell[i] = iHigh(_Symbol, _Period, i) + 15.0 * _Point;
      else if(crossDown && priceBelowCloud)
         sellSignal[i] = iHigh(_Symbol, _Period, i) + 10.0 * _Point;

      // 云层穿越信号
      bool belowCloudPrev = (close_i1 < senkouABuffer[i+1] || close_i1 < senkouBBuffer[i+1]);
      bool aboveCloudCurr = (close_i > senkouABuffer[i] && close_i > senkouBBuffer[i]);
      bool aboveCloudPrev = (close_i1 > senkouABuffer[i+1] || close_i1 > senkouBBuffer[i+1]);
      bool belowCloudCurr = (close_i < senkouABuffer[i] && close_i < senkouBBuffer[i]);

      if(belowCloudPrev && aboveCloudCurr)
         buySignal[i] = iLow(_Symbol, _Period, i) - 10.0 * _Point;
      if(aboveCloudPrev && belowCloudCurr)
         sellSignal[i] = iHigh(_Symbol, _Period, i) + 10.0 * _Point;
   }

   return(0);
}
//+------------------------------------------------------------------+
