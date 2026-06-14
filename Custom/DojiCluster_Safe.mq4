#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                          DojiCluster_Safe.mq4     |
//|  十字星集群 — 连续/密集十字星=重大变盘前兆                         |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum 0
#property indicator_maximum 100
input int InpLookback=10;input double InpDojiThreshold=0.15;
double dojiDensity[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3,clrYellow);SetIndexBuffer(0,dojiDensity);SetIndexLabel(0,"Doji Density%");SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("DojiCluster_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=1;i++){
      int dojiCnt=0;
      for(int j=0;j<InpLookback;j++){double r=iHigh(_Symbol,_Period,i+j)-iLow(_Symbol,_Period,i+j);double b=MathAbs(iClose(_Symbol,_Period,i+j)-iOpen(_Symbol,_Period,i+j));if(r>0&&b<r*InpDojiThreshold)dojiCnt++;}
      dojiDensity[i]=100.0*dojiCnt/InpLookback;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=3;i++){
      // 十字星密度>40%=高度不确定→随后突破方向即趋势方向
      if(dojiDensity[i+2]>40&&dojiDensity[i]<20&&iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+2))buySignal[i]=dojiDensity[i]-10;
      if(dojiDensity[i+2]>40&&dojiDensity[i]<20&&iClose(_Symbol,_Period,i)<iClose(_Symbol,_Period,i+2))sellSignal[i]=dojiDensity[i]+10;
   }
   if(Bars>0){dojiDensity[0]=dojiDensity[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}return(0);}
