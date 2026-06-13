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
#property indicator_buffers 5

input int InpPeriod=14;input color InpColor=clrMagenta;

double zlema[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,InpColor);SetIndexBuffer(0,zlema);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"ZLEMA");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexBuffer(3,strongBuy);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexArrow(3,233);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexBuffer(4,strongSell);SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexArrow(4,234);SetIndexEmptyValue(4,EMPTY_VALUE);
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
   for(int i=limit;i>=1;i--){buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;}
   for(int i=limit;i>=2;i--){
      double c=iClose(_Symbol,_Period,i),c1=iClose(_Symbol,_Period,i+1);
      // strong signals: cross + ZLEMA slope confirmation (multi-condition grading)
      bool isBuyCross=(c1<=zlema[i+1]&&c>zlema[i]);
      bool isSellCross=(c1>=zlema[i+1]&&c<zlema[i]);
      if(isBuyCross){
         if(zlema[i]>zlema[i+1])strongBuy[i]=iLow(_Symbol,_Period,i)-5*Point;
         buySignal[i]=iLow(_Symbol,_Period,i)-5*Point;
      }
      if(isSellCross){
         if(zlema[i]<zlema[i+1])strongSell[i]=iHigh(_Symbol,_Period,i)+5*Point;
         sellSignal[i]=iHigh(_Symbol,_Period,i)+5*Point;
      }
   }
   if(Bars>0){zlema[0]=zlema[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=EMPTY_VALUE;strongSell[0]=EMPTY_VALUE;}
   return(0);
}
