//+------------------------------------------------------------------+
//|                                     UltimateOscillator_Safe.mq4   |
//|  终极振荡器（Ultimate Oscillator）— 不含未来函数                  |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：UO=100*[(4*Avg7)+(2*Avg14)+Avg28]/(4+2+1)                   |
//|  结合短/中/长三个周期，减少单一周期的假信号                        |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 70
#property indicator_level2 30

input int InpFast=7,InpMid=14,InpSlow=28;

double uoBuffer[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,uoBuffer);SetIndexLabel(0,"UO");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   IndicatorDigits(2);IndicatorShortName("UO_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpSlow*2;if(limit<0)limit=0;

   double bp[],tr[];ArrayResize(bp,Bars);ArrayResize(tr,Bars);
   for(int i=Bars-2;i>=1;i--) {
      double h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i);
      double pc=iClose(_Symbol,_Period,i+1),pl=iLow(_Symbol,_Period,i+1);
      bp[i]=MathMax(h-pc,MathMax(pc-l,MathMax(c-pl,0.0)));
      tr[i]=MathMax(h-l,MathMax(MathAbs(h-pc),MathAbs(l-pc)));
   }
   for(int i=limit;i>=1;i--) {
      double avg7=0,avg14=0,avg28=0,sumBP7=0,sumTR7=0,sumBP14=0,sumTR14=0,sumBP28=0,sumTR28=0;
      for(int j=0;j<InpSlow;j++){sumBP28+=bp[i+j];sumTR28+=tr[i+j];if(j<InpMid){sumBP14+=bp[i+j];sumTR14+=tr[i+j];}if(j<InpFast){sumBP7+=bp[i+j];sumTR7+=tr[i+j];}}
      avg7=SafeDivide(sumBP7,sumTR7,0);avg14=SafeDivide(sumBP14,sumTR14,0);avg28=SafeDivide(sumBP28,sumTR28,0);
      uoBuffer[i]=100*(4*avg7+2*avg14+avg28)/7;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=1;i--) {
      if(uoBuffer[i+1]<=30&&uoBuffer[i]>30)buySignal[i]=25;
      if(uoBuffer[i+1]>=70&&uoBuffer[i]<70)sellSignal[i]=75;
      // 背离
      double c=iClose(_Symbol,_Period,i),c2=iClose(_Symbol,_Period,i+3);
      if(c<c2&&uoBuffer[i]>uoBuffer[i+3]&&uoBuffer[i]<50)buySignal[i]=25;
      if(c>c2&&uoBuffer[i]<uoBuffer[i+3]&&uoBuffer[i]>50)sellSignal[i]=75;
   }
   if(Bars>0){uoBuffer[0]=uoBuffer[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
