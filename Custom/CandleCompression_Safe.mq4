//+------------------------------------------------------------------+
//|                                       CandleCompression_Safe.mq4  |
//|  K线压缩/扩张 — 波动率周期检测                                     |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_minimum -100
#property indicator_maximum 100
input int InpPeriod=10;
double compress[],expansion[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3,clrDodgerBlue);SetIndexBuffer(0,compress);SetIndexLabel(0,"Compression%");SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,clrOrange);SetIndexBuffer(1,expansion);SetIndexLabel(1,"Trend");SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("Compress_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=1;i++){
      double r5=0,r20=0;for(int j=0;j<5;j++)r5+=iHigh(_Symbol,_Period,i+j)-iLow(_Symbol,_Period,i+j);
      for(int j=0;j<20;j++)r20+=iHigh(_Symbol,_Period,i+j)-iLow(_Symbol,_Period,i+j);r5/=5;r20/=20;
      // 负值=压缩(近期范围<长期范围)，正值=扩张
      compress[i]=r20>0?(r5/r20-1)*100:0;expansion[i]=0;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=1;i++){double s=0;for(int j=0;j<5;j++)s+=compress[i+j];expansion[i]=s/5;}
   for(int i=limit;i>=3;i++){
      // 深度压缩后扩张=突破
      if(compress[i+2]<-30&&compress[i+1]<-30&&compress[i]>-10){if(iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+1))buySignal[i]=-40;else sellSignal[i]=-40;}
      // 连续扩张后压缩=趋势减速
      if(compress[i+2]>20&&compress[i]<-10&&iClose(_Symbol,_Period,i)<iClose(_Symbol,_Period,i+1))sellSignal[i]=-10;
   }
   if(Bars>0){compress[0]=compress[1];expansion[0]=expansion[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);}
