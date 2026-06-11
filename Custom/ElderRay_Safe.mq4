//+------------------------------------------------------------------+
//|                                                ElderRay_Safe.mq4  |
//|  艾尔德射线（Elder Ray Index）— 不含未来函数                      |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：BullPower=High-EMA(Close,13), BearPower=Low-EMA(Close,13)  |
//|  同时显示Bulls和Bears Power，EMA为中线                             |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5

input int InpPeriod=13;

double bull[],bear[],zero[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,2,clrLimeGreen);SetIndexBuffer(0,bull);SetIndexLabel(0,"Bull Power");
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,2,clrTomato);SetIndexBuffer(1,bear);SetIndexLabel(1,"Bear Power");
   SetIndexStyle(2,DRAW_NONE);SetIndexBuffer(2,zero);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(3,buySignal);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(4,sellSignal);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("ElderRay_Safe("+IntegerToString(InpPeriod)+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpPeriod*3;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      double p[50];for(int j=0;j<50;j++)p[j]=iClose(_Symbol,_Period,i+j);
      double ema=p[49];double a=2.0/(InpPeriod+1);
      for(int j=48;j>=0;j--)ema=p[j]*a+ema*(1-a);
      bull[i]=iHigh(_Symbol,_Period,i)-ema;bear[i]=iLow(_Symbol,_Period,i)-ema;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=3;i--){
      // Bull从负转正+Bear也回升 = 全面转多
      if(bull[i+1]<0&&bull[i]>0&&bear[i]>bear[i+1])buySignal[i]=bull[i]*0.5;
      // Bear从正转负+Bull也下降 = 全面转空
      if(bear[i+1]>0&&bear[i]<0&&bull[i]<bull[i+1])sellSignal[i]=bear[i]*1.5;
      // 顶背离
      double c=iClose(_Symbol,_Period,i),c3=iClose(_Symbol,_Period,i+3);
      if(c>c3&&bull[i]<bull[i+3]&&bull[i]>0)sellSignal[i]=bull[i]*1.5;
      // 底背离
      if(c<c3&&bear[i]>bear[i+3]&&bear[i]<0)buySignal[i]=bear[i]*0.5;
   }
   if(Bars>0){bull[0]=bull[1];bear[0]=bear[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
