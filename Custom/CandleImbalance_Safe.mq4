#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                        CandleImbalance_Safe.mq4   |
//|  K线失衡 — 窗口内阳线vs阴线的数量/幅度失衡度                       |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum -100
#property indicator_maximum 100
input int InpPeriod=10;
double imbalance[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,imbalance);SetIndexLabel(0,"Imbalance");SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("Imbal_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-50;if(limit<0)limit=0;
   for(int i=limit;i>=1;i--){
      int bullCnt=0,bearCnt=0;double bullRange=0,bearRange=0;
      for(int j=0;j<InpPeriod;j++){double r=iHigh(_Symbol,_Period,i+j)-iLow(_Symbol,_Period,i+j);if(iClose(_Symbol,_Period,i+j)>iOpen(_Symbol,_Period,i+j)){bullCnt++;bullRange+=r;}else{bearCnt++;bearRange+=r;}}
      // 失衡 = (数量差% + 幅度差%) / 2
      double cntBias=100.0*(bullCnt-bearCnt)/InpPeriod;
      double rngBias=SafeDivide(100*(bullRange-bearRange),bullRange+bearRange,0);
      imbalance[i]=(cntBias+rngBias)/2;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=3;i++){if(imbalance[i+1]<-40&&imbalance[i]>40)buySignal[i]=-50;if(imbalance[i+1]>40&&imbalance[i]<-40)sellSignal[i]=50;}
   if(Bars>0){imbalance[0]=imbalance[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}return(0);}
