//+------------------------------------------------------------------+
//|                                              TTM_Squeeze_Safe.mq4 |
//|  TTM挤压指标（TTM Squeeze）— 不含未来函数                         |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：BB宽度 < KC宽度 = 挤压状态（即将突破）                      |
//|  Momentum = EMA(Close,20) - EMA(Close,10)（柱状图）                |
//|  挤压+动量转正=看涨突破，挤压+动量转负=看跌突破                    |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 7

input int InpBBPeriod=20;input double InpBBMult=2.0;
input int InpKCPeriod=20;input double InpKCMult=1.5;input int InpATRPeriod=10;

double momBuffer[],squeezeOn[],squeezeOff[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,momBuffer);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Momentum");
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,1,clrYellow);SetIndexBuffer(1,squeezeOn);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Squeeze On");
   SetIndexStyle(2,DRAW_HISTOGRAM,STYLE_SOLID,1,clrGray);SetIndexBuffer(2,squeezeOff);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexLabel(2,"Squeeze Off");
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(3,buySignal);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(4,sellSignal);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(5,strongBuy);SetIndexArrow(5,233);SetIndexEmptyValue(5,EMPTY_VALUE);SetIndexLabel(5,"Strong Buy");
   SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(6,strongSell);SetIndexArrow(6,234);SetIndexEmptyValue(6,EMPTY_VALUE);SetIndexLabel(6,"Strong Sell");
   IndicatorDigits(0);IndicatorShortName("TTM_Squeeze_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--) {
      // Bollinger Bands width
      double sum=0;for(int j=0;j<InpBBPeriod;j++)sum+=iClose(_Symbol,_Period,i+j);
      double sma=sum/InpBBPeriod;double sd=0;for(int j=0;j<InpBBPeriod;j++){double d=iClose(_Symbol,_Period,i+j)-sma;sd+=d*d;}
      sd=MathSqrt(sd/InpBBPeriod);double bbWidth=InpBBMult*sd*2;

      // Keltner Channel width
      double trSum=0;for(int j=0;j<InpATRPeriod;j++)trSum+=GetTrueRange(_Symbol,_Period,i+j);
      double atr=trSum/InpATRPeriod;double kcWidth=InpKCMult*atr*2;

      // Momentum
      double ema20=0;for(int j=0;j<InpBBPeriod;j++)ema20+=iClose(_Symbol,_Period,i+j);ema20/=InpBBPeriod;
      double a20=2.0/(InpBBPeriod+1);for(int j=InpBBPeriod-1;j>=0;j--)ema20=iClose(_Symbol,_Period,i+j)*a20+ema20*(1-a20);
      double ema10=0;for(int j=0;j<10;j++)ema10+=iClose(_Symbol,_Period,i+j);ema10/=10;
      double a10=2.0/11;for(int j=9;j>=0;j--)ema10=iClose(_Symbol,_Period,i+j)*a10+ema10*(1-a10);
      momBuffer[i]=ema10-ema20;

      bool squeeze=(bbWidth<kcWidth);
      squeezeOn[i]=squeeze?momBuffer[i]:0;squeezeOff[i]=!squeeze?momBuffer[i]:0;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=2;i--) {
      bool sqNow=(squeezeOn[i]!=0||squeezeOn[i+1]!=0),sqPrev=(squeezeOn[i+1]!=0||squeezeOn[i+2]!=0);
      // 挤压中动量转正 → 突破买入
      if(sqNow&&momBuffer[i]>0&&momBuffer[i+1]<=0)buySignal[i]=momBuffer[i]*0.5;
      // 挤压中动量转负 → 突破卖出
      if(sqNow&&momBuffer[i]<0&&momBuffer[i+1]>=0)sellSignal[i]=momBuffer[i]*1.5;
      // 挤压释放后首次转正 = 强买入
      if(sqNow&&!sqPrev&&momBuffer[i]>0)buySignal[i]=momBuffer[i]*0.3;
      // 强信号：挤压释放+动量大幅转正+放量
      if(sqNow&&!sqPrev&&momBuffer[i]>3.0&&iVolume(_Symbol,_Period,i)>iVolume(_Symbol,_Period,i+1)*1.3)strongBuy[i]=momBuffer[i]*0.5;
      if(sqNow&&!sqPrev&&momBuffer[i]<-3.0&&iVolume(_Symbol,_Period,i)>iVolume(_Symbol,_Period,i+1)*1.3)strongSell[i]=momBuffer[i]*1.5;
   }
   if(Bars>0){momBuffer[0]=momBuffer[1];squeezeOn[0]=squeezeOff[0]=0;buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=EMPTY_VALUE;strongSell[0]=EMPTY_VALUE;}
   return(0);
}
