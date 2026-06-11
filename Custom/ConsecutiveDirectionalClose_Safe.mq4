//+------------------------------------------------------------------+
//|                              ConsecutiveDirectionalClose_Safe.mq4 |
//|  连续定向收盘 — N根K线收盘持续在开盘的某一侧                        |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_minimum -10
#property indicator_maximum 10
input int InpMaxCount=10;
double consec[],streak[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,consec);SetIndexLabel(0,"Consecutive");SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,clrYellow);SetIndexBuffer(1,streak);SetIndexLabel(1,"Streak");SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("ConsDirClose_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=1;i++){
      int buyCnt=0,sellCnt=0;
      // 统计连续收盘在开盘上方(阳线方向)或下方的K线数
      for(int j=0;j<InpMaxCount;j++){if(iClose(_Symbol,_Period,i+j)>iOpen(_Symbol,_Period,i+j))buyCnt++;else break;}
      for(int j=0;j<InpMaxCount;j++){if(iClose(_Symbol,_Period,i+j)<iOpen(_Symbol,_Period,i+j))sellCnt++;else break;}
      consec[i]=buyCnt>0?buyCnt:(sellCnt>0?-sellCnt:0);streak[i]=buyCnt+sellCnt;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=3;i++){
      // 连续5+阳线后首阴=强力反转
      if(consec[i+1]>=5&&consec[i]<=-1)sellSignal[i]=consec[i]+1;
      // 连续5+阴线后首阳
      if(consec[i+1]<=-5&&consec[i]>=1)buySignal[i]=consec[i]-1;
      // 第3根阳线（趋势确认）
      if(consec[i+1]>=2&&consec[i]>=3)buySignal[i]=3;
   }
   if(Bars>0){consec[0]=consec[1];streak[0]=streak[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);}
