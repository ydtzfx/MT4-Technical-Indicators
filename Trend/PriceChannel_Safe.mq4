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
#property indicator_buffers 7

input int InpPeriod=20;input double InpATRMult=0.5;input int InpATRPeriod=10;

double upper[],mid[],lower[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,clrRoyalBlue);SetIndexBuffer(0,upper);SetIndexLabel(0,"Upper");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrOrange);SetIndexBuffer(1,mid);SetIndexLabel(1,"Mid");
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1,clrRoyalBlue);SetIndexBuffer(2,lower);SetIndexLabel(2,"Lower");
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(3,buySignal);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(4,sellSignal);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);
   SetIndexBuffer(5,strongBuy);SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexArrow(5,233);SetIndexEmptyValue(5,EMPTY_VALUE);
   SetIndexBuffer(6,strongSell);SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexArrow(6,234);SetIndexEmptyValue(6,EMPTY_VALUE);
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
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=1;i--) {
      double c=iClose(_Symbol,_Period,i),c1=iClose(_Symbol,_Period,i+1);
      double rng=iHigh(_Symbol,_Period,i)-iLow(_Symbol,_Period,i);
      // Strong signals first: multi-condition confirmation
      // Strong buy: break above upper channel + close well beyond band (>= 30% of candle range above band)
      // Strong sell: break below lower channel + close well below band (>= 30% of candle range below band)
      bool buyBreak=c1<=upper[i+1]&&c>upper[i];
      bool sellBreak=c1>=lower[i+1]&&c<lower[i];
      if(buyBreak&&c-upper[i]>=rng*0.3)strongBuy[i]=iLow(_Symbol,_Period,i)-5*Point;
      if(sellBreak&&lower[i]-c>=rng*0.3)strongSell[i]=iHigh(_Symbol,_Period,i)+5*Point;
      // Normal signals (fallback when strong condition not met)
      if(buyBreak&&c-upper[i]<rng*0.3)buySignal[i]=iLow(_Symbol,_Period,i)-5*Point;
      if(sellBreak&&lower[i]-c<rng*0.3)sellSignal[i]=iHigh(_Symbol,_Period,i)+5*Point;
   }
   if(Bars>0){upper[0]=upper[1];mid[0]=mid[1];lower[0]=lower[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=EMPTY_VALUE;strongSell[0]=EMPTY_VALUE;}
   return(0);
}
