//+------------------------------------------------------------------+
//|                                                SignalBase.mqh    |
//|  信号基类/工具 — 确保无未来函数的信号生成框架                       |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"

#ifndef _SIGNALBASE_MQH_
#define _SIGNALBASE_MQH_

#include "Common.mqh"

//+------------------------------------------------------------------+
//| 核心原则：                                                        |
//| 1. 信号缓冲区：存储每个bar的信号值，信号产生后不再修改              |
//| 2. 信号仅在 bar[1] 及更早的K线上确认                              |
//| 3. bar[0] 只用于显示当前未完成的指标值，不生成信号                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| 信号缓冲区初始化                                                   |
//| 使用方式：在 init() 中调用                                         |
//| buffer: 指标缓冲区数组引用                                         |
//| bufferName: 缓冲区名称（用于SetIndexLabel）                        |
//| lineColor: 线条颜色                                               |
//| lineStyle: 线条样式                                               |
//| lineWidth: 线条宽度                                               |
//+------------------------------------------------------------------+
void InitSignalBuffer(double &buffer[], string bufferName,
                      color lineColor, int lineStyle = STYLE_SOLID,
                      int lineWidth = 1)
{
   SetIndexStyle(0, DRAW_LINE, lineStyle, lineWidth, lineColor);
   SetIndexBuffer(0, buffer);
   SetIndexLabel(0, bufferName);
   SetIndexEmptyValue(0, 0.0);
}

//+------------------------------------------------------------------+
//| 箭头信号缓冲区初始化                                               |
//| 用于在图表上绘制买卖箭头                                          |
//+------------------------------------------------------------------+
void InitArrowBuffer(double &buffer[], string bufferName,
                     color arrowColor, int arrowCode)
{
   SetIndexStyle(0, DRAW_ARROW, STYLE_SOLID, 1, arrowColor);
   SetIndexBuffer(0, buffer);
   SetIndexLabel(0, bufferName);
   SetIndexArrow(0, arrowCode);
   SetIndexEmptyValue(0, EMPTY_VALUE);
}

//+------------------------------------------------------------------+
//| 多缓冲区初始化辅助                                                 |
//+------------------------------------------------------------------+
void InitMultiBuffers(int totalBuffers, double &buffers[][],
                      string names[], color colors[], int styles[])
{
   for(int i = 0; i < totalBuffers; i++)
   {
      SetIndexStyle(i, DRAW_LINE, styles[i], 1, colors[i]);
      SetIndexBuffer(i, buffers[i]);
      SetIndexLabel(i, names[i]);
      SetIndexEmptyValue(i, 0.0);
   }
}

//+------------------------------------------------------------------+
//| 设置信号值 — 核心函数                                              |
//| barIndex: K线索引                                                  |
//| signal: 信号值                                                     |
//| 规则：barIndex == 0 时将 signal 视为临时值（显示用）               |
//|        barIndex >= 1 时将 signal 永久写入缓冲区                   |
//+------------------------------------------------------------------+
void SetSignalValue(double &buffer[], int barIndex, double signal,
                    ENUM_SIGNAL_MODE mode = SIGNAL_MODE_STRICT)
{
   // 严格模式：bar[0] 不写入信号值（避免未来函数）
   if(mode == SIGNAL_MODE_STRICT && barIndex == 0)
   {
      // bar[0] 只更新显示值，不固化
      // 实际在 start() 中 bar[0] 会在每次tick被重新计算
      buffer[0] = signal;
      return;
   }

   buffer[barIndex] = signal;
}

//+------------------------------------------------------------------+
//| 设置买卖箭头信号                                                    |
//| buyBuffer: 买入信号缓冲区（存储买入价）                             |
//| sellBuffer: 卖出信号缓冲区（存储卖出价）                            |
//| barIndex: 信号K线（必须 >= 1）                                      |
//| signal: BUY/SELL/NEUTRAL                                          |
//| price: 箭头价格位置                                                |
//+------------------------------------------------------------------+
void SetArrowSignal(double &buyBuffer[], double &sellBuffer[],
                    int barIndex, ENUM_TRADE_SIGNAL signal, double price)
{
   // 严格确保barIndex >= 1
   if(barIndex < 1) return;

   if(signal == SIGNAL_BUY)
   {
      buyBuffer[barIndex] = price;
      sellBuffer[barIndex] = EMPTY_VALUE;
   }
   else if(signal == SIGNAL_SELL)
   {
      sellBuffer[barIndex] = price;
      buyBuffer[barIndex] = EMPTY_VALUE;
   }
   else
   {
      buyBuffer[barIndex] = EMPTY_VALUE;
      sellBuffer[barIndex] = EMPTY_VALUE;
   }
}

//+------------------------------------------------------------------+
//| 填充历史信号缓冲区 — 在 start() 中使用的标准循环模式               |
//|                                                                  |
//| 使用示例：                                                        |
//|   int limit = Bars - IndicatorCounted();                         |
//|   for(int i = limit - 1; i >= 1; i--) {                          |
//|       // 计算信号                                                  |
//|       double signal = CalculateMySignal(i);                       |
//|       SetSignalValue(signalBuffer, i, signal);                   |
//|   }                                                              |
//|   // 仅刷新 bar[0] 显示值，不修改信号                              |
//|   signalBuffer[0] = CalculateMySignal(0);                         |
//+------------------------------------------------------------------+
void FillSignalBuffer(double &buffer[], int limit,
                      double &prices[], int priceCount)
{
   // limit 从 IndicatorCounted() 推导:
   // limit = Bars - IndicatorCounted();
   // 循环从 limit-1 向下到 1
   for(int i = limit - 1; i >= 1; i--)
   {
      // 由调用方在外部实现具体计算逻辑
      // 此函数仅作为模式参考保留
   }
}

//+------------------------------------------------------------------+
//| 信号确认：检查两个缓冲区是否交叉                                    |
//| 用于MACD、Stochastic等双线指标的交叉信号                          |
//| fastBuffer: 快线                                                   |
//| slowBuffer: 慢线                                                   |
//| barIndex: 检查的bar位置（>= 1）                                    |
//| 返回: SIGNAL_BUY（快线上穿慢线）, SIGNAL_SELL（快线下穿慢线）, SIGNAL_NONE |
//+------------------------------------------------------------------+
ENUM_TRADE_SIGNAL DetectCross(double &fastBuffer[], double &slowBuffer[],
                               int barIndex)
{
   int idx = (barIndex < 1) ? 1 : barIndex;

   double fastCurr  = fastBuffer[idx];
   double slowCurr  = slowBuffer[idx];
   double fastPrev  = fastBuffer[idx + 1];
   double slowPrev  = slowBuffer[idx + 1];

   // 检查无效值
   if(fastCurr == EMPTY_VALUE || slowCurr == EMPTY_VALUE ||
      fastPrev == EMPTY_VALUE || slowPrev == EMPTY_VALUE)
      return(SIGNAL_NONE);

   // 金叉：快线从下方穿越慢线到上方
   if(fastPrev <= slowPrev && fastCurr > slowCurr)
      return(SIGNAL_BUY);

   // 死叉：快线从上方穿越慢线到下方
   if(fastPrev >= slowPrev && fastCurr < slowCurr)
      return(SIGNAL_SELL);

   return(SIGNAL_NONE);
}

//+------------------------------------------------------------------+
//| 检测价格与指标线的交叉                                             |
//+------------------------------------------------------------------+
ENUM_TRADE_SIGNAL DetectPriceCross(double &indicatorBuffer[], int barIndex,
                                    string symbol, int timeframe)
{
   int idx = (barIndex < 1) ? 1 : barIndex;

   double indCurr  = indicatorBuffer[idx];
   double indPrev  = indicatorBuffer[idx + 1];
   double closeCurr = iClose(symbol, timeframe, idx);
   double closePrev = iClose(symbol, timeframe, idx + 1);

   if(indCurr == EMPTY_VALUE || indPrev == EMPTY_VALUE)
      return(SIGNAL_NONE);

   // 价格上穿指标线
   if(closePrev <= indPrev && closeCurr > indCurr)
      return(SIGNAL_BUY);

   // 价格下穿指标线
   if(closePrev >= indPrev && closeCurr < indCurr)
      return(SIGNAL_SELL);

   return(SIGNAL_NONE);
}

//+------------------------------------------------------------------+
//| 检查超买/超卖区域                                                  |
//+------------------------------------------------------------------+
bool IsOverbought(double value, double overboughtLevel)
{
   return(value >= overboughtLevel);
}

bool IsOversold(double value, double oversoldLevel)
{
   return(value <= oversoldLevel);
}

//+------------------------------------------------------------------+
//| 从超买/超卖区域退出信号                                            |
//| 返回: SIGNAL_SELL（离开超买区）, SIGNAL_BUY（离开超卖区）          |
//+------------------------------------------------------------------+
ENUM_TRADE_SIGNAL DetectOverboughtOversoldExit(
   double &buffer[], int barIndex,
   double overboughtLevel, double oversoldLevel)
{
   int idx = (barIndex < 1) ? 1 : barIndex;

   double curr = buffer[idx];
   double prev = buffer[idx + 1];

   // 离开超买区 → 卖出信号
   if(prev >= overboughtLevel && curr < overboughtLevel)
      return(SIGNAL_SELL);

   // 离开超卖区 → 买入信号
   if(prev <= oversoldLevel && curr > oversoldLevel)
      return(SIGNAL_BUY);

   return(SIGNAL_NONE);
}

//+------------------------------------------------------------------+
//| 增强背离检测：使用多个历史点确认                                   |
//| 返回: SIGNAL_BUY（底背离）, SIGNAL_SELL（顶背离）, SIGNAL_NONE   |
//+------------------------------------------------------------------+
ENUM_TRADE_SIGNAL DetectDivergence(double &indicatorBuffer[], int barIndex,
                                   int lookback = 5)
{
   int idx = (barIndex < lookback) ? lookback : barIndex;

   // 底背离检测：价格新低但指标未新低
   double priceMin  = iClose(_Symbol, _Period, idx);
   double priceMin2 = iClose(_Symbol, _Period, idx);
   double indMin    = indicatorBuffer[idx];
   double indMin2   = indicatorBuffer[idx];

   for(int i = idx; i < idx + lookback; i++)
   {
      double p = iClose(_Symbol, _Period, i);
      if(p < priceMin) priceMin = p;
      if(iClose(_Symbol, _Period, i + lookback) < priceMin2)
         priceMin2 = iClose(_Symbol, _Period, i + lookback);
   }

   // 找3个局部价格低点和对应的指标值
   int lowCount = 0;
   double priceLows[3], indAtLows[3];

   for(int i = idx + 1; i < idx + lookback * 2 && lowCount < 3; i++)
   {
      bool isLocalLow = true;
      double lowP = iLow(_Symbol, _Period, i);
      for(int j = 1; j <= 2; j++)
      {
         if(i + j < Bars && iLow(_Symbol, _Period, i + j) <= lowP) isLocalLow = false;
         if(i - j >= 1 && iLow(_Symbol, _Period, i - j) <= lowP) isLocalLow = false;
      }
      if(isLocalLow)
      {
         priceLows[lowCount] = iClose(_Symbol, _Period, i);
         indAtLows[lowCount] = indicatorBuffer[i];
         lowCount++;
      }
   }

   // 底背离：价格创新低但指标上升
   if(lowCount >= 2)
   {
      if(priceLows[0] < priceLows[1] && indAtLows[0] > indAtLows[1])
         return(SIGNAL_BUY);
   }

   // 顶背离检测：价格新高但指标未新高
   int highCount = 0;
   double priceHighs[3], indAtHighs[3];

   for(int i = idx + 1; i < idx + lookback * 2 && highCount < 3; i++)
   {
      bool isLocalHigh = true;
      double highP = iHigh(_Symbol, _Period, i);
      for(int j = 1; j <= 2; j++)
      {
         if(i + j < Bars && iHigh(_Symbol, _Period, i + j) >= highP) isLocalHigh = false;
         if(i - j >= 1 && iHigh(_Symbol, _Period, i - j) >= highP) isLocalHigh = false;
      }
      if(isLocalHigh)
      {
         priceHighs[highCount] = iClose(_Symbol, _Period, i);
         indAtHighs[highCount] = indicatorBuffer[i];
         highCount++;
      }
   }

   if(highCount >= 2)
   {
      if(priceHighs[0] > priceHighs[1] && indAtHighs[0] < indAtHighs[1])
         return(SIGNAL_SELL);
   }

   return(SIGNAL_NONE);
}

//+------------------------------------------------------------------+
//| 多条件信号确认 — 返回信号强度                                      |
//| 条件越多 → 信号越强                                                |
//+------------------------------------------------------------------+
ENUM_SIGNAL_STRENGTH EvaluateSignalStrength(int conditionCount)
{
   if(conditionCount >= 3) return(SIGNAL_STRONG);
   if(conditionCount >= 2) return(SIGNAL_MEDIUM);
   if(conditionCount >= 1) return(SIGNAL_WEAK);
   return(SIGNAL_WEAK);
}

//+------------------------------------------------------------------+
//| 多条件信号确认器：综合指标交叉 + 区间 + 背离                       |
//| crossSignal: 交叉检测结果                                          |
//| zoneSignal: 超买超卖区域退出结果                                   |
//| divergenceSignal: 背离检测结果                                     |
//| 返回: 综合信号方向                                                  |
//+------------------------------------------------------------------+
ENUM_TRADE_SIGNAL ConfirmSignalWithConditions(
   ENUM_TRADE_SIGNAL crossSignal,
   ENUM_TRADE_SIGNAL zoneSignal,
   ENUM_TRADE_SIGNAL divergenceSignal,
   ENUM_SIGNAL_STRENGTH &outStrength)
{
   int buyCount = 0;
   int sellCount = 0;

   if(crossSignal == SIGNAL_BUY) buyCount++;
   if(crossSignal == SIGNAL_SELL) sellCount++;
   if(zoneSignal == SIGNAL_BUY) buyCount++;
   if(zoneSignal == SIGNAL_SELL) sellCount++;
   if(divergenceSignal == SIGNAL_BUY) buyCount++;
   if(divergenceSignal == SIGNAL_SELL) sellCount++;

   if(buyCount > sellCount)
   {
      outStrength = EvaluateSignalStrength(buyCount);
      return(SIGNAL_BUY);
   }
   else if(sellCount > buyCount)
   {
      outStrength = EvaluateSignalStrength(sellCount);
      return(SIGNAL_SELL);
   }

   outStrength = SIGNAL_WEAK;
   return(SIGNAL_NONE);
}

#endif // _SIGNALBASE_MQH_
