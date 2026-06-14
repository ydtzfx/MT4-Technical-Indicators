#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                          CumulativeDelta_Safe.mq4 |
//|  累积Delta — 原创指标（基于K线推算）                               |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  概念：累积每根bar的买卖差异                                       |
//|  BarDelta = (Close-Open)/Range * Volume（近似买压-卖压）           |
//|  CumDelta = 累加BarDelta                                            |
//|  背离信号：价格新高但CumDelta未确认→顶背离                         |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5

double cumDelta[],barDelta[],signal[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,cumDelta);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Cumulative Δ");
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,1);SetIndexBuffer(1,barDelta);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Bar Δ");
   SetIndexStyle(2,DRAW_LINE,STYLE_DOT,1,clrYellow);SetIndexBuffer(2,signal);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexLabel(2,"Signal");
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(3,buySignal);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(4,sellSignal);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);
   IndicatorDigits(0);IndicatorShortName("CumDelta_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;

   double cum=0;
   for(int i=limit+50;i>=1;i--){
      double h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i),o=iOpen(_Symbol,_Period,i);
      long v=iVolume(_Symbol,_Period,i);double range=h-l;
      // Delta = 净买卖方向 * 成交量
      double delta=range>Point?((c-o)/range*(double)v):0;
      cum+=delta;
      if(i<=limit){cumDelta[i]=cum;barDelta[i]=delta;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;}
   }
   for(i=limit;i>=1;i++){double s=0;for(int j=0;j<10;j++)s+=cumDelta[i+j];signal[i]=s/10;}

   for(i=limit;i>=3;i--){
      // CumDelta与价格背离
      double priceNow=iClose(_Symbol,_Period,i),pricePrev=iClose(_Symbol,_Period,i+5);
      if(priceNow>pricePrev&&cumDelta[i]<cumDelta[i+5])sellSignal[i]=cumDelta[i]*1.2;  // 顶背离
      if(priceNow<pricePrev&&cumDelta[i]>cumDelta[i+5])buySignal[i]=cumDelta[i]*0.8;    // 底背离
      // CumDelta上穿信号线
      if(cumDelta[i+1]<=signal[i+1]&&cumDelta[i]>signal[i])buySignal[i]=cumDelta[i]*0.9;
   }
   if(Bars>0){cumDelta[0]=cumDelta[1];barDelta[0]=barDelta[1];signal[0]=signal[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
