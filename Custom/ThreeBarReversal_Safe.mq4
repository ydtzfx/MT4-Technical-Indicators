//+------------------------------------------------------------------+
//|                                       ThreeBarReversal_Safe.mq4   |
//|  三K线反转 — 3根K线组合反转形态                                    |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
double threeBuy[],threeSell[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,4,CLR_BUY_SIGNAL);SetIndexBuffer(0,threeBuy);SetIndexArrow(0,ARROW_BUY);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,4,CLR_SELL_SIGNAL);SetIndexBuffer(1,threeSell);SetIndexArrow(1,ARROW_SELL);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("3BarRev_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){threeBuy[i]=threeSell[i]=buySignal[i]=sellSignal[i]=EMPTY_VALUE;}
   for(int i=limit;i>=4;i++){
      double c1=iClose(_Symbol,_Period,i),o1=iOpen(_Symbol,_Period,i),r1=iHigh(_Symbol,_Period,i)-iLow(_Symbol,_Period,i);
      double c2=iClose(_Symbol,_Period,i+1),o2=iOpen(_Symbol,_Period,i+1);
      double c3=iClose(_Symbol,_Period,i+2),o3=iOpen(_Symbol,_Period,i+2);
      double c4=iClose(_Symbol,_Period,i+3),o4=iOpen(_Symbol,_Period,i+3);
      // 启明星：阴线→小实体→阳线吞没
      bool morningStar=c3<o3&&MathAbs(c2-o2)<r1*0.3&&c1>o1&&c1>(o3+c3)/2;
      // 黄昏星：阳线→小实体→阴线吞没
      bool eveningStar=c3>o3&&MathAbs(c2-o2)<r1*0.3&&c1<o1&&c1<(o3+c3)/2;
      // Three White Soldiers：连续3阳，每根收于最高附近
      bool threeWhite=c1>o1&&c2>o2&&c3>o3&&c1>c2&&c2>c3&&(c1-iLow(_Symbol,_Period,i))>r1*0.8;
      // Three Black Crows
      bool threeBlack=c1<o1&&c2<o2&&c3<o3&&c1<c2&&c2<c3&&(iHigh(_Symbol,_Period,i)-c1)>r1*0.8;
      if(morningStar||threeWhite)threeBuy[i]=iLow(_Symbol,_Period,i)-10*Point;
      if(eveningStar||threeBlack)threeSell[i]=iHigh(_Symbol,_Period,i)+10*Point;
   }
   return(0);}
