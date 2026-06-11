//+------------------------------------------------------------------+
//|                                    ConsecutiveSmallBody_Safe.mq4  |
//|  连续小实体 — 蓄力阶段，爆发前兆                                   |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
input double InpSmallBody=0.3;input int InpMinCount=4;
double coil[],breakSignal[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,2,clrYellow);SetIndexBuffer(0,coil);SetIndexArrow(0,ARROW_DOT);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,3,clrOrange);SetIndexBuffer(1,breakSignal);SetIndexArrow(1,ARROW_STOP);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("Coil_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){coil[i]=breakSignal[i]=buySignal[i]=sellSignal[i]=EMPTY_VALUE;}
   for(int i=limit;i>=InpMinCount+2;i--){
      int smallCnt=0;double maxR=0;
      for(int j=1;j<=InpMinCount+3;j++){double r=iHigh(_Symbol,_Period,i+j)-iLow(_Symbol,_Period,i+j);double b=MathAbs(iClose(_Symbol,_Period,i+j)-iOpen(_Symbol,_Period,i+j));if(r>0&&b<r*InpSmallBody)smallCnt++;if(j<=InpMinCount&&r>maxR)maxR=r;}
      if(smallCnt>=InpMinCount){coil[i+1]=iLow(_Symbol,_Period,i+1)-3*Point;
         double curR=iHigh(_Symbol,_Period,i)-iLow(_Symbol,_Period,i);double curB=MathAbs(iClose(_Symbol,_Period,i)-iOpen(_Symbol,_Period,i));
         if(curR>maxR*1.5&&curB>curR*0.5){breakSignal[i]=iLow(_Symbol,_Period,i)-5*Point;if(iClose(_Symbol,_Period,i)>iOpen(_Symbol,_Period,i))buySignal[i]=iLow(_Symbol,_Period,i)-10*Point;else sellSignal[i]=iHigh(_Symbol,_Period,i)+10*Point;}
      }
   }return(0);}
