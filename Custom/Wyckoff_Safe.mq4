//+------------------------------------------------------------------+
//|                                              Wyckoff_Safe.mq4    |
//|  威科夫累积/派发检测 — 原创指标                                    |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  检测四个威科夫阶段：累积→上涨→派发→下跌                           |
//|  累积特征：价格区间收窄+成交量低点萎缩+弹簧效应                     |
//|  派发特征：价格区间扩张+成交量高位放大+上冲回落                     |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_minimum -100
#property indicator_maximum 100

double wyckoffPhase[],volAnomaly[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init(){SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,3,clrDodgerBlue);SetIndexBuffer(0,wyckoffPhase);SetIndexLabel(0,"Wyckoff Phase");SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,2);SetIndexBuffer(1,volAnomaly);SetIndexLabel(1,"Vol Anomaly");SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(4,strongBuy);SetIndexArrow(4,233);SetIndexEmptyValue(4,EMPTY_VALUE);SetIndexLabel(4,"Strong Buy");SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(5,strongSell);SetIndexArrow(5,234);SetIndexEmptyValue(5,EMPTY_VALUE);SetIndexLabel(5,"Strong Sell");IndicatorDigits(0);IndicatorShortName("Wyckoff_Safe");return(0);}
int deinit(){return(0);}

int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=20;i--){
      double range5=0,range20=0;for(int j=0;j<5;j++){range5+=iHigh(_Symbol,_Period,i+j)-iLow(_Symbol,_Period,i+j);}range5/=5;
      for(int j=0;j<20;j++){range20+=iHigh(_Symbol,_Period,i+j)-iLow(_Symbol,_Period,i+j);}range20/=20;
      double vol5=0,vol20=0;for(int j=0;j<5;j++)vol5+=iVolume(_Symbol,_Period,i+j);vol5/=5;
      for(int j=0;j<20;j++)vol20+=iVolume(_Symbol,_Period,i+j);vol20/=20;
      double rangeRatio=SafeDivide(range5,range20,1);double volRatio=SafeDivide(vol5,vol20,1);
      // Wyckoff相位判断
      double phase=0;
      if(rangeRatio<0.7&&volRatio<0.7)phase=80;       // 累积：缩量窄幅
      else if(rangeRatio<0.8&&volRatio>1.3)phase=-80;  // 派发：放量但价格不涨
      else if(rangeRatio>1.3&&volRatio>1.3)phase=50;   // 趋势启动：放量扩幅
      else if(rangeRatio>1.5)phase=(iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+5)?30:-30);

      double c=iClose(_Symbol,_Period,i),c5=iClose(_Symbol,_Period,i+5);
      if(phase>50&&volRatio>1.2&&c>c5)phase=90;        // 强势突破=上涨阶段
      if(phase<-50&&volRatio>1.2&&c<c5)phase=-90;      // 强势跌破=下跌阶段

      wyckoffPhase[i]=phase;volAnomaly[i]=(volRatio-1)*50;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=2;i--){
      if(wyckoffPhase[i+1]<-30&&wyckoffPhase[i]>30)buySignal[i]=-50;  // 从派发/下跌转累积
      if(wyckoffPhase[i+1]>30&&wyckoffPhase[i]<-30)sellSignal[i]=50;
      // 强信号：相位转换+成交量异常确认
      if(wyckoffPhase[i+1]<-50&&wyckoffPhase[i]>60&&volAnomaly[i]>10)strongBuy[i]=-60;
      if(wyckoffPhase[i+1]>50&&wyckoffPhase[i]<-60&&volAnomaly[i]<-10)strongSell[i]=60;
   }
   if(Bars>0){wyckoffPhase[0]=wyckoffPhase[1];volAnomaly[0]=volAnomaly[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=EMPTY_VALUE;strongSell[0]=EMPTY_VALUE;}
   return(0);}
