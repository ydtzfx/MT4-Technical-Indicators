//+------------------------------------------------------------------+
//|                                      MarketRegimeClassifier_Safe  |
//|  市场状态识别器 — 原创指标                                         |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  创新：综合多个维度实时判断当前市场处于哪种状态                     |
//|  状态编码：0=强下跌趋势,1=弱下跌,2=盘整,3=弱上涨,4=强上涨趋势       |
//|  检测维度：ADX(趋势强度) + BB宽度(波动率) + 价格位置 + 均线排列     |
//+------------------------------------------------------------------+
#property copyright "Original Composite - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 7
#property indicator_minimum 0
#property indicator_maximum 4
#property indicator_level1 1
#property indicator_level2 2
#property indicator_level3 3

input int InpADXPeriod=14;input int InpBBPeriod=20;input int InpMAPeriod=20;

double regime[],trendStr[],volatility[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,3,clrDodgerBlue);SetIndexBuffer(0,regime);SetIndexLabel(0,"Regime");
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,2,clrYellow);SetIndexBuffer(1,trendStr);SetIndexLabel(1,"Trend Strength");
   SetIndexStyle(2,DRAW_HISTOGRAM,STYLE_SOLID,2,clrGray);SetIndexBuffer(2,volatility);SetIndexLabel(2,"Volatility");
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(3,buySignal);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(4,sellSignal);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(5,strongBuy);SetIndexArrow(5,ARROW_BUY);SetIndexLabel(5,"Strong Buy");SetIndexEmptyValue(5,EMPTY_VALUE);
   SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(6,strongSell);SetIndexArrow(6,ARROW_SELL);SetIndexLabel(6,"Strong Sell");SetIndexEmptyValue(6,EMPTY_VALUE);
   IndicatorDigits(0);IndicatorShortName("Regime_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      // === ADX趋势强度 ===
      double trSum=0,pdmSum=0,mdmSum=0;
      for(int j=0;j<InpADXPeriod;j++){
         int s=i+j;double h=iHigh(_Symbol,_Period,s),l=iLow(_Symbol,_Period,s),pc=iClose(_Symbol,_Period,s+1);
         trSum+=MathMax(h-l,MathMax(MathAbs(h-pc),MathAbs(l-pc)));
         double up=iHigh(_Symbol,_Period,s)-iHigh(_Symbol,_Period,s+1),dn=iLow(_Symbol,_Period,s+1)-iLow(_Symbol,_Period,s);
         if(up>dn&&up>0)pdmSum+=up;if(dn>up&&dn>0)mdmSum+=dn;
      }
      double adx=SafeDivide(100*MathAbs(pdmSum-mdmSum),pdmSum+mdmSum,0);

      // === BB宽度（波动率）===
      double sum=0;for(int j=0;j<InpBBPeriod;j++)sum+=iClose(_Symbol,_Period,i+j);
      double sma=sum/InpBBPeriod;double sd=0;for(int j=0;j<InpBBPeriod;j++){double d=iClose(_Symbol,_Period,i+j)-sma;sd+=d*d;}
      double bbw=SafeDivide(2*MathSqrt(sd/InpBBPeriod),sma,0)*100;

      // === 均线排列 ===
      double ma=0;for(int j=0;j<InpMAPeriod;j++)ma+=iClose(_Symbol,_Period,i+j);ma/=InpMAPeriod;
      double posVsMA=iClose(_Symbol,_Period,i)>ma?1:-1;

      // === 状态分类 ===
      double regVal=2; // 默认盘整
      if(adx>25){
         double pdi=SafeDivide(pdmSum,trSum,0),mdi=SafeDivide(mdmSum,trSum,0);
         if(pdi>mdi*1.2)regVal=(adx>40)?4:3; // 强/弱上涨
         else if(mdi>pdi*1.2)regVal=(adx>40)?0:1; // 强/弱下跌
         else regVal=2;
      }else if(posVsMA>0)regVal=2.5;else regVal=1.5;

      regime[i]=regVal;trendStr[i]=adx;volatility[i]=bbw;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   // 信号：状态从盘整或下跌转为上涨
   for(int i=limit;i>=2;i--){
      if(regime[i+1]<=2&&regime[i]>2.5&&trendStr[i]>20)buySignal[i]=1;
      if(regime[i+1]>=2&&regime[i]<1.5&&trendStr[i]>20)sellSignal[i]=3;
      // 强信号：状态直接跃升到强趋势区域+强趋势强度
      if(regime[i+1]<=2&&regime[i]>3.5&&trendStr[i]>35)strongBuy[i]=1;
      if(regime[i+1]>=2&&regime[i]<0.5&&trendStr[i]>35)strongSell[i]=3;
   }
   if(Bars>0){regime[0]=regime[1];trendStr[0]=trendStr[1];volatility[0]=volatility[1];buySignal[0]=sellSignal[0]=strongBuy[0]=strongSell[0]=EMPTY_VALUE;}
   return(0);
}
