#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                              ThreeLineBreak_Safe.mq4|
//|  三线反转（Three Line Break）— 不含未来函数                       |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  TLB是一种忽略时间的图表方法，连续3根同向K线确认反转               |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2

input int InpLineCount=3; // 反转所需K线数

double buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(0,buySignal);SetIndexArrow(0,ARROW_BUY);SetIndexEmptyValue(0,EMPTY_VALUE);
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(1,sellSignal);SetIndexArrow(1,ARROW_SELL);SetIndexEmptyValue(1,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("TLB_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;}

   for(i=limit;i>=InpLineCount;i--){
      // 连续N根阳线 = 突破确认（三线反转中的白线）
      bool allBull=true,allBear=true;
      for(int j=0;j<InpLineCount;j++){
         if(iClose(_Symbol,_Period,i+j)<=iOpen(_Symbol,_Period,i+j))allBull=false;
         if(iClose(_Symbol,_Period,i+j)>=iOpen(_Symbol,_Period,i+j))allBear=false;
      }
      if(allBull){ // 连续阳线后，前一根是阴线 → 反转向上
         if(iClose(_Symbol,_Period,i+InpLineCount)<iOpen(_Symbol,_Period,i+InpLineCount))
            buySignal[i]=iLow(_Symbol,_Period,i)-5*Point;
      }
      if(allBear){
         if(iClose(_Symbol,_Period,i+InpLineCount)>iOpen(_Symbol,_Period,i+InpLineCount))
            sellSignal[i]=iHigh(_Symbol,_Period,i)+5*Point;
      }
   }
   return(0);
}
