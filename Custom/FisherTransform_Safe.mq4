//+------------------------------------------------------------------+
//|                                        FisherTransform_Safe.mq4   |
//|  费雪变换（Fisher Transform）— 不含未来函数                       |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：将价格归一化后应用Fisher反双曲正切变换                       |
//|  x=2*(Price-Min)/(Max-Min)-1, Fisher=0.5*ln((1+x)/(1-x))          |
//|  使价格分布接近正态，极值点更清晰                                  |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_level1 2
#property indicator_level2 -2

input int InpPeriod=10;input ENUM_PRICE_SAFE InpPrice=PRICE_MEDIAN;

double fisher[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,fisher);SetIndexLabel(0,"Fisher");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   IndicatorDigits(3);IndicatorShortName("Fisher_Safe("+IntegerToString(InpPeriod)+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpPeriod*3;if(limit<0)limit=0;

   double val1[];ArrayResize(val1,Bars);
   for(int i=limit+InpPeriod*2;i>=1;i--) {
      double mn=GetPriceByType(i,InpPrice),mx=GetPriceByType(i,InpPrice);
      for(int j=0;j<InpPeriod;j++){double p=GetPriceByType(i+j,InpPrice);if(p<mn)mn=p;if(p>mx)mx=p;}
      double rng=mx-mn;double x=rng>0?2*(GetPriceByType(i,InpPrice)-mn)/rng-1:0;
      x=MathMax(-0.999,MathMin(0.999,x));
      val1[i]=0.5*MathLog((1+x)/(1-x));
   }
   double prevFish=0;
   for(int i=limit;i>=1;i--) {
      prevFish=0.5*val1[i]+0.5*prevFish;
      fisher[i]=prevFish;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=1;i--) {
      if(fisher[i+1]<-2&&fisher[i]>-2)buySignal[i]=-2.5;
      if(fisher[i+1]>2&&fisher[i]<2)sellSignal[i]=2.5;
      if(fisher[i+1]<fisher[i+2]&&fisher[i]>fisher[i+1]&&fisher[i]<-1)buySignal[i]=-2.5;
      if(fisher[i+1]>fisher[i+2]&&fisher[i]<fisher[i+1]&&fisher[i]>1)sellSignal[i]=2.5;
   }
   if(Bars>0){fisher[0]=fisher[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
