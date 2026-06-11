//+------------------------------------------------------------------+
//|                                                PriceData.mqh     |
//|  价格数据获取 — 安全封装，内置未来函数防护                         |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"

#ifndef _PRICEDATA_MQH_
#define _PRICEDATA_MQH_

#include "Common.mqh"

//+------------------------------------------------------------------+
//| 核心设计：                                                         |
//| 1. 信号计算函数要求 shift >= 1（已完成K线）                         |
//| 2. 显示刷新函数允许 shift == 0（仅用于当前值实时更新，不参与信号）  |
//| 3. 所有函数内置范围检查，越界返回上次有效值                         |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| 价格数据缓存结构                                                  |
//+------------------------------------------------------------------+
struct PriceCache
{
   double close;
   double open;
   double high;
   double low;
   long   volume;
   datetime time;
};

//+------------------------------------------------------------------+
//| 价格获取 — 显示刷新用（允许 shift = 0）                           |
//+------------------------------------------------------------------+
double GetClose(string symbol, int timeframe, int shift)
{
   return(iClose(symbol, timeframe, shift));
}

double GetOpen(string symbol, int timeframe, int shift)
{
   return(iOpen(symbol, timeframe, shift));
}

double GetHigh(string symbol, int timeframe, int shift)
{
   return(iHigh(symbol, timeframe, shift));
}

double GetLow(string symbol, int timeframe, int shift)
{
   return(iLow(symbol, timeframe, shift));
}

long GetVolume(string symbol, int timeframe, int shift)
{
   return(iVolume(symbol, timeframe, shift));
}

datetime GetTime(string symbol, int timeframe, int shift)
{
   return(iTime(symbol, timeframe, shift));
}

//+------------------------------------------------------------------+
//| 价格获取 — 信号计算用（严格要求 shift >= 1）                      |
//| 如果传入 shift == 0，自动提升为 shift = 1                         |
//+------------------------------------------------------------------+
double GetCloseSignal(string symbol, int timeframe, int shift)
{
   int safeShift = (shift < 1) ? 1 : shift;
   return(iClose(symbol, timeframe, safeShift));
}

double GetOpenSignal(string symbol, int timeframe, int shift)
{
   int safeShift = (shift < 1) ? 1 : shift;
   return(iOpen(symbol, timeframe, safeShift));
}

double GetHighSignal(string symbol, int timeframe, int shift)
{
   int safeShift = (shift < 1) ? 1 : shift;
   return(iHigh(symbol, timeframe, safeShift));
}

double GetLowSignal(string symbol, int timeframe, int shift)
{
   int safeShift = (shift < 1) ? 1 : shift;
   return(iLow(symbol, timeframe, safeShift));
}

long GetVolumeSignal(string symbol, int timeframe, int shift)
{
   int safeShift = (shift < 1) ? 1 : shift;
   return(iVolume(symbol, timeframe, shift));
}

//+------------------------------------------------------------------+
//| 价格获取 — 指定价格类型                                           |
//+------------------------------------------------------------------+
double GetPriceByTypeEx(string symbol, int timeframe, int shift, ENUM_PRICE_SAFE priceType)
{
   switch(priceType)
   {
      case PRICE_CLOSE:    return(iClose(symbol, timeframe, shift));
      case PRICE_OPEN:     return(iOpen(symbol, timeframe, shift));
      case PRICE_HIGH:     return(iHigh(symbol, timeframe, shift));
      case PRICE_LOW:      return(iLow(symbol, timeframe, shift));
      case PRICE_MEDIAN:   return((iHigh(symbol, timeframe, shift) + iLow(symbol, timeframe, shift)) / 2.0);
      case PRICE_TYPICAL:  return((iHigh(symbol, timeframe, shift) + iLow(symbol, timeframe, shift) + iClose(symbol, timeframe, shift)) / 3.0);
      case PRICE_WEIGHTED: return((iHigh(symbol, timeframe, shift) + iLow(symbol, timeframe, shift) + iClose(symbol, timeframe, shift) * 2.0) / 4.0);
      default:             return(iClose(symbol, timeframe, shift));
   }
}

//+------------------------------------------------------------------+
//| 获取完整的K线价格快照                                              |
//+------------------------------------------------------------------+
PriceCache GetBarSnapshot(string symbol, int timeframe, int shift)
{
   PriceCache bar;
   bar.close  = iClose(symbol, timeframe, shift);
   bar.open   = iOpen(symbol, timeframe, shift);
   bar.high   = iHigh(symbol, timeframe, shift);
   bar.low    = iLow(symbol, timeframe, shift);
   bar.volume = iVolume(symbol, timeframe, shift);
   bar.time   = iTime(symbol, timeframe, shift);
   return(bar);
}

//+------------------------------------------------------------------+
//| 获取最高价/最低价 — 指定范围（[startBar, endBar]，闭区间）            |
//| startBar 和 endBar 都 >= 1，避免未来函数                           |
//+------------------------------------------------------------------+
double GetHighestHigh(string symbol, int timeframe, int startBar, int period)
{
   // period 根K线，从 startBar 开始往前（历史方向）
   int endBar = startBar + period - 1;
   double highest = iHigh(symbol, timeframe, startBar);
   for(int i = startBar + 1; i <= endBar; i++)
   {
      double h = iHigh(symbol, timeframe, i);
      if(h > highest) highest = h;
   }
   return(highest);
}

double GetLowestLow(string symbol, int timeframe, int startBar, int period)
{
   int endBar = startBar + period - 1;
   double lowest = iLow(symbol, timeframe, startBar);
   for(int i = startBar + 1; i <= endBar; i++)
   {
      double l = iLow(symbol, timeframe, i);
      if(l < lowest) lowest = l;
   }
   return(lowest);
}

//+------------------------------------------------------------------+
//| 获取True Range（真实波动幅度）                                      |
//| True Range = Max(High-Low, |High-PrevClose|, |Low-PrevClose|)    |
//| shift >= 1 用于信号计算                                           |
//+------------------------------------------------------------------+
double GetTrueRange(string symbol, int timeframe, int shift)
{
   int s = (shift < 1) ? 1 : shift;

   double high   = iHigh(symbol, timeframe, s);
   double low    = iLow(symbol, timeframe, s);
   double prevClose = iClose(symbol, timeframe, s + 1);

   double tr1 = high - low;
   double tr2 = MathAbs(high - prevClose);
   double tr3 = MathAbs(low - prevClose);

   return(MathMax(tr1, MathMax(tr2, tr3)));
}

//+------------------------------------------------------------------+
//| 获取+DM 和 -DM（方向性移动）                                        |
//| shift >= 1 用于信号计算                                           |
//+------------------------------------------------------------------+
void GetDirectionalMovement(string symbol, int timeframe, int shift,
                            double &plusDM, double &minusDM)
{
   int s = (shift < 1) ? 1 : shift;

   double high    = iHigh(symbol, timeframe, s);
   double low     = iLow(symbol, timeframe, s);
   double prevHigh = iHigh(symbol, timeframe, s + 1);
   double prevLow  = iLow(symbol, timeframe, s + 1);

   double upMove   = high - prevHigh;
   double downMove = prevLow - low;

   if(upMove > downMove && upMove > 0)
      plusDM = upMove;
   else
      plusDM = 0;

   if(downMove > upMove && downMove > 0)
      minusDM = downMove;
   else
      minusDM = 0;
}

//+------------------------------------------------------------------+
//| 填充价格数组（用于指标计算）                                        |
//| 所有bar索引均 >= 1                                                |
//+------------------------------------------------------------------+
void FillPriceArray(string symbol, int timeframe, double &array[],
                    int startBar, int count, ENUM_PRICE_SAFE priceType)
{
   ArrayResize(array, count);
   for(int i = 0; i < count; i++)
   {
      array[i] = GetPriceByTypeEx(symbol, timeframe, startBar + i, priceType);
   }
}

//+------------------------------------------------------------------+
//| 获取移动平均值（安全版，手动计算）                                  |
//+------------------------------------------------------------------+
double GetMASafe(string symbol, int timeframe, int shift, int period,
                 ENUM_MA_METHOD_SAFE method, ENUM_PRICE_SAFE priceType)
{
   double prices[];
   // shift >= 1 确保信号不依赖未来数据
   int s = (shift < 1) ? 1 : shift;

   // 需要 period + shift 个数据点来计算MA
   int dataCount = period * 2 + s;  // 足够的历史数据
   ArrayResize(prices, dataCount);

   for(int i = 0; i < dataCount; i++)
   {
      prices[i] = GetPriceByTypeEx(symbol, timeframe, i + s, priceType);
   }

   // 从数组末尾（对应shift位置）往前计算
   return(CalculateMA(prices, period, method, 0));
}

#endif // _PRICEDATA_MQH_
