#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                                   TEMA_Safe.mq4   |
//|  三重指数移动平均（TEMA）— 不含未来函数                            |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：TEMA=3*EMA-3*EMA(EMA)+EMA(EMA(EMA))                         |
//|  Patrick Mulloy设计，比EMA更快响应趋势变化                        |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5

input int InpPeriod=14;input color InpColor=clrOrange;

double tema[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,InpColor);SetIndexBuffer(0,tema);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"TEMA");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexBuffer(3,strongBuy);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexArrow(3,233);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexBuffer(4,strongSell);SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexArrow(4,234);SetIndexEmptyValue(4,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("TEMA_Safe("+IntegerToString(InpPeriod)+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   int hist=InpPeriod*3;if(limit>Bars-2)limit=Bars-hist;if(limit<0)limit=0;

   double a=2.0/(InpPeriod+1);
   // EMA1
   double e1[];ArrayResize(e1,Bars);
   for(int i=Bars-2;i>=0;i--){
      if(i>=Bars-hist)e1[i]=iClose(_Symbol,_Period,i);
      else e1[i]=iClose(_Symbol,_Period,i)*a+e1[i+1]*(1-a);
   }
   // EMA2 = EMA of EMA1
   double e2[];ArrayResize(e2,Bars);
   for(i=Bars-2;i>=0;i--){
      if(i>=Bars-hist)e2[i]=e1[i];
      else e2[i]=e1[i]*a+e2[i+1]*(1-a);
   }
   // EMA3 = EMA of EMA2
   double e3[];ArrayResize(e3,Bars);
   for(i=Bars-2;i>=0;i--){
      if(i>=Bars-hist)e3[i]=e2[i];
      else e3[i]=e2[i]*a+e3[i+1]*(1-a);
   }
   // TEMA = 3*EMA1 - 3*EMA2 + EMA3
   for(i=limit;i>=1;i--){tema[i]=3*e1[i]-3*e2[i]+e3[i];buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;}
   for(i=limit;i>=2;i--){
      double c=iClose(_Symbol,_Period,i),c1=iClose(_Symbol,_Period,i+1);
      // Strong signals: cross + TEMA slope confirmation + price above/below TEMA
      if(c1<=tema[i+1]&&c>tema[i]&&tema[i]>tema[i+1]&&c>tema[i])strongBuy[i]=iLow(_Symbol,_Period,i)-10*Point;
      else if(c1<=tema[i+1]&&c>tema[i])buySignal[i]=iLow(_Symbol,_Period,i)-5*Point;
      if(c1>=tema[i+1]&&c<tema[i]&&tema[i]<tema[i+1]&&c<tema[i])strongSell[i]=iHigh(_Symbol,_Period,i)+10*Point;
      else if(c1>=tema[i+1]&&c<tema[i])sellSignal[i]=iHigh(_Symbol,_Period,i)+5*Point;
   }
   if(Bars>0){tema[0]=3*e1[0]-3*e2[0]+e3[0];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=EMPTY_VALUE;strongSell[0]=EMPTY_VALUE;}
   return(0);
}
