//+------------------------------------------------------------------+
//|                                      UpthrustShakeout_Safe.mq4    |
//|  上冲/振出 — Wyckoff的UT/Shakeout检测                              |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
input int InpLookback=30;
double upthrust[],shakeout[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,4,CLR_SELL_SIGNAL);SetIndexBuffer(0,upthrust);SetIndexArrow(0,ARROW_SELL);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,4,CLR_BUY_SIGNAL);SetIndexBuffer(1,shakeout);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("UTSO_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){upthrust[i]=shakeout[i]=buySignal[i]=sellSignal[i]=EMPTY_VALUE;}
   for(int i=limit;i>=5;i++){
      double o=iOpen(_Symbol,_Period,i),h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i);
      double r=h-l;if(r<_Point)continue;long v=iVolume(_Symbol,_Period,i);
      double avgV=0;for(int j=0;j<20;j++)avgV+=iVolume(_Symbol,_Period,i+j);avgV/=20;
      double hh=h;for(int j=1;j<InpLookback;j++){double hj=iHigh(_Symbol,_Period,i+j);if(hj>hh)hh=hj;}
      // Upthrust: 短暂突破前高+放量+收盘回落到前高下方=诱多陷阱
      if(h>hh&&c<hh&&v>avgV*1.3){upthrust[i]=h+5*Point;sellSignal[i]=l-10*Point;}
      // Shakeout: 短暂跌破前低+放量+收盘回升到前低上方=诱空陷阱(弹簧)
      double ll=l;for(int j=1;j<InpLookback;j++){double lj=iLow(_Symbol,_Period,i+j);if(lj<ll)ll=lj;}
      if(l<ll&&c>ll&&v>avgV*1.3){shakeout[i]=l-5*Point;buySignal[i]=h+10*Point;}
   }
   return(0);}
