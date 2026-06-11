//+------------------------------------------------------------------+
//|                                               SwingIndex_Safe.mq4 |
//|  摆动指数（Swing Index）— 不含未来函数                            |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式（Welles Wilder）：综合考虑价格、振幅和极限移动                 |
//|  SI=50*[(C2-C1+0.5*(C2-O2)+0.25*(C1-O1))/R]*K/T                   |
//|  ASI = 累计SI，用于判断趋势方向和强度                              |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3

input double InpLimitMove=30.0; // 极限移动参数

double asiBuffer[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,asiBuffer);SetIndexLabel(0,"ASI");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   IndicatorDigits(0);IndicatorShortName("SwingIndex_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;

   double cumSI=0;
   for(int i=Bars-50;i>=1;i--) {
      double c=iClose(_Symbol,_Period,i),o=iOpen(_Symbol,_Period,i);
      double h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i);
      double pc=iClose(_Symbol,_Period,i+1),po=iOpen(_Symbol,_Period,i+1);
      double r=MathMax(h-pc,MathMax(pc-l,MathMax(h-l,1)));
      double k=MathMax(MathAbs(h-pc),MathAbs(l-pc));
      double t=InpLimitMove*Point;
      double si=0;if(r>0&&t>0)si=50*((c-pc+0.5*(c-o)+0.25*(pc-po))/r)*k/t;
      cumSI+=si;asiBuffer[i]=cumSI;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=3;i--) {
      if(asiBuffer[i]>asiBuffer[i+1]&&asiBuffer[i+1]>asiBuffer[i+2]&&asiBuffer[i+2]>asiBuffer[i+3])buySignal[i]=asiBuffer[i]*0.95;
      if(asiBuffer[i]<asiBuffer[i+1]&&asiBuffer[i+1]<asiBuffer[i+2]&&asiBuffer[i+2]<asiBuffer[i+3])sellSignal[i]=asiBuffer[i]*1.05;
   }
   if(Bars>0){asiBuffer[0]=asiBuffer[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
