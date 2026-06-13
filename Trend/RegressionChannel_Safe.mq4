//+------------------------------------------------------------------+
//|                                      RegressionChannel_Safe.mq4   |
//|  线性回归通道 — 不含未来函数                                      |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  对N根bar的收盘价做线性回归：y = slope*x + intercept               |
//|  Upper/Mid/Lower = Regression + K*StdError                         |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 7

input int InpPeriod=50;input double InpK=2.0;

double upper[],mid[],lower[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,clrRoyalBlue);SetIndexBuffer(0,upper);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Regr Upper");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrYellow);SetIndexBuffer(1,mid);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Regression");
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1,clrRoyalBlue);SetIndexBuffer(2,lower);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexLabel(2,"Regr Lower");
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(3,buySignal);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(4,sellSignal);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);
   SetIndexBuffer(5,strongBuy);SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexArrow(5,233);SetIndexEmptyValue(5,EMPTY_VALUE);
   SetIndexBuffer(6,strongSell);SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexArrow(6,234);SetIndexEmptyValue(6,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("RegChannel_Safe("+IntegerToString(InpPeriod)+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpPeriod*2;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--) {
      double sumX=0,sumY=0,sumXY=0,sumX2=0;int n=InpPeriod;
      for(int j=0;j<n;j++) {
         double y=iClose(_Symbol,_Period,i+j);int x=j;
         sumX+=x;sumY+=y;sumXY+=x*y;sumX2+=x*x;
      }
      double slope=SafeDivide(n*sumXY-sumX*sumY,n*sumX2-sumX*sumX,0);
      double intercept=SafeDivide(sumY-slope*sumX,n,0);
      // 标准差
      double seSum=0;
      for(int j=0;j<n;j++){double yPred=slope*j+intercept;double diff=iClose(_Symbol,_Period,i+j)-yPred;seSum+=diff*diff;}
      double stdErr=MathSqrt(seSum/n);
      // 当前点（j=0）的回归值
      mid[i]=intercept;upper[i]=mid[i]+InpK*stdErr;lower[i]=mid[i]-InpK*stdErr;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=1;i--) {
      double c=iClose(_Symbol,_Period,i),c1=iClose(_Symbol,_Period,i+1);
      // Strong buy: price crosses above lower band + uptrend confirmed by rising regression line
      if(c1<=lower[i+1]&&c>lower[i]&&mid[i]>mid[i+1])strongBuy[i]=iLow(_Symbol,_Period,i)-5*Point;
      // Strong sell: price crosses below upper band + downtrend confirmed by falling regression line
      if(c1>=upper[i+1]&&c<upper[i]&&mid[i]<mid[i+1])strongSell[i]=iHigh(_Symbol,_Period,i)+5*Point;
      // Normal signals
      if(c1<=lower[i+1]&&c>lower[i])buySignal[i]=iLow(_Symbol,_Period,i)-5*Point;
      if(c1>=upper[i+1]&&c<upper[i])sellSignal[i]=iHigh(_Symbol,_Period,i)+5*Point;
      // 价格穿越回归中线
      if(c1<=mid[i+1]&&c>mid[i]&&mid[i]>mid[i+1])buySignal[i]=iLow(_Symbol,_Period,i)-10*Point;
   }
   if(Bars>0){upper[0]=upper[1];mid[0]=mid[1];lower[0]=lower[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=EMPTY_VALUE;strongSell[0]=EMPTY_VALUE;}
   return(0);
}
