#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                         OpenInterest_Safe.mq4     |
//|  持仓量分析 — 成交量与价格联动分析                                  |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 4
input int InpPeriod=10;
double oiSignal[],priceVol[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,oiSignal);SetIndexLabel(0,"OI Signal");SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,2);SetIndexBuffer(1,priceVol);SetIndexLabel(1,"Px+Vol");SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("OI_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=1;i--){
      double vol=0;for(int j=0;j<InpPeriod;j++)vol+=iVolume(_Symbol,_Period,i+j);
      double c=iClose(_Symbol,_Period,i),cPrev=iClose(_Symbol,_Period,i+1);
      // 价格*成交量趋势 = OI代理（价量同向=增仓，反向=减仓）
      double pxDir=(c-cPrev)/Point;double volChange=vol-(vol-iVolume(_Symbol,_Period,i)+iVolume(_Symbol,_Period,i+InpPeriod));
      oiSignal[i]=pxDir*volChange/100;
      priceVol[i]=(c>cPrev?1:-1)*MathAbs(oiSignal[i]);
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=2;i--){
      // 价涨量增=多头增仓 → 强买入
      if(iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+1)&&oiSignal[i]>oiSignal[i+1]*1.5)buySignal[i]=oiSignal[i]*0.5;
      // 价跌量增=空头增仓
      if(iClose(_Symbol,_Period,i)<iClose(_Symbol,_Period,i+1)&&oiSignal[i]<oiSignal[i+1]*1.5)sellSignal[i]=oiSignal[i]*1.5;
   }
   if(Bars>0){oiSignal[0]=oiSignal[1];priceVol[0]=priceVol[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);}
