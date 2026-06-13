//+------------------------------------------------------------------+
//|                                     MarketFacilitation_Safe.mq4   |
//|  市场促进指数（BW MFI）— 不含未来函数                              |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式说明：                                                        |
//|  MFI = (High - Low) / Volume                                       |
//|  即每单位成交量的价格波动幅度                                      |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 绿色(Fake): MFI上升 + Volume下降 → 假突破警告                  |
//|  - 棕色(Squat): MFI下降 + Volume上升 → 吸筹/派发                  |
//|  - 蓝色(Fade): MFI下降 + Volume下降 → 市场休眠                    |
//|  - 粉色(Green): MFI上升 + Volume上升 → 真实趋势                   |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5

// 指标缓冲区
double mfiBuffer[];
double buySignal[];
double sellSignal[];
double strongBuy[];
double strongSell[];

//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0, DRAW_HISTOGRAM, STYLE_SOLID, 2);
   SetIndexBuffer(0, mfiBuffer);
   SetIndexLabel(0, "BW MFI");

   SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, 2, CLR_BUY_SIGNAL);
   SetIndexBuffer(1, buySignal);
   SetIndexArrow(1, ARROW_BUY);
   SetIndexEmptyValue(1, EMPTY_VALUE);

   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 2, CLR_SELL_SIGNAL);
   SetIndexBuffer(2, sellSignal);
   SetIndexArrow(2, ARROW_SELL);
   SetIndexEmptyValue(2, EMPTY_VALUE);

   SetIndexStyle(3, DRAW_ARROW, STYLE_SOLID, 3, clrCyan);
   SetIndexBuffer(3, strongBuy);
   SetIndexArrow(3, 233);
   SetIndexEmptyValue(3, EMPTY_VALUE);

   SetIndexStyle(4, DRAW_ARROW, STYLE_SOLID, 3, clrDeepPink);
   SetIndexBuffer(4, strongSell);
   SetIndexArrow(4, 234);
   SetIndexEmptyValue(4, EMPTY_VALUE);

   IndicatorDigits(0);
   IndicatorShortName("BW_MFI_Safe");
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

   for(int i = limit; i >= 1; i--)
   {
      double high = iHigh(_Symbol, _Period, i);
      double low  = iLow(_Symbol, _Period, i);
      long   vol  = iVolume(_Symbol, _Period, i);

      if(vol > 0)
         mfiBuffer[i] = (high - low) / (double)vol;
      else
         mfiBuffer[i] = 0.0;

      buySignal[i]  = EMPTY_VALUE;
      sellSignal[i] = EMPTY_VALUE;
      strongBuy[i]  = EMPTY_VALUE;
      strongSell[i] = EMPTY_VALUE;
   }

   // 信号（bar[1]+确认）— 分辨4种状态
   for(int i = limit; i >= 2; i--)
   {
      long vol_i   = iVolume(_Symbol, _Period, i);
      long vol_i1  = iVolume(_Symbol, _Period, i + 1);
      double mfi_i  = mfiBuffer[i];
      double mfi_i1 = mfiBuffer[i + 1];

      // Strong signals — multi-condition volume confirmation
      bool greenBuy  = (mfi_i > mfi_i1 && vol_i > vol_i1 && iClose(_Symbol, _Period, i) > iClose(_Symbol, _Period, i+1));
      bool greenSell = (mfi_i > mfi_i1 && vol_i > vol_i1 && iClose(_Symbol, _Period, i) < iClose(_Symbol, _Period, i+1));
      bool squatBuy  = (mfi_i < mfi_i1 && vol_i > vol_i1 * 1.5 && iClose(_Symbol, _Period, i) < iClose(_Symbol, _Period, i+1));
      bool squatSell = (mfi_i < mfi_i1 && vol_i > vol_i1 * 1.5 && iClose(_Symbol, _Period, i) >= iClose(_Symbol, _Period, i+1));

      if((greenBuy && vol_i > vol_i1 * 1.3) || (squatBuy && vol_i > vol_i1 * 2.0))
         strongBuy[i] = mfi_i * 0.5;
      if((greenSell && vol_i > vol_i1 * 1.3) || (squatSell && vol_i > vol_i1 * 2.0))
         strongSell[i] = mfi_i * 1.5;

      // Green: MFI ↑, Vol ↑ → 真实趋势，顺势跟单
      if(mfi_i > mfi_i1 && vol_i > vol_i1)
      {
         double closeCurr = iClose(_Symbol, _Period, i);
         double closePrev = iClose(_Symbol, _Period, i + 1);
         if(closeCurr > closePrev)
            buySignal[i] = mfi_i * 0.5;
         else if(closeCurr < closePrev)
            sellSignal[i] = mfi_i * 1.5;
      }

      // Squat: MFI ↓, Vol ↑ → 可能反转
      if(mfi_i < mfi_i1 && vol_i > vol_i1)
      {
         // 巨量+小波动 = 反转前兆
         if(vol_i > vol_i1 * 1.5)
         {
            double closeCurr = iClose(_Symbol, _Period, i);
            double closePrev = iClose(_Symbol, _Period, i + 1);
            if(closeCurr < closePrev)
               buySignal[i] = mfi_i * 0.5;  // 潜在反转买入
            else
               sellSignal[i] = mfi_i * 1.5; // 潜在反转卖出
         }
      }
   }

   // bar[0] display refresh — no signals on live bar
   mfiBuffer[0] = (iVolume(_Symbol, _Period, 0) > 0) ? (iHigh(_Symbol, _Period, 0) - iLow(_Symbol, _Period, 0)) / (double)iVolume(_Symbol, _Period, 0) : 0.0;
   buySignal[0]  = EMPTY_VALUE;
   sellSignal[0] = EMPTY_VALUE;
   strongBuy[0]  = EMPTY_VALUE;
   strongSell[0] = EMPTY_VALUE;

   return(0);
}
//+------------------------------------------------------------------+
