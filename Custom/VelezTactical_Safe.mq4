#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                         VelezTactical_Safe.mq4    |
//|  Velez战术交易信号 — Oliver Velez的经典体系                        |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  核心概念：三要素共振                                                |
//|  1. 趋势确认（EMA排列+ADX）                                        |
//|  2. 回调到位（价格回到关键均线+缩量）                              |
//|  3. 反转K线（Pin Bar/吞没形态确认）                                |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 4

input int InpFastMA=10,InpSlowMA=30;

double buySignal[],sellSignal[],weakBuy[],weakSell[];

int init() {
   SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(0,buySignal);SetIndexArrow(0,ARROW_BUY);SetIndexEmptyValue(0,EMPTY_VALUE);
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(1,sellSignal);SetIndexArrow(1,ARROW_SELL);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,1,clrCyan);SetIndexBuffer(2,weakBuy);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,1,clrDeepPink);SetIndexBuffer(3,weakSell);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("Velez_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;weakBuy[i]=EMPTY_VALUE;weakSell[i]=EMPTY_VALUE;}

   for(i=limit;i>=3;i--){
      double c=iClose(_Symbol,_Period,i),o=iOpen(_Symbol,_Period,i);
      double h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i);
      double range=h-l,body=MathAbs(c-o);

      // 计算快速和慢速EMA
      double p[80];for(int j=0;j<80;j++)p[j]=iClose(_Symbol,_Period,i+j);
      double fast=0,slow=0;for(int jj=79;j>=0;j--){if(j==79){fast=p[j];slow=p[j];}else{double aF=2.0/(InpFastMA+1);fast=p[j]*aF+fast*(1-aF);double aS=2.0/(InpSlowMA+1);slow=p[j]*aS+slow*(1-aS);}}

      // ADX
      double trS=0,ps=0,ms=0;for(int jjj=0;j<14;j++){int s=i+j;double hi=iHigh(_Symbol,_Period,s),lo=iLow(_Symbol,_Period,s),pc=iClose(_Symbol,_Period,s+1);trS+=MathMax(hi-lo,MathMax(MathAbs(hi-pc),MathAbs(lo-pc)));double up=hi-iHigh(_Symbol,_Period,s+1),dn=iLow(_Symbol,_Period,s+1)-lo;if(up>dn&&up>0)ps+=up;if(dn>up&&dn>0)ms+=dn;}
      double adx=SafeDivide(100*MathAbs(ps-ms),ps+ms,0);

      // 成交量
      double v=iVolume(_Symbol,_Period,i),vAvg=0;for(int jjjj=0;j<20;j++)vAvg+=iVolume(_Symbol,_Period,i+j);vAvg/=20;
      double volRatio=SafeDivide(v,vAvg,1);

      // 条件1：趋势 — 快线上穿慢线或快线在慢线上方
      bool trendUp=fast>slow;
      bool trendDn=fast<slow;
      bool strongTrend=adx>25;

      // 条件2：回调 — 价格回到快线附近
      bool pullbackBuy=c>fast&&c<fast*1.02&&c>slow;
      bool pullbackSell=c<fast&&c>fast*0.98&&c<slow;

      // 条件3：反转K线 — Pin Bar或吞没
      double upperWick=h-MathMax(o,c),lowerWick=MathMin(o,c)-l;
      bool pinBarBull=lowerWick>range*0.6&&body<range*0.3;
      bool pinBarBear=upperWick>range*0.6&&body<range*0.3;
      bool engulfBull=c>o&&iClose(_Symbol,_Period,i+1)<iOpen(_Symbol,_Period,i+1)&&c>iOpen(_Symbol,_Period,i+1);
      bool engulfBear=c<o&&iClose(_Symbol,_Period,i+1)>iOpen(_Symbol,_Period,i+1)&&c<iOpen(_Symbol,_Period,i+1);

      int buyCond=0,sellCond=0;
      if(trendUp)buyCond++;else if(trendDn)sellCond++;
      if(strongTrend){if(trendUp)buyCond++;else if(trendDn)sellCond++;}
      if(pullbackBuy&&volRatio<0.8)buyCond+=2;
      if(pullbackSell&&volRatio<0.8)sellCond+=2;
      if(pinBarBull||engulfBull)buyCond++;if(pinBarBear||engulfBear)sellCond++;

      if(buyCond>=4)buySignal[i]=iLow(_Symbol,_Period,i)-10*Point;
      else if(buyCond>=2)weakBuy[i]=iLow(_Symbol,_Period,i)-15*Point;
      if(sellCond>=4)sellSignal[i]=iHigh(_Symbol,_Period,i)+10*Point;
      else if(sellCond>=2)weakSell[i]=iHigh(_Symbol,_Period,i)+15*Point;
   }
   return(0);
}
