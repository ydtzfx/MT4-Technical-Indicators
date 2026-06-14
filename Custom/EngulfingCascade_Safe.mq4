#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                       EngulfingCascade_Safe.mq4   |
//|  吞没级联 — 连续吞没形态形成趋势加速/反转                           |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
double engulfBull[],engulfBear[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(0,engulfBull);SetIndexArrow(0,ARROW_BUY);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(1,engulfBear);SetIndexArrow(1,ARROW_SELL);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,4,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,4,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("EngulfCascade_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){engulfBull[i]=engulfBear[i]=buySignal[i]=sellSignal[i]=EMPTY_VALUE;}
   for(i=limit;i>=4;i++){
      int cascadeCount=0;int lastDir=0; // 0=none, 1=bull engulfing, -1=bear engulfing
      for(int j=0;j<5;j++){int s=i+j;if(s>=Bars)break;double o=iOpen(_Symbol,_Period,s),h=iHigh(_Symbol,_Period,s),l=iLow(_Symbol,_Period,s),c=iClose(_Symbol,_Period,s);double po=iOpen(_Symbol,_Period,s+1),ph=iHigh(_Symbol,_Period,s+1),pl=iLow(_Symbol,_Period,s+1),pc=iClose(_Symbol,_Period,s+1);
         if(c>o&&pc<po&&c>po&&o<pc){if(lastDir==1)cascadeCount++;else{cascadeCount=1;lastDir=1;}}else if(c<o&&pc>po&&c<po&&o>pc){if(lastDir==-1)cascadeCount++;else{cascadeCount=1;lastDir=-1;}}else{lastDir=0;cascadeCount=0;}}
      if(cascadeCount>=2){if(lastDir==1)engulfBull[i]=iLow(_Symbol,_Period,i)-10*Point;else engulfBear[i]=iHigh(_Symbol,_Period,i)+10*Point;}
      if(cascadeCount>=3){if(lastDir==1)buySignal[i]=iLow(_Symbol,_Period,i)-15*Point;else sellSignal[i]=iHigh(_Symbol,_Period,i)+15*Point;}
   }return(0);}
