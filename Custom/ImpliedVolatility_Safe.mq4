#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                      ImpliedVolatility_Safe.mq4   |
//|  隐含波动率代理 — 用历史波动率期限结构推算                          |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 5
input int InpIVPeriod=20;input int InpSignalPeriod=10;
double iv[],ivMA[],delta[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,iv);SetIndexLabel(0,"IV Proxy");SetIndexStyle(1,DRAW_LINE,STYLE_DOT,1,clrYellow);SetIndexBuffer(1,ivMA);SetIndexLabel(1,"IV MA");SetIndexStyle(2,DRAW_HISTOGRAM,STYLE_SOLID,2);SetIndexBuffer(2,delta);SetIndexLabel(2,"ΔIV");SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(3,buySignal);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(4,sellSignal);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);IndicatorDigits(2);IndicatorShortName("IV_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=1;i--){
      double ret[];ArrayResize(ret,InpIVPeriod);double sum=0;
      for(int j=0;j<InpIVPeriod;j++){ret[j]=MathLog(iClose(_Symbol,_Period,i+j)/iClose(_Symbol,_Period,i+j+1));sum+=ret[j];}
      double mean=sum/InpIVPeriod;double var=0;for(int jj=0;j<InpIVPeriod;j++){double d=ret[j]-mean;var+=d*d;}
      // 年化波动率 = 标准差 * sqrt(PeriodsPerYear)
      int barsPerYear=0;switch(Period()){case PERIOD_D1:barsPerYear=260;break;case PERIOD_H4:barsPerYear=1560;break;case PERIOD_H1:barsPerYear=6240;break;default:barsPerYear=260;}
      iv[i]=MathSqrt(var/InpIVPeriod)*MathSqrt(barsPerYear)*100;
      delta[i]=iv[i]-iv[i+1];buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=1;i++){double s=0;for(int jjj=0;j<InpSignalPeriod;j++)s+=iv[i+j];ivMA[i]=s/InpSignalPeriod;}
   for(i=limit;i>=2;i++){
      // IV从极高位回落 = 恐慌消退 → 可能反弹
      if(iv[i+1]>ivMA[i+1]*1.5&&iv[i]<iv[i+1])buySignal[i]=iv[i]-5;
      // IV从低位飙升 = 风险突增 → 可能下跌
      if(iv[i+1]<ivMA[i+1]*0.7&&iv[i]>iv[i+1]*1.3)sellSignal[i]=iv[i]+5;
   }
   if(Bars>0){iv[0]=iv[1];ivMA[0]=ivMA[1];delta[0]=delta[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);}
