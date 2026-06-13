//+------------------------------------------------------------------+
//|                                       ChandelierExit_Safe.mq4     |
//|  吊灯止损（Chandelier Exit）— 不含未来函数                        |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：多头止损=HH(N)-K*ATR, 空头止损=LL(N)+K*ATR                 |
//|  用于趋势跟踪型止损，兼具通道和止损参考功能                        |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 7

input int InpPeriod=22;input double InpMultiplier=3.0;input int InpATRPeriod=14;

double longStop[],shortStop[],trendLine[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,clrLimeGreen);SetIndexBuffer(0,longStop);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Long Stop");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,clrTomato);SetIndexBuffer(1,shortStop);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Short Stop");
   SetIndexStyle(2,DRAW_NONE);SetIndexBuffer(2,trendLine);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(3,buySignal);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(4,sellSignal);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(5,strongBuy);SetIndexArrow(5,ARROW_BUY);SetIndexLabel(5,"Strong Buy");SetIndexEmptyValue(5,EMPTY_VALUE);
   SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(6,strongSell);SetIndexArrow(6,ARROW_SELL);SetIndexLabel(6,"Strong Sell");SetIndexEmptyValue(6,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("Chandelier_Safe("+IntegerToString(InpPeriod)+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpPeriod*3;if(limit<0)limit=0;

   bool isLong=true;double prevStop=0;
   for(int i=limit+InpPeriod;i>=1;i--) {
      double atr=0;for(int j=0;j<InpATRPeriod;j++)atr+=GetTrueRange(_Symbol,_Period,i+j);atr/=InpATRPeriod;
      double hh=iHigh(_Symbol,_Period,i),ll=iLow(_Symbol,_Period,i);
      for(int j=1;j<InpPeriod;j++){double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);if(h>hh)hh=h;if(l<ll)ll=l;}
      double ls=hh-InpMultiplier*atr,ss=ll+InpMultiplier*atr;
      if(i==limit+InpPeriod){isLong=iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+InpPeriod);prevStop=isLong?ls:ss;}
      else{if(isLong){prevStop=MathMax(ls,prevStop);if(iClose(_Symbol,_Period,i)<prevStop){isLong=false;prevStop=ss;}}else{prevStop=MathMin(ss,prevStop);if(iClose(_Symbol,_Period,i)>prevStop){isLong=true;prevStop=ls;}}}
      longStop[i]=isLong?prevStop:EMPTY_VALUE;shortStop[i]=!isLong?prevStop:EMPTY_VALUE;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=2;i--) {
      double atr=0;for(int j=0;j<InpATRPeriod;j++)atr+=GetTrueRange(_Symbol,_Period,i+j);atr/=InpATRPeriod;
      double gap = MathAbs(longStop[i] - shortStop[i]);
      bool wideFlip = (gap > atr * 2); // 止损间距大=趋势转折剧烈
      if(shortStop[i+1]!=EMPTY_VALUE&&longStop[i]!=EMPTY_VALUE&&wideFlip)strongBuy[i]=iLow(_Symbol,_Period,i)-15*Point;
      else if(shortStop[i+1]!=EMPTY_VALUE&&longStop[i]!=EMPTY_VALUE)buySignal[i]=iLow(_Symbol,_Period,i)-10*Point;
      if(longStop[i+1]!=EMPTY_VALUE&&shortStop[i]!=EMPTY_VALUE&&wideFlip)strongSell[i]=iHigh(_Symbol,_Period,i)+15*Point;
      else if(longStop[i+1]!=EMPTY_VALUE&&shortStop[i]!=EMPTY_VALUE)sellSignal[i]=iHigh(_Symbol,_Period,i)+10*Point;
   }
   if(Bars>0){longStop[0]=longStop[1];shortStop[0]=shortStop[1];buySignal[0]=sellSignal[0]=strongBuy[0]=strongSell[0]=EMPTY_VALUE;}
   return(0);
}
