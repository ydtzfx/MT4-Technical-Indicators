#include "../Include/Common.mqh"
#include "../Include/Drawing.mqh"
//+------------------------------------------------------------------+
//|                                          GannSquare_Safe.mq4      |
//|  Gann Square of 9 — 江恩四方图                                     |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 2
input double InpStartPrice=1.0;input double InpStep=1.0;input int InpRings=6;
double buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(0,buySignal);SetIndexArrow(0,ARROW_BUY);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(1,sellSignal);SetIndexArrow(1,ARROW_SELL);SetIndexEmptyValue(1,EMPTY_VALUE);IndicatorDigits(4);IndicatorShortName("GannSquare_Safe");return(0);}
int deinit(){RemoveAllObjects();return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;RemoveAllObjects();
   for(int i=limit;i>=100;i--){
      double base=iClose(_Symbol,_Period,i);double step=InpStep*Point;if(InpStartPrice>0)base=InpStartPrice;if(InpStartPrice>0)step=InpStep;
      // Gann关键角度线: 每圈8个方向的价格水平
      for(int ring=1;ring<=InpRings;ring++){
         double r=ring*step;double levels[8];for(int k=0;k<8;k++)levels[k]=base+r*(k+1)/8;
         for(int kk=0;k<8;k++){
            string nm=OBJ_PREFIX+"GS_"+IntegerToString(i)+"_"+IntegerToString(ring)+"_"+IntegerToString(k);
            if(ObjectFind(nm)<0){ObjectCreate(nm,OBJ_HLINE,0,0,levels[k]);ObjectSet(nm,OBJPROP_COLOR,k==0||k==4?clrYellow:clrGray);ObjectSet(nm,OBJPROP_STYLE,ring==1?STYLE_SOLID:STYLE_DOT);}
         }
      }
      double c=iClose(_Symbol,_Period,i);int nearest=-1;double minDist=99999;
      for(int ringg=1;ring<=InpRings;ring++){double lvl=base+ring*step*0.375;double dist=MathAbs(c-lvl);if(dist<minDist){minDist=dist;nearest=ring;}}
      if(nearest>0&&c>base)buySignal[i]=base-5*Point;
      break;}
   return(0);}
