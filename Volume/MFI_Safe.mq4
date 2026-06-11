//+------------------------------------------------------------------+
//|                                                    MFI_Safe.mq4   |
//|  资金流量指数 — 不含未来函数                                      |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  TP = (High + Low + Close) / 3                                    |
//|  MF = TP * Volume  (Money Flow)                                   |
//|  MFI = 100 - 100 / (1 + Sum(PositiveMF, N) / Sum(NegativeMF, N)) |
//|  取值范围 [0, 100]                                                 |
//|                                                                   |
//|  与RSI类似但融入成交量信息                                         |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：MFI从20下方回升突破确认(bar[1])                          |
//|  - 卖出：MFI从80上方回落跌破确认(bar[1])                          |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 80
#property indicator_level2 20

// 输入参数
input int    InpMFIPeriod = 14;   // MFI周期
input double InpOverbought = 80.0;
input double InpOversold   = 20.0;

// 指标缓冲区
double mfiBuffer[];
double buySignal[];
double sellSignal[];

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, clrDodgerBlue);
   SetIndexBuffer(0, mfiBuffer);
   SetIndexLabel(0, "MFI");

   SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(1, buySignal);
   SetIndexArrow(1, ARROW_BUY);
   SetIndexEmptyValue(1, EMPTY_VALUE);

   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(2, sellSignal);
   SetIndexArrow(2, ARROW_SELL);
   SetIndexEmptyValue(2, EMPTY_VALUE);

   IndicatorDigits(2);
   IndicatorShortName("MFI_Safe(" + IntegerToString(InpMFIPeriod) + ")");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;
   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - InpMFIPeriod * 3;
   if(limit < 0) limit = 0;

   for(int i = limit; i >= 0; i--)
   {
      double posMF = 0.0;
      double negMF = 0.0;
      double prevTP = 0.0;

      for(int j = InpMFIPeriod - 1; j >= 0; j--)
      {
         int shift = i + j;
         double high = iHigh(_Symbol, _Period, shift);
         double low  = iLow(_Symbol, _Period, shift);
         double close = iClose(_Symbol, _Period, shift);
         double tp   = (high + low + close) / 3.0;
         long   vol  = iVolume(_Symbol, _Period, shift);
         double mf   = tp * vol;

         if(j == InpMFIPeriod - 1)
         {
            prevTP = tp;
            continue;  // 第一个不需要比较
         }

         double nextTP = tp;
         // 比较：如果当前的TP > 更近期的TP（即j更小的），则正向
         // 注：MFI比较TP_i和TP_{i-1}，即价格方向
         double nextShiftTP = (iHigh(_Symbol, _Period, shift) + iLow(_Symbol, _Period, shift) + iClose(_Symbol, _Period, shift)) / 3.0;

         // 需要TP的历史比较 — 用TP(shift)和TP(shift+1)比较
         double tpPrev = (iHigh(_Symbol, _Period, shift + 1) + iLow(_Symbol, _Period, shift + 1) + iClose(_Symbol, _Period, shift + 1)) / 3.0;

         double tpCurr = tp;
         double tpCompare = tpPrev;

         if(tpCurr > tpCompare)
            posMF += tpCurr * vol;
         else if(tpCurr < tpCompare)
            negMF += tpCurr * vol;
         // 相等时不计数
      }

      double totalMF = posMF + negMF;
      double mfRatio = SafeDivide(posMF, negMF, 1.0);

      mfiBuffer[i] = (MathAbs(negMF) < 0.00000001 && MathAbs(posMF) < 0.00000001)
                     ? 50.0 : (100.0 - 100.0 / (1.0 + mfRatio));

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // 信号（bar[1]+确认）
   for(int i = limit; i >= 1; i--)
   {
      if(mfiBuffer[i+1] <= InpOversold && mfiBuffer[i] > InpOversold)
         buySignal[i] = 5.0;
      if(mfiBuffer[i+1] >= InpOverbought && mfiBuffer[i] < InpOverbought)
         sellSignal[i] = 95.0;
   }

   return(0);
}
//+------------------------------------------------------------------+
