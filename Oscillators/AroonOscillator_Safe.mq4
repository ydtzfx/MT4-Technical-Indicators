//+------------------------------------------------------------------+
//|                                     AroonOscillator_Safe.mq4      |
//|  阿隆振荡器（Aroon Oscillator）— 不含未来函数                     |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：AroonOsc = AroonUp - AroonDown                              |
//|  >0=多头, <0=空头, >50=强多头, <-50=强空头                       |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_minimum -100
#property indicator_maximum 100
#property indicator_level1 0

input int InpPeriod=14;

double aoBuffer[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,2);SetIndexBuffer(0,aoBuffer);SetIndexLabel(0,"Aroon Osc");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexBuffer(3,strongBuy);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexArrow(3,233);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexBuffer(4,strongSell);SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexArrow(4,234);SetIndexEmptyValue(4,EMPTY_VALUE);
   IndicatorDigits(1);IndicatorShortName("AroonOsc_Safe("+IntegerToString(InpPeriod)+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpPeriod*2;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--) {
      int hBars=0,lBars=0;double hh=iHigh(_Symbol,_Period,i),ll=iLow(_Symbol,_Period,i);
      for(int j=0;j<=InpPeriod;j++){double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);if(h>hh){hh=h;hBars=j;}if(l<ll){ll=l;lBars=j;}}
      aoBuffer[i]=100.0*(InpPeriod-hBars)/InpPeriod-100.0*(InpPeriod-lBars)/InpPeriod;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=1;i--) {
      // strong signals: cross + significant oscillator magnitude
      if(aoBuffer[i+1]<0&&aoBuffer[i]>0&&aoBuffer[i]>25)strongBuy[i]=-10;
      else if(aoBuffer[i+1]<0&&aoBuffer[i]>0)buySignal[i]=-5;
      if(aoBuffer[i+1]>0&&aoBuffer[i]<0&&aoBuffer[i]<-25)strongSell[i]=10;
      else if(aoBuffer[i+1]>0&&aoBuffer[i]<0)sellSignal[i]=5;
   }
   if(Bars>0){aoBuffer[0]=aoBuffer[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=EMPTY_VALUE;strongSell[0]=EMPTY_VALUE;}
   return(0);
}
