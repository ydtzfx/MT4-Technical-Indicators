//+------------------------------------------------------------------+
//|                                                    CCI_Safe.mq4   |
//|  商品通道指数 — 不含未来函数                                      |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  TP = (High + Low + Close) / 3                                    |
//|  CCI = (TP - SMA(TP, N)) / (0.015 * MeanDeviation)                |
//|  MeanDeviation = Σ|TP_i - SMA(TP)| / N                            |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：CCI从-100下方回升突破确认(bar[1])                         |
//|  - 卖出：CCI从+100上方回落跌破确认(bar[1])                         |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_level1 100
#property indicator_level2 -100

// 输入参数
input int InpCCIPeriod = 14;   // CCI周期
input color InpCCIColor = clrDodgerBlue;

// 指标缓冲区
double cciBuffer[];
double buySignal[];
double sellSignal[];
double strongBuy[];
double strongSell[];

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, InpCCIColor);
   SetIndexBuffer(0, cciBuffer);
   SetIndexLabel(0, "CCI");

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

   IndicatorDigits(2);
   IndicatorShortName("CCI_Safe(" + IntegerToString(InpCCIPeriod) + ")");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;
   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - InpCCIPeriod * 3;
   if(limit < 0) limit = 0;

   for(int i = limit; i >= 0; i--)
   {
      // 计算典型价和SMA
      double tp[];
      ArrayResize(tp, InpCCIPeriod);
      double sum = 0.0;
      for(int j = 0; j < InpCCIPeriod; j++)
      {
         tp[j] = (iHigh(_Symbol, _Period, i + j) +
                  iLow(_Symbol, _Period, i + j) +
                  iClose(_Symbol, _Period, i + j)) / 3.0;
         sum += tp[j];
      }
      double smaTP = sum / InpCCIPeriod;

      // Mean Deviation
      double meanDev = 0.0;
      for(int j = 0; j < InpCCIPeriod; j++)
         meanDev += MathAbs(tp[j] - smaTP);
      meanDev /= InpCCIPeriod;

      // CCI
      double tpCurr = (iHigh(_Symbol, _Period, i) + iLow(_Symbol, _Period, i) + iClose(_Symbol, _Period, i)) / 3.0;
      if(MathAbs(meanDev) < 0.00000001)
         cciBuffer[i] = 0.0;
      else
         cciBuffer[i] = (tpCurr - smaTP) / (0.015 * meanDev);

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // 信号（bar[1]+确认）— 增强分级
   for(int i = limit; i >= 1; i--)
   {
      bool exitDeepOS  = (cciBuffer[i+1] <= -200 && cciBuffer[i] > -200);
      bool exitOS      = (cciBuffer[i+1] <= -100 && cciBuffer[i] > -100);
      bool exitOB      = (cciBuffer[i+1] >= 100 && cciBuffer[i] < 100);
      bool exitDeepOB  = (cciBuffer[i+1] >= 200 && cciBuffer[i] < 200);
      bool cciRising   = (cciBuffer[i] > cciBuffer[i+1]);
      bool cciFalling  = (cciBuffer[i] < cciBuffer[i+1]);

      // 强买：深度超卖(-200)回升 + CCI加速
      if(exitDeepOS && cciRising) strongBuy[i] = MathMin(cciBuffer[i] - 15, -210);
      // 普通买：超卖(-100)回升
      else if(exitOS && cciRising) buySignal[i] = MathMin(cciBuffer[i] - 10, -110);

      // 强卖：深度超买(200)回落 + CCI加速
      if(exitDeepOB && cciFalling) strongSell[i] = MathMax(cciBuffer[i] + 15, 210);
      // 普通卖：超买(100)回落
      else if(exitOB && cciFalling) sellSignal[i] = MathMax(cciBuffer[i] + 10, 110);
   }

   return(0);
}
//+------------------------------------------------------------------+
