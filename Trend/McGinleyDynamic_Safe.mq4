//+------------------------------------------------------------------+
//|                                            McGinleyDynamic_Safe.mq4|
//|  麦金利动态均线（McGinley Dynamic）— 不含未来函数                 |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：MD=MD_prev+(Price-MD_prev)/(N*(Price/MD_prev)^4)            |
//|  自动调整速度：远离价格时加速，靠近价格时减速                      |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 3

input int InpPeriod=14;input color InpColor=clrYellow;

double md[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,InpColor);SetIndexBuffer(0,md);SetIndexLabel(0,"McGinley");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("McGinley_Safe("+IntegerToString(InpPeriod)+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;

   for(int i=limit+50;i>=1;i--){
      double c=iClose(_Symbol,_Period,i);
      if(i>=Bars-50)md[i]=c;
      else{double r=md[i+1]>0?c/md[i+1]:1;md[i]=md[i+1]+(c-md[i+1])/MathMax(InpPeriod*MathPow(r,4),1.0);}
      if(i<=limit){buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;}
   }
   for(int i=limit;i>=2;i--){
      double c=iClose(_Symbol,_Period,i),c1=iClose(_Symbol,_Period,i+1);
      if(c1<=md[i+1]&&c>md[i])buySignal[i]=iLow(_Symbol,_Period,i)-5*Point;
      if(c1>=md[i+1]&&c<md[i])sellSignal[i]=iHigh(_Symbol,_Period,i)+5*Point;
   }
   if(Bars>0){md[0]=md[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
