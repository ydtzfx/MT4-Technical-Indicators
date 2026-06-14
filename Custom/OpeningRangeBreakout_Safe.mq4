#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                       OpeningRangeBreakout_Safe   |
//|  开盘区间突破（ORB）— 日内交易经典策略                             |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  概念：开盘后前N分钟形成初始区间，突破该区间方向=当日趋势方向        |
//|  默认30分钟（H1图=前30根M1，M15图=前2根）                          |
//|  突破OR高+回踩不破=买入，跌破OR低+反弹不破=卖出                    |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 8

input int InpORMinutes=30; // 开盘区间分钟数（需要对应周期合理设置）

double orHigh[],orLow[],orMid[],buySignal[],sellSignal[],expansion[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrYellow);SetIndexBuffer(0,orHigh);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"OR High");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrYellow);SetIndexBuffer(1,orLow);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"OR Low");
   SetIndexStyle(2,DRAW_LINE,STYLE_DOT,1,clrGray);SetIndexBuffer(2,orMid);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexLabel(2,"OR Mid");
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(3,buySignal);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(4,sellSignal);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);
   SetIndexStyle(5,DRAW_HISTOGRAM,STYLE_SOLID,1);SetIndexBuffer(5,expansion);SetIndexEmptyValue(5,EMPTY_VALUE);SetIndexLabel(5,"Expansion");
   SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(6,strongBuy);SetIndexArrow(6,ARROW_BUY);SetIndexEmptyValue(6,EMPTY_VALUE);SetIndexLabel(6,"Strong Buy");
   SetIndexStyle(7,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(7,strongSell);SetIndexArrow(7,ARROW_SELL);SetIndexEmptyValue(7,EMPTY_VALUE);SetIndexLabel(7,"Strong Sell");
   IndicatorDigits(4);IndicatorShortName("ORB_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-500;if(limit<0)limit=0;

   // 计算当前图表周期下OR对应的bar数
   int periodMin=Period()==PERIOD_M1?1:Period()==PERIOD_M5?5:Period()==PERIOD_M15?15:Period()==PERIOD_M30?30:Period()==PERIOD_H1?60:Period()==PERIOD_H4?240:1440;
   int orBars=MathMax(1,InpORMinutes/periodMin);

   for(int i=limit;i>=1;i--){
      // 找最近的开盘时间（简化：每个bar都可能是一个新OR的起点）
      int orStart=i+orBars-1;
      if(orStart>=Bars){orHigh[i]=orHigh[i+1];orLow[i]=orLow[i+1];orMid[i]=orMid[i+1];}
      else{
         double orH=iHigh(_Symbol,_Period,i),orL=iLow(_Symbol,_Period,i);
         for(int j=1;j<orBars;j++){double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);if(h>orH)orH=h;if(l<orL)orL=l;}
         orHigh[i]=orH;orLow[i]=orL;orMid[i]=(orH+orL)/2;
      }
      expansion[i]=(orHigh[i]-orLow[i])/Point; // OR宽度（点数）
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }

   for(i=limit;i>=2;i--){
      double c=iClose(_Symbol,_Period,i),c1=iClose(_Symbol,_Period,i+1);

      // 计算近N个OR的平均宽度，用于判断当前OR是否"够宽"
      int avgBars=5; double sumExp=0; int cnt=0;
      for(int k=i+1;k<=i+avgBars&&k<Bars;k++){if(expansion[k]>=0){sumExp+=expansion[k];cnt++;}}
      double avgExp=cnt>0?sumExp/cnt:0;

      // ---- 常规信号 ----
      // 突破OR高点
      if(c1<=orHigh[i+1]&&c>orHigh[i]){
         buySignal[i]=orMid[i];
         // Strong: 条件A(突破) + 条件B(OR宽度≥平均80%) + 条件C(收盘在OR高+10%OR宽度之上)
         if(expansion[i]>=avgExp*0.8&&c>orHigh[i]+expansion[i]*0.1*Point)
            strongBuy[i]=orMid[i]+5*Point;
      }
      // 跌破OR低点
      if(c1>=orLow[i+1]&&c<orLow[i]){
         sellSignal[i]=orMid[i];
         // Strong: 条件A(跌破) + 条件B(OR宽度≥平均80%) + 条件C(收盘在OR低-10%OR宽度之下)
         if(expansion[i]>=avgExp*0.8&&c<orLow[i]-expansion[i]*0.1*Point)
            strongSell[i]=orMid[i]-5*Point;
      }
      // 回踩OR中位（仅常规信号）
      if(c>orHigh[i]&&c1<=orMid[i+1]&&c>orMid[i])buySignal[i]=orMid[i]-5*Point;
   }
   if(Bars>0){orHigh[0]=orHigh[1];orLow[0]=orLow[1];orMid[0]=orMid[1];expansion[0]=expansion[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=strongSell[0]=EMPTY_VALUE;}
   return(0);
}
