#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                           WRB_HiddenGap_Safe.mq4  |
//|  宽幅实体+隐藏缺口（WRB Hidden Gap）检测                            |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
input double InpWRBThreshold=1.5; // 实体>均幅*倍数
double wrbUp[],wrbDn[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(0,wrbUp);SetIndexArrow(0,ARROW_BUY);SetIndexLabel(0,"WRB Up");SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(1,wrbDn);SetIndexArrow(1,ARROW_SELL);SetIndexLabel(1,"WRB Down");SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("WRB_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){wrbUp[i]=wrbDn[i]=buySignal[i]=sellSignal[i]=EMPTY_VALUE;}
   double avgBody=0;for(int j=0;j<20;j++)avgBody+=MathAbs(iClose(_Symbol,_Period,limit+10+j)-iOpen(_Symbol,_Period,limit+10+j));avgBody/=20;
   for(i=limit;i>=3;i--){
      double body=MathAbs(iClose(_Symbol,_Period,i)-iOpen(_Symbol,_Period,i));
      if(body>avgBody*InpWRBThreshold){
         double upShadow=iHigh(_Symbol,_Period,i)-MathMax(iOpen(_Symbol,_Period,i),iClose(_Symbol,_Period,i));
         double loShadow=MathMin(iOpen(_Symbol,_Period,i),iClose(_Symbol,_Period,i))-iLow(_Symbol,_Period,i);
         // WRB+几乎无影线=强势方向
         if(iClose(_Symbol,_Period,i)>iOpen(_Symbol,_Period,i)&&upShadow<body*0.1)wrbUp[i]=iLow(_Symbol,_Period,i)-5*Point;
         if(iClose(_Symbol,_Period,i)<iOpen(_Symbol,_Period,i)&&loShadow<body*0.1)wrbDn[i]=iHigh(_Symbol,_Period,i)+5*Point;
         // Hidden Gap: WRB的实体区间成为支撑/阻力
         if(wrbUp[i]!=EMPTY_VALUE&&i>=4&&iLow(_Symbol,_Period,i-1)>iOpen(_Symbol,_Period,i))buySignal[i-1]=iLow(_Symbol,_Period,i-1)-8*Point;
      }
   }
   return(0);}
