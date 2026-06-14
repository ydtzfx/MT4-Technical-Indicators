#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                        BodyShadowRatio_Safe.mq4   |
//|  实体/影线比率 — K线结构分析指标                                   |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 3
double bsr[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,bsr);SetIndexLabel(0,"Body/Shadow");SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);IndicatorDigits(2);IndicatorShortName("BSR_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=1;i--){
      double o=iOpen(_Symbol,_Period,i),h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i);
      double body=MathAbs(c-o),range=h-l;if(range<_Point)range=_Point;
      double upperW=h-MathMax(o,c),lowerW=MathMin(o,c)-l;
      double shadow=upperW+lowerW;
      // BSR = 实体/影线比。>1=实体主导(趋势明确)，<1=影线主导(犹豫/反转)
      bsr[i]=shadow>0?body/shadow*50:100;
      bool isBull=c>o;if(isBull)bsr[i]=bsr[i];else bsr[i]=-bsr[i];
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=3;i--){
      // 从高BSR(-)翻到高BSR(+)=影线主导转实体主导=确认反转
      if(bsr[i+1]<-50&&bsr[i]>50)buySignal[i]=-60;
      if(bsr[i+1]>50&&bsr[i]<-50)sellSignal[i]=60;
   }
   if(Bars>0){bsr[0]=bsr[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);}
