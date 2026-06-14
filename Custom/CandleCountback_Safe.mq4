#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                        CandleCountback_Safe.mq4   |
//|  K线计数回溯 — 日本蜡烛图计数法                                    |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_minimum 0
input int InpBase=9; // 基准数(9/13/26/33等)
double countUp[],countDn[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3,clrLimeGreen);SetIndexBuffer(0,countUp);SetIndexLabel(0,"Count Up");SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,3,clrTomato);SetIndexBuffer(1,countDn);SetIndexLabel(1,"Count Down");SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("Countback_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=1;i--){
      // 买入计数：找到最低点后，依次比较每根K线收盘是否高于前第2根收盘
      int buyCount=0;double lowest=iLow(_Symbol,_Period,i+1);int lowBar=i+1;
      for(int j=2;j<20;j++){if(iLow(_Symbol,_Period,i+j)<lowest){lowest=iLow(_Symbol,_Period,i+j);lowBar=i+j;}}
      for(int jj=lowBar-1;j>=1;j--){if(iClose(_Symbol,_Period,j)>iClose(_Symbol,_Period,j+2))buyCount++;else break;if(buyCount>=InpBase)break;}
      // 卖出计数：找到最高点后，依次比较收盘是否低于前第2根
      int sellCount=0;double highest=iHigh(_Symbol,_Period,i+1);int highBar=i+1;
      for(int jjj=2;j<20;j++){if(iHigh(_Symbol,_Period,i+j)>highest){highest=iHigh(_Symbol,_Period,i+j);highBar=i+j;}}
      for(int jjjj=highBar-1;j>=1;j--){if(iClose(_Symbol,_Period,j)<iClose(_Symbol,_Period,j+2))sellCount++;else break;if(sellCount>=InpBase)break;}
      countUp[i]=buyCount;countDn[i]=sellCount;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=2;i++){
      if(countUp[i+1]<InpBase&&countUp[i]>=InpBase)buySignal[i]=InpBase-1;   // 计数完成=买入
      if(countDn[i+1]<InpBase&&countDn[i]>=InpBase)sellSignal[i]=InpBase+1;
   }
   if(Bars>0){countUp[0]=countUp[1];countDn[0]=countDn[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);}
