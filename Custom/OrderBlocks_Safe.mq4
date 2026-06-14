#include "../Include/Common.mqh"
#include "../Include/Drawing.mqh"
//+------------------------------------------------------------------+
//|                                            OrderBlocks_Safe.mq4   |
//|  订单块检测（Order Blocks）— ICT/SMC 概念                         |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  概念：订单块是机构留下的大订单痕迹——在趋势反转前最后一根反向K线    |
//|  Bullish OB：下跌趋势中最后一根阴线，之后价格反转上涨               |
//|  Bearish OB：上涨趋势中最后一根阳线，之后价格反转下跌               |
//|  确认机制：反转需突破前一根K线的高/低点(bar[1]+确认)               |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 6

input int InpSwingLookback=5;  // 摆动点回溯
input bool InpShowOBZone=true;  // 显示订单块区域

double bullOB[],bearOB[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(0,bullOB);SetIndexArrow(0,ARROW_BUY);SetIndexLabel(0,"Bullish OB");SetIndexEmptyValue(0,EMPTY_VALUE);
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(1,bearOB);SetIndexArrow(1,ARROW_SELL);SetIndexLabel(1,"Bearish OB");SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexLabel(2,"OB Confirmed");SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexLabel(3,"OB Confirmed");SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(4,strongBuy);SetIndexArrow(4,233);SetIndexEmptyValue(4,EMPTY_VALUE);SetIndexLabel(4,"Strong Buy");
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(5,strongSell);SetIndexArrow(5,234);SetIndexEmptyValue(5,EMPTY_VALUE);SetIndexLabel(5,"Strong Sell");
   IndicatorDigits(4);IndicatorShortName("OrderBlocks_Safe");return(0);
}
int deinit(){RemoveObjectsByPrefix("OB_");return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){bullOB[i]=EMPTY_VALUE;bearOB[i]=EMPTY_VALUE;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;}
   RemoveObjectsByPrefix("OB_");

   for(i=limit;i>=InpSwingLookback+2;i--){
      double c=iClose(_Symbol,_Period,i),o=iOpen(_Symbol,_Period,i);
      double h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i);

      // === 检测看涨订单块 ===
      // 条件：当前是下跌中的最后一根阴线，之后出阳线反转
      bool wasDown=true;for(int j=1;j<=3;j++)if(iClose(_Symbol,_Period,i+j)>iClose(_Symbol,_Period,i+j+1))wasDown=false;
      bool isReversalUp=iClose(_Symbol,_Period,i-1)>iClose(_Symbol,_Period,i)&&iClose(_Symbol,_Period,i-2)>iClose(_Symbol,_Period,i-1);
      if(c<o&&wasDown&&isReversalUp){ // 阴线后连续阳线
         bullOB[i]=l-3*Point;
         if(InpShowOBZone){
            string nm=OBJ_PREFIX+"OB_BULL_"+IntegerToString(i);
            ObjectCreate(nm,OBJ_RECTANGLE,0,iTime(_Symbol,_Period,i),o,iTime(_Symbol,_Period,i-2),c);
            ObjectSet(nm,OBJPROP_COLOR,clrLimeGreen);ObjectSet(nm,OBJPROP_BACK,true);ObjectSet(nm,OBJPROP_WIDTH,2);
         }
         // 确认：价格回踩订单块后反弹
         if(i>=3&&iLow(_Symbol,_Period,i-1)>l&&iClose(_Symbol,_Period,i-2)>c)buySignal[i-1]=l-8*Point;
         // 强信号：OB确认+放量+连续阳线确认
         if(i>=4&&iLow(_Symbol,_Period,i-1)>l&&iClose(_Symbol,_Period,i-2)>c&&iClose(_Symbol,_Period,i-3)>c&&iVolume(_Symbol,_Period,i-1)>iVolume(_Symbol,_Period,i)*1.3)strongBuy[i-1]=l-14*Point;
      }

      // === 检测看跌订单块 ===
      bool wasUp=true;for(int jj=1;j<=3;j++)if(iClose(_Symbol,_Period,i+j)<iClose(_Symbol,_Period,i+j+1))wasUp=false;
      bool isReversalDn=iClose(_Symbol,_Period,i-1)<iClose(_Symbol,_Period,i)&&iClose(_Symbol,_Period,i-2)<iClose(_Symbol,_Period,i-1);
      if(c>o&&wasUp&&isReversalDn){
         bearOB[i]=h+3*Point;
         if(InpShowOBZone){
            nm=OBJ_PREFIX+"OB_BEAR_"+IntegerToString(i);
            ObjectCreate(nm,OBJ_RECTANGLE,0,iTime(_Symbol,_Period,i),o,iTime(_Symbol,_Period,i-2),c);
            ObjectSet(nm,OBJPROP_COLOR,clrTomato);ObjectSet(nm,OBJPROP_BACK,true);ObjectSet(nm,OBJPROP_WIDTH,2);
         }
         if(i>=3&&iHigh(_Symbol,_Period,i-1)<h&&iClose(_Symbol,_Period,i-2)<c)sellSignal[i-1]=h+8*Point;
         // 强信号：OB确认+放量+连续阴线确认
         if(i>=4&&iHigh(_Symbol,_Period,i-1)<h&&iClose(_Symbol,_Period,i-2)<c&&iClose(_Symbol,_Period,i-3)<c&&iVolume(_Symbol,_Period,i-1)>iVolume(_Symbol,_Period,i)*1.3)strongSell[i-1]=h+14*Point;
      }
   }
   if(Bars>0){bullOB[0]=EMPTY_VALUE;bearOB[0]=EMPTY_VALUE;buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=EMPTY_VALUE;strongSell[0]=EMPTY_VALUE;}
   return(0);
}
