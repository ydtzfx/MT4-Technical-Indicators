#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                   CandlePatternScanner_Safe.mq4   |
//|  K线形态扫描器 — 8种形态识别                                      |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 8

input bool InpShowLabels=true;

double doji[],hammer[],shooting[],engulfBull[],engulfBear[],morningStar[],eveningStar[],harami[];

int init(){
   // MQL4不支持 double *b[] 指针数组，必须逐缓冲区绑定
   SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,2,clrGray);SetIndexBuffer(0,doji);SetIndexArrow(0,108);SetIndexLabel(0,"Doji");SetIndexEmptyValue(0,EMPTY_VALUE);
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,hammer);SetIndexArrow(1,ARROW_BUY);SetIndexLabel(1,"Hammer");SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,shooting);SetIndexArrow(2,ARROW_SELL);SetIndexLabel(2,"ShootingStar");SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(3,engulfBull);SetIndexArrow(3,ARROW_BUY);SetIndexLabel(3,"EngulfBull");SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(4,engulfBear);SetIndexArrow(4,ARROW_SELL);SetIndexLabel(4,"EngulfBear");SetIndexEmptyValue(4,EMPTY_VALUE);
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(5,morningStar);SetIndexArrow(5,ARROW_BUY);SetIndexLabel(5,"MorningStar");SetIndexEmptyValue(5,EMPTY_VALUE);
   SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(6,eveningStar);SetIndexArrow(6,ARROW_SELL);SetIndexLabel(6,"EveningStar");SetIndexEmptyValue(6,EMPTY_VALUE);
   SetIndexStyle(7,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(7,harami);SetIndexArrow(7,ARROW_BUY);SetIndexLabel(7,"Harami");SetIndexEmptyValue(7,EMPTY_VALUE);
   IndicatorDigits(0);IndicatorShortName("CandleScan_Safe");return(0);
}
int deinit(){return(0);}

int start(){
   int i;
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   for(i=limit;i>=0;i--){doji[i]=hammer[i]=shooting[i]=engulfBull[i]=engulfBear[i]=morningStar[i]=eveningStar[i]=harami[i]=EMPTY_VALUE;}
   for(i=limit;i>=3;i--){
      double o=iOpen(_Symbol,_Period,i),h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i);
      double po=iOpen(_Symbol,_Period,i+1),ph=iHigh(_Symbol,_Period,i+1),pl=iLow(_Symbol,_Period,i+1),pc=iClose(_Symbol,_Period,i+1);
      double range=h-l,body=MathAbs(c-o);double pRange=ph-pl,pBody=MathAbs(pc-po);
      double upperW=h-MathMax(o,c),lowerW=MathMin(o,c)-l;
      if(range<_Point)continue;
      // Doji
      if(body<range*0.1)doji[i]=l-3*Point;
      // Hammer (下影线>实体2倍)
      if(lowerW>body*2&&upperW<body*0.5&&c<pc)hammer[i]=l-5*Point;
      // Shooting Star
      if(upperW>body*2&&lowerW<body*0.5&&c>pc)shooting[i]=h+5*Point;
      // Engulfing Bull
      if(c>o&&pc<po&&c>po&&o<pc)engulfBull[i]=l-8*Point;
      // Engulfing Bear
      if(c<o&&pc>po&&c<po&&o>pc)engulfBear[i]=h+8*Point;
      // Morning Star
      double p2c=iClose(_Symbol,_Period,i+2),p2o=iOpen(_Symbol,_Period,i+2);
      if(c>o&&pc<po&&MathAbs(pc-po)<pRange*0.3&&p2c<p2o&&c>p2o)morningStar[i]=l-10*Point;
      // Evening Star
      if(c<o&&pc>po&&MathAbs(pc-po)<pRange*0.3&&p2c>p2o&&c<p2o)eveningStar[i]=h+10*Point;
      // Harami
      if(body<pBody*0.5&&MathMax(o,c)<MathMax(po,pc)&&MathMin(o,c)>MathMin(po,pc)){if(c>o)harami[i]=l-5*Point;else harami[i]=h+5*Point;}
   }
   return(0);
}
