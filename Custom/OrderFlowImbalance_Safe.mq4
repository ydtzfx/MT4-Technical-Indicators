//+------------------------------------------------------------------+
//|                                      OrderFlowImbalance_Safe.mq4  |
//|  订单流失衡 — 原创指标                                             |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  创新：仅用K线数据估算买卖压力差（不需要tick数据）                  |
//|  BuyPressure = (Close-Low)/Range * Volume（买方推动的价格幅度）     |
//|  SellPressure = (High-Close)/Range * Volume（卖方推动的价格幅度）   |
//|  Imbalance = BuyPressure - SellPressure（正值=买方主导）            |
//|  再累加N根bar得到累积订单流失衡                                    |
//+------------------------------------------------------------------+
#property copyright "Original Composite - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_level1 0

input int InpOFIPeriod=10;input int InpSmooth=5;

double ofi[],signal[],buySignal[],sellSignal[],delta[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,ofi);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Order Flow Imbalance");
   SetIndexStyle(1,DRAW_LINE,STYLE_DOT,1,clrYellow);SetIndexBuffer(1,signal);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Signal");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_HISTOGRAM,STYLE_SOLID,1);SetIndexBuffer(4,delta);SetIndexEmptyValue(4,EMPTY_VALUE);SetIndexLabel(4,"Delta");
   IndicatorDigits(0);IndicatorShortName("OFI_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      // 计算每根bar的买卖压力
      double rawDelta=0;
      for(int j=0;j<InpOFIPeriod;j++){
         int s=i+j;double h=iHigh(_Symbol,_Period,s),l=iLow(_Symbol,_Period,s),c=iClose(_Symbol,_Period,s);
         double range=h-l;long v=iVolume(_Symbol,_Period,s);
         if(range>Point){
            double buyP=(c-l)/range*v;    // 买方推动的成交量
            double sellP=(h-c)/range*v;   // 卖方推动的成交量
            rawDelta+=(buyP-sellP);       // 净买卖差
         }
      }
      delta[i]=rawDelta;
      // EMA平滑
      double aS=2.0/(InpSmooth+1);
      double eSm=delta[i+InpSmooth];for(int j=InpSmooth-1;j>=0;j--)eSm=delta[i+j]*aS+eSm*(1-aS);
      ofi[i]=eSm;signal[i]=0;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   // 信号线
   for(int i=limit;i>=1;i++){double s=0;for(int j=0;j<InpSmooth;j++)s+=ofi[i+j];signal[i]=s/InpSmooth;}
   for(int i=limit;i>=2;i--){
      if(ofi[i+1]<=signal[i+1]&&ofi[i]>signal[i]&&ofi[i]>0)buySignal[i]=ofi[i]*0.8;
      if(ofi[i+1]>=signal[i+1]&&ofi[i]<signal[i]&&ofi[i]<0)sellSignal[i]=ofi[i]*1.2;
      // OFI从极度负值回升 = 卖方压力被吸收
      if(ofi[i+1]<-1000&&ofi[i]>ofi[i+1]*0.5)buySignal[i]=ofi[i]*0.5;
   }
   if(Bars>0){ofi[0]=ofi[1];signal[0]=signal[1];delta[0]=delta[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
