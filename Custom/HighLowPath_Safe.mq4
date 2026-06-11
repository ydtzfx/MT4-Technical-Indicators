//+------------------------------------------------------------------+
//|                                          HighLowPath_Safe.mq4     |
//|  高低路径 — K线内部是先触高还是先触低                              |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum -100
#property indicator_maximum 100
double pathBias[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,pathBias);SetIndexLabel(0,"Path Bias");SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("HLPath_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;
   for(int i=limit;i>=1;i--){
      double o=iOpen(_Symbol,_Period,i),h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i);
      double r=h-l;if(r<_Point)r=_Point;
      // 估算路径：通过Open→Close方向判断先触哪端
      // 阳线且开盘接近最低=先触低后走高；阴线且开盘接近最高=先触高后走低
      double oPos=(o-l)/r; // 开盘位置(0=最低,1=最高)
      double cPos=(c-l)/r; // 收盘位置
      // 路径偏置：正=先低后高(买方主导)，负=先高后低(卖方主导)
      double bias=(cPos-oPos)*100;
      // 修正：阳线中如果开盘在低位且上影短=强势推动
      if(c>o&&oPos<0.3)bias+=30;
      if(c<o&&oPos>0.7)bias-=30;
      // 影线配合判断
      double upW=(h-MathMax(o,c))/r,loW=(MathMin(o,c)-l)/r;
      if(loW>0.5&&upW<0.1)bias+=20; // 长下影=拒绝下跌
      if(upW>0.5&&loW<0.1)bias-=20; // 长上影=拒绝上涨
      pathBias[i]=MathMax(-100,MathMin(100,bias));buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=2;i++){if(pathBias[i+1]<-40&&pathBias[i]>40)buySignal[i]=-50;if(pathBias[i+1]>40&&pathBias[i]<-40)sellSignal[i]=50;}
   if(Bars>0){pathBias[0]=pathBias[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}return(0);}
