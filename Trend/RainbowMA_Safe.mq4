//+------------------------------------------------------------------+
//|                                               RainbowMA_Safe.mq4  |
//|  彩虹均线（Rainbow MA）— 不含未来函数                              |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  20条EMA(2,4,6,...,40)用渐变色显示，均线束发散/收缩判断趋势       |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 24

input bool InpShowSignals=true;

double ma[20][],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   for(int i=0;i<20;i++) {
      int r=(i<10)?(i*25):(255-(i-10)*25);int g=(i<10)?(255-i*25):(i-10)*25;int b=128-i*6;
      SetIndexStyle(i,DRAW_LINE,STYLE_SOLID,1,StringToColor(IntegerToString(r)+","+IntegerToString(g)+","+IntegerToString(b)));
      SetIndexBuffer(i,ma[i]);SetIndexLabel(i,"MA"+IntegerToString((i+1)*2));SetIndexEmptyValue(i,0);
   }
   SetIndexStyle(20,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(20,buySignal);SetIndexArrow(20,ARROW_BUY);SetIndexEmptyValue(20,EMPTY_VALUE);
   SetIndexStyle(21,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(21,sellSignal);SetIndexArrow(21,ARROW_SELL);SetIndexEmptyValue(21,EMPTY_VALUE);
   SetIndexBuffer(22,strongBuy);SetIndexStyle(22,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexArrow(22,233);SetIndexEmptyValue(22,EMPTY_VALUE);
   SetIndexBuffer(23,strongSell);SetIndexStyle(23,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexArrow(23,234);SetIndexEmptyValue(23,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("RainbowMA_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-150;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--) {
      double p[100];for(int j=0;j<100&&(i+j<Bars);j++)p[j]=iClose(_Symbol,_Period,i+j);
      for(int m=0;m<20;m++){int per=(m+1)*2;double e=0;for(int j=100-per;j<100;j++)e+=p[j];e/=per;double a=2.0/(per+1);for(int j=100-per-1;j>=0;j--)e=p[j]*a+e*(1-a);ma[m][i]=e;}
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   if(InpShowSignals) for(int i=limit;i>=2;i--) {
      // Strong buy: MA2 crosses above MA40 + all 20 MAs fully aligned bullish (ascending order)
      if(ma[0][i+1]<=ma[19][i+1]&&ma[0][i]>ma[19][i]) {
         bool aligned=true; for(int m=1;m<20;m++){if(ma[m-1][i]<=ma[m][i]){aligned=false;break;}}
         if(aligned) strongBuy[i]=iLow(_Symbol,_Period,i)-30*Point;
         else buySignal[i]=iLow(_Symbol,_Period,i)-20*Point;
      }
      // Strong sell: MA2 crosses below MA40 + all 20 MAs fully aligned bearish (descending order)
      if(ma[0][i+1]>=ma[19][i+1]&&ma[0][i]<ma[19][i]) {
         bool aligned=true; for(int m=1;m<20;m++){if(ma[m-1][i]>=ma[m][i]){aligned=false;break;}}
         if(aligned) strongSell[i]=iHigh(_Symbol,_Period,i)+30*Point;
         else sellSignal[i]=iHigh(_Symbol,_Period,i)+20*Point;
      }
   }
   if(Bars>0){for(int m=0;m<20;m++)ma[m][0]=ma[m][1];buySignal[0]=sellSignal[0]=strongBuy[0]=strongSell[0]=EMPTY_VALUE;}
   return(0);
}
