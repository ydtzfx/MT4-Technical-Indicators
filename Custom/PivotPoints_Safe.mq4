#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                            PivotPoints_Safe.mq4   |
//|  枢轴点指标（Floor/Camarilla/Woodie）— 不含未来函数               |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  基于前一周期OHLC计算关键支撑阻力位                                 |
//|  Floor: PP=(H+L+C)/3, R1=2PP-L, S1=2PP-H, R2=PP+(H-L)...        |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 9

input int InpDayBars=24; // H1=24h
input ENUM_MA_METHOD_SAFE InpType=MA_SMA; // 0=Floor,1=Camarilla,2=Woodie (用MA类型模拟)

double pp[],r1[],s1[],r2[],s2[],r3[],s3[],buySignal[],sellSignal[];
int pivotType=0; // Floor by default

int init() {
   pivotType=(int)InpType;if(pivotType>2)pivotType=0;
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrWhite);SetIndexBuffer(0,pp);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"PP");
   SetIndexStyle(1,DRAW_LINE,STYLE_DOT,1,clrYellow);SetIndexBuffer(1,r1);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"R1");
   SetIndexStyle(2,DRAW_LINE,STYLE_DOT,1,clrYellow);SetIndexBuffer(2,s1);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexLabel(2,"S1");
   SetIndexStyle(3,DRAW_LINE,STYLE_DOT,1,clrOrange);SetIndexBuffer(3,r2);SetIndexEmptyValue(3,EMPTY_VALUE);SetIndexLabel(3,"R2");
   SetIndexStyle(4,DRAW_LINE,STYLE_DOT,1,clrOrange);SetIndexBuffer(4,s2);SetIndexEmptyValue(4,EMPTY_VALUE);SetIndexLabel(4,"S2");
   SetIndexStyle(5,DRAW_LINE,STYLE_DOT,1,clrTomato);SetIndexBuffer(5,r3);SetIndexEmptyValue(5,EMPTY_VALUE);SetIndexLabel(5,"R3");
   SetIndexStyle(6,DRAW_LINE,STYLE_DOT,1,clrLimeGreen);SetIndexBuffer(6,s3);SetIndexEmptyValue(6,EMPTY_VALUE);SetIndexLabel(6,"S3");
   SetIndexStyle(7,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(7,buySignal);SetIndexArrow(7,ARROW_BUY);SetIndexEmptyValue(7,EMPTY_VALUE);
   SetIndexStyle(8,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(8,sellSignal);SetIndexArrow(8,ARROW_SELL);SetIndexEmptyValue(8,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("Pivot_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){pp[i]=r1[i]=s1[i]=r2[i]=s2[i]=r3[i]=s3[i]=0;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;}

   for(i=limit+InpDayBars;i>=InpDayBars;i--) {
      double h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i),o=iOpen(_Symbol,_Period,i);
      for(int j=1;j<InpDayBars;j++){double hh=iHigh(_Symbol,_Period,i+j),ll=iLow(_Symbol,_Period,i+j);if(hh>h)h=hh;if(ll<l)l=ll;}
      double pivot=0,rng=h-l;
      if(pivotType==0){pivot=(h+l+c)/3;r1[i]=2*pivot-l;s1[i]=2*pivot-h;r2[i]=pivot+rng;s2[i]=pivot-rng;r3[i]=h+2*(pivot-l);s3[i]=l-2*(h-pivot);}
      else if(pivotType==1){pivot=(h+l+c)/3;r1[i]=c+rng*1.1/12;s1[i]=c-rng*1.1/12;r2[i]=c+rng*1.1/6;s2[i]=c-rng*1.1/6;r3[i]=c+rng*1.1/4;s3[i]=c-rng*1.1/4;}
      else{pivot=(h+l+o*2)/4;r1[i]=2*pivot-l;s1[i]=2*pivot-h;r2[i]=pivot+rng;s2[i]=pivot-rng;r3[i]=h+2*(pivot-l);s3[i]=l-2*(h-pivot);}
      pp[i]=pivot;
   }
   for(i=limit;i>=1;i--) {
      c=iClose(_Symbol,_Period,i);double c1=iClose(_Symbol,_Period,i+1);
      if(c1<=s1[i+1]&&c>s1[i]&&c>pp[i])buySignal[i]=s2[i]-5*Point;
      if(c1>=r1[i+1]&&c<r1[i]&&c<pp[i])sellSignal[i]=r2[i]+5*Point;
   }
   return(0);
}
