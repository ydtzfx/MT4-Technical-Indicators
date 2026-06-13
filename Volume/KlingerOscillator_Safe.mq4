//+------------------------------------------------------------------+
//|                                     KlingerOscillator_Safe.mq4    |
//|  克林格振荡器（Klinger Oscillator）— 不含未来函数                 |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：VForce=Volume*|2*(dm/cm)-1|*Trend*100, dm=H-L,cm=H+L       |
//|  KO=EMA(VForce,34)-EMA(VForce,55), Signal=EMA(KO,13)              |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 6

input int InpFast=34,InpSlow=55,InpSignal=13;

double koBuffer[],signalBuffer[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,clrDodgerBlue);SetIndexBuffer(0,koBuffer);SetIndexLabel(0,"KO");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrRed);SetIndexBuffer(1,signalBuffer);SetIndexLabel(1,"Signal");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,3,clrCyan);SetIndexBuffer(4,strongBuy);SetIndexArrow(4,233);SetIndexEmptyValue(4,EMPTY_VALUE);
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,3,clrDeepPink);SetIndexBuffer(5,strongSell);SetIndexArrow(5,234);SetIndexEmptyValue(5,EMPTY_VALUE);
   IndicatorDigits(0);IndicatorShortName("KO_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpSlow*3;if(limit<0)limit=0;

   double vf[];ArrayResize(vf,Bars);
   for(int i=limit+InpSlow*2;i>=1;i--) {
      double h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i);
      long v=iVolume(_Symbol,_Period,i);double dm=h-l,cm=h+l;
      double trend=0;if(cm>0&&iClose(_Symbol,_Period,i+1)>0)trend=(c-l)/(iClose(_Symbol,_Period,i+1));
      vf[i]=(double)v*MathAbs(2*dm/SafeDivide(cm,1,1)-1)*trend*100;
   }
   double aF=2.0/(InpFast+1),aS=2.0/(InpSlow+1);
   for(int i=limit;i>=1;i--) {
      double eF=vf[i+InpSlow],eS=vf[i+InpSlow];
      for(int j=InpSlow-1;j>=0;j--){eF=vf[i+j]*aF+eF*(1-aF);eS=vf[i+j]*aS+eS*(1-aS);}
      koBuffer[i]=eF-eS;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   double aSig=2.0/(InpSignal+1);
   for(int i=limit;i>=1;i--) {
      double e=koBuffer[i+InpSignal];for(int j=InpSignal-1;j>=0;j--)e=koBuffer[i+j]*aSig+e*(1-aSig);
      signalBuffer[i]=e;
   }
   for(int i=limit;i>=1;i--) {
      // Strong signals — multi-condition volume-specific confirmation
      bool koCrossAboveSignal=(koBuffer[i+1]<=signalBuffer[i+1]&&koBuffer[i]>signalBuffer[i]);
      bool koCrossBelowSignal=(koBuffer[i+1]>=signalBuffer[i+1]&&koBuffer[i]<signalBuffer[i]);
      bool koCrossAboveZero=(koBuffer[i+1]<0&&koBuffer[i]>0);
      bool koCrossBelowZero=(koBuffer[i+1]>0&&koBuffer[i]<0);

      if((koCrossAboveSignal&&koCrossAboveZero)||(koCrossAboveSignal&&koBuffer[i+1]<(-MathAbs(koBuffer[i+1])*0.5)))
         strongBuy[i]=koBuffer[i]*0.7;
      if((koCrossBelowSignal&&koCrossBelowZero)||(koCrossBelowSignal&&koBuffer[i+1]>MathAbs(koBuffer[i+1])*0.5))
         strongSell[i]=koBuffer[i]*1.3;

      // Normal signals
      if(koCrossAboveSignal)buySignal[i]=koBuffer[i]*0.8;
      if(koCrossBelowSignal)sellSignal[i]=koBuffer[i]*1.2;
      if(koCrossAboveZero)buySignal[i]=koBuffer[i]*0.5;
   }
   if(Bars>0){koBuffer[0]=koBuffer[1];signalBuffer[0]=signalBuffer[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=EMPTY_VALUE;strongSell[0]=EMPTY_VALUE;}
   return(0);
}
