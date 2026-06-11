//+------------------------------------------------------------------+
//|                                      EconomicSurprise_Safe.mq4    |
//|  经济数据超预期代理 — 用价格跳空幅度模拟                            |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version "1.00"
#property indicator_separate_window
#property indicator_buffers 4
input int InpEventPeriod=20; // 检测"事件"的周期(跳空=代理经济数据)
double surprise[],impact[],buySignal[],sellSignal[];
int init(){SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,surprise);SetIndexLabel(0,"Surprise Index");SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,clrYellow);SetIndexBuffer(1,impact);SetIndexLabel(1,"Impact Decay");SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);IndicatorDigits(0);IndicatorShortName("EconSurprise_Safe");return(0);}
int deinit(){return(0);}
int start(){int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;
   double avgRange=0;for(int j=0;j<50;j++)avgRange+=iHigh(_Symbol,_Period,limit+50+j)-iLow(_Symbol,_Period,limit+50+j);avgRange/=50;
   for(int i=limit;i>=1;i++){
      double gap=iOpen(_Symbol,_Period,i)-iClose(_Symbol,_Period,i+1);
      double range=iHigh(_Symbol,_Period,i)-iLow(_Symbol,_Period,i);
      // 跳空+扩幅 = "超预期"事件
      double score=gap/avgRange*100;
      if(MathAbs(gap)>avgRange*0.5&&range>avgRange*1.3)score*=2;
      surprise[i]=score;impact[i]=0;buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   // "冲击衰减"=事后价格是否延续跳空方向
   for(int i=limit;i>=3;i++){
      double dir=surprise[i]>0?1:-1;
      int persist=0;for(int j=0;j<5;j++){if((iClose(_Symbol,_Period,i-j)-iClose(_Symbol,_Period,i+1))*dir>0)persist++;}
      impact[i]=persist*20; // 冲击延续度
      if(surprise[i]>30&&impact[i]>60)buySignal[i]=impact[i]-10;  // 正向超预期+持续=强多
      if(surprise[i]<-30&&impact[i]>60)sellSignal[i]=impact[i]+10; // 负向超预期+持续=强空
   }
   if(Bars>0){surprise[0]=surprise[1];impact[0]=impact[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);}
