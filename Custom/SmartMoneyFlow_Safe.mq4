//+------------------------------------------------------------------+
//|                                            SmartMoneyFlow_Safe.mq4|
//|  聪明钱流向 — 原创指标                                            |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  创新：通过四个维度检测机构/聪明钱动向                              |
//|  1. 隐性成交量：大成交量+小K线实体=吸筹/派发(隐藏意图)             |
//|  2. 价格拒绝：长影线+大成交量=机构在关键位反击                     |
//|  3. 突破确认：放量突破+回踩不破=真突破(聪明钱方向)                 |
//|  4. 尾盘异动：收盘前价格快速回归=机构调仓                          |
//|  正值=聪明钱在买，负值=聪明钱在卖                                  |
//+------------------------------------------------------------------+
#property copyright "Original Composite - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_minimum -100
#property indicator_maximum 100
#property indicator_level1 40
#property indicator_level2 -40

input int InpVolAvgPeriod=20;input double InpVolSpikeMult=2.0;input double InpSmallBodyRatio=0.3;

double smfLine[],buySignal[],sellSignal[],intensity[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,smfLine);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Smart Money Flow");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_HISTOGRAM,STYLE_SOLID,2);SetIndexBuffer(3,intensity);SetIndexEmptyValue(3,EMPTY_VALUE);SetIndexLabel(3,"Intensity");
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(4,strongBuy);SetIndexArrow(4,233);SetIndexEmptyValue(4,EMPTY_VALUE);SetIndexLabel(4,"Strong Buy");
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(5,strongSell);SetIndexArrow(5,234);SetIndexEmptyValue(5,EMPTY_VALUE);SetIndexLabel(5,"Strong Sell");
   IndicatorDigits(1);IndicatorShortName("SmartMoney_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;

   // 计算平均成交量基准
   double avgVol=0;for(int j=0;j<InpVolAvgPeriod;j++)avgVol+=iVolume(_Symbol,_Period,limit+j+10);avgVol/=InpVolAvgPeriod;

   for(int i=limit;i>=1;i--){
      double o=iOpen(_Symbol,_Period,i),h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),c=iClose(_Symbol,_Period,i);
      double range=h-l,body=MathAbs(c-o);long v=iVolume(_Symbol,_Period,i);
      double volRatio=SafeDivide((double)v,avgVol,1);

      double smfScore=0;

      // === 检测1：隐性吸筹/派发（高量+小实体）===
      double bodyRatio=SafeDivide(body,range,1);
      if(volRatio>InpVolSpikeMult&&bodyRatio<InpSmallBodyRatio){
         // 小实体+放量=机构在悄悄建仓/出货
         double upperWick=h-MathMax(o,c),lowerWick=MathMin(o,c)-l;
         if(lowerWick>upperWick*1.5)smfScore+=25;  // 下影线长=吸筹
         else if(upperWick>lowerWick*1.5)smfScore-=25; // 上影线长=派发
      }

      // === 检测2：关键位价格拒绝（长影线+放量）=机构护盘/打压 ===
      double wickRatio=SafeDivide(MathMax(h-MathMax(o,c),MathMin(o,c)-l),range,1);
      if(wickRatio>0.6&&volRatio>1.5){
         double pc=iClose(_Symbol,_Period,i+1);
         if(c>pc&&l<iLow(_Symbol,_Period,i+1))smfScore+=30; // 跌破前低后拉回=护盘
         if(c<pc&&h>iHigh(_Symbol,_Period,i+1))smfScore-=30; // 突破前高后打压
      }

      // === 检测3：尾盘异动（收盘价远离开盘价+大成交量）===
      if(volRatio>1.3&&bodyRatio>0.7){
         if(c>o)smfScore+=15;
         else smfScore-=15;
      }

      // === 检测4：连续高量推升/打压=聪明钱持续介入 ===
      int consecVol=0;for(int j=0;j<3;j++)if(iVolume(_Symbol,_Period,i+j)>avgVol*1.2)consecVol++;
      if(consecVol>=2){if(c>iClose(_Symbol,_Period,i+3))smfScore+=20;else smfScore-=20;}

      smfLine[i]=MathMax(-100,MathMin(100,smfScore));
      intensity[i]=MathAbs(smfLine[i]);
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=2;i--){
      if(smfLine[i+1]<-40&&smfLine[i]>-40)buySignal[i]=-50;
      if(smfLine[i+1]>40&&smfLine[i]<40)sellSignal[i]=50;
      if(smfLine[i+1]<smfLine[i+2]&&smfLine[i]>smfLine[i+1]&&smfLine[i]<-20)buySignal[i]=smfLine[i]-5;
      // 强信号：SMF强势转向+高强度确认
      if(smfLine[i+1]<-60&&smfLine[i]>-30&&intensity[i]>40)strongBuy[i]=-60;
      if(smfLine[i+1]>60&&smfLine[i]<30&&intensity[i]>40)strongSell[i]=60;
   }
   if(Bars>0){smfLine[0]=smfLine[1];intensity[0]=intensity[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=EMPTY_VALUE;strongSell[0]=EMPTY_VALUE;}
   return(0);
}
