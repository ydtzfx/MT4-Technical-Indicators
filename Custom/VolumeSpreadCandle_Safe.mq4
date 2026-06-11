//+------------------------------------------------------------------+
//|                                    VolumeSpreadCandle_Safe.mq4    |
//|  VSA量价K线 — Volume Spread Analysis on Candles                   |
//|  量价四象限：放量+宽幅=趋势，缩量+窄幅=蓄力                       |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 5
input int InpAvgPeriod=20;
double vsaSignal[],volZ[],spreadZ[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,vsaSignal);SetIndexLabel(0,"VSA Signal");SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,clrYellow);SetIndexBuffer(1,volZ);SetIndexLabel(1,"Vol Z");SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1,clrGray);SetIndexBuffer(2,spreadZ);SetIndexLabel(2,"Spread Z");SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(3,buySignal);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(4,sellSignal);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);IndicatorDigits(1);IndicatorShortName("VSA_Candle_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=1;i--){
      double r=iHigh(_Symbol,_Period,i)-iLow(_Symbol,_Period,i),v=iVolume(_Symbol,_Period,i);
      double avgR=0,avgV=0,sdR=0,sdV=0;
      for(int j=0;j<InpAvgPeriod;j++){double rj=iHigh(_Symbol,_Period,i+j)-iLow(_Symbol,_Period,i+j);avgR+=rj;avgV+=iVolume(_Symbol,_Period,i+j);}avgR/=InpAvgPeriod;avgV/=InpAvgPeriod;
      for(int j=0;j<InpAvgPeriod;j++){double rj=iHigh(_Symbol,_Period,i+j)-iLow(_Symbol,_Period,i+j);sdR+=(rj-avgR)*(rj-avgR);sdV+=(iVolume(_Symbol,_Period,i+j)-avgV)*(iVolume(_Symbol,_Period,i+j)-avgV);}
      sdR=MathSqrt(sdR/InpAvgPeriod);sdV=MathSqrt(sdV/InpAvgPeriod);
      volZ[i]=sdV>0?(v-avgV)/sdV:0;spreadZ[i]=sdR>0?(r-avgR)/sdR:0;
      bool isUp=iClose(_Symbol,_Period,i)>iOpen(_Symbol,_Period,i);
      double sig=volZ[i]+spreadZ[i];if(isUp)sig=MathAbs(sig);else sig=-MathAbs(sig);
      vsaSignal[i]=sig;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=2;i--){
      if(volZ[i+1]<-1&&spreadZ[i+1]<-1&&volZ[i]>0&&spreadZ[i]>0){if(vsaSignal[i]>0)buySignal[i]=-5;else sellSignal[i]=5;}
      if(volZ[i]>2&&spreadZ[i]<0&&iClose(_Symbol,_Period,i)<iOpen(_Symbol,_Period,i))sellSignal[i]=5; // 巨量滞涨
   }
   if(Bars>0){vsaSignal[0]=vsaSignal[1];volZ[0]=volZ[1];spreadZ[0]=spreadZ[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);}
