#include "../Include/Common.mqh"
#include "../Include/PriceData.mqh"
//+------------------------------------------------------------------+
//|                                        AdaptiveStopLoss_Safe.mq4  |
//|  自适应止损计算器 — 原创指标                                       |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  创新：综合多因素动态计算最优止损距离（以ATR倍数输出）              |
//|  1. 基础ATR止损                                                 |
//|  2. 近期波动率调幅（波动大→放宽止损，波动小→收紧止损）              |
//|  3. 支撑阻力距离修正（靠近支撑→缩小止损，远离→放大）               |
//|  4. 市场状态修正（趋势中→宽松止损，盘整中→紧凑止损）               |
//|  输出：推荐止损距离（ATR倍数）+ 推荐止盈距离                       |
//+------------------------------------------------------------------+
#property copyright "Original Composite - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 4

input int InpATRPeriod=14;input double InpBaseStopMult=2.0;input double InpRRRatio=2.0;

double stopATR[],takeProfit[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrTomato);SetIndexBuffer(0,stopATR);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Stop Loss (ATR)");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrLimeGreen);SetIndexBuffer(1,takeProfit);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Take Profit (ATR)");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,clrYellow);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_DOT);SetIndexLabel(2,"Optimal Entry");SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,clrYellow);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_DOT);SetIndexLabel(3,"Optimal Exit");SetIndexEmptyValue(3,EMPTY_VALUE);
   IndicatorDigits(2);IndicatorShortName("AdaptiveSL_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      // ATR计算
      double atr=0;for(int j=0;j<InpATRPeriod;j++)atr+=GetTrueRange(_Symbol,_Period,i+j);atr/=InpATRPeriod;

      // 因子1：近期波动率 vs 长期波动率
      double atr5=0,atr50=0;for(int jj=0;j<5;j++)atr5+=GetTrueRange(_Symbol,_Period,i+j);
      for(int jjj=0;j<50&&(i+j<Bars);j++)atr50+=GetTrueRange(_Symbol,_Period,i+j);atr5/=5;atr50/=50;
      double volAdj=SafeDivide(atr5,atr50,1);volAdj=MathMax(0.7,MathMin(1.5,volAdj));

      // 因子2：ADX趋势强度
      double trS=0,pdS=0,mdS=0;
      for(int jjjj=0;j<14;j++){int s=i+j;double h=iHigh(_Symbol,_Period,s),l=iLow(_Symbol,_Period,s),pc=iClose(_Symbol,_Period,s+1);trS+=MathMax(h-l,MathMax(MathAbs(h-pc),MathAbs(l-pc)));double up=h-iHigh(_Symbol,_Period,s+1),dn=iLow(_Symbol,_Period,s+1)-l;if(up>dn&&up>0)pdS+=up;if(dn>up&&dn>0)mdS+=dn;}
      double adx=SafeDivide(100*MathAbs(pdS-mdS),pdS+mdS,0);
      double trendAdj=adx>30?1.2:(adx>20?1.0:0.8); // 强趋势放宽，盘整收紧

      // 因子3：支撑阻力距离
      double hh=iHigh(_Symbol,_Period,i+1),ll=iLow(_Symbol,_Period,i+1);
      for(int jjjjj=2;j<20;j++){h=iHigh(_Symbol,_Period,i+j);l=iLow(_Symbol,_Period,i+j);if(h>hh)hh=h;if(l<ll)ll=l;}
      double c=iClose(_Symbol,_Period,i);
      double srDist=MathMin(c-ll,hh-c)/atr; // 到最近S/R的ATR距离
      double srAdj=MathMax(0.5,MathMin(1.5,srDist/InpBaseStopMult));

      // 综合止损倍数
      double stopMult=InpBaseStopMult*volAdj*trendAdj*srAdj;
      stopATR[i]=MathMax(1.0,MathMin(5.0,stopMult));
      takeProfit[i]=stopATR[i]*InpRRRatio; // 默认2:1盈亏比

      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   // 标记最优入场区：止损适中+趋势明确
   for(i=limit;i>=2;i--){
      if(stopATR[i]>1.5&&stopATR[i]<3.0&&stopATR[i]<stopATR[i+1])buySignal[i]=stopATR[i];
      if(stopATR[i]>3.5)sellSignal[i]=stopATR[i]; // 止损过大=高波动，谨慎
   }
   if(Bars>0){stopATR[0]=stopATR[1];takeProfit[0]=takeProfit[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
