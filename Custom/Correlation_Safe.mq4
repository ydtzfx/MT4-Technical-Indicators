//+------------------------------------------------------------------+
//|                                           Correlation_Safe.mq4    |
//|  货币对相关性 — 不含未来函数                                      |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  计算当前品种与参考品种的Pearson相关系数                           |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum -1
#property indicator_maximum 1
#property indicator_level1 0.8
#property indicator_level2 -0.8

input string InpSymbol2="EURUSD";input int InpPeriod=20;

double corr[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,corr);SetIndexLabel(0,"Correlation");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   IndicatorDigits(2);IndicatorShortName("Corr_Safe("+InpSymbol2+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpPeriod*2;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      double sumX=0,sumY=0,sumXY=0,sumX2=0,sumY2=0;int n=0;
      for(int j=0;j<InpPeriod;j++){
         double r1=iClose(_Symbol,_Period,i+j)-iClose(_Symbol,_Period,i+j+1);
         double r2=iClose(InpSymbol2,_Period,iBarShift(InpSymbol2,_Period,iTime(_Symbol,_Period,i+j)))-iClose(InpSymbol2,_Period,iBarShift(InpSymbol2,_Period,iTime(_Symbol,_Period,i+j))+1);
         sumX+=r1;sumY+=r2;sumXY+=r1*r2;sumX2+=r1*r1;sumY2+=r2*r2;n++;
      }
      double num=n*sumXY-sumX*sumY;
      double den=MathSqrt((n*sumX2-sumX*sumX)*(n*sumY2-sumY*sumY));
      corr[i]=SafeDivide(num,den,0);buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=1;i--){
      if(corr[i+1]<-0.8&&corr[i]>-0.8)buySignal[i]=-0.85; // 从强负相关回升
      if(corr[i+1]>0.8&&corr[i]<0.8)sellSignal[i]=0.85;   // 从强正相关回落
   }
   if(Bars>0){corr[0]=corr[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
