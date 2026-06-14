#include "../Include/Common.mqh"
#include "../Include/PriceData.mqh"
//+------------------------------------------------------------------+
//|                                        CandleDisplacement_Safe    |
//|  K线位移 — 当前价格相对于N根前K线中位的偏离                         |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum -100
#property indicator_maximum 100
input int InpPeriod=10;
double displace[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,displace);SetIndexLabel(0,"Displacement");SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);IndicatorDigits(1);IndicatorShortName("Displace_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-50;if(limit<0)limit=0;
   for(int i=limit;i>=1;i++){
      double sum=0;for(int j=1;j<=InpPeriod;j++)sum+=iClose(_Symbol,_Period,i+j);double ref=sum/InpPeriod;
      double atr=0;for(int jj=0;j<14;j++)atr+=GetTrueRange(_Symbol,_Period,i+j);atr/=14;
      displace[i]=SafeDivide(100*(iClose(_Symbol,_Period,i)-ref),atr,0);
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=3;i++){
      if(displace[i+1]<-80&&displace[i]>-50)buySignal[i]=-60; // 大幅低位移回升
      if(displace[i+1]>80&&displace[i]<50)sellSignal[i]=60;  // 大幅高位移回落
   }if(Bars>0){displace[0]=displace[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}return(0);}
