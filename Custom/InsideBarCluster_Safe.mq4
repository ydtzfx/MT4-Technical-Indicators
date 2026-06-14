#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                       InsideBarCluster_Safe.mq4   |
//|  内含线集群 — 连续多根内含线=暴风雨前的宁静                        |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
input int InpMinCluster=3;
double cluster[],breakout[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,3,clrYellow);SetIndexBuffer(0,cluster);SetIndexArrow(0,ARROW_DOT);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,4,clrOrange);SetIndexBuffer(1,breakout);SetIndexArrow(1,ARROW_STOP);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("IBC_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){cluster[i]=breakout[i]=buySignal[i]=sellSignal[i]=EMPTY_VALUE;}
   int ibCount=0;double motherHi=0,motherLo=0;
   for(i=limit+50;i>=3;i--){
      double h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i);
      if(h<motherHi&&l>motherLo){ibCount++;if(ibCount>=InpMinCluster&&i<=limit)cluster[i]=l-3*Point;}
      else{motherHi=h;motherLo=l;if(ibCount>=InpMinCluster&&i>=2){breakout[i]=l-5*Point;if(iClose(_Symbol,_Period,i)>motherHi)buySignal[i]=l-10*Point;else if(iClose(_Symbol,_Period,i)<motherLo)sellSignal[i]=h+10*Point;}ibCount=0;}
   }
   return(0);}
