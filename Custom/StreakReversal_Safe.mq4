//+------------------------------------------------------------------+
//|                                          StreakReversal_Safe.mq4  |
//|  连阳连阴反转 — 连续同向K线后的反转信号                            |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
input int InpStreakThreshold=5; // 连续N根后考虑反转
double streakBuy[],streakSell[],weakBuy[],weakSell[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(0,streakBuy);SetIndexArrow(0,ARROW_BUY);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(1,streakSell);SetIndexArrow(1,ARROW_SELL);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,1,clrCyan);SetIndexBuffer(2,weakBuy);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,1,clrDeepPink);SetIndexBuffer(3,weakSell);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("StreakRev_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){streakBuy[i]=streakSell[i]=weakBuy[i]=weakSell[i]=EMPTY_VALUE;}
   for(int i=limit;i>=InpStreakThreshold;i++){
      // 统计连续阴阳
      int bullStreak=0,bearStreak=0;
      for(int j=1;j<=InpStreakThreshold+2;j++){if(iClose(_Symbol,_Period,i+j)>iClose(_Symbol,_Period,i+j+1)){bullStreak++;bearStreak=0;}else{bearStreak++;bullStreak=0;}}
      // 连阴后首根阳线=反转买入
      if(bearStreak>=InpStreakThreshold&&iClose(_Symbol,_Period,i)>iOpen(_Symbol,_Period,i)){
         double body=MathAbs(iClose(_Symbol,_Period,i)-iOpen(_Symbol,_Period,i)),range=iHigh(_Symbol,_Period,i)-iLow(_Symbol,_Period,i);
         if(body>range*0.5)streakBuy[i]=iLow(_Symbol,_Period,i)-8*Point;else weakBuy[i]=iLow(_Symbol,_Period,i)-12*Point;}
      // 连阳后首根阴线=反转向下
      if(bullStreak>=InpStreakThreshold&&iClose(_Symbol,_Period,i)<iOpen(_Symbol,_Period,i)){
         double body=MathAbs(iClose(_Symbol,_Period,i)-iOpen(_Symbol,_Period,i)),range=iHigh(_Symbol,_Period,i)-iLow(_Symbol,_Period,i);
         if(body>range*0.5)streakSell[i]=iHigh(_Symbol,_Period,i)+8*Point;else weakSell[i]=iHigh(_Symbol,_Period,i)+12*Point;}
   }
   return(0);}
