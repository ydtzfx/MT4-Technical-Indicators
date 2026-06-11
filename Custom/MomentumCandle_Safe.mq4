//+------------------------------------------------------------------+
//|                                        MomentumCandle_Safe.mq4    |
//|  动量K线 — 宽幅+收于极端+放量=趋势动量                             |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
input double InpRangeMult=1.5; // 范围>均幅*倍数
double momBull[],momBear[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(0,momBull);SetIndexArrow(0,ARROW_BUY);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(1,momBear);SetIndexArrow(1,ARROW_SELL);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("MomCandle_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){momBull[i]=momBear[i]=buySignal[i]=sellSignal[i]=EMPTY_VALUE;}
   double avgR=0;for(int j=0;j<20;j++)avgR+=iHigh(_Symbol,_Period,limit+10+j)-iLow(_Symbol,_Period,limit+10+j);avgR/=20;
   double avgV=0;for(int j=0;j<20;j++)avgV+=iVolume(_Symbol,_Period,limit+10+j);avgV/=20;
   for(int i=limit;i>=3;i--){
      double range=iHigh(_Symbol,_Period,i)-iLow(_Symbol,_Period,i),body=MathAbs(iClose(_Symbol,_Period,i)-iOpen(_Symbol,_Period,i));
      double vol=iVolume(_Symbol,_Period,i);double cPos=(iClose(_Symbol,_Period,i)-iLow(_Symbol,_Period,i))/MathMax(range,Point);
      // 动量阳线：宽幅+大实体+收于高位+放量
      if(range>avgR*InpRangeMult&&body>range*0.6&&cPos>0.8&&vol>avgV*1.3){
         if(iClose(_Symbol,_Period,i)>iOpen(_Symbol,_Period,i))momBull[i]=iLow(_Symbol,_Period,i)-5*Point;
         else momBear[i]=iHigh(_Symbol,_Period,i)+5*Point;}
      // 动量K线后跟踪：下一根继续同向=趋势确认
      if(momBull[i+1]!=EMPTY_VALUE&&iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+1))buySignal[i]=iLow(_Symbol,_Period,i)-10*Point;
   }
   return(0);}
