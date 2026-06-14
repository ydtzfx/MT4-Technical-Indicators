#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                      VolumeOscillator_Safe.mq4    |
//|  成交量振荡器 — 不含未来函数                                      |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：VO=100*(EMA(V,Fast)-EMA(V,Slow))/EMA(V,Slow)                |
//|  正值=放量(短期超长期)，负值=缩量                                  |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_level1 0

input int InpFast=5,InpSlow=10;

double vo[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,2);SetIndexBuffer(0,vo);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Vol Osc");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(3,strongBuy);SetIndexArrow(3,233);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(4,strongSell);SetIndexArrow(4,234);SetIndexEmptyValue(4,EMPTY_VALUE);
   IndicatorDigits(1);IndicatorShortName("VolOsc_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpSlow*3;if(limit<0)limit=0;

   double aF=2.0/(InpFast+1),aS=2.0/(InpSlow+1);
   for(int i=limit+InpSlow;i>=1;i--){ // 预计算EMA
      double eF=0,eS=0;for(int j=0;j<InpSlow*2;j++){double v=iVolume(_Symbol,_Period,i+j);eF+=v;eS+=v;}
      eF/=InpSlow*2;eS/=InpSlow*2;
      for(int jj=InpSlow*2-1;j>=0;j--){v=iVolume(_Symbol,_Period,i+j);eF=v*aF+eF*(1-aF);eS=v*aS+eS*(1-aS);}
      if(i<=limit){vo[i]=SafeDivide(100*(eF-eS),eS,0);strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;}
   }
   for(i=limit;i>=1;i--){
      // Strong signal: multi-condition volume confirmation
      // Cond1: extreme VO surge (>40), Cond2: price direction, Cond3: close vs EMA(5) trend filter
      double ma5=iMA(_Symbol,_Period,5,0,MODE_EMA,SAFE_PRICE_CLOSE,i);
      if(vo[i]>40&&iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+1)&&iClose(_Symbol,_Period,i)>ma5)
         strongBuy[i]=vo[i]*0.8;
      if(vo[i]>40&&iClose(_Symbol,_Period,i)<iClose(_Symbol,_Period,i+1)&&iClose(_Symbol,_Period,i)<ma5)
         strongSell[i]=vo[i]*1.2;
      // 放量+价格涨=多头确认
      if(vo[i]>20&&iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+1))buySignal[i]=vo[i]*0.5;
      // 放量+价格跌=空头确认
      if(vo[i]>20&&iClose(_Symbol,_Period,i)<iClose(_Symbol,_Period,i+1))sellSignal[i]=vo[i]*1.5;
   }
   if(Bars>0){vo[0]=vo[1];strongBuy[0]=EMPTY_VALUE;strongSell[0]=EMPTY_VALUE;buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
