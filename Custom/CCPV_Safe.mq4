#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                                   CCPV_Safe.mq4   |
//|  收盘位置价值（CCPV）— K线收盘位置分析                              |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_minimum 0
#property indicator_maximum 100
input int InpPeriod=10;
double ccpv[],signal[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,ccpv);SetIndexLabel(0,"CCPV%");SetIndexStyle(1,DRAW_LINE,STYLE_DOT,1,clrYellow);SetIndexBuffer(1,signal);SetIndexLabel(1,"CCPV MA");SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(1);IndicatorShortName("CCPV_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=1;i--){
      double h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i);
      double r=h-l;ccpv[i]=r>0?100*(c-l)/r:50; // 收盘在K线范围内的百分比位置
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=1;i++){double s=0;for(int j=0;j<InpPeriod;j++)s+=ccpv[i+j];signal[i]=s/InpPeriod;}
   for(i=limit;i>=3;i++){
      // CCPV从低位回升 = 买方开始掌控
      if(ccpv[i+1]<30&&ccpv[i]>30&&iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+1))buySignal[i]=25;
      // CCPV从高位回落 = 卖方开始掌控
      if(ccpv[i+1]>70&&ccpv[i]<70&&iClose(_Symbol,_Period,i)<iClose(_Symbol,_Period,i+1))sellSignal[i]=75;
      // CCPV持续>80=强趋势，持续<20=弱趋势
      if(ccpv[i+2]>80&&ccpv[i+1]>80&&ccpv[i]>80)buySignal[i]=ccpv[i]-5;
   }
   if(Bars>0){ccpv[0]=ccpv[1];signal[0]=signal[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);}
