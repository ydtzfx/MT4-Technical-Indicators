#include "../Include/Common.mqh"
#include "../Include/PriceData.mqh"
//+------------------------------------------------------------------+
//|                                        CandleTimeExhaustion_Safe  |
//|  K线时间衰竭 — 盘整时间过长后的方向性突破                          |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
input double InpRangeThreshold=0.3; // 盘整范围阈(%ATR)
input int InpMaxBars=20; // 最大盘整bar数
double exhausted[],breakDir[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,2,clrYellow);SetIndexBuffer(0,exhausted);SetIndexArrow(0,ARROW_DOT);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,3,clrOrange);SetIndexBuffer(1,breakDir);SetIndexArrow(1,ARROW_STOP);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("TimeExh_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){exhausted[i]=breakDir[i]=buySignal[i]=sellSignal[i]=EMPTY_VALUE;}
   double atr=0;for(int j=0;j<14;j++)atr+=GetTrueRange(_Symbol,_Period,limit+10+j);atr/=14;
   for(i=limit;i>=InpMaxBars;i--){
      // 寻找长时间的窄幅盘整
      int consBars=0;double rngHi=iHigh(_Symbol,_Period,i+1),rngLo=iLow(_Symbol,_Period,i+1);
      for(int jj=1;j<InpMaxBars;j++){double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);if(h>rngHi)rngHi=h;if(l<rngLo)rngLo=l;if((rngHi-rngLo)<atr*InpRangeThreshold)consBars++;else break;}
      if(consBars>=5){exhausted[consBars]=iLow(_Symbol,_Period,i)-3*Point;
         double c=iClose(_Symbol,_Period,i),range=iHigh(_Symbol,_Period,i)-iLow(_Symbol,_Period,i);
         if(c>rngHi&&range>atr)buySignal[i]=iLow(_Symbol,_Period,i)-8*Point;
         else if(c<rngLo&&range>atr)sellSignal[i]=iHigh(_Symbol,_Period,i)+8*Point;}
   }return(0);}
