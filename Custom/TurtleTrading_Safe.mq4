//+------------------------------------------------------------------+
//|                                        TurtleTrading_Safe.mq4     |
//|  海龟交易策略 — 经典趋势跟踪策略                                  |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  入场：20日高点突破(做多)/20日低点跌破(做空)                       |
//|  出场：10日低点跌破(多仓)/10日高点突破(空仓)                       |
//|  头寸：ATR(20)*2止损 + ATR-based仓位管理                          |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 8

input int InpEntry=20;input int InpExit=10;input int InpATR=20;

double entryHi[],entryLo[],exitHi[],exitLo[],atrVal[],posSize[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrLimeGreen);SetIndexBuffer(0,entryHi);SetIndexLabel(0,"Entry Hi");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrTomato);SetIndexBuffer(1,entryLo);SetIndexLabel(1,"Entry Lo");
   SetIndexStyle(2,DRAW_LINE,STYLE_DOT,1,clrLime);SetIndexBuffer(2,exitHi);SetIndexLabel(2,"Exit Hi");
   SetIndexStyle(3,DRAW_LINE,STYLE_DOT,1,clrRed);SetIndexBuffer(3,exitLo);SetIndexLabel(3,"Exit Lo");
   SetIndexStyle(4,DRAW_NONE);SetIndexBuffer(4,atrVal);SetIndexLabel(4,"ATR");
   SetIndexStyle(5,DRAW_NONE);SetIndexBuffer(5,posSize);SetIndexLabel(5,"PosSize");
   SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(6,buySignal);SetIndexArrow(6,ARROW_BUY);SetIndexEmptyValue(6,EMPTY_VALUE);
   SetIndexStyle(7,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(7,sellSignal);SetIndexArrow(7,ARROW_SELL);SetIndexEmptyValue(7,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("Turtle_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      double eHi=iHigh(_Symbol,_Period,i+1),eLo=iLow(_Symbol,_Period,i+1),xHi=iHigh(_Symbol,_Period,i+1),xLo=iLow(_Symbol,_Period,i+1);
      for(int j=2;j<=InpEntry;j++){double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);if(h>eHi)eHi=h;if(l<eLo)eLo=l;}
      for(int j=1;j<=InpExit;j++){double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);if(h>xHi)xHi=h;if(l<xLo)xLo=l;}
      entryHi[i]=eHi;entryLo[i]=eLo;exitHi[i]=xHi;exitLo[i]=xLo;
      double atr=0;for(int j=0;j<InpATR;j++)atr+=GetTrueRange(_Symbol,_Period,i+j);atr/=InpATR;atrVal[i]=atr;
      posSize[i]=SafeDivide(0.01*iClose(_Symbol,_Period,i),2*atr,0); // 1%风险仓位
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=2;i++){
      double c=iClose(_Symbol,_Period,i),c1=iClose(_Symbol,_Period,i+1);
      if(c1<=entryHi[i+1]&&c>entryHi[i])buySignal[i]=iLow(_Symbol,_Period,i)-10*Point;
      if(c1>=entryLo[i+1]&&c<entryLo[i])sellSignal[i]=iHigh(_Symbol,_Period,i)+10*Point;
      if(c1>=exitLo[i+1]&&c<exitLo[i]&&buySignal[i]==EMPTY_VALUE)buySignal[i]=iLow(_Symbol,_Period,i)-15*Point; // 出场反转
   }
   if(Bars>0){entryHi[0]=entryHi[1];entryLo[0]=entryLo[1];exitHi[0]=exitHi[1];exitLo[0]=exitLo[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
