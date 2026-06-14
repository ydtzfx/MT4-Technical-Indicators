#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                           CycleDetector_Safe.mq4  |
//|  周期检测器（Autocorrelation-based）— 信号处理指标                 |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：自相关ACF(lag)=Corr(Price,Price[lag])                        |
//|  找到ACF的第一个显著峰值→主导周期长度                               |
//|  输出：当前主导周期长度+周期强度                                    |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 4

input int InpMaxPeriod=50;  // 最大检测周期

double domCycle[],cycleStr[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,domCycle);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Dominant Cycle");
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,2);SetIndexBuffer(1,cycleStr);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Cycle Strength");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   IndicatorDigits(0);IndicatorShortName("CycleDet_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   int window=InpMaxPeriod*3;if(limit>Bars-2)limit=Bars-window;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      // 收集价格序列（去趋势：使用变化量）
      double diff[];ArrayResize(diff,window);
      for(int j=0;j<window;j++)diff[j]=iClose(_Symbol,_Period,i+j)-iClose(_Symbol,_Period,i+j+1);

      // 计算自相关函数 for lags 2..InpMaxPeriod
      double bestACF=0;int bestLag=2;
      for(int lag=2;lag<=InpMaxPeriod;lag++){
         double mean1=0,mean2=0;
         for(int jj=0;j<window-lag;j++){mean1+=diff[j];mean2+=diff[j+lag];}
         mean1/=(window-lag);mean2/=(window-lag);
         double num=0,den1=0,den2=0;
         for(int jjj=0;j<window-lag;j++){num+=(diff[j]-mean1)*(diff[j+lag]-mean2);den1+=(diff[j]-mean1)*(diff[j]-mean1);den2+=(diff[j+lag]-mean2)*(diff[j+lag]-mean2);}
         double acf=SafeDivide(num,MathSqrt(den1*den2),0);
         if(acf>bestACF){bestACF=acf;bestLag=lag;}
      }
      domCycle[i]=bestLag;cycleStr[i]=bestACF*100;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=2;i--){
      // 周期从长变短 = 波动加快（可能变盘）
      if(domCycle[i+1]>30&&domCycle[i]<15&&cycleStr[i]>30)buySignal[i]=domCycle[i]-2;
      // 周期强度突变
      if(cycleStr[i+1]<20&&cycleStr[i]>50)buySignal[i]=domCycle[i]-2;
   }
   if(Bars>0){domCycle[0]=domCycle[1];cycleStr[0]=cycleStr[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
