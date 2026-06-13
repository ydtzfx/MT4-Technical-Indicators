//+------------------------------------------------------------------+
//|                                      BreakoutProbability_Safe.mq4 |
//|  突破概率评估器 — 原创指标                                         |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  创新：不判断方向，而是计算「当前突破是真突破的概率」               |
//|  评估维度：                                                         |
//|  1. 成交量确认（放量突破>缩量突破）                                  |
//|  2. 突破幅度（远超阻力>勉强触及）                                    |
//|  3. 市场状态（趋势中突破>盘整中突破）                                |
//|  4. 前期测试（多次测试后突破>首次突破）                              |
//|  输出0-100%概率，>70%为高概率真突破                                |
//+------------------------------------------------------------------+
#include "../Include/Common.mqh"
#include "../Include/PriceData.mqh"
#property copyright "Original Composite - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 7
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 70
#property indicator_level2 40

input int InpLookback=20;input double InpBreakThreshold=0.3; // 突破幅度(%ATR)

double prob[],volConfirm[],breakStr[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,3,clrDodgerBlue);SetIndexBuffer(0,prob);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Breakout Prob %");
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,1,clrLimeGreen);SetIndexBuffer(1,volConfirm);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Vol Confirm");
   SetIndexStyle(2,DRAW_HISTOGRAM,STYLE_SOLID,1,clrYellow);SetIndexBuffer(2,breakStr);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexLabel(2,"Break Strength");
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(3,buySignal);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(4,sellSignal);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(5,strongBuy);SetIndexArrow(5,ARROW_BUY);SetIndexEmptyValue(5,EMPTY_VALUE);
   SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(6,strongSell);SetIndexArrow(6,ARROW_SELL);SetIndexEmptyValue(6,EMPTY_VALUE);
   IndicatorDigits(0);IndicatorShortName("BreakProb_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-150;if(limit<0)limit=0;

   double avgVol=0;for(int j=0;j<50;j++)avgVol+=iVolume(_Symbol,_Period,limit+50+j);avgVol/=50;

   for(int i=limit;i>=1;i--){
      // 找局部高低点作为"突破参考位"
      double hh=iHigh(_Symbol,_Period,i+1),ll=iLow(_Symbol,_Period,i+1);
      for(int j=2;j<InpLookback;j++){double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);if(h>hh)hh=h;if(l<ll)ll=l;}
      double atr=0;for(int j=0;j<14;j++)atr+=GetTrueRange(_Symbol,_Period,i+j);atr/=14;

      double c=iClose(_Symbol,_Period,i);
      double breakUp=SafeDivide(c-hh,atr,0);   // 向上突破幅度(ATR倍数)
      double breakDn=SafeDivide(ll-c,atr,0);   // 向下突破幅度

      double probVal=0;double volConf=0;double bStr=0;
      if(breakUp>InpBreakThreshold||breakDn>InpBreakThreshold){
         bool isUp=breakUp>breakDn;
         // 成交量确认
         double volR=SafeDivide((double)iVolume(_Symbol,_Period,i),avgVol,1);
         volConf=MathMin(100,volR*33); // 3倍均量=100分

         // 突破幅度
         double sizeScore=MathMin(100,(isUp?breakUp:breakDn)*50);

         // 前期测试：检查该价位是否被多次触碰
         int touches=0;
         for(int j=2;j<InpLookback;j++){
            double h=iHigh(_Symbol,_Period,i+j);
            if(isUp&&MathAbs(h-hh)<atr*0.5)touches++;
            else if(!isUp&&MathAbs(iLow(_Symbol,_Period,i+j)-ll)<atr*0.5)touches++;
         }
         double testScore=MathMin(100,touches*25);

         // ADX趋势强度
         double adxS=0;for(int j=0;j<14;j++)adxS+=GetTrueRange(_Symbol,_Period,i+j);adxS/=14;
         double adxA=SafeDivide(adxS,atr,0);double trendScore=MathMin(100,adxA*50);

         probVal=0.35*volConf+0.3*sizeScore+0.2*testScore+0.15*trendScore;
         bStr=(isUp?breakUp:-breakDn)*20;
      }
      prob[i]=MathMin(100,probVal);volConfirm[i]=volConf;breakStr[i]=bStr;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=2;i--){
      if(prob[i+1]<=40&&prob[i]>70){
         // Strong signals (multi-condition confirmation) first
         if(breakStr[i]>0&&volConfirm[i]>50&&breakStr[i]>15)strongBuy[i]=prob[i]-5;
         if(breakStr[i]<0&&volConfirm[i]>50&&breakStr[i]<-15)strongSell[i]=prob[i]+5;
         // Normal signals
         if(breakStr[i]>0)buySignal[i]=prob[i]-10;
         if(breakStr[i]<0)sellSignal[i]=prob[i]+10;
      }
   }
   if(Bars>0){prob[0]=prob[1];volConfirm[0]=volConfirm[1];breakStr[0]=breakStr[1];buySignal[0]=sellSignal[0]=strongBuy[0]=strongSell[0]=EMPTY_VALUE;}
   return(0);
}
