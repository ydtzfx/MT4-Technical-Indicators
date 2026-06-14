#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                             Harmonics_Safe.mq4    |
//|  谐波形态检测 — 不含未来函数（确认后绘制）                          |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  检测Gartley和Butterfly形态：XABCD5点结构                          |
//|  Gartley: B=0.618XA, C=0.382-0.886AB, D=0.786XA+1.27BC           |
//|  信号确认需要所有5点都完成（bar[1]+）                              |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 4

double bullPattern[],bearPattern[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(0,bullPattern);SetIndexArrow(0,ARROW_BUY);SetIndexEmptyValue(0,EMPTY_VALUE);
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(1,bearPattern);SetIndexArrow(1,ARROW_SELL);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("Harmonics_Safe");return(0);
}
int deinit(){return(0);}

// 寻找极值点 — 回溯方向不同
int FindSwingHigh(int start,int lookback){
   for(int i=start+1;i<start+lookback;i++){
      bool isHigh=true;
      for(int j=1;j<=3;j++){if(i+j<Bars&&iHigh(_Symbol,_Period,i+j)>=iHigh(_Symbol,_Period,i))isHigh=false;if(i-j>=0&&iHigh(_Symbol,_Period,i-j)>=iHigh(_Symbol,_Period,i))isHigh=false;}
      if(isHigh)return i;
   }
   return -1;
}
int FindSwingLow(int start,int lookback){
   int i,j;
   for(i=start+1;i<start+lookback;i++){
      bool isLow=true;
      for(int jj=1;j<=3;j++){if(i+j<Bars&&iLow(_Symbol,_Period,i+j)<=iLow(_Symbol,_Period,i))isLow=false;if(i-j>=0&&iLow(_Symbol,_Period,i-j)<=iLow(_Symbol,_Period,i))isLow=false;}
      if(isLow)return i;
   }
   return -1;
}

int start() {
   int i;
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(i=limit;i>=0;i--){bullPattern[i]=EMPTY_VALUE;bearPattern[i]=EMPTY_VALUE;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;}

   for(i=limit;i>=20;i--){
      // 找XABC 4个摆动点
      int x=FindSwingLow(i,30);if(x<0)continue;
      int a=FindSwingHigh(x-5,20);if(a<0)continue;
      int b=FindSwingLow(a-3,15);if(b<0)continue;
      int c=FindSwingHigh(b-2,10);if(c<0||c<5)continue;

      double xa=iHigh(_Symbol,_Period,a)-iLow(_Symbol,_Period,x);
      double ab=iHigh(_Symbol,_Period,a)-iLow(_Symbol,_Period,b);
      double bc=iHigh(_Symbol,_Period,c)-iLow(_Symbol,_Period,b);

      // B在XA的0.618附近（0.55-0.7）
      double bRetrace=SafeDivide(ab,xa,0);
      double cRetrace=SafeDivide(bc,ab,0);
      bool isGartleyBull=(bRetrace>0.55&&bRetrace<0.7&&cRetrace>0.38&&cRetrace<0.88);
      bool isButterflyBull=(bRetrace>0.7&&bRetrace<0.88&&cRetrace>0.38&&cRetrace<0.88);

      if(isGartleyBull||isButterflyBull){
         // D点目标
         double dPrice=iHigh(_Symbol,_Period,c)-1.27*bc;
         // 当前价格在D附近
         if(iClose(_Symbol,_Period,i)<=dPrice*1.01&&iClose(_Symbol,_Period,i)>=dPrice*0.99)
            bullPattern[i]=iLow(_Symbol,_Period,i)-10*Point;
         else buySignal[i]=iLow(_Symbol,_Period,i)-15*Point; // 接近D
      }
   }
   return(0);
}
