//+------------------------------------------------------------------+
//|                                           PriceChannel_Safe.mq4   |
//|  价格通道 — 不含未来函数                                          |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：Upper=HH(N)+K*ATR, Lower=LL(N)-K*ATR, Mid=(U+L)/2          |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5

input int InpPeriod=20;input double InpATRMult=0.5;input int InpATRPeriod=10;

double upper[],mid[],lower[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,clrRoyalBlue);SetIndexBuffer(0,upper);SetIndexLabel(0,"Upper");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrOrange);SetIndexBuffer(1,mid);SetIndexLabel(1,"Mid");
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1,clrRoyalBlue);SetIndexBuffer(2,lower);SetIndexLabel(2,"Lower");
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(3,buySignal);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(4,sellSignal);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("PriceChannel_Safe("+IntegerToString(InpPeriod)+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpPeriod*2;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--) {
      double hh=iHigh(_Symbol,_Period,i),ll=iLow(_Symbol,_Period,i);
      for(int j=1;j<InpPeriod;j++){double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);if(h>hh)hh=h;if(l<ll)ll=l;}
      double trSum=0;for(int j=0;j<InpATRPeriod;j++)trSum+=GetTrueRange(_Symbol,_Period,i+j);double atr=trSum/InpATRPeriod;
      upper[i]=hh+InpATRMult*atr;lower[i]=ll-InpATRMult*atr;mid[i]=(upper[i]+lower[i])/2;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=1;i--) {
      double c=iClose(_Symbol,_Period,i),c1=iClose(_Symbol,_Period,i+1);
      if(c1<=upper[i+1]&&c>upper[i])buySignal[i]=iLow(_Symbol,_Period,i)-5*Point;
      if(c1>=lower[i+1]&&c<lower[i])sellSignal[i]=iHigh(_Symbol,_Period,i)+5*Point;
   }
   if(Bars>0){upper[0]=upper[1];mid[0]=mid[1];lower[0]=lower[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
