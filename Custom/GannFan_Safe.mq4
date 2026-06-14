#include "../Include/Common.mqh"
#include "../Include/Drawing.mqh"
//+------------------------------------------------------------------+
//|                                          GannFan_Safe.mq4         |
//|  Gann Fan — 江恩角度线 1x1/1x2/2x1等                              |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 2
input int InpPivotBars=50;input double InpPointPerBar=1.0; // 每根bar的价格步长
double buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(0,buySignal);SetIndexArrow(0,ARROW_BUY);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(1,sellSignal);SetIndexArrow(1,ARROW_SELL);SetIndexEmptyValue(1,EMPTY_VALUE);IndicatorDigits(4);IndicatorShortName("GannFan_Safe");return(0);}
int deinit(){RemoveObjectsByPrefix("GF_");return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;RemoveObjectsByPrefix("GF_");
   for(int i=limit;i>=InpPivotBars;i--){
      double ll=iLow(_Symbol,_Period,i);int llBar=i;
      for(int j=1;j<InpPivotBars;j++){if(iLow(_Symbol,_Period,i+j)<ll){ll=iLow(_Symbol,_Period,i+j);llBar=i+j;}}
      double ratios[]={1.0/8,1.0/4,1.0/3,1.0/2,1.0,2.0,3.0,4.0,8.0};
      color clrs[]={clrGray,clrGray,clrYellow,clrOrange,clrRed,clrGreen,clrOrange,clrYellow,clrGray};
      for(int r=0;r<9;r++){
         double price=ll+ratios[r]*InpPointPerBar*Point*(i-llBar);
         string nm=OBJ_PREFIX+"GF_"+IntegerToString(i)+"_"+IntegerToString(r);
         if(ObjectFind(nm)<0){ObjectCreate(nm,OBJ_TREND,0,iTime(_Symbol,_Period,llBar),ll,iTime(_Symbol,_Period,i),price);ObjectSet(nm,OBJPROP_COLOR,clrs[r]);ObjectSet(nm,OBJPROP_WIDTH,ratios[r]==1?2:1);ObjectSet(nm,OBJPROP_RAY,true);}
      }
      double c=iClose(_Symbol,_Period,i);if(c<ll*1.1)buySignal[i]=ll-3*Point;
      break;}
   return(0);}
