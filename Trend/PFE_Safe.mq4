//+------------------------------------------------------------------+
//|                                                   PFE_Safe.mq4    |
//|  极化分形效率（Polarized Fractal Efficiency）— 不含未来函数       |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：PFE=100*(√(ΔP²+N²)/Σ√(ΔP_i²+1))*sign(Close-Price[N])       |
//|  衡量价格移动的效率：>50趋势明确，<50震荡                        |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_level1 50
#property indicator_level2 -50

input int InpPeriod=10;input int InpSmooth=5;

double pfe[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,pfe);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"PFE");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexBuffer(3,strongBuy);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexArrow(3,233);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexBuffer(4,strongSell);SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexArrow(4,234);SetIndexEmptyValue(4,EMPTY_VALUE);
   IndicatorDigits(1);IndicatorShortName("PFE_Safe("+IntegerToString(InpPeriod)+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpPeriod*3;if(limit<0)limit=0;

   double raw[];ArrayResize(raw,Bars);
   for(int i=limit+InpPeriod*2;i>=1;i--){
      double dp=iClose(_Symbol,_Period,i)-iClose(_Symbol,_Period,i+InpPeriod);
      double num=MathSqrt(dp*dp+InpPeriod*InpPeriod),den=0;
      for(int j=0;j<InpPeriod;j++){double d=iClose(_Symbol,_Period,i+j)-iClose(_Symbol,_Period,i+j+1);den+=MathSqrt(d*d+1);}
      raw[i]=SafeDivide(100*num,den,0);if(dp<0)raw[i]=-raw[i];
   }
   for(int i=limit;i>=1;i--){
      double s=0;for(int j=0;j<InpSmooth;j++)s+=raw[i+j];pfe[i]=s/InpSmooth;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=1;i--){
      // Strong signals (multi-condition confirmation)
      if(pfe[i+1]<-50&&pfe[i]>-50&&raw[i+1]<-50)strongBuy[i]=-60;
      if(pfe[i+1]>50&&pfe[i]<50&&raw[i+1]>50)strongSell[i]=60;
      if(pfe[i+1]<0&&pfe[i]>0&&(pfe[i]-pfe[i+1])>10)strongBuy[i]=-12;
      if(pfe[i+1]>0&&pfe[i]<0&&(pfe[i+1]-pfe[i])>10)strongSell[i]=12;
      // Normal signals
      if(pfe[i+1]<-50&&pfe[i]>-50)buySignal[i]=-55;
      if(pfe[i+1]>50&&pfe[i]<50)sellSignal[i]=55;
      if(pfe[i+1]<0&&pfe[i]>0)buySignal[i]=-5;
      if(pfe[i+1]>0&&pfe[i]<0)sellSignal[i]=5;
   }
   if(Bars>0){pfe[0]=pfe[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=EMPTY_VALUE;strongSell[0]=EMPTY_VALUE;}
   return(0);
}
