//+------------------------------------------------------------------+
//|                                       SwingFailureCandle_Safe.mq4 |
//|  摆动失败K线 — 尝试创新高/低但失败的K线                           |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
input int InpSwingBars=5;
double failBuy[],failSell[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(0,failBuy);SetIndexArrow(0,ARROW_BUY);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(1,failSell);SetIndexArrow(1,ARROW_SELL);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("SwingFail_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){failBuy[i]=failSell[i]=buySignal[i]=sellSignal[i]=EMPTY_VALUE;}
   for(int i=limit;i>=InpSwingBars;i--){
      double h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i);
      double refH=iHigh(_Symbol,_Period,i+1);for(int j=2;j<=InpSwingBars;j++){double hj=iHigh(_Symbol,_Period,i+j);if(hj>refH)refH=hj;}
      double refL=iLow(_Symbol,_Period,i+1);for(int j=2;j<=InpSwingBars;j++){double lj=iLow(_Symbol,_Period,i+j);if(lj<refL)refL=lj;}
      // 尝试突破新高但收盘低于前高=买方失败→卖方信号
      if(h>refH&&c<refH)failSell[i]=h+5*Point;
      // 尝试跌破新低但收盘高于前低=卖方失败→买方信号
      if(l<refL&&c>refL)failBuy[i]=l-5*Point;
      // 失败后下一根确认
      if(failBuy[i+1]!=EMPTY_VALUE&&c>refH)buySignal[i]=l-10*Point;
      if(failSell[i+1]!=EMPTY_VALUE&&c<refL)sellSignal[i]=h+10*Point;
   }return(0);}
