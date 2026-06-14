#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                     CandleBodyMomentum_Safe.mq4   |
//|  K线实体动量 — 实体连续扩大/缩小的趋势分析                          |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum -100
#property indicator_maximum 100
double bodyMom[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,bodyMom);SetIndexLabel(0,"Body Momentum");SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("BodyMom_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-50;if(limit<0)limit=0;
   for(int i=limit;i>=1;i++){
      double b=MathAbs(iClose(_Symbol,_Period,i)-iOpen(_Symbol,_Period,i));
      double b1=MathAbs(iClose(_Symbol,_Period,i+1)-iOpen(_Symbol,_Period,i+1));
      double b2=MathAbs(iClose(_Symbol,_Period,i+2)-iOpen(_Symbol,_Period,i+2));
      double avgB=0;for(int j=3;j<13;j++)avgB+=MathAbs(iClose(_Symbol,_Period,i+j)-iOpen(_Symbol,_Period,i+j));avgB/=10;
      // 实体变化率：连续扩大=动量加速，连续缩小=动量减速
      double change=(b-b2)/SafeDivide(avgB,1,1)*100;
      bool isUp=iClose(_Symbol,_Period,i)>iOpen(_Symbol,_Period,i);
      bodyMom[i]=isUp?MathAbs(change):-MathAbs(change);
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=3;i++){
      // 阳线实体连续扩大=买方加速
      if(bodyMom[i+2]>20&&bodyMom[i+1]>30&&bodyMom[i]>40)buySignal[i]=bodyMom[i]-10;
      // 阴线实体连续扩大=卖方加速
      if(bodyMom[i+2]<-20&&bodyMom[i+1]<-30&&bodyMom[i]<-40)sellSignal[i]=bodyMom[i]+10;
      // 从扩大转为缩小=衰竭
      if(bodyMom[i+1]>50&&bodyMom[i]<20)sellSignal[i]=bodyMom[i]+5;
   }
   if(Bars>0){bodyMom[0]=bodyMom[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}return(0);}
