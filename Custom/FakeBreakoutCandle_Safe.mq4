//+------------------------------------------------------------------+
//|                                    FakeBreakoutCandle_Safe.mq4    |
//|  假突破K线 — 突破关键位后又回到区间内的K线                         |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
input int InpLookback=20;
double fakeBuy[],fakeSell[],trueBuy[],trueSell[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(0,fakeBuy);SetIndexArrow(0,ARROW_SELL);SetIndexLabel(0,"Fake Break Up");SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(1,fakeSell);SetIndexArrow(1,ARROW_BUY);SetIndexLabel(1,"Fake Break Dn");SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,trueBuy);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,trueSell);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("FakeBO_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){fakeBuy[i]=fakeSell[i]=trueBuy[i]=trueSell[i]=EMPTY_VALUE;}
   for(int i=limit;i>=5;i--){
      double h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i),o=iOpen(_Symbol,_Period,i);
      double hh=h,ll=l;for(int j=1;j<InpLookback;j++){double hj=iHigh(_Symbol,_Period,i+j),lj=iLow(_Symbol,_Period,i+j);if(hj>hh)hh=hj;if(lj<ll)ll=lj;}
      // 假突破上：先突破前高→又回落到前高以下
      if(h>hh&&c<hh){fakeBuy[i]=h+5*Point;trueSell[i]=l-10*Point;}
      // 假突破下：先跌破前低→又回升到前低以上
      if(l<ll&&c>ll){fakeSell[i]=l-5*Point;trueBuy[i]=h+10*Point;}
   }
   return(0);}
