//+------------------------------------------------------------------+
//|                                                StochRSI_Safe.mq4  |
//|  随机RSI（StochRSI）— 不含未来函数                                |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：StochRSI = (RSI - MinRSI(N)) / (MaxRSI(N) - MinRSI(N))     |
//|  对RSI再做Stochastic处理，更敏感                                   |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_minimum 0
#property indicator_maximum 1

input int InpRSIPeriod=14;input int InpStochPeriod=14;input int InpSmooth=3;

double srsi[],signal[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,clrDodgerBlue);SetIndexBuffer(0,srsi);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"StochRSI");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrRed);SetIndexBuffer(1,signal);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Signal");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(4,strongBuy);SetIndexArrow(4,ARROW_BUY);SetIndexLabel(4,"Strong Buy");SetIndexEmptyValue(4,EMPTY_VALUE);
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(5,strongSell);SetIndexArrow(5,ARROW_SELL);SetIndexLabel(5,"Strong Sell");SetIndexEmptyValue(5,EMPTY_VALUE);
   IndicatorDigits(3);IndicatorShortName("StochRSI_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;

   double rsi[];ArrayResize(rsi,Bars);
   for(int i=Bars-InpRSIPeriod*3;i>=1;i--){
      double aG=0,aL=0;for(int j=0;j<InpRSIPeriod;j++){double ch=iClose(_Symbol,_Period,i+j)-iClose(_Symbol,_Period,i+j+1);if(ch>0)aG+=ch;else aL-=ch;}
      aG/=InpRSIPeriod;aL/=InpRSIPeriod;double rs=SafeDivide(aG,aL,0);rsi[i]=(aL<0.00000001)?1:1-1/(1+rs);
   }
   for(int i=limit;i>=1;i--){
      double mn=rsi[i],mx=rsi[i];for(int j=0;j<InpStochPeriod;j++){if(rsi[i+j]<mn)mn=rsi[i+j];if(rsi[i+j]>mx)mx=rsi[i+j];}
      double rng=mx-mn;srsi[i]=rng>0?(rsi[i]-mn)/rng:0.5;signal[i]=0;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=1;i++){double s=0;for(int j=0;j<InpSmooth;j++)s+=srsi[i+j];signal[i]=s/InpSmooth;}
   for(int i=limit;i>=1;i--){
      bool deepOS=(srsi[i+1]<=0.05&&srsi[i]>0.05);  // <0.05深超卖
      bool deepOB=(srsi[i+1]>=0.95&&srsi[i]<0.95);  // >0.95深超买
      bool crossUp=(srsi[i+1]<=signal[i+1]&&srsi[i]>signal[i]);
      bool crossDn=(srsi[i+1]>=signal[i+1]&&srsi[i]<signal[i]);
      // 强买：深超卖反弹 + 金叉
      if(deepOS&&crossUp)strongBuy[i]=0.10;
      else if(srsi[i+1]<=0.2&&srsi[i]>0.2)buySignal[i]=0.15;
      else if(crossUp&&srsi[i]<0.5)buySignal[i]=0.15;
      // 强卖：深超买回落 + 死叉
      if(deepOB&&crossDn)strongSell[i]=0.90;
      else if(srsi[i+1]>=0.8&&srsi[i]<0.8)sellSignal[i]=0.85;
      else if(crossDn&&srsi[i]>0.5)sellSignal[i]=0.85;
   }
   if(Bars>0){srsi[0]=srsi[1];signal[0]=signal[1];buySignal[0]=sellSignal[0]=strongBuy[0]=strongSell[0]=EMPTY_VALUE;}
   return(0);
}
