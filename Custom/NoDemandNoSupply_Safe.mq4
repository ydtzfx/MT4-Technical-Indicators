//+------------------------------------------------------------------+
//|                                     NoDemandNoSupply_Safe.mq4     |
//|  无需求/无供给 — Wyckoff VSA概念                                   |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
input double InpLowVolPct=0.5; // 低于均量50%=低量
double noDemand[],noSupply[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(0,noDemand);SetIndexArrow(0,ARROW_SELL);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(1,noSupply);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("NDNS_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){noDemand[i]=noSupply[i]=buySignal[i]=sellSignal[i]=EMPTY_VALUE;}
   double avgV=0;for(int j=0;j<30;j++)avgV+=iVolume(_Symbol,_Period,limit+30+j);avgV/=30;
   for(int i=limit;i>=3;i--){
      double o=iOpen(_Symbol,_Period,i),h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i);
      double r=h-l,body=MathAbs(c-o);long v=iVolume(_Symbol,_Period,i);
      // 无需求：低量+窄体+上影线+价格上涨=买方匮乏→可能下跌
      if(v<avgV*InpLowVolPct&&body<r*0.3&&(h-MathMax(o,c))>body&&c>iClose(_Symbol,_Period,i+1))noDemand[i]=h+5*Point;
      // 无供给：低量+窄体+下影线+价格下跌=卖方匮乏→可能上涨
      if(v<avgV*InpLowVolPct&&body<r*0.3&&(MathMin(o,c)-l)>body&&c<iClose(_Symbol,_Period,i+1))noSupply[i]=l-5*Point;
      // ND后价格跌破=确认
      if(noDemand[i+1]!=EMPTY_VALUE&&c<iLow(_Symbol,_Period,i+1))sellSignal[i]=h+10*Point;
      if(noSupply[i+1]!=EMPTY_VALUE&&c>iHigh(_Symbol,_Period,i+1))buySignal[i]=l-10*Point;
   }
   return(0);}
