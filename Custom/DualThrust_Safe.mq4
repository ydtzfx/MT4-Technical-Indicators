//+------------------------------------------------------------------+
//|                                           DualThrust_Safe.mq4     |
//|  Dual Thrust策略 — 经典日内突破策略                               |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：Range=Max(HH-LC,HC-LL), BuyLine=Open+K1*Range               |
//|        SellLine=Open-K2*Range                                       |
//|  突破BuyLine做多，跌破SellLine做空                                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 8

input int InpPeriod=5;input double InpK1=0.7;input double InpK2=0.7;
input bool InpAlert=false;

double buyLine[],sellLine[],upper[],lower[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_DASH,1,clrLimeGreen);SetIndexBuffer(0,buyLine);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"BuyLine");
   SetIndexStyle(1,DRAW_LINE,STYLE_DASH,1,clrTomato);SetIndexBuffer(1,sellLine);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"SellLine");
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,2,clrYellow);SetIndexBuffer(2,upper);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexLabel(2,"HH");
   SetIndexStyle(3,DRAW_LINE,STYLE_SOLID,2,clrYellow);SetIndexBuffer(3,lower);SetIndexEmptyValue(3,EMPTY_VALUE);SetIndexLabel(3,"LL");
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(4,buySignal);SetIndexArrow(4,ARROW_BUY);SetIndexEmptyValue(4,EMPTY_VALUE);
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(5,sellSignal);SetIndexArrow(5,ARROW_SELL);SetIndexEmptyValue(5,EMPTY_VALUE);
   SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(6,strongBuy);SetIndexArrow(6,ARROW_BUY);SetIndexLabel(6,"Strong Buy");SetIndexEmptyValue(6,EMPTY_VALUE);
   SetIndexStyle(7,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(7,strongSell);SetIndexArrow(7,ARROW_SELL);SetIndexLabel(7,"Strong Sell");SetIndexEmptyValue(7,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("DualThrust_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      double hh=iHigh(_Symbol,_Period,i+1),ll=iLow(_Symbol,_Period,i+1),hc=iClose(_Symbol,_Period,i+1),lc=iClose(_Symbol,_Period,i+1);
      for(int j=2;j<=InpPeriod;j++){double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);if(h>hh)hh=h;if(l<ll)ll=l;}
      for(int j=1;j<=InpPeriod;j++){double c=iClose(_Symbol,_Period,i+j);if(c>hc)hc=c;if(c<lc)lc=c;}
      double range=MathMax(hh-lc,hc-ll);
      double open=iOpen(_Symbol,_Period,i);
      buyLine[i]=open+InpK1*range;sellLine[i]=open-InpK2*range;upper[i]=hh;lower[i]=ll;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=2;i--){
      double c=iClose(_Symbol,_Period,i),c1=iClose(_Symbol,_Period,i+1);
      double o=iOpen(_Symbol,_Period,i),h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i);
      bool isBuyBreak=c1<=buyLine[i+1]&&c>buyLine[i];
      bool isSellBreak=c1>=sellLine[i+1]&&c<sellLine[i];
      if(isBuyBreak){buySignal[i]=l-5*Point;if(InpAlert)AlertBuy("DualThrust",c,"Break");}
      if(isSellBreak){sellSignal[i]=h+5*Point;if(InpAlert)AlertSell("DualThrust",c,"Break");}
      // 强买入：突破 + 阳线实体较大 + 收盘价接近最高点
      if(isBuyBreak&&c-o>(h-l)*0.4&&h-c<(h-l)*0.25){strongBuy[i]=l-10*Point;}
      // 强卖出：跌破 + 阴线实体较大 + 收盘价接近最低点
      if(isSellBreak&&o-c>(h-l)*0.4&&c-l<(h-l)*0.25){strongSell[i]=h+10*Point;}
   }
   if(Bars>0){buyLine[0]=buyLine[1];sellLine[0]=sellLine[1];upper[0]=upper[1];lower[0]=lower[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=EMPTY_VALUE;strongSell[0]=EMPTY_VALUE;}
   return(0);
}
