#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                                MTF_RSI_Safe.mq4   |
//|  多周期RSI（Multi-Timeframe RSI）— 不含未来函数                   |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  同时显示M1/M5/M15/H1/H4/D1六个周期的RSI值                        |
//|  多周期共振=强信号                                                 |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 8
#property indicator_minimum 0
#property indicator_maximum 100

input int InpRSIPeriod=14;

double rsiM1[],rsiM5[],rsiM15[],rsiH1[],rsiH4[],rsiD1[],buySignal[],sellSignal[];

double CalcRSI(int tf,int shift,int per){
   double aG=0,aL=0;
   int j;
   for(j=0;j<per;j++){double ch=iClose(_Symbol,tf,shift+j)-iClose(_Symbol,tf,shift+j+1);if(ch>0)aG+=ch;else aL-=ch;}
   aG/=per;aL/=per;double rs=SafeDivide(aG,aL,0);return (aL<0.00000001)?100:100-100/(1+rs);
}

int init() {
   color clrs[6]={clrGray,clrYellow,clrOrange,clrDodgerBlue,clrMagenta,clrWhite};
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,clrs[0]);SetIndexBuffer(0,rsiM1);SetIndexLabel(0,"RSI_M1");SetIndexEmptyValue(0,0);
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,clrs[1]);SetIndexBuffer(1,rsiM5);SetIndexLabel(1,"RSI_M5");SetIndexEmptyValue(1,0);
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1,clrs[2]);SetIndexBuffer(2,rsiM15);SetIndexLabel(2,"RSI_M15");SetIndexEmptyValue(2,0);
   SetIndexStyle(3,DRAW_LINE,STYLE_SOLID,1,clrs[3]);SetIndexBuffer(3,rsiH1);SetIndexLabel(3,"RSI_H1");SetIndexEmptyValue(3,0);
   SetIndexStyle(4,DRAW_LINE,STYLE_SOLID,1,clrs[4]);SetIndexBuffer(4,rsiH4);SetIndexLabel(4,"RSI_H4");SetIndexEmptyValue(4,0);
   SetIndexStyle(5,DRAW_LINE,STYLE_SOLID,1,clrs[5]);SetIndexBuffer(5,rsiD1);SetIndexLabel(5,"RSI_D1");SetIndexEmptyValue(5,0);
   SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(6,buySignal);SetIndexArrow(6,ARROW_BUY);SetIndexEmptyValue(6,EMPTY_VALUE);
   SetIndexStyle(7,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(7,sellSignal);SetIndexArrow(7,ARROW_SELL);SetIndexEmptyValue(7,EMPTY_VALUE);
   IndicatorDigits(1);IndicatorShortName("MTF_RSI_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int i, t;
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;

   int tfs[6]={PERIOD_M1,PERIOD_M5,PERIOD_M15,PERIOD_H1,PERIOD_H4,PERIOD_D1};

   for(i=limit;i>=1;i--){
      int shift=iBarShift(_Symbol,_Period,iTime(_Symbol,_Period,i));
      rsiM1[i]  = CalcRSI(tfs[0], shift, InpRSIPeriod);
      rsiM5[i]  = CalcRSI(tfs[1], shift, InpRSIPeriod);
      rsiM15[i] = CalcRSI(tfs[2], shift, InpRSIPeriod);
      rsiH1[i]  = CalcRSI(tfs[3], shift, InpRSIPeriod);
      rsiH4[i]  = CalcRSI(tfs[4], shift, InpRSIPeriod);
      rsiD1[i]  = CalcRSI(tfs[5], shift, InpRSIPeriod);
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }

   for(i=limit;i>=1;i--){
      int bCount=0,sCount=0;
      if(rsiM1[i]>50)bCount++;else sCount++;
      if(rsiM5[i]>50)bCount++;else sCount++;
      if(rsiM15[i]>50)bCount++;else sCount++;
      if(rsiH1[i]>50)bCount++;else sCount++;
      if(rsiH4[i]>50)bCount++;else sCount++;
      if(rsiD1[i]>50)bCount++;else sCount++;
      if(bCount>=5)buySignal[i]=45;
      if(sCount>=5)sellSignal[i]=55;
   }

   if(Bars>0){
      rsiM1[0]=rsiM1[1];rsiM5[0]=rsiM5[1];rsiM15[0]=rsiM15[1];
      rsiH1[0]=rsiH1[1];rsiH4[0]=rsiH4[1];rsiD1[0]=rsiD1[1];
      buySignal[0]=sellSignal[0]=EMPTY_VALUE;
   }
   return(0);
}
