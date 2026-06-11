//+------------------------------------------------------------------+
//|                                        KeltnerChannel_Safe.mq4    |
//|  肯特纳通道 — 不含未来函数                                        |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：Middle = EMA(Price, N), Upper = Middle + K*ATR(N)           |
//|        Lower = Middle - K*ATR(N)                                    |
//|  与Bollinger的区别：用ATR代替标准差，对缺口更敏感                  |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5

input int    InpMAPeriod   = 20;      // EMA周期
input double InpMultiplier = 2.0;     // ATR倍数
input int    InpATRPeriod  = 10;      // ATR周期
input ENUM_PRICE_SAFE InpPriceType = PRICE_CLOSE;
input bool   InpShowSignals = true;

double upper[],middle[],lower[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,clrRoyalBlue);SetIndexBuffer(0,upper);SetIndexLabel(0,"KC Upper");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrOrange);SetIndexBuffer(1,middle);SetIndexLabel(1,"KC Middle");
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1,clrRoyalBlue);SetIndexBuffer(2,lower);SetIndexLabel(2,"KC Lower");
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(3,buySignal);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(4,sellSignal);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("KC_Safe("+IntegerToString(InpMAPeriod)+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpMAPeriod*2;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--) {
      double prices[50];for(int j=0;j<InpMAPeriod*2;j++)prices[j]=GetPriceByType(i+j,InpPriceType);
      double ema=prices[InpMAPeriod*2-1];double alpha=2.0/(InpMAPeriod+1);
      for(int j=InpMAPeriod*2-2;j>=0;j--)ema=prices[j]*alpha+ema*(1-alpha);
      middle[i]=ema;
      double trSum=0;for(int j=0;j<InpATRPeriod;j++){trSum+=GetTrueRange(_Symbol,_Period,i+j);}
      double atr=trSum/InpATRPeriod;
      upper[i]=ema+InpMultiplier*atr;lower[i]=ema-InpMultiplier*atr;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   if(InpShowSignals) for(int i=limit;i>=1;i--) {
      double c=iClose(_Symbol,_Period,i),c1=iClose(_Symbol,_Period,i+1);
      // 突破上轨
      if(c1<=upper[i+1]&&c>upper[i])buySignal[i]=iLow(_Symbol,_Period,i)-5*Point;
      // 跌破下轨
      if(c1>=lower[i+1]&&c<lower[i])sellSignal[i]=iHigh(_Symbol,_Period,i)+5*Point;
      // 中轨穿越
      if(c1<=middle[i+1]&&c>middle[i]&&middle[i]>middle[i+1])buySignal[i]=iLow(_Symbol,_Period,i)-8*Point;
   }
   if(Bars>0){upper[0]=upper[1];middle[0]=middle[1];lower[0]=lower[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
