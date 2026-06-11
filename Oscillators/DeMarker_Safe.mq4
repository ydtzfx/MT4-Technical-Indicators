//+------------------------------------------------------------------+
//|                                               DeMarker_Safe.mq4   |
//|  DeMarker指标 — 不含未来函数                                      |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  DeMax_i = Max(High_i - High_{i-1}, 0)                             |
//|  DeMin_i = Max(Low_{i-1} - Low_i, 0)                               |
//|  DeMarker = SMA(DeMax, N) / (SMA(DeMax, N) + SMA(DeMin, N))       |
//|  取值范围 [0, 1]                                                   |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：DeMarker从0.3下方回升(bar[1]确认)                        |
//|  - 卖出：DeMarker从0.7上方回落(bar[1]确认)                        |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_minimum 0
#property indicator_maximum 1
#property indicator_level1 0.7
#property indicator_level2 0.3

// 输入参数
input int InpDeMPeriod = 14;   // DeMarker周期
input color InpDeMColor = clrDodgerBlue;

// 指标缓冲区
double demBuffer[];
double buySignal[];
double sellSignal[];
double strongBuy[];
double strongSell[];

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, InpDeMColor);
   SetIndexBuffer(0, demBuffer);
   SetIndexLabel(0, "DeMarker");

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

   IndicatorDigits(3);
   IndicatorShortName("DeM_Safe(" + IntegerToString(InpDeMPeriod) + ")");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;
   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - InpDeMPeriod * 3;
   if(limit < 0) limit = 0;

   for(int i = limit; i >= 0; i--)
   {
      double sumDeMax = 0.0;
      double sumDeMin = 0.0;

      for(int j = 0; j < InpDeMPeriod; j++)
      {
         double high_j   = iHigh(_Symbol, _Period, i + j);
         double high_j1  = iHigh(_Symbol, _Period, i + j + 1);
         double low_j    = iLow(_Symbol, _Period, i + j);
         double low_j1   = iLow(_Symbol, _Period, i + j + 1);

         sumDeMax += MathMax(high_j - high_j1, 0.0);
         sumDeMin += MathMax(low_j1 - low_j, 0.0);
      }

      double total = sumDeMax + sumDeMin;
      demBuffer[i] = (MathAbs(total) < 0.00000001) ? 0.5 : sumDeMax / total;

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // 信号（bar[1]+确认）— 增强分级
   for(int i = limit; i >= 1; i--)
   {
      bool exitDeepOS  = (demBuffer[i+1] <= 0.15 && demBuffer[i] > 0.15);
      bool exitOS      = (demBuffer[i+1] <= 0.3  && demBuffer[i] > 0.3);
      bool exitOB      = (demBuffer[i+1] >= 0.7  && demBuffer[i] < 0.7);
      bool exitDeepOB  = (demBuffer[i+1] >= 0.85 && demBuffer[i] < 0.85);
      bool demRising   = (demBuffer[i] > demBuffer[i+1]);
      bool demFalling  = (demBuffer[i] < demBuffer[i+1]);

      // 强买：深度超卖(0.15)回升
      if(exitDeepOS && demRising) strongBuy[i] = 0.10;
      // 普通买：超卖(0.3)回升
      else if(exitOS) buySignal[i] = 0.25;

      // 强卖：深度超买(0.85)回落
      if(exitDeepOB && demFalling) strongSell[i] = 0.90;
      // 普通卖：超买(0.7)回落
      else if(exitOB) sellSignal[i] = 0.75;
   }

   return(0);
}
//+------------------------------------------------------------------+
