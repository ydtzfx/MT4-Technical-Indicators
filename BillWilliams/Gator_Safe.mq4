//+------------------------------------------------------------------+
//|                                               Gator_Safe.mq4      |
//|  鳄鱼震荡器 — 不含未来函数                                        |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  Gator = |Jaw - Teeth| (上行柱) + |Lips - Teeth| (下行柱)          |
//|  上柱 = Lips - Teeth（当所有线都计算后）                           |
//|  下柱 = -(Jaw - Teeth)（当所有线都计算后）                         |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 鳄鱼沉睡期：上下柱都短（鳄鱼嘴闭合）                            |
//|  - 鳄鱼苏醒：柱体开始变长，上下柱交替颜色                          |
//|  - 信号仅在bar[1]+确认                                            |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5

// 输入参数
input int InpJawPeriod   = 13;   // 下巴周期
input int InpJawShift    = 8;    // 下巴前移
input int InpTeethPeriod = 8;    // 牙齿周期
input int InpTeethShift  = 5;    // 牙齿前移
input int InpLipsPeriod  = 5;    // 嘴唇周期
input int InpLipsShift   = 3;    // 嘴唇前移

// 指标缓冲区
double upBarBuffer[];     // 上行柱（Lips - Teeth）
double downBarBuffer[];   // 下行柱（-(Jaw - Teeth)）
double buySignal[];
double sellSignal[];

// 内部计算的缓冲区
double jawBuffer[];
double teethBuffer[];
double lipsBuffer[];

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_HISTOGRAM, STYLE_SOLID, 2, clrLimeGreen);
   SetIndexBuffer(0, upBarBuffer);
   SetIndexLabel(0, "Gator Up");

   SetIndexStyle(1, DRAW_HISTOGRAM, STYLE_SOLID, 2, clrTomato);
   SetIndexBuffer(1, downBarBuffer);
   SetIndexLabel(1, "Gator Down");

   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(2, buySignal);
   SetIndexArrow(2, ARROW_BUY);
   SetIndexEmptyValue(2, EMPTY_VALUE);

   SetIndexStyle(3, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(3, sellSignal);
   SetIndexArrow(3, ARROW_SELL);
   SetIndexEmptyValue(3, EMPTY_VALUE);

   // 内部缓冲区
   SetIndexBuffer(4, jawBuffer);
   SetIndexLabel(4, "Jaw (hidden)");

   IndicatorDigits(4);
   IndicatorShortName("Gator_Safe");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
double CalcSMMA(double &prices[], int period, int shift)
{
   double smma = 0.0;
   int start = shift;
   for(int i = start; i < start + period; i++)
      smma += prices[i];
   smma /= period;
   for(int i = start - 1; i >= 0; i--)
      smma = (prices[i] + smma * (period - 1.0)) / period;
   return(smma);
}

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;
   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - InpJawPeriod * 3;
   if(limit < 0) limit = 0;

   int maxShift = InpJawPeriod + InpJawShift;

   for(int i = limit; i >= 0; i--)
   {
      int arrSize = maxShift * 2;
      double median[];
      ArrayResize(median, arrSize);
      for(int j = 0; j < arrSize; j++)
         median[j] = (iHigh(_Symbol, _Period, i + j) + iLow(_Symbol, _Period, i + j)) / 2.0;

      jawBuffer[i]   = CalcSMMA(median, InpJawPeriod, InpJawShift);
      teethBuffer[i] = CalcSMMA(median, InpTeethPeriod, InpTeethShift);
      lipsBuffer[i]  = CalcSMMA(median, InpLipsPeriod, InpLipsShift);

      double diffLipsTeeth   = lipsBuffer[i] - teethBuffer[i];
      double diffJawTeeth    = -(jawBuffer[i] - teethBuffer[i]);

      // 上柱：Lips - Teeth (正值在零轴上，负值在零轴下)
      upBarBuffer[i] = diffLipsTeeth;

      // 下柱：-(Jaw - Teeth)
      downBarBuffer[i] = diffJawTeeth;

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // 信号：鳄鱼苏醒检测（bar[1]+）
   for(int i = limit; i >= 2; i--)
   {
      double prevUpHeight = MathAbs(upBarBuffer[i+1]);
      double currUpHeight = MathAbs(upBarBuffer[i]);

      // 柱体急速增长 = 鳄鱼苏醒
      if(prevUpHeight < Point * 3 && currUpHeight >= Point * 5)
      {
         if(upBarBuffer[i] > 0)
            buySignal[i] = downBarBuffer[i] * 0.5;
         else
            sellSignal[i] = downBarBuffer[i] * 1.5;
      }
   }

   return(0);
}
//+------------------------------------------------------------------+
