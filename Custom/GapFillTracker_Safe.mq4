#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                          GapFillTracker_Safe.mq4  |
//|  缺口追踪K线 — 逐K线跟踪未回补缺口                                  |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum 0
double unfilled[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3,clrTomato);SetIndexBuffer(0,unfilled);SetIndexLabel(0,"Unfilled Gaps");SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("GapTrack_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=1;i++){int cnt=0;
      for(int j=20;j>=3;j--){int s=i+j;if(s>=Bars)continue;double gap=iOpen(_Symbol,_Period,s)-iClose(_Symbol,_Period,s+1);if(MathAbs(gap)>3*Point){bool filled=false;for(int k=s-1;k>=0;k--){if(gap>0&&iLow(_Symbol,_Period,k)<=iClose(_Symbol,_Period,s+1))filled=true;if(gap<0&&iHigh(_Symbol,_Period,k)>=iClose(_Symbol,_Period,s+1))filled=true;}if(!filled)cnt++;}}
      unfilled[i]=cnt;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=3;i++){if(unfilled[i+1]>=3&&unfilled[i]<2)buySignal[i]=unfilled[i];}
   if(Bars>0){unfilled[0]=unfilled[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}return(0);}
