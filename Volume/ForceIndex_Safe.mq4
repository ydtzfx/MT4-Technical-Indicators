//+------------------------------------------------------------------+
//|                                            ForceIndex_Safe.mq4    |
//|  强力指数（Force Index）— 不含未来函数                            |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  RawFI = (Close - PrevClose) * Volume                              |
//|  ForceIndex = EMA(RawFI, Period)                                   |
//|                                                                   |
//|  三位一体：结合了价格方向、价格幅度和成交量                         |
//|  >0 = 多方主导，<0 = 空方主导                                      |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：FI从负转正（bar[1]确认）                                  |
//|  - 卖出：FI从正转负（bar[1]确认）                                  |
//|  - 底背离：价格新低但FI回升                                       |
//|  - 顶背离：价格新高但FI下降                                       |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5

input int    InpFIPeriod = 13;           // EMA周期
input ENUM_MA_METHOD_SAFE InpMAMethod = MA_EMA; // 平滑方式

// 指标缓冲区
double fiBuffer[];      // Force Index主线（柱状图）
double buySignal[];     // 买入信号
double sellSignal[];    // 卖出信号
double strongBuy[];     // 强买入信号（多条件确认）
double strongSell[];    // 强卖出信号（多条件确认）

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_HISTOGRAM, STYLE_SOLID, 2);
   SetIndexBuffer(0, fiBuffer);
   SetIndexLabel(0, "Force Index(" + IntegerToString(InpFIPeriod) + ")");
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
   SetIndexArrow(3, 233);  // 上箭头
   SetIndexLabel(3, "Strong Buy Signal");
   SetIndexEmptyValue(3, EMPTY_VALUE);

   SetIndexStyle(4, DRAW_ARROW, STYLE_SOLID, 4, clrDeepPink);
   SetIndexBuffer(4, strongSell);
   SetIndexArrow(4, 234);  // 下箭头
   SetIndexLabel(4, "Strong Sell Signal");
   SetIndexEmptyValue(4, EMPTY_VALUE);

   IndicatorDigits(0);
   IndicatorShortName("ForceIndex_Safe(" + IntegerToString(InpFIPeriod) + ")");
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
   if(limit > Bars - 2) limit = Bars - InpFIPeriod * 3;
   if(limit < 0) limit = 0;

   // --- 第1步：计算原始FI序列 ---
   double rawFI[];
   ArrayResize(rawFI, Bars);
   ArrayInitialize(rawFI, 0.0);

   for(int i = limit + InpFIPeriod; i >= 1; i--)
   {
      double priceChange = iClose(_Symbol, _Period, i) - iClose(_Symbol, _Period, i + 1);
      long   volume      = iVolume(_Symbol, _Period, i);
      rawFI[i] = priceChange * (double)volume;
   }

   // --- 第2步：平滑FI ---
   for(int i = limit; i >= 1; i--)
   {
      double rawVals[];
      int count = 0;
      ArrayResize(rawVals, InpFIPeriod * 2);
      for(int j = 0; j < InpFIPeriod * 2 && (i + j < Bars); j++)
         rawVals[count++] = rawFI[i + j];

      if(count >= InpFIPeriod)
         fiBuffer[i] = CalculateMA(rawVals, InpFIPeriod, InpMAMethod, 0);
      else
         fiBuffer[i] = 0.0;

      buySignal[i]   = EMPTY_VALUE;
      sellSignal[i]  = EMPTY_VALUE;
      strongBuy[i]   = EMPTY_VALUE;
      strongSell[i]  = EMPTY_VALUE;
   }

   // --- 第3步：信号判断（bar[1]+确认）---
   for(int i = limit; i >= 1; i--)
   {
      // --- 强信号：多条件确认（任意满足2条即强信号）---
      // 条件A：FI零轴穿越
      bool crossBuy  = (fiBuffer[i + 1] < 0.0 && fiBuffer[i] > 0.0);
      bool crossSell = (fiBuffer[i + 1] > 0.0 && fiBuffer[i] < 0.0);

      // 条件B：成交量激增（当前量 > 前一根量 * 1.5）
      long volNow = iVolume(_Symbol, _Period, i);
      long volPrev = iVolume(_Symbol, _Period, i + 1);
      bool volSurge = (volNow > volPrev * 1.5);

      // 条件C：FI绝对值超过阈值（近期均值的2倍），表示极端动量
      double absFI = MathAbs(fiBuffer[i]);
      double refFI = MathMax(MathAbs(fiBuffer[i + 1]), MathAbs(fiBuffer[i + 2]));
      bool extremeFI = (absFI > refFI * 2.0 && refFI > 0.0);

      // 条件D：背离确认
      double priceI   = iClose(_Symbol, _Period, i);
      double priceI3  = iClose(_Symbol, _Period, i + 3);
      bool diverBuy   = (priceI < priceI3 && fiBuffer[i] > fiBuffer[i + 3]);
      bool diverSell  = (priceI > priceI3 && fiBuffer[i] < fiBuffer[i + 3]);

      // 强买入：crossBuy + (volSurge 或 extremeFI 或 diverBuy)
      int buyStrength = (crossBuy ? 1 : 0) + (volSurge ? 1 : 0)
                      + (extremeFI ? 1 : 0) + (diverBuy ? 1 : 0);
      if(buyStrength >= 2)
         strongBuy[i] = fiBuffer[i] * 0.6;

      // 强卖出：crossSell + (volSurge 或 extremeFI 或 diverSell)
      int sellStrength = (crossSell ? 1 : 0) + (volSurge ? 1 : 0)
                       + (extremeFI ? 1 : 0) + (diverSell ? 1 : 0);
      if(sellStrength >= 2)
         strongSell[i] = fiBuffer[i] * 1.6;

      // FI零轴穿越（普通信号）
      if(crossBuy && strongBuy[i] == EMPTY_VALUE)
         buySignal[i] = fiBuffer[i] * 0.5;

      if(crossSell && strongSell[i] == EMPTY_VALUE)
         sellSignal[i] = fiBuffer[i] * 1.5;

      // 底背离（普通信号，未被强信号覆盖时）
      if(diverBuy && strongBuy[i] == EMPTY_VALUE)
         buySignal[i] = fiBuffer[i] * 0.5;

      // 顶背离（普通信号，未被强信号覆盖时）
      if(diverSell && strongSell[i] == EMPTY_VALUE)
         sellSignal[i] = fiBuffer[i] * 1.5;
   }

   // --- 第4步：刷新 bar[0] ---
   if(Bars > 0)
   {
      fiBuffer[0] = fiBuffer[1];
      buySignal[0]  = EMPTY_VALUE;
      sellSignal[0] = EMPTY_VALUE;
      strongBuy[0]  = EMPTY_VALUE;
      strongSell[0] = EMPTY_VALUE;
   }

   return(0);
}
//+------------------------------------------------------------------+
