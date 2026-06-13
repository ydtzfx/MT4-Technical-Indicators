//+------------------------------------------------------------------+
//|                                      ChaikinVolatility_Safe.mq4   |
//|  蔡金波动率（Chaikin Volatility）— 不含未来函数                   |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：CV=100*(EMA(H-L,N)-EMA(H-L,N)_prev)/EMA(H-L,N)_prev        |
//|  衡量波动率变化方向，CV上升=波动加大                              |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_level1 0

input int InpPeriod=10;input int InpROC=10;

double cv[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,cv);SetIndexLabel(0,"Chaikin Vol");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexBuffer(3,strongBuy);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexArrow(3,233);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexBuffer(4,strongSell);SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexArrow(4,234);SetIndexEmptyValue(4,EMPTY_VALUE);
   IndicatorDigits(2);IndicatorShortName("ChaikinVol_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;

   double emaHL[],rangeDay[];ArrayResize(emaHL,Bars);ArrayResize(rangeDay,Bars);
   for(int i=Bars-2;i>=1;i--)rangeDay[i]=iHigh(_Symbol,_Period,i)-iLow(_Symbol,_Period,i);
   double a=2.0/(InpPeriod+1);
   for(int i=Bars-2;i>=1;i--){if(i>=Bars-30)emaHL[i]=rangeDay[i];else emaHL[i]=rangeDay[i]*a+emaHL[i+1]*(1-a);}
   for(int i=limit;i>=1;i--){
      double prev=emaHL[i+InpROC];cv[i]=prev>0?100*(emaHL[i]-prev)/prev:0;
      strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   // 波动率变化不直接产生买卖信号，只标记波动率拐点
   for(int i=limit;i>=1;i--){
      // Strong signals (multi-condition confirmation)
      if(cv[i+1]<-25&&cv[i]>cv[i+1]&&(cv[i]-cv[i+1])>2)strongBuy[i]=cv[i]-2;  // 更强波动率萎缩后强劲回升
      else if(cv[i+1]<-20&&cv[i]>cv[i+1])buySignal[i]=cv[i]-2;               // 波动率极度萎缩后回升
      if(cv[i+1]>55&&cv[i]<cv[i+1]&&(cv[i+1]-cv[i])>2)strongSell[i]=cv[i]+2; // 更强波动率放大后强劲回落
      else if(cv[i+1]>50&&cv[i]<cv[i+1])sellSignal[i]=cv[i]+2;               // 波动率极度放大后回落
   }
   if(Bars>0){cv[0]=cv[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=EMPTY_VALUE;strongSell[0]=EMPTY_VALUE;}
   return(0);
}
