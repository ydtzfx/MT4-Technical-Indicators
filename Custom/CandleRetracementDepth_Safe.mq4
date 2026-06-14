#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                     CandleRetracementDepth_Safe   |
//|  K线回撤深度 — 每根K线相对于前一波动的回撤百分比                    |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 61.8
input int InpSwingBars=10;
double retrace[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,retrace);SetIndexLabel(0,"Retrace%");SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);IndicatorDigits(1);IndicatorShortName("Retrace_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=1;i++){
      double hh=iHigh(_Symbol,_Period,i+1),ll=iLow(_Symbol,_Period,i+1);
      for(int j=2;j<InpSwingBars;j++){double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);if(h>hh)hh=h;if(l<ll)ll=l;}
      double swing=hh-ll;double c=iClose(_Symbol,_Period,i);
      retrace[i]=swing>0?100*(c-ll)/swing:50;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=3;i++){
      if(retrace[i+1]>61.8&&retrace[i]<38.2)buySignal[i]=retrace[i]-5;   // 从深度回撤反弹→买入
      if(retrace[i+1]<38.2&&retrace[i]>61.8)sellSignal[i]=retrace[i]+5; // 从浅回撤跌入深回撤
   }if(Bars>0){retrace[0]=retrace[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}return(0);}
