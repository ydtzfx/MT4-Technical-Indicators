//+------------------------------------------------------------------+
//|                                                    ROC_Safe.mq4   |
//|  变化率指标（Rate of Change）— 不含未来函数                        |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  ROC = 100 * (Price - Price[N]) / Price[N]                         |
//|  衡量价格在N周期内的百分比变化率                                    |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：ROC从负值转为正值（上穿零轴, bar[1]确认）                |
//|  - 卖出：ROC从正值转为负值（下穿零轴, bar[1]确认）                |
//|  - 顶背离：价格新高但ROC下降（bar[1]确认）                        |
//|  - 底背离：价格新低但ROC上升（bar[1]确认）                        |
//|  - ROC持续在超买/超卖区域 → 趋势加速                              |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_level1 0

input int    InpROCPeriod = 12;         // ROC周期
input ENUM_PRICE_SAFE InpPriceType = PRICE_CLOSE; // 价格类型

// 指标缓冲区
double rocBuffer[];     // ROC主线
double buySignal[];     // 买入信号
double sellSignal[];    // 卖出信号
double strongBuy[];     // 强买入信号（多条件确认）
double strongSell[];    // 强卖出信号（多条件确认）

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, clrDodgerBlue);
   SetIndexBuffer(0, rocBuffer);
   SetIndexLabel(0, "ROC(" + IntegerToString(InpROCPeriod) + ")");
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

   // --- 强信号缓冲区 ---
   int idx = 3;
   SetIndexBuffer(idx, strongBuy);
   SetIndexStyle(idx, DRAW_ARROW, STYLE_SOLID, 4, clrCyan);
   SetIndexArrow(idx, 233);
   SetIndexLabel(idx, "Strong Buy");
   SetIndexEmptyValue(idx, EMPTY_VALUE);
   idx++;
   SetIndexBuffer(idx, strongSell);
   SetIndexStyle(idx, DRAW_ARROW, STYLE_SOLID, 4, clrDeepPink);
   SetIndexArrow(idx, 234);
   SetIndexLabel(idx, "Strong Sell");
   SetIndexEmptyValue(idx, EMPTY_VALUE);

   IndicatorDigits(2);
   IndicatorShortName("ROC_Safe(" + IntegerToString(InpROCPeriod) + ")");
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
   if(limit > Bars - 2) limit = Bars - InpROCPeriod * 2;
   if(limit < 0) limit = 0;

   // --- 第1步：计算历史ROC ---
   for(int i = limit; i >= 1; i--)
   {
      double currentPrice = GetPriceByType(i, InpPriceType);
      double pastPrice    = GetPriceByType(i + InpROCPeriod, InpPriceType);

      // ROC = 100 * (Current - Past) / Past
      if(pastPrice > 0.0)
         rocBuffer[i] = 100.0 * (currentPrice - pastPrice) / pastPrice;
      else
         rocBuffer[i] = 0.0;

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
      strongBuy[i]  = EMPTY_VALUE;
      strongSell[i] = EMPTY_VALUE;
   }

   // --- 第2步：信号判断（bar[1]+确认）---
   for(int i = limit; i >= 1; i--)
   {
      // ---- 零轴穿越 — 买入 ----
      // 强信号：穿越零轴且ROC值>2.0（强劲动量）
      if(rocBuffer[i + 1] < 0.0 && rocBuffer[i] > 0.0 && rocBuffer[i] > 2.0)
         strongBuy[i] = rocBuffer[i] - 0.5;
      else if(rocBuffer[i + 1] < 0.0 && rocBuffer[i] > 0.0)
         buySignal[i] = rocBuffer[i] - 0.5;

      // ---- 零轴穿越 — 卖出 ----
      // 强信号：穿越零轴且ROC值<-2.0（强劲动量）
      if(rocBuffer[i + 1] > 0.0 && rocBuffer[i] < 0.0 && rocBuffer[i] < -2.0)
         strongSell[i] = rocBuffer[i] + 0.5;
      else if(rocBuffer[i + 1] > 0.0 && rocBuffer[i] < 0.0)
         sellSignal[i] = rocBuffer[i] + 0.5;

      // ---- 顶背离检测（价格新高但ROC下降） ----
      double priceI  = iClose(_Symbol, _Period, i);
      double priceI3 = iClose(_Symbol, _Period, i + 3);
      if(priceI > priceI3 && rocBuffer[i] < rocBuffer[i + 3] &&
         rocBuffer[i] > 0.0)
      {
         // 强信号：顶背离 + ROC此前处于极度超买区域(>5.0)
         if(rocBuffer[i + 3] > 5.0)
            strongSell[i] = rocBuffer[i] + 0.5;
         else
            sellSignal[i] = rocBuffer[i] + 0.5;
      }

      // ---- 底背离检测（价格新低但ROC上升） ----
      if(priceI < priceI3 && rocBuffer[i] > rocBuffer[i + 3] &&
         rocBuffer[i] < 0.0)
      {
         // 强信号：底背离 + ROC此前处于极度超卖区域(<-5.0)
         if(rocBuffer[i + 3] < -5.0)
            strongBuy[i] = rocBuffer[i] - 0.5;
         else
            buySignal[i] = rocBuffer[i] - 0.5;
      }
   }

   // --- 第3步：刷新 bar[0] ---
   if(Bars > 0)
   {
      double cp = GetPriceByType(0, InpPriceType);
      double pp = GetPriceByType(InpROCPeriod, InpPriceType);
      rocBuffer[0] = (pp > 0.0) ? 100.0 * (cp - pp) / pp : 0.0;
      buySignal[0]  = EMPTY_VALUE;
      sellSignal[0] = EMPTY_VALUE;
      strongBuy[0]  = EMPTY_VALUE;
      strongSell[0] = EMPTY_VALUE;
   }

   return(0);
}
//+------------------------------------------------------------------+
