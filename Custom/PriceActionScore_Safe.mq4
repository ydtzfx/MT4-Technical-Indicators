#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                        PriceActionScore_Safe.mq4  |
//|  Price Action综合评分 — 多K线形态加权评分                          |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum -100
#property indicator_maximum 100
#property indicator_level1 40
#property indicator_level2 -40
input int InpLookback=5;
double paScore[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,paScore);SetIndexLabel(0,"PA Score");SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("PAScore_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=1;i--){
      int score=0;
      for(int j=0;j<InpLookback;j++){
         int s=i+j;double o=iOpen(_Symbol,_Period,s),h=iHigh(_Symbol,_Period,s),l=iLow(_Symbol,_Period,s),c=iClose(_Symbol,_Period,s);
         double r=h-l;if(r<_Point)continue;
         double body=MathAbs(c-o),upW=h-MathMax(o,c),loW=MathMin(o,c)-l;
         // 阳线得分
         if(c>o){score+=10;if(body>r*0.6)score+=15;if(loW<body*0.3)score+=10;if((c-l)>r*0.8)score+=15;}
         // 阴线扣分
         if(c<o){score-=10;if(body>r*0.6)score-=15;if(upW<body*0.3)score-=10;if((h-c)>r*0.8)score-=15;}
         // 影线信号
         if(loW>body*2&&loW>r*0.4)score+=20; // 长下影
         if(upW>body*2&&upW>r*0.4)score-=20; // 长上影
         // 收盘位置
         double cPos=(c-l)/r;if(cPos>0.7)score+=5;if(cPos<0.3)score-=5;
         // 权重衰减(越近权重越大)
         score=(int)(score*(1.0-j*0.15));
      }
      paScore[i]=MathMax(-100,MathMin(100,score));buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=2;i++){
      if(paScore[i+1]<-40&&paScore[i]>-40)buySignal[i]=-50;
      if(paScore[i+1]>40&&paScore[i]<40)sellSignal[i]=50;
   }
   if(Bars>0){paScore[0]=paScore[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);}
