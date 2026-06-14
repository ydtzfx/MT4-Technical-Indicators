#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                                    TSI_Safe.mq4   |
//|  真实强弱指数（True Strength Index）— 不含未来函数                 |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：PC=Price-Price[1], DS1=EMA(PC,25), DS2=EMA(ABS(PC),25)     |
//|        TSI=100*EMA(DS1,13)/EMA(DS2,13), Signal=EMA(TSI,7)        |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_level1 0

input int InpR=25;input int InpS=13;input int InpSig=7;

double tsi[],signal[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,clrDodgerBlue);SetIndexBuffer(0,tsi);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"TSI");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrRed);SetIndexBuffer(1,signal);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Signal");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(4,strongBuy);SetIndexArrow(4,ARROW_BUY);SetIndexLabel(4,"Strong Buy");SetIndexEmptyValue(4,EMPTY_VALUE);
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(5,strongSell);SetIndexArrow(5,ARROW_SELL);SetIndexLabel(5,"Strong Sell");SetIndexEmptyValue(5,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("TSI_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   double pc[];ArrayResize(pc,Bars);for(int i=Bars-2;i>=1;i--)pc[i]=iClose(_Symbol,_Period,i)-iClose(_Symbol,_Period,i+1);
   double aR=2.0/(InpR+1),aS=2.0/(InpS+1),aSig=2.0/(InpSig+1);
   double ds1[],ds2[];ArrayResize(ds1,Bars);ArrayResize(ds2,Bars);
   for(i=Bars-2;i>=1;i--){
      if(i>=Bars-100){ds1[i]=pc[i];ds2[i]=MathAbs(pc[i]);}
      else{ds1[i]=pc[i]*aR+ds1[i+1]*(1-aR);ds2[i]=MathAbs(pc[i])*aR+ds2[i+1]*(1-aR);}
   }
   double e1[],e2[];ArrayResize(e1,Bars);ArrayResize(e2,Bars);
   for(i=Bars-2;i>=1;i--){
      if(i>=Bars-120){e1[i]=ds1[i];e2[i]=ds2[i];}
      else{e1[i]=ds1[i]*aS+e1[i+1]*(1-aS);e2[i]=ds2[i]*aS+e2[i+1]*(1-aS);}
   }
   for(i=limit;i>=1;i--){tsi[i]=SafeDivide(100*e1[i],e2[i],0);buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;}
   for(i=limit;i>=1;i--){double e=tsi[i+10];for(int j=9;j>=0;j--)e=tsi[i+j]*aSig+e*(1-aSig);signal[i]=e;}
   for(i=limit;i>=1;i--){
      bool crossUp=(tsi[i+1]<=signal[i+1]&&tsi[i]>signal[i]);
      bool crossDn=(tsi[i+1]>=signal[i+1]&&tsi[i]<signal[i]);
      bool zeroUp=(tsi[i+1]<0&&tsi[i]>0);
      double str=MathAbs(tsi[i]-tsi[i+5]); // 近期动量
      // 强买：金叉 + 零轴上穿 + 强动量
      if(crossUp&&zeroUp&&str>0.5)strongBuy[i]=tsi[i]-0.2;
      else if(crossUp||zeroUp)buySignal[i]=tsi[i]-0.1;
      // 强卖：死叉 + 零轴下穿 + 强动量
      if(crossDn&&tsi[i+1]>0&&tsi[i]<0&&str>0.5)strongSell[i]=tsi[i]+0.2;
      else if(crossDn)sellSignal[i]=tsi[i]+0.1;
   }
   if(Bars>0){tsi[0]=tsi[1];signal[0]=signal[1];buySignal[0]=sellSignal[0]=strongBuy[0]=strongSell[0]=EMPTY_VALUE;}
   return(0);
}
