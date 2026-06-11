//+------------------------------------------------------------------+
//|                                          ParabolicSAR_Safe.mq4    |
//|  抛物线SAR指标 — 不含未来函数                                     |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明（递推公式）：                                            |
//|  SAR_today = SAR_yesterday + AF * (EP - SAR_yesterday)            |
//|  AF(加速因子) 起始值 = Step, 每次创新高/新低增加Step, 上限=Max    |
//|  EP(极点) = 趋势中的最高价(多头)或最低价(空头)                     |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：SAR从价格上方翻转到下方（趋势转多, bar[1]确认）           |
//|  - 卖出：SAR从价格下方翻转到上方（趋势转空, bar[1]确认）           |
//|  - SAR本身是滞后的，天然不含未来函数，但需确认反转后才发出信号     |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 3

// 输入参数
input double InpStep     = 0.02;   // 步长(AF起始)
input double InpMaximum  = 0.2;    // 最大AF值
input color  InpSARColor = clrOrangeRed;  // SAR颜色
input int    InpSARWidth = 2;      // SAR宽度

// 指标缓冲区
double sarBuffer[];
double buySignal[];
double sellSignal[];

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_ARROW, STYLE_SOLID, InpSARWidth, InpSARColor);
   SetIndexBuffer(0, sarBuffer);
   SetIndexLabel(0, "Parabolic SAR");
   SetIndexArrow(0, ARROW_DOT);
   SetIndexEmptyValue(0, EMPTY_VALUE);

   SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(1, buySignal);
   SetIndexArrow(1, ARROW_BUY);
   SetIndexEmptyValue(1, EMPTY_VALUE);

   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(2, sellSignal);
   SetIndexArrow(2, ARROW_SELL);
   SetIndexEmptyValue(2, EMPTY_VALUE);

   IndicatorDigits(4);
   IndicatorShortName("SAR_Safe(" + DoubleToStr(InpStep,2) + "," + DoubleToStr(InpMaximum,2) + ")");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;

   // SAR需要从最初开始递推，但可以用已计算部分优化
   int startBar = Bars - 2;
   if(startBar < 0) startBar = 0;

   // 从最久远的bar开始递推计算SAR
   // 先找到初始趋势（用前几根K线判断）
   double sar = 0;
   double ep = 0;
   double af = InpStep;
   bool isLong = true;  // 初始假设多头

   // 简化：使用前一根K线的高/低来确定初始方向
   double initHigh1 = iHigh(_Symbol, _Period, startBar);
   double initHigh2 = iHigh(_Symbol, _Period, startBar + 1);
   double initLow1  = iLow(_Symbol, _Period, startBar);
   double initLow2  = iLow(_Symbol, _Period, startBar + 1);

   if(initHigh2 > initHigh1 && initLow2 > initLow1)
   {
      isLong = true;
      sar = initLow2;
      ep = initHigh2;
   }
   else if(initLow2 < initLow1 && initHigh2 < initHigh1)
   {
      isLong = false;
      sar = initHigh2;
      ep = initLow2;
   }
   else
   {
      // 默认多头
      isLong = true;
      sar = initLow2;
      ep = initHigh2;
   }

   for(int i = startBar; i >= 0; i--)
   {
      double high_i = iHigh(_Symbol, _Period, i);
      double low_i  = iLow(_Symbol, _Period, i);

      if(isLong)
      {
         // 多头趋势中计算SAR
         sar = sar + af * (ep - sar);

         // SAR不能高于前两日的最低价
         double prevLow1 = iLow(_Symbol, _Period, i + 1);
         double prevLow2 = iLow(_Symbol, _Period, i + 2);
         if(sar > prevLow1) sar = prevLow1;
         if(sar > prevLow2) sar = prevLow2;

         sarBuffer[i] = sar;

         // 更新EP
         if(high_i > ep)
         {
            ep = high_i;
            af = MathMin(af + InpStep, InpMaximum);
         }

         // 检查反转：价格跌破SAR → 转为空头
         if(low_i < sar)
         {
            isLong = false;
            sar = ep;       // 新SAR = 之前多头趋势的极点
            ep = low_i;     // 新极点 = 当前最低价
            af = InpStep;   // 重置AF
         }
      }
      else
      {
         // 空头趋势中计算SAR
         sar = sar + af * (ep - sar);  // 注意：af*(ep-sar) 当ep<sar时为负

         // SAR不能低于前两日的最高价
         double prevHigh1 = iHigh(_Symbol, _Period, i + 1);
         double prevHigh2 = iHigh(_Symbol, _Period, i + 2);
         if(sar < prevHigh1) sar = prevHigh1;
         if(sar < prevHigh2) sar = prevHigh2;

         sarBuffer[i] = sar;

         // 更新EP
         if(low_i < ep)
         {
            ep = low_i;
            af = MathMin(af + InpStep, InpMaximum);
         }

         // 检查反转：价格突破SAR → 转为多头
         if(high_i > sar)
         {
            isLong = true;
            sar = ep;       // 新SAR = 之前空头趋势的极点
            ep = high_i;    // 新极点 = 当前最高价
            af = InpStep;   // 重置AF
         }
      }

      // 信号（bar[1]+确认反转）
      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // 信号判断：SAR与价格的相对位置变化
   for(int i = limit; i >= 1; i--)
   {
      if(sarBuffer[i] == EMPTY_VALUE || sarBuffer[i+1] == EMPTY_VALUE)
         continue;

      double low_i    = iLow(_Symbol, _Period, i);
      double low_i1   = iLow(_Symbol, _Period, i + 1);
      double high_i   = iHigh(_Symbol, _Period, i);
      double high_i1  = iHigh(_Symbol, _Period, i + 1);

      // SAR 从上方翻转到下方 = 趋势转多
      if(sarBuffer[i+1] > high_i1 && sarBuffer[i] < low_i)
         buySignal[i] = low_i - 5.0 * _Point;

      // SAR 从下方翻转到上方 = 趋势转空
      if(sarBuffer[i+1] < low_i1 && sarBuffer[i] > high_i)
         sellSignal[i] = high_i + 5.0 * _Point;
   }

   return(0);
}
//+------------------------------------------------------------------+
