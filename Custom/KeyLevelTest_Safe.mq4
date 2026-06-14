#include "../Include/Common.mqh"
#include "../Include/PriceData.mqh"
//+------------------------------------------------------------------+
//|                                          KeyLevelTest_Safe.mq4    |
//|  关键位测试K线 — 检测价格对关键位的触碰和反应                      |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
input int InpSRLookback=50;
double testResist[],testSupport[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,2,clrTomato);SetIndexBuffer(0,testResist);SetIndexArrow(0,ARROW_SELL);SetIndexLabel(0,"Test Resist");SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,clrLimeGreen);SetIndexBuffer(1,testSupport);SetIndexArrow(1,ARROW_BUY);SetIndexLabel(1,"Test Support");SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("KeyLevel_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){testResist[i]=testSupport[i]=buySignal[i]=sellSignal[i]=EMPTY_VALUE;}
   for(i=limit;i>=10;i--){
      double hh=iHigh(_Symbol,_Period,i+1),ll=iLow(_Symbol,_Period,i+1);
      for(int j=2;j<InpSRLookback;j++){double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);if(h>hh)hh=h;if(l<ll)ll=l;}
      double c=iClose(_Symbol,_Period,i);h=iHigh(_Symbol,_Period,i);l=iLow(_Symbol,_Period,i);
      double atr=0;for(int jj=0;j<14;j++)atr+=GetTrueRange(_Symbol,_Period,i+j);atr/=14;double tol=atr*0.2;
      // 触碰阻力
      if(MathAbs(h-hh)<tol){testResist[i]=h+3*Point;if(c<h&&c<hh)sellSignal[i]=h+8*Point;}
      // 触碰支撑
      if(MathAbs(l-ll)<tol){testSupport[i]=l-3*Point;if(c>l&&c>ll)buySignal[i]=l-8*Point;}
      // 突破阻力+确认=真突破买入
      if(c>hh&&iClose(_Symbol,_Period,i+1)<=hh)buySignal[i]=l-10*Point;
   }
   return(0);}
