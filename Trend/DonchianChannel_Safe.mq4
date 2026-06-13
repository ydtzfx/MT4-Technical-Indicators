//+------------------------------------------------------------------+
//|                                       DonchianChannel_Safe.mq4    |
//|  唐奇安通道 — 不含未来函数                                        |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：Upper=Highest(High,N), Lower=Lowest(Low,N)                   |
//|        Middle=(Upper+Lower)/2                                       |
//|  突破上轨=做多，跌破下轨=做空（经典海龟策略）                      |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 7

input int InpPeriod=20;input bool InpShowSignals=true;

double upper[],middle[],lower[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,clrRoyalBlue);SetIndexBuffer(0,upper);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Donchian Upper");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrOrange);SetIndexBuffer(1,middle);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Donchian Mid");
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1,clrRoyalBlue);SetIndexBuffer(2,lower);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexLabel(2,"Donchian Lower");
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(3,buySignal);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(4,sellSignal);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(5,strongBuy);SetIndexArrow(5,ARROW_BUY);SetIndexLabel(5,"Strong Buy");SetIndexEmptyValue(5,EMPTY_VALUE);
   SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(6,strongSell);SetIndexArrow(6,ARROW_SELL);SetIndexLabel(6,"Strong Sell");SetIndexEmptyValue(6,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("Donchian_Safe("+IntegerToString(InpPeriod)+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpPeriod*2;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--) {
      double hh=iHigh(_Symbol,_Period,i),ll=iLow(_Symbol,_Period,i);
      for(int j=1;j<InpPeriod;j++){double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);if(h>hh)hh=h;if(l<ll)ll=l;}
      upper[i]=hh;lower[i]=ll;middle[i]=(hh+ll)/2;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   if(InpShowSignals) for(int i=limit;i>=2;i--) {
      double c=iClose(_Symbol,_Period,i),c1=iClose(_Symbol,_Period,i+1);
      double range = upper[i]-lower[i];
      bool tightRange = (range < iATR(_Symbol,_Period,14,i)*3); // 窄幅盘整后突破更强
      // 强买：窄幅盘整后N周期高点突破
      if(c1<=upper[i+1]&&c>upper[i]&&tightRange)strongBuy[i]=iLow(_Symbol,_Period,i)-8*Point;
      else if(c1<=upper[i+1]&&c>upper[i])buySignal[i]=iLow(_Symbol,_Period,i)-5*Point;
      // 强卖：窄幅盘整后N周期低点跌破
      if(c1>=lower[i+1]&&c<lower[i]&&tightRange)strongSell[i]=iHigh(_Symbol,_Period,i)+8*Point;
      else if(c1>=lower[i+1]&&c<lower[i])sellSignal[i]=iHigh(_Symbol,_Period,i)+5*Point;
   }
   if(Bars>0){upper[0]=upper[1];lower[0]=lower[1];middle[0]=middle[1];buySignal[0]=sellSignal[0]=strongBuy[0]=strongSell[0]=EMPTY_VALUE;}
   return(0);
}
