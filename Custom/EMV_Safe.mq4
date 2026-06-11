//+------------------------------------------------------------------+
//|                                                   EMV_Safe.mq4    |
//|  简易波动指标（Ease of Movement）— 不含未来函数                   |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  MidPoint = (High + Low) / 2                                       |
//|  BoxRatio = Volume / (High - Low)                                  |
//|  RawEMV = (MidPoint - MidPoint_prev) / BoxRatio                   |
//|  EMV = MA(RawEMV, N)                                               |
//|                                                                   |
//|  正值：价格上涨所需的成交量较小（容易上涨）                         |
//|  负值：价格下跌所需的成交量较小（容易下跌）                         |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：EMV从负值转为正值（bar[1]确认）                           |
//|  - 卖出：EMV从正值转为负值（bar[1]确认）                           |
//|  - EMV持续上升+价格盘整=潜在突破                                   |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3

input int    InpEMVPeriod = 14;          // EMV平滑周期
input ENUM_MA_METHOD_SAFE InpMAMethod = MA_SMA; // 平滑方式

// 指标缓冲区
double emvBuffer[];     // EMV主线
double buySignal[];     // 买入信号
double sellSignal[];    // 卖出信号

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, clrDodgerBlue);
   SetIndexBuffer(0, emvBuffer);
   SetIndexLabel(0, "EMV");
   SetIndexEmptyValue(0, 0.0);

   SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(1, buySignal);
   SetIndexArrow(1, ARROW_BUY);
   SetIndexLabel(1, "Buy Signal");
   SetIndexEmptyValue(1, EMPTY_VALUE);

   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(2, sellSignal);
   SetIndexArrow(2, ARROW_SELL);
   SetIndexLabel(2, "Sell Signal");
   SetIndexEmptyValue(2, EMPTY_VALUE);

   IndicatorDigits(0);
   IndicatorShortName("EMV_Safe(" + IntegerToString(InpEMVPeriod) + ")");
   return(0);
}

//+------------------------------------------------------------------+
int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;

   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - InpEMVPeriod * 3;
   if(limit < 0) limit = 0;

   // --- 第1步：计算原始EMV序列 ---
   double rawEMV[];
   ArrayResize(rawEMV, Bars);
   ArrayInitialize(rawEMV, 0.0);

   for(int i = limit + InpEMVPeriod; i >= 1; i--)
   {
      // 今日中间价
      double midPoint = (iHigh(_Symbol, _Period, i) + iLow(_Symbol, _Period, i)) / 2.0;
      // 昨日中间价
      double midPointPrev = (iHigh(_Symbol, _Period, i + 1) + iLow(_Symbol, _Period, i + 1)) / 2.0;

      double range = iHigh(_Symbol, _Period, i) - iLow(_Symbol, _Period, i);
      long   volume = iVolume(_Symbol, _Period, i);

      // BoxRatio = Volume / Range，衡量每个价格单位需要多少成交量
      double boxRatio = SafeDivide((double)volume, range, 1.0);

      // RawEMV = 中间价变化 / BoxRatio
      rawEMV[i] = SafeDivide(midPoint - midPointPrev, boxRatio, 0.0);
   }

   // --- 第2步：平滑EMV ---
   for(int i = limit; i >= 1; i--)
   {
      double rawVals[];
      int count = 0;
      ArrayResize(rawVals, InpEMVPeriod * 2);
      for(int j = 0; j < InpEMVPeriod * 2 && (i + j < Bars); j++)
         rawVals[count++] = rawEMV[i + j];

      if(count >= InpEMVPeriod)
         emvBuffer[i] = CalculateMA(rawVals, InpEMVPeriod, InpMAMethod, 0);
      else
         emvBuffer[i] = 0.0;

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // --- 第3步：信号判断（bar[1]+确认）---
   for(int i = limit; i >= 1; i--)
   {
      // EMV零轴穿越 — 买入信号
      if(emvBuffer[i + 1] < 0.0 && emvBuffer[i] > 0.0)
         buySignal[i] = emvBuffer[i] * 0.5;

      // EMV零轴穿越 — 卖出信号
      if(emvBuffer[i + 1] > 0.0 && emvBuffer[i] < 0.0)
         sellSignal[i] = emvBuffer[i] * 1.5;

      // EMV连续上升且价格盘整 → 可能突破向上
      if(emvBuffer[i] > emvBuffer[i + 1] && emvBuffer[i + 1] > emvBuffer[i + 2])
      {
         double range3 = MathAbs(iClose(_Symbol, _Period, i) - iClose(_Symbol, _Period, i + 3));
         if(range3 < iClose(_Symbol, _Period, i) * 0.01)  // 1%内窄幅
            buySignal[i] = emvBuffer[i] * 0.5;
      }
   }

   // --- 第4步：刷新 bar[0] ---
   if(Bars > 0)
   {
      emvBuffer[0] = emvBuffer[1];  // 近似值
      buySignal[0]  = EMPTY_VALUE;
      sellSignal[0] = EMPTY_VALUE;
   }

   return(0);
}
//+------------------------------------------------------------------+
