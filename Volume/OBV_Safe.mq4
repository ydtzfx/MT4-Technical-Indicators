//+------------------------------------------------------------------+
//|                                                    OBV_Safe.mq4   |
//|  能量潮指标 — 不含未来函数                                        |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  If Close > PrevClose: OBV = PrevOBV + Volume                     |
//|  If Close < PrevClose: OBV = PrevOBV - Volume                     |
//|  If Close = PrevClose: OBV = PrevOBV (不变)                       |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：OBV与价格底背离（价格新低但OBV未新低, bar[1]确认）       |
//|  - 卖出：OBV与价格顶背离（价格新高但OBV未新高, bar[1]确认）       |
//|  - OBV趋势变化先于价格趋势变化                                    |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3

// 输入参数
input ENUM_PRICE_SAFE InpPriceType = PRICE_CLOSE;

// 指标缓冲区
double obvBuffer[];
double buySignal[];
double sellSignal[];

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, clrDodgerBlue);
   SetIndexBuffer(0, obvBuffer);
   SetIndexLabel(0, "OBV");

   SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(1, buySignal);
   SetIndexArrow(1, ARROW_BUY);
   SetIndexEmptyValue(1, EMPTY_VALUE);

   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(2, sellSignal);
   SetIndexArrow(2, ARROW_SELL);
   SetIndexEmptyValue(2, EMPTY_VALUE);

   IndicatorDigits(0);
   IndicatorShortName("OBV_Safe");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;
   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - 2;
   if(limit < 0) limit = 0;

   // OBV从最远bar开始累加
   double cumulativeOBV = 0.0;
   int lastIndex = limit + 100 > Bars ? Bars - 1 : limit + 100;
   if(lastIndex < 0) lastIndex = Bars - 1;

   for(int i = lastIndex; i >= 0; i--)
   {
      if(i == lastIndex)
      {
         // 初始OBV = 当前成交量
         cumulativeOBV = (double)iVolume(_Symbol, _Period, i);
         obvBuffer[i] = cumulativeOBV;
         continue;
      }
      double closeCurr = GetPriceByType(i, InpPriceType);
      double closePrev = GetPriceByType(i + 1, InpPriceType);
      double volume    = (double)iVolume(_Symbol, _Period, i);

      if(closeCurr > closePrev)
         cumulativeOBV += volume;
      else if(closeCurr < closePrev)
         cumulativeOBV -= volume;

      obvBuffer[i] = cumulativeOBV;
      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // 信号判断：背离检测（bar[1]+确认）
   for(int i = limit; i >= 3; i--)
   {
      // 底背离：价格新低但OBV未新低
      double price_i   = GetPriceByType(i, InpPriceType);
      double price_i2  = GetPriceByType(i + 2, InpPriceType);
      double price_i4  = GetPriceByType(i + 4, InpPriceType);

      if(price_i < price_i4 && price_i < price_i2 &&
         obvBuffer[i] > obvBuffer[i+4])
         buySignal[i] = obvBuffer[i] * 0.95;

      // 顶背离：价格新高但OBV未新高
      if(price_i > price_i4 && price_i > price_i2 &&
         obvBuffer[i] < obvBuffer[i+4])
         sellSignal[i] = obvBuffer[i] * 1.05;
   }

   return(0);
}
//+------------------------------------------------------------------+
