//+------------------------------------------------------------------+
//|                                                  WVAD_Safe.mq4    |
//|  威廉变异离散量（WVAD）— 不含未来函数                              |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  WVAD = Σ( (Close - Open) / (High - Low) * Volume, N )            |
//|  把成交量按照K线实体的方向加权后累加                               |
//|                                                                   |
//|  正值 = 资金净流入（买方主导），负值 = 资金净流出（卖方主导）       |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：WVAD从负值穿越到正值（bar[1]确认）                        |
//|  - 卖出：WVAD从正值穿越到负值（bar[1]确认）                        |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3

input int    InpWVADPeriod = 24;        // 累加周期
input ENUM_MA_METHOD_SAFE InpMAMethod = MA_SMA;

// 指标缓冲区
double wvadBuffer[];    // WVAD主线
double buySignal[];     // 买入信号
double sellSignal[];    // 卖出信号

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, clrDodgerBlue);
   SetIndexBuffer(0, wvadBuffer);
   SetIndexLabel(0, "WVAD");
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

   IndicatorDigits(0);
   IndicatorShortName("WVAD_Safe(" + IntegerToString(InpWVADPeriod) + ")");
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
   if(limit > Bars - 2) limit = Bars - InpWVADPeriod * 2;
   if(limit < 0) limit = 0;

   // --- 第1步：计算每日WVAD分量 ---
   double rawWVAD[];
   ArrayResize(rawWVAD, Bars);
   ArrayInitialize(rawWVAD, 0.0);

   for(int i = limit + InpWVADPeriod; i >= 1; i--)
   {
      double range = iHigh(_Symbol, _Period, i) - iLow(_Symbol, _Period, i);
      double body  = iClose(_Symbol, _Period, i) - iOpen(_Symbol, _Period, i);
      long   volume = iVolume(_Symbol, _Period, i);

      // WVAD分量 = K线实体方向 * 成交量 / 振幅
      rawWVAD[i] = SafeDivide(body * (double)volume, range, 0.0);
   }

   // --- 第2步：N周期累加 ---
   for(int i = limit; i >= 1; i--)
   {
      double sum = 0.0;
      for(int j = 0; j < InpWVADPeriod; j++)
      {
         if(i + j < Bars)
            sum += rawWVAD[i + j];
      }
      wvadBuffer[i] = sum;

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
   }

   // --- 第3步：信号判断（bar[1]+确认）---
   for(int i = limit; i >= 1; i--)
   {
      // WVAD零轴穿越 → 资金流向转变
      if(wvadBuffer[i + 1] < 0.0 && wvadBuffer[i] > 0.0)
         buySignal[i] = wvadBuffer[i] * 0.5;

      if(wvadBuffer[i + 1] > 0.0 && wvadBuffer[i] < 0.0)
         sellSignal[i] = wvadBuffer[i] * 1.5;

      // 底背离：价格新低但WVAD底部抬升
      double priceI  = iClose(_Symbol, _Period, i);
      double priceI3 = iClose(_Symbol, _Period, i + 3);
      if(priceI < priceI3 && wvadBuffer[i] > wvadBuffer[i + 3])
         buySignal[i] = wvadBuffer[i] * 0.5;

      // 顶背离：价格新高但WVAD顶部下降
      if(priceI > priceI3 && wvadBuffer[i] < wvadBuffer[i + 3])
         sellSignal[i] = wvadBuffer[i] * 1.5;
   }

   // --- 第4步：刷新 bar[0] ---
   if(Bars > 0)
   {
      wvadBuffer[0] = wvadBuffer[1];
      buySignal[0]  = EMPTY_VALUE;
      sellSignal[0] = EMPTY_VALUE;
   }

   return(0);
}
//+------------------------------------------------------------------+
