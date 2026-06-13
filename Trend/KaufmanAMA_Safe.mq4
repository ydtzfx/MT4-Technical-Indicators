//+------------------------------------------------------------------+
//|                                            KaufmanAMA_Safe.mq4    |
//|  考夫曼自适应移动平均（KAMA）— 不含未来函数                       |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：ER=|Price-Price[N]|/Σ|Price_i-Price_{i-1}|→SC→AMA           |
//|  市场噪音大时减缓，趋势明确时加速，自适应                          |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5

input int InpPeriod=10;input int InpFast=2;input int InpSlow=30;

double ama[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,ama);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"KAMA");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexBuffer(3,strongBuy);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexArrow(3,233);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexBuffer(4,strongSell);SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexArrow(4,234);SetIndexEmptyValue(4,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("KAMA_Safe("+IntegerToString(InpPeriod)+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpPeriod*3;if(limit<0)limit=0;

   double fastSC=2.0/(InpFast+1),slowSC=2.0/(InpSlow+1);

   for(int i=limit+InpPeriod*2;i>=1;i--){
      double dir=MathAbs(iClose(_Symbol,_Period,i)-iClose(_Symbol,_Period,i+InpPeriod));
      double vol=0;for(int j=0;j<InpPeriod;j++)vol+=MathAbs(iClose(_Symbol,_Period,i+j)-iClose(_Symbol,_Period,i+j+1));
      double er=vol>0?dir/vol:0;
      double sc=MathPow(er*(fastSC-slowSC)+slowSC,2);
      if(i>=Bars-InpPeriod*2)ama[i]=iClose(_Symbol,_Period,i);
      else ama[i]=ama[i+1]+sc*(iClose(_Symbol,_Period,i)-ama[i+1]);
   }
   for(int i=limit;i>=1;i--){ama[i]=ama[i]>0?ama[i]:iClose(_Symbol,_Period,i);buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;}
   for(int i=limit;i>=2;i--){
      // Strong Buy: crossover + significant price-KAMA gap + clear KAMA uptrend
      if(iClose(_Symbol,_Period,i+1)<=ama[i+1]&&iClose(_Symbol,_Period,i)>ama[i]&&ama[i]>ama[i+1]&&
         (iClose(_Symbol,_Period,i)-ama[i])>Point*20&&(ama[i]-ama[i+1])>Point)
         strongBuy[i]=iLow(_Symbol,_Period,i)-8*Point;
      // Strong Sell: crossover + significant price-KAMA gap + clear KAMA downtrend
      if(iClose(_Symbol,_Period,i+1)>=ama[i+1]&&iClose(_Symbol,_Period,i)<ama[i]&&ama[i]<ama[i+1]&&
         (ama[i]-iClose(_Symbol,_Period,i))>Point*20&&(ama[i+1]-ama[i])>Point)
         strongSell[i]=iHigh(_Symbol,_Period,i)+8*Point;
      if(iClose(_Symbol,_Period,i+1)<=ama[i+1]&&iClose(_Symbol,_Period,i)>ama[i]&&ama[i]>ama[i+1])buySignal[i]=iLow(_Symbol,_Period,i)-5*Point;
      if(iClose(_Symbol,_Period,i+1)>=ama[i+1]&&iClose(_Symbol,_Period,i)<ama[i]&&ama[i]<ama[i+1])sellSignal[i]=iHigh(_Symbol,_Period,i)+5*Point;
   }
   if(Bars>0){ama[0]=ama[1];buySignal[0]=sellSignal[0]=strongBuy[0]=strongSell[0]=EMPTY_VALUE;}
   return(0);
}
