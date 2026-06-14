#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                        CandleNoiseFilter_Safe.mq4 |
//|  K线噪声过滤器 — 分离信号K线与噪声K线                              |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_minimum 0
#property indicator_maximum 100
input int InpPeriod=10;
double signalPct[],noise[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,signalPct);SetIndexLabel(0,"Signal%");SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,1,clrGray);SetIndexBuffer(1,noise);SetIndexLabel(1,"Noise Level");SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("NoiseFilter_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-50;if(limit<0)limit=0;
   for(int i=limit;i>=1;i++){int sigC=0;
      for(int j=0;j<InpPeriod;j++){int s=i+j;double r=iHigh(_Symbol,_Period,s)-iLow(_Symbol,_Period,s);double b=MathAbs(iClose(_Symbol,_Period,s)-iOpen(_Symbol,_Period,s));double upW=(iHigh(_Symbol,_Period,s)-MathMax(iOpen(_Symbol,_Period,s),iClose(_Symbol,_Period,s)))/MathMax(r,_Point);double loW=(MathMin(iOpen(_Symbol,_Period,s),iClose(_Symbol,_Period,s))-iLow(_Symbol,_Period,s))/MathMax(r,_Point);
         // 信号K线：大实体+小影线+方向明确
         if(b>r*0.5&&MathMax(upW,loW)<0.3)sigC++;}
      signalPct[i]=100.0*sigC/InpPeriod;noise[i]=100-signalPct[i];buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;}
   for(i=limit;i>=3;i++){if(noise[i+2]>70&&signalPct[i]>50&&iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+1))buySignal[i]=signalPct[i]-10;if(noise[i+2]>70&&signalPct[i]>50&&iClose(_Symbol,_Period,i)<iClose(_Symbol,_Period,i+1))sellSignal[i]=signalPct[i]+10;}
   if(Bars>0){signalPct[0]=signalPct[1];noise[0]=noise[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}return(0);}
