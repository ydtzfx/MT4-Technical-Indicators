//+------------------------------------------------------------------+
//|                                       VolumeFootprint_Safe.mq4    |
//|  成交量足迹图 — 每根bar内部的价格-成交量分布                       |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 5
input int InpLevels=10; // K线内价格分层数
double bidVol[],askVol[],delta[],cumDelta[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,2,clrLimeGreen);SetIndexBuffer(0,bidVol);SetIndexLabel(0,"Buy Vol");SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,2,clrTomato);SetIndexBuffer(1,askVol);SetIndexLabel(1,"Sell Vol");SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(2,delta);SetIndexLabel(2,"Bar Delta");SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(3,buySignal);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(4,sellSignal);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("Footprint_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   double cumD=0;
   for(int i=limit+50;i>=1;i--){
      double h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i),o=iOpen(_Symbol,_Period,i);
      long v=iVolume(_Symbol,_Period,i);double range=h-l;if(range<Point)range=Point;
      // 估算买卖量：基于K线内部价格位置
      double bodyUp=MathMax(0,c-o),bodyDn=MathMax(0,o-c);
      double buyV=(bodyUp/range+(l<o?0:(c-l)/range*0.5))*v;
      double sellV=(bodyDn/range+(h>c?0:(h-c)/range*0.5))*v;
      cumD+=buyV-sellV;
      if(i<=limit){bidVol[i]=buyV;askVol[i]=sellV;delta[i]=buyV-sellV;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;}
   }
   for(int i=limit;i>=2;i--){
      if(delta[i+1]<0&&delta[i]>0&&iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+1))buySignal[i]=delta[i]*0.5;
      if(delta[i+1]>0&&delta[i]<0&&iClose(_Symbol,_Period,i)<iClose(_Symbol,_Period,i+1))sellSignal[i]=delta[i]*1.5;
   }
   if(Bars>0){bidVol[0]=bidVol[1];askVol[0]=askVol[1];delta[0]=delta[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);}
