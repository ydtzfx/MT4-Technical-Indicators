//+------------------------------------------------------------------+
//|                                                   VWAP_Safe.mq4   |
//|  成交量加权平均价（Anchored VWAP）— 不含未来函数                  |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：VWAP = Σ(Price_i * Volume_i) / ΣVolume_i                    |
//|  Price=(H+L+C)/3, 从指定起点开始累积                               |
//|  机构常用基准价，价格在VWAP上方=多头优势                          |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 3

input int InpStartBars=0; // 0=今日开始, >0=N根bar前开始

double vwap[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrYellow);SetIndexBuffer(0,vwap);SetIndexLabel(0,"VWAP");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("VWAP_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-500;if(limit<0)limit=0;

   // 确定起点（每日重置）
   int startB=InpStartBars>0?InpStartBars:0;
   if(startB==0){for(int i=0;i<500;i++){if(iTime(_Symbol,PERIOD_D1,0)==iTime(_Symbol,_Period,i)){startB=i;break;}}}

   for(int i=limit;i>=1;i--){
      double sumPV=0,sumV=0;
      for(int j=i;j<=startB&&j<Bars;j++){
         double tp=(iHigh(_Symbol,_Period,j)+iLow(_Symbol,_Period,j)+iClose(_Symbol,_Period,j))/3;
         long v=iVolume(_Symbol,_Period,j);sumPV+=tp*v;sumV+=v;
      }
      vwap[i]=SafeDivide(sumPV,sumV,iClose(_Symbol,_Period,i));
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=2;i--){
      double c=iClose(_Symbol,_Period,i),c1=iClose(_Symbol,_Period,i+1);
      if(c1<=vwap[i+1]&&c>vwap[i])buySignal[i]=iLow(_Symbol,_Period,i)-5*Point;
      if(c1>=vwap[i+1]&&c<vwap[i])sellSignal[i]=iHigh(_Symbol,_Period,i)+5*Point;
   }
   if(Bars>0){vwap[0]=vwap[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
