//+------------------------------------------------------------------+
//|                                                   DEMA_Safe.mq4   |
//|  双重指数移动平均（DEMA）— 不含未来函数                            |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：DEMA = 2*EMA - EMA(EMA)                                     |
//|  Patrick Mulloy设计，减少滞后，比EMA快一倍                        |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5

input int InpPeriod=14;input color InpColor=clrLimeGreen;

double dema[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,InpColor);SetIndexBuffer(0,dema);SetIndexLabel(0,"DEMA");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(3,strongBuy);SetIndexArrow(3,233);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(4,strongSell);SetIndexArrow(4,234);SetIndexEmptyValue(4,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("DEMA_Safe("+IntegerToString(InpPeriod)+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   int hist=InpPeriod*3;if(limit>Bars-2)limit=Bars-hist;if(limit<0)limit=0;

   double a=2.0/(InpPeriod+1),e1[],e2[];ArrayResize(e1,Bars);ArrayResize(e2,Bars);
   for(int i=Bars-2;i>=0;i--){
      if(i>=Bars-hist){e1[i]=iClose(_Symbol,_Period,i);e2[i]=e1[i];}
      else{e1[i]=iClose(_Symbol,_Period,i)*a+e1[i+1]*(1-a);e2[i]=e1[i]*a+e2[i+1]*(1-a);}
   }
   for(int i=limit;i>=1;i--){dema[i]=2*e1[i]-e2[i];buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;}
   for(int i=limit;i>=2;i--){
      double c=iClose(_Symbol,_Period,i),c1=iClose(_Symbol,_Period,i+1);
      double o=iOpen(_Symbol,_Period,i);
      bool isBuyCross=(c1<=dema[i+1]&&c>dema[i]);
      bool isSellCross=(c1>=dema[i+1]&&c<dema[i]);
      bool bullishCandle=(c>o);
      bool bearishCandle=(c<o);
      bool demaRising=(dema[i]>dema[i+1]);
      bool demaFalling=(dema[i]<dema[i+1]);
      if(isBuyCross&&bullishCandle&&demaRising)strongBuy[i]=iLow(_Symbol,_Period,i)-5*Point;
      else if(isBuyCross)buySignal[i]=iLow(_Symbol,_Period,i)-5*Point;
      if(isSellCross&&bearishCandle&&demaFalling)strongSell[i]=iHigh(_Symbol,_Period,i)+5*Point;
      else if(isSellCross)sellSignal[i]=iHigh(_Symbol,_Period,i)+5*Point;
   }
   if(Bars>0){dema[0]=2*e1[0]-e2[0];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=EMPTY_VALUE;strongSell[0]=EMPTY_VALUE;}
   return(0);
}
