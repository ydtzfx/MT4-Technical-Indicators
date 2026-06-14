#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                        CandleEquilibrium_Safe.mq4 |
//|  K线均衡点 — N根K线价格重合的中心区域                              |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
input int InpPeriod=10;
double equiHi[],equiLo[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_LINE,STYLE_DASH,2,clrYellow);SetIndexBuffer(0,equiHi);SetIndexLabel(0,"Equi Hi");SetIndexStyle(1,DRAW_LINE,STYLE_DASH,2,clrYellow);SetIndexBuffer(1,equiLo);SetIndexLabel(1,"Equi Lo");SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(4);IndicatorShortName("Equi_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){equiHi[i]=equiLo[i]=buySignal[i]=sellSignal[i]=EMPTY_VALUE;}
   for(i=limit;i>=InpPeriod;i--){
      // 均衡区域：N根K线的价格交集(重叠最多的区间)
      double hi=iHigh(_Symbol,_Period,i),lo=iLow(_Symbol,_Period,i);
      for(int j=1;j<InpPeriod;j++){if(iHigh(_Symbol,_Period,i+j)<hi)hi=iHigh(_Symbol,_Period,i+j);if(iLow(_Symbol,_Period,i+j)>lo)lo=iLow(_Symbol,_Period,i+j);}
      if(hi>lo){equiHi[i]=hi;equiLo[i]=lo;double c=iClose(_Symbol,_Period,i);
         if(c>hi)buySignal[i]=lo-5*Point;else if(c<lo)sellSignal[i]=hi+5*Point;}
   }return(0);}
