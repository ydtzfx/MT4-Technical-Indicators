//+------------------------------------------------------------------+
//|                                            DarvasBox_Safe.mq4     |
//|  达瓦斯箱体 — Nicolas Darvas的经典策略                            |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  规则：价格创新高后形成箱体上沿，回调不破低点为下沿                |
//|  突破上沿=买入（加仓），跌破下沿=卖出（全部平仓）                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 6

input int InpSwingPeriod=10;

double boxHi[],boxLo[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrLimeGreen);SetIndexBuffer(0,boxHi);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Box High");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrTomato);SetIndexBuffer(1,boxLo);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Box Low");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(4,strongBuy);SetIndexArrow(4,233);SetIndexEmptyValue(4,EMPTY_VALUE);
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(5,strongSell);SetIndexArrow(5,234);SetIndexEmptyValue(5,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("DarvasBox_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   double currentBoxHi=0,currentBoxLo=99999;
   for(int i=limit+100;i>=1;i--){
      // 找新高的bar
      double h=iHigh(_Symbol,_Period,i);bool isNewHigh=true;
      for(int j=1;j<=InpSwingPeriod&&(i+j<Bars);j++){if(iHigh(_Symbol,_Period,i+j)>=h)isNewHigh=false;}
      if(isNewHigh&&h>currentBoxHi){
         currentBoxHi=h;double l=iLow(_Symbol,_Period,i);for(int j=1;j<=InpSwingPeriod&&(i-j>=0);j++){if(iLow(_Symbol,_Period,i-j)<l)l=iLow(_Symbol,_Period,i-j);}
         currentBoxLo=l;
      }
      if(i<=limit){boxHi[i]=currentBoxHi;boxLo[i]=currentBoxLo;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;}
   }
   for(int i=limit;i>=2;i--){
      double c=iClose(_Symbol,_Period,i),c1=iClose(_Symbol,_Period,i+1);
      double hb=iHigh(_Symbol,_Period,i),lb=iLow(_Symbol,_Period,i);
      // Average range over swing period for momentum confirmation
      double avgRange=0;int rCount=0;
      for(int k=1;k<=InpSwingPeriod&&(i+k-1<Bars);k++){avgRange+=iHigh(_Symbol,_Period,i+k-1)-iLow(_Symbol,_Period,i+k-1);rCount++;}
      if(rCount>0)avgRange/=rCount;
      double barRange=hb-lb;
      // Normal signals
      if(c1<=boxHi[i+1]&&c>boxHi[i]){buySignal[i]=lb-5*Point;
         if(barRange>=1.3*avgRange)strongBuy[i]=lb-8*Point;}
      if(c1>=boxLo[i+1]&&c<boxLo[i]){sellSignal[i]=hb+5*Point;
         if(barRange>=1.3*avgRange)strongSell[i]=hb+8*Point;}
   }
   if(Bars>0){boxHi[0]=boxHi[1];boxLo[0]=boxLo[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=EMPTY_VALUE;strongSell[0]=EMPTY_VALUE;}
   return(0);
}
