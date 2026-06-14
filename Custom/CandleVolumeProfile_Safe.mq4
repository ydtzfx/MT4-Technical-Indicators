#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                      CandleVolumeProfile_Safe.mq4 |
//|  K线成交量节点 — 每根K线的成交量在其价格范围内的重心               |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum -100
#property indicator_maximum 100
double volCenter[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,volCenter);SetIndexLabel(0,"Vol Center%");SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("VolCenter_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-50;if(limit<0)limit=0;
   for(int i=limit;i>=1;i++){
      double o=iOpen(_Symbol,_Period,i),h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i),r=h-l;if(r<_Point)r=_Point;
      // 估算成交量重心：用收盘位置+实体方向推算成交量集中的价格区
      double bodyPos=(MathMax(o,c)+MathMin(o,c))/2; // 实体中位
      double cPos=(c-l)/r; // 收盘位置
      // 重心偏上(>50)=成交量集中在高位=买方积极
      double center=(bodyPos-l)/r*100; // 实体中心在范围内的位置
      if(cPos>0.5)center+=20; // 收盘高位加分
      if(cPos<0.5)center-=20;
      volCenter[i]=MathMax(-100,MathMin(100,center-50));buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=2;i++){if(volCenter[i+1]<-30&&volCenter[i]>30)buySignal[i]=-40;if(volCenter[i+1]>30&&volCenter[i]<-30)sellSignal[i]=40;}
   if(Bars>0){volCenter[0]=volCenter[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}return(0);}
