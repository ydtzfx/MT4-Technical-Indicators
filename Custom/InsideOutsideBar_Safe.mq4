//+------------------------------------------------------------------+
//|                                        InsideOutsideBar_Safe.mq4  |
//|  内含线/外包线检测 — Price Action核心形态                          |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
double inside[],outside[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,2,clrYellow);SetIndexBuffer(0,inside);SetIndexArrow(0,ARROW_DOT);SetIndexLabel(0,"Inside Bar");SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,3,clrOrange);SetIndexBuffer(1,outside);SetIndexArrow(1,ARROW_STOP);SetIndexLabel(1,"Outside Bar");SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("IOB_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){inside[i]=outside[i]=buySignal[i]=sellSignal[i]=EMPTY_VALUE;}
   for(int i=limit;i>=3;i--){
      double h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i),o=iOpen(_Symbol,_Period,i);
      double ph=iHigh(_Symbol,_Period,i+1),pl=iLow(_Symbol,_Period,i+1);
      // Inside Bar: 完全在前一根范围内
      if(h<ph&&l>pl){inside[i]=l-3*Point;if(c>o)buySignal[i]=l-8*Point;else sellSignal[i]=h+8*Point;}
      // Outside Bar: 完全吞没前一根
      if(h>ph&&l<pl){outside[i]=l-5*Point;if(c>o)buySignal[i]=l-10*Point;else sellSignal[i]=h+10*Point;}
   }
   return(0);}
