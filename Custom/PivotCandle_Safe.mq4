#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                          PivotCandle_Safe.mq4     |
//|  枢纽K线 — 标记摆动高低点K线+反转确认                              |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
input int InpSwingBars=5;
double pivotHigh[],pivotLow[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,4,clrTomato);SetIndexBuffer(0,pivotHigh);SetIndexArrow(0,ARROW_SELL);SetIndexLabel(0,"Pivot High");SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,4,clrLimeGreen);SetIndexBuffer(1,pivotLow);SetIndexArrow(1,ARROW_BUY);SetIndexLabel(1,"Pivot Low");SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("PivotCandle_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){pivotHigh[i]=pivotLow[i]=buySignal[i]=sellSignal[i]=EMPTY_VALUE;}
   for(i=limit;i>=InpSwingBars;i--){
      double h=iHigh(_Symbol,_Period,i);bool isHigh=true;
      for(int j=1;j<=InpSwingBars;j++){if(i+j<Bars&&iHigh(_Symbol,_Period,i+j)>=h)isHigh=false;if(i-j>=0&&iHigh(_Symbol,_Period,i-j)>=h)isHigh=false;}
      if(isHigh){pivotHigh[i]=h+5*Point;
         // 枢纽K线确认反转：后续跌破枢纽K线低点
         for(int k=i-1;k>=1;k--){if(iLow(_Symbol,_Period,k)<iLow(_Symbol,_Period,i)){sellSignal[k]=iHigh(_Symbol,_Period,k)+10*Point;break;}}}
      double l=iLow(_Symbol,_Period,i);bool isLow=true;
      for(int jj=1;j<=InpSwingBars;j++){if(i+j<Bars&&iLow(_Symbol,_Period,i+j)<=l)isLow=false;if(i-j>=0&&iLow(_Symbol,_Period,i-j)<=l)isLow=false;}
      if(isLow){pivotLow[i]=l-5*Point;
         for(int kk=i-1;k>=1;k--){if(iHigh(_Symbol,_Period,k)>iHigh(_Symbol,_Period,i)){buySignal[k]=iLow(_Symbol,_Period,k)-10*Point;break;}}}
   }
   return(0);}
