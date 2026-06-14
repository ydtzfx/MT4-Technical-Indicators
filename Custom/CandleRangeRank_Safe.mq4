#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                         CandleRangeRank_Safe.mq4  |
//|  K线范围排名 — 当前K线范围在历史中的百分位                         |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 80
#property indicator_level2 20
input int InpHistBars=100;
double rangePct[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,rangePct);SetIndexLabel(0,"Range %ile");SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("RangeRank_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=1;i++){
      double r=iHigh(_Symbol,_Period,i)-iLow(_Symbol,_Period,i),body=MathAbs(iClose(_Symbol,_Period,i)-iOpen(_Symbol,_Period,i));
      int smallerC=0;
      for(int j=1;j<=InpHistBars&&(i+j<Bars);j++){double rj=iHigh(_Symbol,_Period,i+j)-iLow(_Symbol,_Period,i+j);if(r>rj)smallerC++;}
      rangePct[i]=100.0*smallerC/InpHistBars;
      // 同时标注实体占比
      if(body>r*0.7)rangePct[i]=rangePct[i]; // 保持原值
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=3;i++){
      // >90%分位=极端大范围→可能衰竭或突破
      if(rangePct[i+1]>90&&rangePct[i]<70){if(iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+2))buySignal[i]=rangePct[i]-10;else sellSignal[i]=rangePct[i]+10;}
      // <10%分位后扩张=压缩后突破
      if(rangePct[i+2]<10&&rangePct[i+1]<10&&rangePct[i]>50){if(iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+1))buySignal[i]=rangePct[i]-10;}
   }
   if(Bars>0){rangePct[0]=rangePct[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);}
