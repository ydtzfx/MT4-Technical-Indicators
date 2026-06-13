//+------------------------------------------------------------------+
//|                                                  HullMA_Safe.mq4  |
//|  Hull Moving Average — 不含未来函数                               |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：HMA = WMA(2*WMA(Price,N/2)-WMA(Price,N), sqrt(N))          |
//|  Alan Hull设计，极度减少滞后同时保持平滑                          |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5

input int InpPeriod=16;input color InpColor=clrDodgerBlue;input int InpWidth=2;

double hma[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,InpWidth,InpColor);SetIndexBuffer(0,hma);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"HMA");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(3,strongBuy);SetIndexArrow(3,233);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(4,strongSell);SetIndexArrow(4,234);SetIndexEmptyValue(4,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("HMA_Safe("+IntegerToString(InpPeriod)+")");return(0);
}
int deinit(){return(0);}

double WMA(double &p[],int per,int st){double s=0,w=0;for(int i=0;i<per;i++){int wt=per-i;s+=p[st+i]*wt;w+=wt;}return w>0?s/w:0;}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   int sq=(int)MathSqrt(InpPeriod);int hist=InpPeriod*3;if(limit>Bars-2)limit=Bars-hist;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--) {
      double pr[200];for(int j=0;j<hist&&(i+j<Bars);j++)pr[j]=iClose(_Symbol,_Period,i+j);
      double wmaN2=WMA(pr,InpPeriod/2,0),wmaN=WMA(pr,InpPeriod,0);
      double diffVals[100];for(int j=0;j<sq*2&&(i+j<Bars);j++)diffVals[j]=2*WMA(pr,InpPeriod/2,j)-WMA(pr,InpPeriod,j);
      hma[i]=WMA(diffVals,sq,0);
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
      strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=2;i--){
      double c=iClose(_Symbol,_Period,i),c1=iClose(_Symbol,_Period,i+1);
      // Strong Buy: price crosses above HMA + HMA uptrend confirmed (2 consecutive rises) + significant penetration
      if(c1<=hma[i+1]&&c>hma[i]&&hma[i]>hma[i+1]&&hma[i+1]>hma[i+2]&&(c-hma[i])>5*Point)
         strongBuy[i]=iLow(_Symbol,_Period,i)-5*Point;
      else if(c1<=hma[i+1]&&c>hma[i])
         buySignal[i]=iLow(_Symbol,_Period,i)-5*Point;
      // Strong Sell: price crosses below HMA + HMA downtrend confirmed (2 consecutive falls) + significant penetration
      if(c1>=hma[i+1]&&c<hma[i]&&hma[i]<hma[i+1]&&hma[i+1]<hma[i+2]&&(hma[i]-c)>5*Point)
         strongSell[i]=iHigh(_Symbol,_Period,i)+5*Point;
      else if(c1>=hma[i+1]&&c<hma[i])
         sellSignal[i]=iHigh(_Symbol,_Period,i)+5*Point;
   }
   if(Bars>0){hma[0]=hma[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=strongSell[0]=EMPTY_VALUE;}
   return(0);
}
