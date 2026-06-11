//+------------------------------------------------------------------+
//|                                        RejectionCandle_Safe.mq4   |
//|  拒绝K线 — 长影线在关键位的拒绝信号                                |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
input double InpWickRatio=0.5; // 影线占比>50%
double rejectBuy[],rejectSell[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,4,CLR_BUY_SIGNAL);SetIndexBuffer(0,rejectBuy);SetIndexArrow(0,ARROW_BUY);SetIndexLabel(0,"Reject Buy");SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,4,CLR_SELL_SIGNAL);SetIndexBuffer(1,rejectSell);SetIndexArrow(1,ARROW_SELL);SetIndexLabel(1,"Reject Sell");SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("Reject_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){rejectBuy[i]=rejectSell[i]=buySignal[i]=sellSignal[i]=EMPTY_VALUE;}
   for(int i=limit;i>=3;i--){
      double o=iOpen(_Symbol,_Period,i),h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i);
      double r=h-l;if(r<_Point)continue;
      double upW=h-MathMax(o,c),loW=MathMin(o,c)-l;
      double pc=iClose(_Symbol,_Period,i+1);
      // 长下影拒绝（买方在低位强力反击）
      if(loW>r*InpWickRatio&&(h-MathMin(o,c))<r*0.2&&c>o){rejectBuy[i]=l-5*Point;if(pc<l)rejectBuy[i]=l-10*Point;}
      // 长上影拒绝（卖方在高位强力反击）
      if(upW>r*InpWickRatio&&(MathMax(o,c)-l)<r*0.2&&c<o){rejectSell[i]=h+5*Point;if(pc>h)rejectSell[i]=h+10*Point;}
      // 确认：下一根K线延续拒绝方向
      if(rejectBuy[i+1]!=EMPTY_VALUE&&iClose(_Symbol,_Period,i)>iHigh(_Symbol,_Period,i+1))buySignal[i]=l-12*Point;
      if(rejectSell[i+1]!=EMPTY_VALUE&&iClose(_Symbol,_Period,i)<iLow(_Symbol,_Period,i+1))sellSignal[i]=h+12*Point;
   }
   return(0);}
