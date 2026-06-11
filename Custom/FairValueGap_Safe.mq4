//+------------------------------------------------------------------+
//|                                          FairValueGap_Safe.mq4    |
//|  公允价值缺口（FVG）— ICT/SMC 概念                                |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  概念：当K线之间存在价格真空区（跳空/急速波动），该区域倾向于被回补 |
//|  Bullish FVG：阳线低点 > 前前阳线高点（上涨缺口）                   |
//|  Bearish FVG：阴线高点 < 前前阴线低点（下跌缺口）                   |
//|  缺口回补后价格可能继续原方向或反转——FVG是磁铁区                    |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 4

input double InpMinGapPct=0.05; // 最小缺口(%ATR)
input bool InpShowFilled=true;   // 回补后标记

double bullFVG[],bearFVG[],filledBuy[],filledSell[];

int init() {
   SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(0,bullFVG);SetIndexArrow(0,ARROW_BUY);SetIndexLabel(0,"Bullish FVG");SetIndexEmptyValue(0,EMPTY_VALUE);
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(1,bearFVG);SetIndexArrow(1,ARROW_SELL);SetIndexLabel(1,"Bearish FVG");SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,1,clrCyan);SetIndexBuffer(2,filledBuy);SetIndexArrow(2,ARROW_BUY);SetIndexLabel(2,"FVG Filled-Buy");SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,1,clrDeepPink);SetIndexBuffer(3,filledSell);SetIndexArrow(3,ARROW_SELL);SetIndexLabel(3,"FVG Filled-Sell");SetIndexEmptyValue(3,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("FVG_Safe");return(0);
}
int deinit(){RemoveObjectsByPrefix("FVG_");return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){bullFVG[i]=EMPTY_VALUE;bearFVG[i]=EMPTY_VALUE;filledBuy[i]=EMPTY_VALUE;filledSell[i]=EMPTY_VALUE;}
   RemoveObjectsByPrefix("FVG_");

   double atr=0;for(int j=0;j<14;j++)atr+=GetTrueRange(_Symbol,_Period,limit+10+j);atr/=14;
   double minGap=InpMinGapPct*atr/100;

   for(int i=limit;i>=3;i--){
      // === 看涨FVG：当前阳线的低点 > 前前K线的高点（之间有价格缺口）===
      double h0=iHigh(_Symbol,_Period,i),l0=iLow(_Symbol,_Period,i);
      double h2=iHigh(_Symbol,_Period,i+2),l2=iLow(_Symbol,_Period,i+2);
      if(iClose(_Symbol,_Period,i)>iOpen(_Symbol,_Period,i)&&l0>h2&&(l0-h2)>minGap){
         bullFVG[i]=l0-3*Point;
         string nm=OBJ_PREFIX+"FVG_BULL_"+IntegerToString(i);
         ObjectCreate(nm,OBJ_RECTANGLE,0,iTime(_Symbol,_Period,i),h2,iTime(_Symbol,_Period,i),l0);
         ObjectSet(nm,OBJPROP_COLOR,clrLimeGreen);ObjectSet(nm,OBJPROP_BACK,true);
      }

      // === 看跌FVG：当前阴线的高点 < 前前K线的低点 ===
      if(iClose(_Symbol,_Period,i)<iOpen(_Symbol,_Period,i)&&h0<l2&&(l2-h0)>minGap){
         bearFVG[i]=h0+3*Point;
         string nm=OBJ_PREFIX+"FVG_BEAR_"+IntegerToString(i);
         ObjectCreate(nm,OBJ_RECTANGLE,0,iTime(_Symbol,_Period,i),l2,iTime(_Symbol,_Period,i),h0);
         ObjectSet(nm,OBJPROP_COLOR,clrTomato);ObjectSet(nm,OBJPROP_BACK,true);
      }
   }

   // 检测回补：价格回踩FVG区域
   for(int i=limit;i>=5;i--){
      for(int j=3;j<20;j++){ // 检查近期的FVG
         int fvgBar=i+j;
         if(bullFVG[fvgBar]!=EMPTY_VALUE){
            double gapTop=iLow(_Symbol,_Period,fvgBar),gapBot=iHigh(_Symbol,_Period,fvgBar+2);
            if(iLow(_Symbol,_Period,i)<=gapTop&&iLow(_Symbol,_Period,i)>=gapBot)filledBuy[i]=gapBot-5*Point;
         }
         if(bearFVG[fvgBar]!=EMPTY_VALUE){
            double gapBot=iHigh(_Symbol,_Period,fvgBar),gapTop=iLow(_Symbol,_Period,fvgBar+2);
            if(iHigh(_Symbol,_Period,i)>=gapBot&&iHigh(_Symbol,_Period,i)<=gapTop)filledSell[i]=gapTop+5*Point;
         }
      }
   }
   return(0);
}
