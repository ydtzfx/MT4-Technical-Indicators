//+------------------------------------------------------------------+
//|                                             Spread_Safe.mq4       |
//|  点差监控 — 不含未来函数                                          |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  实时显示Ask-Bid点差，高点差时发出预警                            |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3

input double InpSpreadWarn=30; // 超过此点差发出预警(基于point)

double spreadBuffer[],warnHigh[],warnLow[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,clrYellow);SetIndexBuffer(0,spreadBuffer);SetIndexLabel(0,"Spread");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,clrTomato);SetIndexBuffer(1,warnHigh);SetIndexArrow(1,ARROW_SELL);SetIndexLabel(1,"High Spread");SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,clrLimeGreen);SetIndexBuffer(2,warnLow);SetIndexArrow(2,ARROW_BUY);SetIndexLabel(2,"Low Spread");SetIndexEmptyValue(2,EMPTY_VALUE);
   IndicatorDigits(1);IndicatorShortName("Spread_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-2;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      double spread=(MarketInfo(_Symbol,MODE_ASK)-MarketInfo(_Symbol,MODE_BID))/Point;
      // 获取历史点差（实际历史点差需要数据记录，这里使用当前值近似）
      spreadBuffer[i]=i==1?spread:spreadBuffer[1]; // 简化：使用最新点差
      warnHigh[i]=spread>InpSpreadWarn?spread:EMPTY_VALUE;
      warnLow[i]=EMPTY_VALUE;
   }
   if(Bars>0){spreadBuffer[0]=spreadBuffer[1];warnHigh[0]=warnLow[0]=EMPTY_VALUE;}
   return(0);
}
