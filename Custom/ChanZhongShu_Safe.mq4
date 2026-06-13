//+------------------------------------------------------------------+
//|                                       ChanZhongShu_Safe.mq4       |
//|  缠论中枢 — 三段重叠区域识别                                       |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 6
input int InpFenxingBars=2;
double zhongShuHi[],zhongShuLo[],buySignal[],sellSignal[],strongBuySignal[],strongSellSignal[];
int init(){SetIndexStyle(0,DRAW_LINE,STYLE_DASH,2,clrOrange);SetIndexBuffer(0,zhongShuHi);SetIndexLabel(0,"ZS High");SetIndexStyle(1,DRAW_LINE,STYLE_DASH,2,clrOrange);SetIndexBuffer(1,zhongShuLo);SetIndexLabel(1,"ZS Low");SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(4,strongBuySignal);SetIndexArrow(4,ARROW_BUY);SetIndexEmptyValue(4,EMPTY_VALUE);SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(5,strongSellSignal);SetIndexArrow(5,ARROW_SELL);SetIndexEmptyValue(5,EMPTY_VALUE);IndicatorDigits(4);IndicatorShortName("ChanZS_Safe");return(0);}
int deinit(){RemoveObjectsByPrefix("ZS_");return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-300;if(limit<0)limit=0;
   RemoveObjectsByPrefix("ZS_");
   for(int i=limit;i>=0;i--){zhongShuHi[i]=EMPTY_VALUE;zhongShuLo[i]=EMPTY_VALUE;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuySignal[i]=EMPTY_VALUE;strongSellSignal[i]=EMPTY_VALUE;}
   // 找摆动点，每3段重叠=中枢
   double segHi[],segLo[];int segBars[],segCnt=0;ArrayResize(segHi,200);ArrayResize(segLo,200);ArrayResize(segBars,200);
   for(int i=Bars-InpFenxingBars-2;i>=InpFenxingBars;i--){
      bool isHigh=true,isLow=true;
      for(int j=1;j<=InpFenxingBars;j++){if(i+j<Bars&&iHigh(_Symbol,_Period,i+j)>=iHigh(_Symbol,_Period,i))isHigh=false;if(i-j>=0&&iHigh(_Symbol,_Period,i-j)>=iHigh(_Symbol,_Period,i))isHigh=false;if(i+j<Bars&&iLow(_Symbol,_Period,i+j)<=iLow(_Symbol,_Period,i))isLow=false;if(i-j>=0&&iLow(_Symbol,_Period,i-j)<=iLow(_Symbol,_Period,i))isLow=false;}
      if((isHigh||isLow)&&segCnt<199){segHi[segCnt]=isHigh?iHigh(_Symbol,_Period,i):iLow(_Symbol,_Period,i);segLo[segCnt]=isHigh?iLow(_Symbol,_Period,i):iHigh(_Symbol,_Period,i);segBars[segCnt]=i;segCnt++;}
   }
   for(int s=3;s<segCnt-1;s+=2){double zsH=MathMin(segHi[s],MathMin(segHi[s-1],segHi[s-2]));double zsL=MathMax(segLo[s],MathMax(segLo[s-1],segLo[s-2]));if(zsH>zsL&&segBars[s]<=limit){zhongShuHi[segBars[s]]=zsH;zhongShuLo[segBars[s]]=zsL;double c=iClose(_Symbol,_Period,segBars[s]);double zoneW=zsH-zsL;if(c>zsH){buySignal[segBars[s]]=zsL-5*Point;if(c>zsH+zoneW*0.3)strongBuySignal[segBars[s]]=zsL-12*Point;}else if(c<zsL){sellSignal[segBars[s]]=zsH+5*Point;if(c<zsL-zoneW*0.3)strongSellSignal[segBars[s]]=zsH+12*Point;}}}
   return(0);}
