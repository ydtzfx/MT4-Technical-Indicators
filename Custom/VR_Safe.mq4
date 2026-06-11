//+------------------------------------------------------------------+
//|                                                    VR_Safe.mq4    |
//|  成交量变异率（VR）— 不含未来函数                                  |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  VR = 100 * (UV + 0.5*PV) / (DV + 0.5*PV)                         |
//|  UV = 上涨日成交量之和，DV = 下跌日成交量之和                      |
//|  PV = 平盘日成交量之和                                             |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：VR从70下方回升，或在40-70安全买入区(bar[1]确认)          |
//|  - 卖出：VR从160上方回落(bar[1]确认)                              |
//|  - VR<40 极度超卖，40-70 低价区可考虑买入                         |
//|  - VR>160 超买区，>450 极度强势                                    |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_level1 160
#property indicator_level2 70

// 输入参数
input int   InpVRPeriod = 26;        // VR周期
input color InpVRColor  = clrDodgerBlue; // VR线颜色

// 指标缓冲区
double vrBuffer[];      // VR主线
double buySignal[];     // 买入信号
double sellSignal[];    // 卖出信号

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, InpVRColor);
   SetIndexBuffer(0, vrBuffer);
   SetIndexLabel(0, "VR");
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

   IndicatorDigits(2);
   IndicatorShortName("VR_Safe(" + IntegerToString(InpVRPeriod) + ")");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;

   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - InpVRPeriod * 2;
   if(limit < 0) limit = 0;

   // --- 第1步：计算历史VR ---
   for(int i = limit; i >= 1; i--)
   {
      double uv = 0.0;  // 上涨日成交量累计
      double dv = 0.0;  // 下跌日成交量累计
      double pv = 0.0;  // 平盘日成交量累计

      for(int j = 0; j < InpVRPeriod; j++)
      {
         int shift = i + j;
         double closeCurr = iClose(_Symbol, _Period, shift);
         double closePrev = iClose(_Symbol, _Period, shift + 1);
         long   volume    = iVolume(_Symbol, _Period, shift);

         if(closeCurr > closePrev)
            uv += (double)volume;       // 上涨日
         else if(closeCurr < closePrev)
            dv += (double)volume;       // 下跌日
         else
            pv += (double)volume;       // 平盘日
      }

      // VR = 100 * (UV + 0.5*PV) / (DV + 0.5*PV)
      vrBuffer[i] = SafeDivide(100.0 * (uv + 0.5 * pv), (dv + 0.5 * pv), 100.0);

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // --- 第2步：信号判断（bar[1]+确认）---
   for(int i = limit; i >= 1; i--)
   {
      // 从安全买入区回升 → 买入
      if(vrBuffer[i + 1] <= 70.0 && vrBuffer[i] > 70.0)
         buySignal[i] = 60.0;

      // 从超买区回落 → 卖出
      if(vrBuffer[i + 1] >= 160.0 && vrBuffer[i] < 160.0)
         sellSignal[i] = 170.0;

      // 极度超卖：VR<40后回升
      if(vrBuffer[i + 1] <= 40.0 && vrBuffer[i] > 40.0)
         buySignal[i] = 35.0;

      // 极度强势后转弱
      if(vrBuffer[i + 1] >= 450.0 && vrBuffer[i] < 450.0)
         sellSignal[i] = 460.0;
   }

   // --- 第3步：刷新 bar[0] ---
   if(Bars > 0)
   {
      double u0 = 0.0, d0 = 0.0, p0 = 0.0;
      for(int j = 0; j < InpVRPeriod; j++)
      {
         double cc = iClose(_Symbol, _Period, j);
         double cp = iClose(_Symbol, _Period, j + 1);
         long   vv = iVolume(_Symbol, _Period, j);
         if(cc > cp) u0 += (double)vv;
         else if(cc < cp) d0 += (double)vv;
         else p0 += (double)vv;
      }
      vrBuffer[0] = SafeDivide(100.0 * (u0 + 0.5 * p0), (d0 + 0.5 * p0), 100.0);
      buySignal[0]  = EMPTY_VALUE;
      sellSignal[0] = EMPTY_VALUE;
   }

   return(0);
}
//+------------------------------------------------------------------+
