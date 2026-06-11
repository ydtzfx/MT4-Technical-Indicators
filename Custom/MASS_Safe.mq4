//+------------------------------------------------------------------+
//|                                                  MASS_Safe.mq4    |
//|  梅斯线（Mass Index）— 不含未来函数                               |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：EMA1=EMA(High-Low,9), EMA2=EMA(EMA1,9)                      |
//|  Ratio = EMA1/EMA2, Mass = Σ(Ratio, 25)                            |
//|                                                                   |
//|  Mass>27 且随后回落到26.5以下 → 趋势即将反转                      |
//|  是预测趋势反转的领先指标                                          |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_level1 27

input int InpEMAPeriod = 9;
input int InpSumPeriod = 25;
input double InpReversalTrigger = 26.5;
input double InpReversalLine = 27.0;

double massBuffer[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,massBuffer);SetIndexLabel(0,"Mass Index");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   IndicatorDigits(2);IndicatorShortName("MASS_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;

   double ema1[],ema2[],ratio[];
   ArrayResize(ema1,Bars);ArrayResize(ema2,Bars);ArrayResize(ratio,Bars);
   double alpha=2.0/(InpEMAPeriod+1);

   for(int i=Bars-2;i>=0;i--) {
      double range=iHigh(_Symbol,_Period,i)-iLow(_Symbol,_Period,i);
      if(i>=Bars-30)ema1[i]=range;else ema1[i]=range*alpha+ema1[i+1]*(1.0-alpha);
   }
   for(int i=Bars-2;i>=0;i--) {
      if(i>=Bars-40)ema2[i]=ema1[i];else ema2[i]=ema1[i]*alpha+ema2[i+1]*(1.0-alpha);
      ratio[i]=SafeDivide(ema1[i],ema2[i],1.0);
   }
   for(int i=limit;i>=1;i--) {
      double sum=0.0;for(int j=0;j<InpSumPeriod;j++)sum+=ratio[i+j];
      massBuffer[i]=sum;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   // 信号：Mass从27上方回落到触发线以下 → 趋势反转前兆
   for(int i=limit;i>=2;i--) {
      if(massBuffer[i+1]>=InpReversalLine&&massBuffer[i]<InpReversalTrigger) {
         double c=iClose(_Symbol,_Period,i),pc=iClose(_Symbol,_Period,i+1);
         if(c<pc)buySignal[i]=massBuffer[i]*0.5;else sellSignal[i]=massBuffer[i]*1.5;
      }
   }
   if(Bars>0){massBuffer[0]=massBuffer[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
