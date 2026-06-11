//+------------------------------------------------------------------+
//|                                              ZeroLagEMA_Safe.mq4  |
//|  零滞后EMA — 不含未来函数                                         |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：ZLEMA=EMA(Price+Price-Price[lag],N)                         |
//|  通过前移价格来补偿EMA的滞后                                       |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 3

input int InpPeriod=14;input color InpColor=clrMagenta;

double zlema[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,InpColor);SetIndexBuffer(0,zlema);SetIndexLabel(0,"ZLEMA");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("ZLEMA_Safe("+IntegerToString(InpPeriod)+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   int lag=(InpPeriod-1)/2;int hist=InpPeriod*2;if(limit>Bars-2)limit=Bars-hist;if(limit<0)limit=0;

   double a=2.0/(InpPeriod+1);
   for(int i=limit+hist;i>=1;i--){
      // 去滞后价格 = Price + (Price - Price[lag])
      double deLag=iClose(_Symbol,_Period,i)+(iClose(_Symbol,_Period,i)-iClose(_Symbol,_Period,i+lag));
      if(i>=Bars-hist)zlema[i]=deLag;
      else zlema[i]=deLag*a+zlema[i+1]*(1-a);
   }
   for(int i=limit;i>=1;i--){buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;}
   for(int i=limit;i>=2;i--){
      double c=iClose(_Symbol,_Period,i),c1=iClose(_Symbol,_Period,i+1);
      if(c1<=zlema[i+1]&&c>zlema[i])buySignal[i]=iLow(_Symbol,_Period,i)-5*Point;
      if(c1>=zlema[i+1]&&c<zlema[i])sellSignal[i]=iHigh(_Symbol,_Period,i)+5*Point;
   }
   if(Bars>0){zlema[0]=zlema[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
