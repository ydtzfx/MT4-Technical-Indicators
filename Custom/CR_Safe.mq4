//+------------------------------------------------------------------+
//|                                                    CR_Safe.mq4    |
//|  能量指标（CR）— 不含未来函数                                     |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  MidPoint = (PrevHigh + PrevLow + PrevClose) / 3                   |
//|  CR = 100 * Σ(High - MidPoint, N) / Σ(MidPoint - Low, N)          |
//|  以昨日中间价为基准，衡量今日多空能量对比                          |
//|                                                                   |
//|  四条均线参考（a/b/c/d）：                                        |
//|  - a: MA10(CR), b: MA20(CR), c: MA40(CR), d: MA62(CR)            |
//|  - a线上穿b/c/d线为多头信号                                       |
//|  - a线下穿b/c/d线为空头信号                                       |
//|  - 各均线构成压力/支撑带                                           |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 7

// 输入参数
input int InpCRPeriod = 26;     // CR周期
input int InpMAa = 10;          // a均线周期
input int InpMAb = 20;          // b均线周期
input int InpMAc = 40;          // c均线周期
input int InpMAd = 62;          // d均线周期
input color InpCRColor = clrWhite;      // CR线颜色
input color InpAColor  = clrYellow;     // a线颜色
input color InpBColor  = clrOrange;     // b线颜色
input color InpCColor  = clrTomato;     // c线颜色
input color InpDColor  = clrLimeGreen;  // d线颜色

// 指标缓冲区
double crBuffer[];      // CR主线
double maA[];           // a均线
double maB[];           // b均线
double maC[];           // c均线
double maD[];           // d均线
double buySignal[];     // 买入信号
double sellSignal[];    // 卖出信号

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 1, InpCRColor);
   SetIndexBuffer(0, crBuffer);
   SetIndexLabel(0, "CR");
   SetIndexEmptyValue(0, 0.0);

   SetIndexStyle(1, DRAW_LINE, STYLE_DOT, 1, InpAColor);
   SetIndexBuffer(1, maA);
   SetIndexLabel(1, "MA" + IntegerToString(InpMAa));
   SetIndexEmptyValue(1, 0.0);

   SetIndexStyle(2, DRAW_LINE, STYLE_DOT, 1, InpBColor);
   SetIndexBuffer(2, maB);
   SetIndexLabel(2, "MA" + IntegerToString(InpMAb));
   SetIndexEmptyValue(2, 0.0);

   SetIndexStyle(3, DRAW_LINE, STYLE_DOT, 1, InpCColor);
   SetIndexBuffer(3, maC);
   SetIndexLabel(3, "MA" + IntegerToString(InpMAc));
   SetIndexEmptyValue(3, 0.0);

   SetIndexStyle(4, DRAW_LINE, STYLE_DOT, 1, InpDColor);
   SetIndexBuffer(4, maD);
   SetIndexLabel(4, "MA" + IntegerToString(InpMAd));
   SetIndexEmptyValue(4, 0.0);

   SetIndexStyle(5, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(5, buySignal);
   SetIndexArrow(5, ARROW_BUY);
   SetIndexLabel(5, "Buy Signal");
   SetIndexEmptyValue(5, EMPTY_VALUE);

   SetIndexStyle(6, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(6, sellSignal);
   SetIndexArrow(6, ARROW_SELL);
   SetIndexLabel(6, "Sell Signal");
   SetIndexEmptyValue(6, EMPTY_VALUE);

   IndicatorDigits(2);
   IndicatorShortName("CR_Safe(" + IntegerToString(InpCRPeriod) + ")");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;

   int limit = Bars - counted_bars;
   int maxMA = MathMax(InpMAa, MathMax(InpMAb, MathMax(InpMAc, InpMAd)));
   if(limit > Bars - 2) limit = Bars - InpCRPeriod * 2;
   if(limit < 0) limit = 0;

   // --- 第1步：计算CR值 ---
   for(int i = limit; i >= 1; i--)
   {
      double sumHigh = 0.0;
      double sumLow  = 0.0;

      for(int j = 0; j < InpCRPeriod; j++)
      {
         int shift = i + j;
         // 昨日中间价 = (昨高 + 昨低 + 昨收) / 3
         double prevMid = (iHigh(_Symbol, _Period, shift + 1) +
                           iLow(_Symbol, _Period, shift + 1) +
                           iClose(_Symbol, _Period, shift + 1)) / 3.0;
         double high = iHigh(_Symbol, _Period, shift);
         double low  = iLow(_Symbol, _Period, shift);

         sumHigh += MathMax(high - prevMid, 0.0);
         sumLow  += MathMax(prevMid - low, 0.0);
      }

      crBuffer[i] = SafeDivide(100.0 * sumHigh, sumLow, 100.0);

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // --- 第2步：计算四条均线 ---
   for(int i = limit; i >= 1; i--)
   {
      // a均线 = SMA(CR, InpMAa)
      double sa = 0.0, sb = 0.0, sc = 0.0, sd = 0.0;
      for(int j = 0; j < InpMAa; j++) sa += crBuffer[i + j];
      for(int j = 0; j < InpMAb; j++) sb += crBuffer[i + j];
      for(int j = 0; j < InpMAc; j++) sc += crBuffer[i + j];
      for(int j = 0; j < InpMAd; j++) sd += crBuffer[i + j];

      maA[i] = sa / InpMAa;
      maB[i] = sb / InpMAb;
      maC[i] = sc / InpMAc;
      maD[i] = sd / InpMAd;
   }

   // --- 第3步：信号判断（bar[1]+，CR上穿多条均线确认强度）---
   for(int i = limit; i >= 1; i--)
   {
      // 统计CR上穿几条均线
      int upCross = 0;
      if(crBuffer[i + 1] <= maA[i + 1] && crBuffer[i] > maA[i]) upCross++;
      if(crBuffer[i + 1] <= maB[i + 1] && crBuffer[i] > maB[i]) upCross++;
      if(crBuffer[i + 1] <= maC[i + 1] && crBuffer[i] > maC[i]) upCross++;
      if(crBuffer[i + 1] <= maD[i + 1] && crBuffer[i] > maD[i]) upCross++;

      // CR上穿2条以上均线 → 买入
      if(upCross >= 2)
         buySignal[i] = crBuffer[i] * 0.9;

      // 统计CR下穿几条均线
      int dnCross = 0;
      if(crBuffer[i + 1] >= maA[i + 1] && crBuffer[i] < maA[i]) dnCross++;
      if(crBuffer[i + 1] >= maB[i + 1] && crBuffer[i] < maB[i]) dnCross++;
      if(crBuffer[i + 1] >= maC[i + 1] && crBuffer[i] < maC[i]) dnCross++;
      if(crBuffer[i + 1] >= maD[i + 1] && crBuffer[i] < maD[i]) dnCross++;

      if(dnCross >= 2)
         sellSignal[i] = crBuffer[i] * 1.1;
   }

   // --- 第4步：刷新 bar[0] ---
   if(Bars > 0)
   {
      double sH0 = 0.0, sL0 = 0.0;
      for(int j = 0; j < InpCRPeriod; j++)
      {
         double pm = (iHigh(_Symbol, _Period, j + 1) + iLow(_Symbol, _Period, j + 1) + iClose(_Symbol, _Period, j + 1)) / 3.0;
         sH0 += MathMax(iHigh(_Symbol, _Period, j) - pm, 0.0);
         sL0 += MathMax(pm - iLow(_Symbol, _Period, j), 0.0);
      }
      crBuffer[0] = SafeDivide(100.0 * sH0, sL0, 100.0);
      maA[0] = maA[1]; maB[0] = maB[1]; maC[0] = maC[1]; maD[0] = maD[1];
      buySignal[0]  = EMPTY_VALUE;
      sellSignal[0] = EMPTY_VALUE;
   }

   return(0);
}
//+------------------------------------------------------------------+
