#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                     ChaikinMoneyFlow_Safe.mq4     |
//|  蔡金资金流（CMF）— 不含未来函数                                  |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  MFV = ((Close-Low) - (High-Close)) / (High-Low) * Volume         |
//|  CMF = ΣMFV(N) / ΣVolume(N)                                        |
//|                                                                   |
//|  取值范围 [-1, 1]：                                                |
//|  >0.1 = 资金在流入（买方主导），<-0.1 = 资金在流出（卖方主导）     |
//|  接近0 = 资金流向平衡                                              |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：CMF从-0.1下方回升突破(bar[1]确认)                        |
//|  - 卖出：CMF从+0.1上方回落跌破(bar[1]确认)                        |
//|  - CMF正值持续扩大 = 上涨趋势有资金支持                           |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_minimum -1
#property indicator_maximum 1
#property indicator_level1 0.1
#property indicator_level2 -0.1

input int InpCMFPeriod = 21;    // CMF周期

// 指标缓冲区
double cmfBuffer[];     // CMF主线（柱状图）
double buySignal[];     // 买入信号
double sellSignal[];    // 卖出信号
double strongBuy[];     // 强买入信号（多重条件确认）
double strongSell[];    // 强卖出信号（多重条件确认）

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_HISTOGRAM, STYLE_SOLID, 2);
   SetIndexBuffer(0, cmfBuffer);
   SetIndexLabel(0, "CMF(" + IntegerToString(InpCMFPeriod) + ")");
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

   SetIndexStyle(3, DRAW_ARROW, STYLE_SOLID, 4, clrCyan);
   SetIndexBuffer(3, strongBuy);
   SetIndexArrow(3, 233);
   SetIndexLabel(3, "Strong Buy");
   SetIndexEmptyValue(3, EMPTY_VALUE);

   SetIndexStyle(4, DRAW_ARROW, STYLE_SOLID, 4, clrDeepPink);
   SetIndexBuffer(4, strongSell);
   SetIndexArrow(4, 234);
   SetIndexLabel(4, "Strong Sell");
   SetIndexEmptyValue(4, EMPTY_VALUE);

   IndicatorDigits(3);
   IndicatorShortName("CMF_Safe(" + IntegerToString(InpCMFPeriod) + ")");
   return(0);
}

//+------------------------------------------------------------------+
int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;

   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - InpCMFPeriod * 2;
   if(limit < 0) limit = 0;

   // --- 第1步：计算CMF ---
   for(int i = limit; i >= 1; i--)
   {
      double mfvSum = 0.0;  // 资金流量累计
      double volSum = 0.0;  // 成交量累计

      for(int j = 0; j < InpCMFPeriod; j++)
      {
         int shift = i + j;
         if(shift >= Bars) continue;

         double high  = iHigh(_Symbol, _Period, shift);
         double low   = iLow(_Symbol, _Period, shift);
         double close = iClose(_Symbol, _Period, shift);
         long   volume = iVolume(_Symbol, _Period, shift);
         double range  = high - low;

         // MFV = CLV * Volume
         double mfv = 0.0;
         if(MathAbs(range) > _Point)
         {
            double clv = ((close - low) - (high - close)) / range;
            mfv = clv * (double)volume;
         }

         mfvSum += mfv;
         volSum += (double)volume;
      }

      // CMF = ΣMFV / ΣVolume
      cmfBuffer[i] = SafeDivide(mfvSum, volSum, 0.0);

      buySignal[i]   = EMPTY_VALUE;
      sellSignal[i]  = EMPTY_VALUE;
      strongBuy[i]   = EMPTY_VALUE;
      strongSell[i]  = EMPTY_VALUE;
   }

   // --- 第2步：强信号判断（多重条件确认，成交量放大+极端阈值+趋势共振）---
   for(i = limit; i >= 1; i--)
   {
      // 计算平均成交量用于激增检测
      double avgVol = 0.0;
      int volCount = 0;
      for(int jj = 1; j <= InpCMFPeriod; j++)
      {
         int vShift = i + j;
         if(vShift < Bars) { avgVol += (double)iVolume(_Symbol, _Period, vShift); volCount++; }
      }
      if(volCount > 0) avgVol /= volCount;
      bool volumeSurge = (volCount > 0 && (double)iVolume(_Symbol, _Period, i) > avgVol * 1.5);

      // 强买入：3条件确认 — ①退出超卖区 + ②上穿零轴 + ③成交量激增
      if(cmfBuffer[i+1] < -0.1 && cmfBuffer[i] > 0.0 && volumeSurge)
         strongBuy[i] = cmfBuffer[i] - 0.04;

      // 强卖出：3条件确认 — ①退出超买区 + ②下穿零轴 + ③成交量激增
      if(cmfBuffer[i+1] > 0.1 && cmfBuffer[i] < 0.0 && volumeSurge)
         strongSell[i] = cmfBuffer[i] + 0.04;

      // 附加强信号：持续极端 + 继续同向加速 + 成交量确认
      if(cmfBuffer[i+1] > 0.1 && cmfBuffer[i+2] > 0.1 && cmfBuffer[i] > cmfBuffer[i+1] && volumeSurge)
         strongBuy[i] = cmfBuffer[i] - 0.04;

      if(cmfBuffer[i+1] < -0.1 && cmfBuffer[i+2] < -0.1 && cmfBuffer[i] < cmfBuffer[i+1] && volumeSurge)
         strongSell[i] = cmfBuffer[i] + 0.04;
   }

   // --- 第3步：常规信号判断（bar[1]+确认）---
   for(i = limit; i >= 1; i--)
   {
      // 资金从流出转为流入 → 买入
      if(cmfBuffer[i + 1] < -0.1 && cmfBuffer[i] > -0.1)
         buySignal[i] = cmfBuffer[i] - 0.02;

      // 资金从流入转为流出 → 卖出
      if(cmfBuffer[i + 1] > 0.1 && cmfBuffer[i] < 0.1)
         sellSignal[i] = cmfBuffer[i] + 0.02;

      // CMF从负值区上穿零轴 → 资金态度根本转变
      if(cmfBuffer[i + 1] < 0.0 && cmfBuffer[i] > 0.0)
         buySignal[i] = cmfBuffer[i] - 0.03;

      // CMF从正值区下穿零轴
      if(cmfBuffer[i + 1] > 0.0 && cmfBuffer[i] < 0.0)
         sellSignal[i] = cmfBuffer[i] + 0.03;
   }

   // --- 第4步：刷新 bar[0] ---
   if(Bars > 0)
   {
      cmfBuffer[0]  = cmfBuffer[1];
      buySignal[0]   = EMPTY_VALUE;
      sellSignal[0]  = EMPTY_VALUE;
      strongBuy[0]   = EMPTY_VALUE;
      strongSell[0]  = EMPTY_VALUE;
   }

   return(0);
}
//+------------------------------------------------------------------+
