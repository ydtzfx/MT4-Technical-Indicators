//+------------------------------------------------------------------+
//|                                                    ATR_Safe.mq4   |
//|  平均真实波动幅度 — 不含未来函数                                  |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  TR = Max(H-L, |H-PrevC|, |L-PrevC|)                               |
//|  ATR = EMA(TR, N)  或  SMMA(TR, N)                                |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - ATR本身不产生买卖信号，只衡量波动性                             |
//|  - ATR急剧扩大 → 趋势加速/突破                                    |
//|  - ATR持续缩小 → 盘整/变盘前兆                                    |
//|  - 辅助止损设置：止损距离 = ATR * multiplier                       |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3

// 输入参数
input int   InpATRPeriod = 14;      // ATR周期
input bool  InpShowVolatility = true; // 显示波动率预警
input double InpHighVolThreshold = 1.5; // 高波动倍数（vs 20日平均ATR）

// 指标缓冲区
double atrBuffer[];
double highVolSignal[];
double lowVolSignal[];

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, clrDodgerBlue);
   SetIndexBuffer(0, atrBuffer);
   SetIndexLabel(0, "ATR");

   SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, 2, clrTomato);
   SetIndexBuffer(1, highVolSignal);
   SetIndexArrow(1, ARROW_STOP);
   SetIndexLabel(1, "High Volatility");
   SetIndexEmptyValue(1, EMPTY_VALUE);

   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 2, clrGray);
   SetIndexBuffer(2, lowVolSignal);
   SetIndexArrow(2, ARROW_DOT);
   SetIndexLabel(2, "Low Volatility");
   SetIndexEmptyValue(2, EMPTY_VALUE);

   IndicatorDigits(4);
   IndicatorShortName("ATR_Safe(" + IntegerToString(InpATRPeriod) + ")");
   return(0);
}

int deinit() { return(0); }

//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) counted_bars = 0;
   int limit = Bars - counted_bars;
   if(limit > Bars - 2) limit = Bars - InpATRPeriod * 3;
   if(limit < 0) limit = 0;

   // 计算TR和ATR
   for(int i = limit; i >= 0; i--)
   {
      double sumTR = 0.0;
      for(int j = 0; j < InpATRPeriod; j++)
      {
         int shift = i + j;
         double high   = iHigh(_Symbol, _Period, shift);
         double low    = iLow(_Symbol, _Period, shift);
         double prevC  = iClose(_Symbol, _Period, shift + 1);

         double tr = MathMax(high - low,
                     MathMax(MathAbs(high - prevC), MathAbs(low - prevC)));
         sumTR += tr;
      }

      // 初始SMA，然后用EMA平滑
      double atr = sumTR / InpATRPeriod;
      double alpha = 2.0 / (InpATRPeriod + 1.0);

      // 继续EMA递推到当前位置
      for(int j = InpATRPeriod; j < InpATRPeriod * 2; j++)
      {
         int shift2 = i + j;
         if(shift2 < Bars)
         {
            double h = iHigh(_Symbol, _Period, shift2);
            double l = iLow(_Symbol, _Period, shift2);
            double pc = iClose(_Symbol, _Period, shift2 + 1);
            double tr2 = MathMax(h - l,
                          MathMax(MathAbs(h - pc), MathAbs(l - pc)));
            atr = tr2 * alpha + atr * (1.0 - alpha);
         }
      }

      atrBuffer[i] = atr;
      highVolSignal[i] = EMPTY_VALUE;
      lowVolSignal[i]  = EMPTY_VALUE;
   }

   // 波动率预警（bar[1]+确认）
   if(InpShowVolatility)
   {
      for(int i = limit; i >= 20; i--)
      {
         // 计算20周期均ATR作为基准
         double avgATR20 = 0.0;
         for(int j = 0; j < 20; j++)
            avgATR20 += atrBuffer[i + j];
         avgATR20 /= 20.0;

         // 当前ATR显著高于基准 → 高波动预警
         if(atrBuffer[i] > avgATR20 * InpHighVolThreshold)
            highVolSignal[i] = atrBuffer[i] * 1.2;

         // 当前ATR显著低于基准 → 低波动盘整
         if(atrBuffer[i] < avgATR20 * 0.5)
            lowVolSignal[i] = atrBuffer[i] * 0.8;
      }
   }

   return(0);
}
//+------------------------------------------------------------------+
