//+------------------------------------------------------------------+
//|                                       StoppingVolume_Safe.mq4     |
//|  停止量 — 巨量+反转影线=趋势停止信号                               |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 4
input double InpVolMult=2.5;
double stopBuy[],stopSell[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_ARROW,STYLE_SOLID,4,CLR_BUY_SIGNAL);SetIndexBuffer(0,stopBuy);SetIndexArrow(0,ARROW_BUY);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,4,CLR_SELL_SIGNAL);SetIndexBuffer(1,stopSell);SetIndexArrow(1,ARROW_SELL);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("StopVol_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){stopBuy[i]=stopSell[i]=buySignal[i]=sellSignal[i]=EMPTY_VALUE;}
   double avgV=0;for(int j=0;j<20;j++)avgV+=iVolume(_Symbol,_Period,limit+10+j);avgV/=20;
   for(int i=limit;i>=3;i--){
      double o=iOpen(_Symbol,_Period,i),h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i);
      double r=h-l,body=MathAbs(c-o);long v=iVolume(_Symbol,_Period,i);
      if(v<avgV*InpVolMult)continue;
      double loW=MathMin(o,c)-l,upW=h-MathMax(o,c);
      // 下跌趋势中巨量+长下影=停止下跌（买方介入）
      bool wasDown=iClose(_Symbol,_Period,i+1)<iClose(_Symbol,_Period,i+3);
      if(wasDown&&loW>r*0.4&&c>o)stopBuy[i]=l-8*Point;
      // 上涨趋势中巨量+长上影=停止上涨（卖方介入）
      bool wasUp=iClose(_Symbol,_Period,i+1)>iClose(_Symbol,_Period,i+3);
      if(wasUp&&upW>r*0.4&&c<o)stopSell[i]=h+8*Point;
      if(stopBuy[i]!=EMPTY_VALUE&&iClose(_Symbol,_Period,i-1)>iHigh(_Symbol,_Period,i))buySignal[i-1]=iLow(_Symbol,_Period,i-1)-12*Point;
   }
   return(0);}
