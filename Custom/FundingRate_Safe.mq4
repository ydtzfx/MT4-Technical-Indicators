#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                          FundingRate_Safe.mq4     |
//|  资金费率代理 — 用价格-现货偏离估算永续合约资金费率                  |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 4
input int InpOBPeriod=20; // 价格偏离检测周期
input string InpSpotSymbol=""; // 现货价格(空=同一品种)
double fr[],oiChange[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,fr);SetIndexLabel(0,"Funding Rate Proxy");SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,clrYellow);SetIndexBuffer(1,oiChange);SetIndexLabel(1,"OI Change %");SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(4);IndicatorShortName("FundingRate_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=1;i--){
      // 估计资金费率：用价格与EMA的偏离（类似永续合约溢价）
      double ema=0;for(int j=0;j<InpOBPeriod;j++)ema+=iClose(_Symbol,_Period,i+j);ema/=InpOBPeriod;
      double frVal=SafeDivide((iClose(_Symbol,_Period,i)-ema),ema,0)*100;
      fr[i]=frVal;
      // OI变化代理：成交量变化率
      double volNow=iVolume(_Symbol,_Period,i),volPrev=iVolume(_Symbol,_Period,i+1);
      oiChange[i]=volPrev>0?100.0*(volNow-volPrev)/volPrev:0;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=2;i--){
      // 资金费率从极端正值转负 = 多头拥挤后清算 → 卖出
      if(fr[i+1]>0.5&&fr[i]<-0.5)sellSignal[i]=fr[i]+0.5;
      // 资金费率从极端负值转正 = 空头拥挤后回补 → 买入
      if(fr[i+1]<-0.5&&fr[i]>0.5)buySignal[i]=fr[i]-0.5;
      // OI暴增 + 价格下跌 = 空头开仓 → 可能继续跌
      if(oiChange[i]>50&&iClose(_Symbol,_Period,i)<iClose(_Symbol,_Period,i+1))sellSignal[i]=fr[i]+0.5;
   }
   if(Bars>0){fr[0]=fr[1];oiChange[0]=oiChange[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);}
