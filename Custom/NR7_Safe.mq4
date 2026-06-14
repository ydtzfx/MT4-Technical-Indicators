#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                                   NR7_Safe.mq4   |
//|  NR7/NR4 — 窄幅波动收缩（即将突破）                                 |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
input int InpNR=7; // 7=NR7, 4=NR4
double nr[],expansion[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,3,clrYellow);SetIndexBuffer(0,nr);SetIndexArrow(0,ARROW_DOT);SetIndexLabel(0,"NR"+IntegerToString(InpNR));SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,1);SetIndexBuffer(1,expansion);SetIndexLabel(1,"Expansion");SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("NR"+IntegerToString(InpNR)+"_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){nr[i]=expansion[i]=buySignal[i]=sellSignal[i]=EMPTY_VALUE;}
   for(i=limit;i>=InpNR;i--){
      double range=iHigh(_Symbol,_Period,i)-iLow(_Symbol,_Period,i);bool isNR=true;
      for(int j=1;j<InpNR;j++){if((iHigh(_Symbol,_Period,i+j)-iLow(_Symbol,_Period,i+j))<range)isNR=false;}
      if(isNR){nr[i]=iLow(_Symbol,_Period,i)-3*Point;expansion[i]=range;}
      // NR后突破方向=信号
      if(isNR&&iClose(_Symbol,_Period,i-1)>iHigh(_Symbol,_Period,i))buySignal[i-1]=iLow(_Symbol,_Period,i-1)-5*Point;
      if(isNR&&iClose(_Symbol,_Period,i-1)<iLow(_Symbol,_Period,i))sellSignal[i-1]=iHigh(_Symbol,_Period,i-1)+5*Point;
   }
   return(0);}
