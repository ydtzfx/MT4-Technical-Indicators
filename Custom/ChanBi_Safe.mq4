//+------------------------------------------------------------------+
//|                                       ChanBi_Safe.mq4 缠论笔      |
//|  缠论笔 — 顶底分型确认后连线                                      |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 6
input int InpFenxingBars=3; // 分型确认bar数(标准=包含处理后)
double upBi[],dnBi[],buySignal[],sellSignal[],strongBuy[],strongSell[];
int init(){SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrLimeGreen);SetIndexBuffer(0,upBi);SetIndexLabel(0,"Up Bi");SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrTomato);SetIndexBuffer(1,dnBi);SetIndexLabel(1,"Down Bi");SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,4,Cyan);SetIndexBuffer(4,strongBuy);SetIndexArrow(4,233);SetIndexEmptyValue(4,EMPTY_VALUE);SetIndexLabel(4,"Strong Buy");SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,DeepPink);SetIndexBuffer(5,strongSell);SetIndexArrow(5,234);SetIndexEmptyValue(5,EMPTY_VALUE);SetIndexLabel(5,"Strong Sell");IndicatorDigits(4);IndicatorShortName("ChanBi_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-300;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){upBi[i]=EMPTY_VALUE;dnBi[i]=EMPTY_VALUE;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;}
   int topBars[],botBars[],topCnt=0,botCnt=0;ArrayResize(topBars,100);ArrayResize(botBars,100);
   for(int i=Bars-InpFenxingBars-2;i>=InpFenxingBars;i--){
      bool isTop=true,isBot=true;
      for(int j=1;j<=InpFenxingBars;j++){if(i+j<Bars&&iHigh(_Symbol,_Period,i+j)>=iHigh(_Symbol,_Period,i))isTop=false;if(i-j>=0&&iHigh(_Symbol,_Period,i-j)>=iHigh(_Symbol,_Period,i))isTop=false;if(i+j<Bars&&iLow(_Symbol,_Period,i+j)<=iLow(_Symbol,_Period,i))isBot=false;if(i-j>=0&&iLow(_Symbol,_Period,i-j)<=iLow(_Symbol,_Period,i))isBot=false;}
      if(isTop&&topCnt<99){topBars[topCnt]=i;topCnt++;}
      if(isBot&&botCnt<99){botBars[botCnt]=i;botCnt++;}
   }
   // 连接交替的顶底分型=笔
   int ti=0,bi=0;while(ti<topCnt-1&&bi<botCnt-1){if(topBars[ti]<botBars[bi]){upBi[topBars[ti]]=iHigh(_Symbol,_Period,topBars[ti]);dnBi[botBars[bi]]=iLow(_Symbol,_Period,botBars[bi]);if(topBars[ti]<=limit){if(bi>0&&iLow(_Symbol,_Period,botBars[bi])<iLow(_Symbol,_Period,botBars[bi-1]))strongBuy[topBars[ti]]=iLow(_Symbol,_Period,botBars[bi]);else buySignal[topBars[ti]]=iLow(_Symbol,_Period,botBars[bi]);}ti++;}else{dnBi[botBars[bi]]=iLow(_Symbol,_Period,botBars[bi]);upBi[topBars[ti]]=iHigh(_Symbol,_Period,topBars[ti]);if(botBars[bi]<=limit){if(ti>0&&iHigh(_Symbol,_Period,topBars[ti])>iHigh(_Symbol,_Period,topBars[ti-1]))strongSell[botBars[bi]]=iHigh(_Symbol,_Period,topBars[ti]);else sellSignal[botBars[bi]]=iHigh(_Symbol,_Period,topBars[ti]);}bi++;}}
   return(0);}
