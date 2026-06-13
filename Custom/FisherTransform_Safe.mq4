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
#property indicator_buffers 5
#property indicator_level1 2
#property indicator_level2 -2

input int InpPeriod=10;input ENUM_PRICE_SAFE InpPrice=PRICE_MEDIAN;

double fisher[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,fisher);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Fisher");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(3,strongBuy);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(4,strongSell);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);
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
      fisher[i]=prevFish;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=1;i--) {
      bool priceUp=iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+3);
      bool fishRising=fisher[i]>fisher[i+1]&&fisher[i+1]>fisher[i+2];
      bool fishFalling=fisher[i]<fisher[i+1]&&fisher[i+1]<fisher[i+2];
      // Strong Buy: Fisher从超卖回升 + 持续上升 + 价格上涨
      if(fisher[i+1]<-2&&fisher[i]>-2&&fishRising&&priceUp)strongBuy[i]=-2.8;
      // Strong Sell: Fisher从超买回落 + 持续下降 + 价格下跌
      if(fisher[i+1]>2&&fisher[i]<2&&fishFalling&&!priceUp)strongSell[i]=2.8;
      // Normal Buy: Fisher从超卖回升
      if(fisher[i+1]<-2&&fisher[i]>-2&&strongBuy[i]==EMPTY_VALUE)buySignal[i]=-2.5;
      // Normal Sell: Fisher从超买回落
      if(fisher[i+1]>2&&fisher[i]<2&&strongSell[i]==EMPTY_VALUE)sellSignal[i]=2.5;
      // 底部反转形态
      if(fisher[i+1]<fisher[i+2]&&fisher[i]>fisher[i+1]&&fisher[i]<-1&&strongBuy[i]==EMPTY_VALUE)buySignal[i]=-2.5;
      // 顶部反转形态
      if(fisher[i+1]>fisher[i+2]&&fisher[i]<fisher[i+1]&&fisher[i]>1&&strongSell[i]==EMPTY_VALUE)sellSignal[i]=2.5;
   }
   if(Bars>0){fisher[0]=fisher[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=strongSell[0]=EMPTY_VALUE;}
   return(0);
}
