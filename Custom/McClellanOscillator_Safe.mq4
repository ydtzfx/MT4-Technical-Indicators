#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                    McClellanOscillator_Safe.mq4   |
//|  麦克莱伦振荡器 — 市场宽度指标（单品种模拟版）                      |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  模拟版：用价格在N根bar中的"上涨bar比例"代替涨跌家数比              |
//|  公式：McOsc=EMA(UpRatio,Short)-EMA(UpRatio,Long)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_level1 0

input int InpShort=19;input int InpLong=39;

double mcOsc[],buySignal[],sellSignal[];

int init(){SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,mcOsc);SetIndexLabel(0,"McC Osc");SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);IndicatorDigits(1);IndicatorShortName("McOsc_Safe");return(0);}
int deinit(){return(0);}

int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   // 计算上涨bar比例序列
   double upRatio[];ArrayResize(upRatio,Bars);
   for(int i=Bars-2;i>=1;i--){int up=0;for(int j=0;j<5;j++)if(iClose(_Symbol,_Period,i+j)>iClose(_Symbol,_Period,i+j+1))up++;upRatio[i]=up/5.0;}
   double aS=2.0/(InpShort+1),aL=2.0/(InpLong+1);
   for(i=limit;i>=1;i--){
      double eS=0,eL=0;for(int jj=0;j<InpLong*2;j++){eS+=upRatio[i+j];eL+=upRatio[i+j];}eS/=(InpLong*2);eL/=(InpLong*2);
      for(int jjj=InpLong*2-1;j>=0;j--){eS=upRatio[i+j]*aS+eS*(1-aS);eL=upRatio[i+j]*aL+eL*(1-aL);}
      mcOsc[i]=eS-eL;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=2;i--){
      if(mcOsc[i+1]<-0.1&&mcOsc[i]>-0.1)buySignal[i]=-0.15;
      if(mcOsc[i+1]>0.1&&mcOsc[i]<0.1)sellSignal[i]=0.15;
   }
   if(Bars>0){mcOsc[0]=mcOsc[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);}
