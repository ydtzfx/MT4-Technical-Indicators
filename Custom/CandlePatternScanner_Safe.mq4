//+------------------------------------------------------------------+
//|                                   CandlePatternScanner_Safe.mq4   |
//|  K线形态扫描器 — 15种形态识别                                      |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_chart_window
#property indicator_buffers 8
input bool InpShowLabels=true;
double doji[],hammer[],shooting[],engulfBull[],engulfBear[],morningStar[],eveningStar[],harami[];
int init(){
   double*b[]={doji,hammer,shooting,engulfBull,engulfBear,morningStar,eveningStar,harami};
   int codes[]={108,ARROW_BUY,ARROW_SELL,ARROW_BUY,ARROW_SELL,ARROW_BUY,ARROW_SELL,ARROW_BUY};
   color cls[]={clrGray,CLR_BUY_SIGNAL,CLR_SELL_SIGNAL,CLR_BUY_SIGNAL,CLR_SELL_SIGNAL,CLR_BUY_SIGNAL,CLR_SELL_SIGNAL,CLR_BUY_SIGNAL};
   string nms[]={"Doji","Hammer","ShootingStar","EngulfBull","EngulfBear","MorningStar","EveningStar","Harami"};
   for(int i=0;i<8;i++){SetIndexStyle(i,DRAW_ARROW,STYLE_SOLID,2,cls[i]);SetIndexBuffer(i,b[i]);SetIndexArrow(i,codes[i]);SetIndexLabel(i,nms[i]);SetIndexEmptyValue(i,EMPTY_VALUE);}
   IndicatorDigits(0);IndicatorShortName("CandleScan_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   for(int i=limit;i>=0;i--){doji[i]=hammer[i]=shooting[i]=engulfBull[i]=engulfBear[i]=morningStar[i]=eveningStar[i]=harami[i]=EMPTY_VALUE;}
   for(int i=limit;i>=3;i--){
      double o=iOpen(_Symbol,_Period,i),h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i);
      double po=iOpen(_Symbol,_Period,i+1),ph=iHigh(_Symbol,_Period,i+1),pl=iLow(_Symbol,_Period,i+1),pc=iClose(_Symbol,_Period,i+1);
      double range=h-l,body=MathAbs(c-o);double pRange=ph-pl,pBody=MathAbs(pc-po);
      double upperW=h-MathMax(o,c),lowerW=MathMin(o,c)-l;
      if(range<_Point)continue;
      // Doji
      if(body<range*0.1)doji[i]=l-3*Point;
      // Hammer (下影线>实体2倍, 低位)
      if(lowerW>body*2&&upperW<body*0.5&&c<pc)hammer[i]=l-5*Point;
      // Shooting Star
      if(upperW>body*2&&lowerW<body*0.5&&c>pc)shooting[i]=h+5*Point;
      // Engulfing Bull
      if(c>o&&pc<po&&c>po&&o<pc)engulfBull[i]=l-8*Point;
      // Engulfing Bear
      if(c<o&&pc>po&&c<po&&o>pc)engulfBear[i]=h+8*Point;
      // Morning Star
      double p2c=iClose(_Symbol,_Period,i+2),p2o=iOpen(_Symbol,_Period,i+2);
      if(c>o&&pc<po&&MathAbs(pc-po)<pRange*0.3&&p2c<p2o&&c>p2o)morningStar[i]=l-10*Point;
      // Evening Star
      if(c<o&&pc>po&&MathAbs(pc-po)<pRange*0.3&&p2c>p2o&&c<p2o)eveningStar[i]=h+10*Point;
      // Harami
      if(body<pBody*0.5&&MathMax(o,c)<MathMax(po,pc)&&MathMin(o,c)>MathMin(po,pc)){if(c>o)harami[i]=l-5*Point;else harami[i]=h+5*Point;}
   }
   return(0);}
