#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                   VolumeDeltaDivergence_Safe.mq4  |
//|  量价Delta背离 — 原创复合指标                                      |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  概念：同时检测三组背离：                                            |
//|  1. 价格与累积Delta背离（新高无Delta确认）                          |
//|  2. 价格与OBV背离（新高无量确认）                                   |
//|  3. 价格与MFI背离（新高无资金流确认）                               |
//|  三组都背离=强背离信号，两组背离=中等信号，一组=弱信号               |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_minimum -100
#property indicator_maximum 100
#property indicator_level1 66
#property indicator_level2 -66

input int InpDivPeriod=10;

double divScore[],deltaDiv[],obvDiv[],mfiDiv[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,divScore);SetIndexLabel(0,"Divergence Score");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,clrDodgerBlue);SetIndexBuffer(1,deltaDiv);SetIndexLabel(1,"Delta Div");
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1,clrOrange);SetIndexBuffer(2,obvDiv);SetIndexLabel(2,"OBV Div");
   SetIndexStyle(3,DRAW_LINE,STYLE_SOLID,1,clrMagenta);SetIndexBuffer(3,mfiDiv);SetIndexLabel(3,"MFI Div");
   SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(4,buySignal);SetIndexArrow(4,ARROW_BUY);SetIndexEmptyValue(4,EMPTY_VALUE);
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(5,sellSignal);SetIndexArrow(5,ARROW_SELL);SetIndexEmptyValue(5,EMPTY_VALUE);
   IndicatorDigits(0);IndicatorShortName("VolDeltaDiv_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   // 累积OBV
   double obv[];ArrayResize(obv,Bars);double cumOBV=0;
   for(int i=Bars-2;i>=1;i--){if(iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+1))cumOBV+=iVolume(_Symbol,_Period,i);else cumOBV-=iVolume(_Symbol,_Period,i);obv[i]=cumOBV;}

   // 累积Delta
   double delta[];ArrayResize(delta,Bars);double cumD=0;
   for(i=Bars-2;i>=1;i--){double r=iHigh(_Symbol,_Period,i)-iLow(_Symbol,_Period,i);cumD+=r>Point?((iClose(_Symbol,_Period,i)-iOpen(_Symbol,_Period,i))/r*iVolume(_Symbol,_Period,i)):0;delta[i]=cumD;}

   // 累积MFI（资金流）
   double mfi[];ArrayResize(mfi,Bars);double cumM=0;
   for(i=Bars-2;i>=1;i--){double tp=(iHigh(_Symbol,_Period,i)+iLow(_Symbol,_Period,i)+iClose(_Symbol,_Period,i))/3;cumM+=tp*iVolume(_Symbol,_Period,i);mfi[i]=cumM;}

   for(i=limit;i>=1;i++){
      double pNow=iClose(_Symbol,_Period,i),pPrev=iClose(_Symbol,_Period,i+InpDivPeriod);
      double dScore=0,oScore=0,mScore=0;

      // Delta背离
      if(pNow>pPrev&&delta[i]<delta[i+InpDivPeriod])dScore=-50; // 价格涨但Delta跌=顶背
      if(pNow<pPrev&&delta[i]>delta[i+InpDivPeriod])dScore=50;  // 价格跌但Delta涨=底背

      // OBV背离
      if(pNow>pPrev&&obv[i]<obv[i+InpDivPeriod])oScore=-50;
      if(pNow<pPrev&&obv[i]>obv[i+InpDivPeriod])oScore=50;

      // MFI背离
      if(pNow>pPrev&&mfi[i]<mfi[i+InpDivPeriod])mScore=-50;
      if(pNow<pPrev&&mfi[i]>mfi[i+InpDivPeriod])mScore=50;

      deltaDiv[i]=dScore;obvDiv[i]=oScore;mfiDiv[i]=mScore;
      divScore[i]=(dScore+oScore+mScore)/3; // 三组平均
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=2;i++){
      if(divScore[i+1]<-66&&divScore[i]>-66)buySignal[i]=-70;
      if(divScore[i+1]>66&&divScore[i]<66)sellSignal[i]=70;
   }
   if(Bars>0){divScore[0]=divScore[1];deltaDiv[0]=deltaDiv[1];obvDiv[0]=obvDiv[1];mfiDiv[0]=mfiDiv[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
