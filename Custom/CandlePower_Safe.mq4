#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                            CandlePower_Safe.mq4   |
//|  K线力量：综合实体/影线/位置评估多空力量                           |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum -100
#property indicator_maximum 100
input int InpSmooth=3;
double power[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,power);SetIndexLabel(0,"Candle Power");SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("CandlePower_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=1;i--){
      double o=iOpen(_Symbol,_Period,i),h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i),r=h-l;if(r<_Point)r=_Point;
      double body=(c-o)/r*100;      // 实体分数(-100到100)
      double uW=(h-MathMax(o,c))/r*100; // 上影线%
      double lW=(MathMin(o,c)-l)/r*100; // 下影线%
      double closePos=(c-l)/r*100;      // 收盘位置%
      // 买方力量 = 实体方向(正) + 收盘高位 + 下影线短
      double bullP=(body>0?body:0)+closePos-lW;
      // 卖方力量 = 实体方向(负) + 收盘低位 + 上影线短
      double bearP=(body<0?-body:0)+(100-closePos)-uW;
      power[i]=MathMax(-100,MathMin(100,bullP-bearP));
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=3;i++){
      if(power[i+1]<-30&&power[i]>30&&power[i+2]<-20)buySignal[i]=-40;
      if(power[i+1]>30&&power[i]<-30&&power[i+2]>20)sellSignal[i]=40;
   }
   if(Bars>0){power[0]=power[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);}
