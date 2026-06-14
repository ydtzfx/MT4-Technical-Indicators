#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                    OpeningClosingDrive_Safe.mq4   |
//|  开盘/收盘驱动 — K线开盘和收盘阶段的方向力度                        |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum -100
#property indicator_maximum 100
double drive[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,drive);SetIndexLabel(0,"O/C Drive");SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("OCDrive_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=1;i--){
      double o=iOpen(_Symbol,_Period,i),h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i);
      double r=h-l;if(r<_Point)r=_Point;
      // 开盘驱动：High-Open（开盘后买方推进距离） vs Open-Low（开盘后卖方推进）
      double openDrive=(h-o)-(o-l);
      // 收盘驱动：Close-Min(O,C)（收盘方向力度） vs Max(O,C)-Close
      double closeDrive=(c>o?c-o:o-c)*((c>o)?1:-1);
      // 综合：开盘定方向，收盘定确认
      drive[i]=SafeDivide(openDrive+closeDrive*2,r,0)*50;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=2;i++){
      if(drive[i+1]<-30&&drive[i]>30)buySignal[i]=-40; // 开盘弱+收盘强=反转买入
      if(drive[i+1]>30&&drive[i]<-30)sellSignal[i]=40;
      if(drive[i+1]>20&&drive[i]>50&&iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+1))buySignal[i]=-40; // 持续强势
   }
   if(Bars>0){drive[0]=drive[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);}
