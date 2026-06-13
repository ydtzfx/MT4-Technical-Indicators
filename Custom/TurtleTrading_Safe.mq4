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
#property indicator_buffers 10

input int InpEntry=20;input int InpExit=10;input int InpATR=20;

double entryHi[],entryLo[],exitHi[],exitLo[],atrVal[],posSize[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrLimeGreen);SetIndexBuffer(0,entryHi);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Entry Hi");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrTomato);SetIndexBuffer(1,entryLo);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Entry Lo");
   SetIndexStyle(2,DRAW_LINE,STYLE_DOT,1,clrLime);SetIndexBuffer(2,exitHi);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexLabel(2,"Exit Hi");
   SetIndexStyle(3,DRAW_LINE,STYLE_DOT,1,clrRed);SetIndexBuffer(3,exitLo);SetIndexEmptyValue(3,EMPTY_VALUE);SetIndexLabel(3,"Exit Lo");
   SetIndexStyle(4,DRAW_NONE);SetIndexBuffer(4,atrVal);SetIndexEmptyValue(4,EMPTY_VALUE);SetIndexLabel(4,"ATR");
   SetIndexStyle(5,DRAW_NONE);SetIndexBuffer(5,posSize);SetIndexEmptyValue(5,EMPTY_VALUE);SetIndexLabel(5,"PosSize");
   SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(6,buySignal);SetIndexArrow(6,ARROW_BUY);SetIndexEmptyValue(6,EMPTY_VALUE);
   SetIndexStyle(7,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(7,sellSignal);SetIndexArrow(7,ARROW_SELL);SetIndexEmptyValue(7,EMPTY_VALUE);
   SetIndexStyle(8,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(8,strongBuy);SetIndexArrow(8,233);SetIndexEmptyValue(8,EMPTY_VALUE);SetIndexLabel(8,"Strong Buy");
   SetIndexStyle(9,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(9,strongSell);SetIndexArrow(9,234);SetIndexEmptyValue(9,EMPTY_VALUE);SetIndexLabel(9,"Strong Sell");
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
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=2;i++){
      double c=iClose(_Symbol,_Period,i),c1=iClose(_Symbol,_Period,i+1);
      bool isBreakBuy=(c1<=entryHi[i+1]&&c>entryHi[i]);
      bool isBreakSell=(c1>=entryLo[i+1]&&c<entryLo[i]);
      double atrAvg=(atrVal[i]+atrVal[i+1]+atrVal[i+2])/3;
      if(isBreakBuy){
         buySignal[i]=iLow(_Symbol,_Period,i)-10*Point;
         if(atrVal[i]>atrAvg*1.1&&(iHigh(_Symbol,_Period,i)-c)<(c-iLow(_Symbol,_Period,i))*0.5)strongBuy[i]=iLow(_Symbol,_Period,i)-15*Point;
      }
      if(isBreakSell){
         sellSignal[i]=iHigh(_Symbol,_Period,i)+10*Point;
         if(atrVal[i]>atrAvg*1.1&&(c-iLow(_Symbol,_Period,i))<(iHigh(_Symbol,_Period,i)-c)*0.5)strongSell[i]=iHigh(_Symbol,_Period,i)+15*Point;
      }
      if(c1>=exitLo[i+1]&&c<exitLo[i]&&buySignal[i]==EMPTY_VALUE)buySignal[i]=iLow(_Symbol,_Period,i)-15*Point; // 出场反转
   }
   if(Bars>0){entryHi[0]=entryHi[1];entryLo[0]=entryLo[1];exitHi[0]=exitHi[1];exitLo[0]=exitLo[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=EMPTY_VALUE;strongSell[0]=EMPTY_VALUE;}
   return(0);
}
