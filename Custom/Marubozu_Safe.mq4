//+------------------------------------------------------------------+
//|                                             Marubozu_Safe.mq4     |
//|  光头光脚检测 — 趋势最强信号                                       |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
input double InpShadowMax=0.05; // 最大影线占比
double maruBull[],maruBear[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,4,CLR_BUY_SIGNAL);SetIndexBuffer(0,maruBull);SetIndexArrow(0,ARROW_BUY);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,4,CLR_SELL_SIGNAL);SetIndexBuffer(1,maruBear);SetIndexArrow(1,ARROW_SELL);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("Marubozu_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){maruBull[i]=maruBear[i]=buySignal[i]=sellSignal[i]=EMPTY_VALUE;}
   for(int i=limit;i>=3;i++){
      double o=iOpen(_Symbol,_Period,i),h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i);
      double r=h-l;if(r<_Point)continue;
      double upW=h-MathMax(o,c),loW=MathMin(o,c)-l;
      // 光头光脚阳线：几乎无上下影，收于最高
      if(c>o&&upW<r*InpShadowMax&&loW<r*InpShadowMax){
         maruBull[i]=l-8*Point;if(o<=l+1*Point&&c>=h-1*Point)maruBull[i]=l-12*Point;}
      // 光头光脚阴线
      if(c<o&&upW<r*InpShadowMax&&loW<r*InpShadowMax){
         maruBear[i]=h+8*Point;if(o>=h-1*Point&&c<=l+1*Point)maruBear[i]=h+12*Point;}
      // 光头光脚后续：确认趋势延续
      if(maruBull[i+1]!=EMPTY_VALUE&&iClose(_Symbol,_Period,i)>iHigh(_Symbol,_Period,i+1))buySignal[i]=l-15*Point;
      if(maruBear[i+1]!=EMPTY_VALUE&&iClose(_Symbol,_Period,i)<iLow(_Symbol,_Period,i+1))sellSignal[i]=h+15*Point;
   }
   return(0);}
