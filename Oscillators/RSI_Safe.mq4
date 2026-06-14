#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                                    RSI_Safe.mq4  |
//|  相对强弱指数 — 不含未来函数                                      |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  RS = AverageGain(N) / AverageLoss(N)                              |
//|  RSI = 100 - 100 / (1 + RS)                                       |
//|  AverageGain = EMA of positive price changes                       |
//|  AverageLoss = EMA of absolute negative price changes               |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：RSI从超卖区(<=30)回升突破确认(bar[1])                    |
//|  - 卖出：RSI从超买区(>=70)回落跌破确认(bar[1])                    |
//|  - 信号仅在bar[1]产生，RSI值不超过bar[1]                          |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 70
#property indicator_level2 30

// 输入参数
input int   InpRSIPeriod = 14;      // RSI周期
input ENUM_PRICE_SAFE InpPriceType = SAFE_PRICE_CLOSE; // 价格类型
input double InpOverbought = 70.0;  // 超买水平
input double InpOversold   = 30.0;  // 超卖水平
input color  InpRSIColor   = clrDodgerBlue; // RSI线颜色

// 指标缓冲区
double rsiBuffer[];
double buySignal[];
double sellSignal[];
double strongBuy[];   // 强买入信号（多条件确认）
double strongSell[];  // 强卖出信号

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, InpRSIColor);
   SetIndexBuffer(0, rsiBuffer);
   SetIndexEmptyValue(0, EMPTY_VALUE);
   SetIndexLabel(0, "RSI");

   SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(1, buySignal);
   SetIndexArrow(1, ARROW_BUY);
   SetIndexEmptyValue(1, EMPTY_VALUE);

   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(2, sellSignal);
   SetIndexArrow(2, ARROW_SELL);
   SetIndexEmptyValue(2, EMPTY_VALUE);

   // 强买入信号（更大箭头）
   SetIndexStyle(3, DRAW_ARROW, STYLE_SOLID, 4, clrCyan);
   SetIndexBuffer(3, strongBuy);
   SetIndexArrow(3, ARROW_BUY);
   SetIndexLabel(3, "Strong Buy");
   SetIndexEmptyValue(3, EMPTY_VALUE);

   // 强卖出信号（更大箭头）
   SetIndexStyle(4, DRAW_ARROW, STYLE_SOLID, 4, clrDeepPink);
   SetIndexBuffer(4, strongSell);
   SetIndexArrow(4, ARROW_SELL);
   SetIndexLabel(4, "Strong Sell");
   SetIndexEmptyValue(4, EMPTY_VALUE);

   IndicatorDigits(2);
   IndicatorShortName("RSI_Safe(" + IntegerToString(InpRSIPeriod) + ")");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;
   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - InpRSIPeriod * 3;
   if(limit < 0) limit = 0;

   for(int i = limit; i >= 0; i--)
   {
      // 收集价格变化
      double changes[];
      ArrayResize(changes, InpRSIPeriod * 2);
      for(int j = 0; j < InpRSIPeriod * 2; j++)
      {
         double curr = GetPriceByType(i + j, InpPriceType);
         double prev = GetPriceByType(i + j + 1, InpPriceType);
         changes[j] = curr - prev;
      }

      // EMA of gains and losses
      int startIdx = InpRSIPeriod * 2 - 1;
      double avgGain = (changes[startIdx] > 0) ? changes[startIdx] : 0.0;
      double avgLoss = (changes[startIdx] < 0) ? -changes[startIdx] : 0.0;

      double alpha = 2.0 / (InpRSIPeriod + 1.0);
      for(int jj = startIdx - 1; j >= 0; j--)
      {
         if(changes[j] > 0)
         {
            avgGain = changes[j] * alpha + avgGain * (1.0 - alpha);
            avgLoss = avgLoss * (1.0 - alpha);
         }
         else
         {
            avgGain = avgGain * (1.0 - alpha);
            avgLoss = (-changes[j]) * alpha + avgLoss * (1.0 - alpha);
         }
      }

      double rs = SafeDivide(avgGain, avgLoss, 0.0);
      rsiBuffer[i] = (avgLoss < 0.00000001) ? 100.0 : (100.0 - 100.0 / (1.0 + rs));

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
      strongBuy[i]  = EMPTY_VALUE;
      strongSell[i] = EMPTY_VALUE;
   }

   // 信号判断（bar[1]+确认，增强版：多条件确认+信号强度分级）
   for(i = limit; i >= 3; i--)
   {
      int buyConditions = 0, sellConditions = 0;

      // 条件1：超卖/超买区退出
      if(rsiBuffer[i+1] <= InpOversold && rsiBuffer[i] > InpOversold)
         { buySignal[i] = 5.0; buyConditions++; }
      if(rsiBuffer[i+1] >= InpOverbought && rsiBuffer[i] < InpOverbought)
         { sellSignal[i] = 95.0; sellConditions++; }

      // 条件2：增强背离检测（3点验证）
      // 底背离：价格连创新低但RSI底部抬升
      double p1=iClose(_Symbol,_Period,i),   r1=rsiBuffer[i];
      double p2=iClose(_Symbol,_Period,i+2), r2=rsiBuffer[i+2];
      double p3=iClose(_Symbol,_Period,i+4), r3=rsiBuffer[i+4];
      if(p1<p2&&p2<p3&&r1>r2&&r2>r3&&r1<50) { buySignal[i]=5.0; buyConditions+=2; }

      // 条件3：RSI与均线交叉（RSI的短期趋势转多）
      double rsiMA=0; for(int jjj=0;j<5;j++)rsiMA+=rsiBuffer[i+j]*0.2;
      if(rsiBuffer[i+1]<=rsiMA&&rsiBuffer[i]>rsiMA&&rsiBuffer[i]<50)
         { buyConditions++; }

      // 顶背离
      if(p1>p2&&p2>p3&&r1<r2&&r2<r3&&r1>50) { sellSignal[i]=95.0; sellConditions+=2; }

      // 条件4：价格与50中线的关系
      if(rsiBuffer[i+1]<50&&rsiBuffer[i]>50) { buyConditions++; }
      if(rsiBuffer[i+1]>50&&rsiBuffer[i]<50) { sellConditions++; }

      // 综合评估：3+条件为强信号
      if(buyConditions >= 3) strongBuy[i] = 2.0;
      if(sellConditions >= 3) strongSell[i] = 98.0;
   }

   return(0);
}
//+------------------------------------------------------------------+
