//+------------------------------------------------------------------+
//|                                            Alligator_Safe.mq4     |
//|  鳄鱼线指标（Alligator）— 不含未来函数                              |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明（基于 SMMA of Median Price）：                           |
//|  中位价 = (High + Low) / 2                                         |
//|  Jaw(蓝线/鳄鱼下巴)  = SMMA(Median, 13), shift 8                   |
//|  Teeth(红线/鳄鱼牙齿) = SMMA(Median, 8), shift 5                   |
//|  Lips(绿线/鳄鱼嘴唇)  = SMMA(Median, 5), shift 3                   |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：Lips上穿Teeth，且Lips上穿Jaw（三线发散向上, bar[1]确认） |
//|  - 卖出：Lips下穿Teeth，且Lips下穿Jaw（三线发散向下, bar[1]确认） |
//|  - 鳄鱼沉睡→苏醒：价格突破鳄鱼线                                  |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 7

// 输入参数
input int InpJawPeriod   = 13;   // 下巴周期(SMMA)
input int InpJawShift    = 8;    // 下巴前移
input int InpTeethPeriod = 8;    // 牙周期(SMMA)
input int InpTeethShift  = 5;    // 牙前移
input int InpLipsPeriod  = 5;    // 唇周期(SMMA)
input int InpLipsShift   = 3;    // 唇前移
input color InpJawColor   = clrDodgerBlue;  // 下巴颜色
input color InpTeethColor = clrRed;          // 牙齿颜色
input color InpLipsColor  = clrLimeGreen;    // 嘴唇颜色

// 指标缓冲区
double jawBuffer[];       // 下巴（蓝线）- 最慢
double teethBuffer[];     // 牙齿（红线）- 中速
double lipsBuffer[];      // 嘴唇（绿线）- 最快
double buySignal[];
double sellSignal[];
double strongBuy[];
double strongSell[];

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, InpJawColor);
   SetIndexBuffer(0, jawBuffer);
   SetIndexEmptyValue(0, EMPTY_VALUE);
   SetIndexLabel(0, "Alligator Jaw");

   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 2, InpTeethColor);
   SetIndexBuffer(1, teethBuffer);
   SetIndexEmptyValue(1, EMPTY_VALUE);
   SetIndexLabel(1, "Alligator Teeth");

   SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 2, InpLipsColor);
   SetIndexBuffer(2, lipsBuffer);
   SetIndexEmptyValue(2, EMPTY_VALUE);
   SetIndexLabel(2, "Alligator Lips");

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
   IndicatorShortName("Alligator_Safe(" + IntegerToString(InpJawPeriod) + "," +
                      IntegerToString(InpTeethPeriod) + "," + IntegerToString(InpLipsPeriod) + ")");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
//| SMMA计算（平滑移动平均）                                          |
//+------------------------------------------------------------------+
double CalcSMMA(double &prices[], int period, int startIdx)
{
   // 初始SMA
   double smma = 0.0;
   for(int i = startIdx; i < startIdx + period; i++)
      smma += prices[i];
   smma /= period;

   // 递推SMMA
   for(int i = startIdx - 1; i >= 0; i--)
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

   // 先初始化为空
   for(int i = limit + InpJawShift; i >= -InpJawShift; i--)
   {
      if(i >= 0)
      {
         jawBuffer[i]   = 0.0;
         teethBuffer[i] = 0.0;
         lipsBuffer[i]  = 0.0;
         buySignal[i]   = EMPTY_VALUE;
         sellSignal[i]  = EMPTY_VALUE;
         strongBuy[i]   = EMPTY_VALUE;
         strongSell[i]  = EMPTY_VALUE;
      }
   }

   for(int i = limit; i >= 0; i--)
   {
      // 构建中位价数组
      int maxPeriod = InpJawPeriod + InpJawShift;
      int arraySize = maxPeriod * 3;
      double medianPrices[];
      ArrayResize(medianPrices, arraySize);
      for(int j = 0; j < arraySize; j++)
         medianPrices[j] = (iHigh(_Symbol, _Period, i + j) + iLow(_Symbol, _Period, i + j)) / 2.0;

      // Jaw = SMMA(Median, 13) 前移8
      jawBuffer[i] = CalcSMMA(medianPrices, InpJawPeriod, InpJawShift);

      // Teeth = SMMA(Median, 8) 前移5
      teethBuffer[i] = CalcSMMA(medianPrices, InpTeethPeriod, InpTeethShift);

      // Lips = SMMA(Median, 5) 前移3
      lipsBuffer[i] = CalcSMMA(medianPrices, InpLipsPeriod, InpLipsShift);
   }

   // 信号判断（bar[1]+确认）— 增强分级
   for(int i = limit; i >= 1; i--)
   {
      double jaw_i    = jawBuffer[i];
      double jaw_i1   = jawBuffer[i + 1];
      double teeth_i  = teethBuffer[i];
      double teeth_i1 = teethBuffer[i + 1];
      double lips_i   = lipsBuffer[i];
      double lips_i1  = lipsBuffer[i + 1];
      double close_i  = iClose(_Symbol, _Period, i);
      double close_i1 = iClose(_Symbol, _Period, i + 1);

      // === 鳄鱼苏醒信号 ===
      bool wasSleeping = (MathAbs(lips_i1 - jaw_i1) < MathAbs(lips_i - jaw_i) * 0.5);
      bool isAwakeUp   = (lips_i > teeth_i && teeth_i > jaw_i);
      bool isAwakeDown = (lips_i < teeth_i && teeth_i < jaw_i);
      bool lipsCrossUpTeeth   = (lips_i1 <= teeth_i1 && lips_i > teeth_i);
      bool lipsCrossDownTeeth = (lips_i1 >= teeth_i1 && lips_i < teeth_i);
      bool lipsCrossUpJaw     = (lips_i1 <= jaw_i1 && lips_i > jaw_i);
      bool lipsCrossDownJaw   = (lips_i1 >= jaw_i1 && lips_i < jaw_i);

      // 强买：沉睡后苏醒 + 向上张嘴 + 价格突破
      if(wasSleeping && isAwakeUp && close_i > lips_i && close_i > teeth_i)
         strongBuy[i] = iLow(_Symbol, _Period, i) - 12.0 * _Point;

      // 强卖：沉睡后苏醒 + 向下张嘴 + 价格突破
      if(wasSleeping && isAwakeDown && close_i < lips_i && close_i < teeth_i)
         strongSell[i] = iHigh(_Symbol, _Period, i) + 12.0 * _Point;

      // 普通买：Lips 上穿 Teeth
      if(lipsCrossUpTeeth && lips_i > jaw_i)
         buySignal[i] = iLow(_Symbol, _Period, i) - 10.0 * _Point;

      // 普通卖：Lips 下穿 Teeth
      if(lipsCrossDownTeeth && lips_i < jaw_i)
         sellSignal[i] = iHigh(_Symbol, _Period, i) + 10.0 * _Point;
   }

   return(0);
}
//+------------------------------------------------------------------+
