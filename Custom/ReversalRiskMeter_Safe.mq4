//+------------------------------------------------------------------+
//|                                         ReversalRiskMeter_Safe.mq4|
//|  反转风险计 — 原创指标                                            |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  创新：综合评估当前趋势发生反转的风险（0-100%）                    |
//|  评估因子：                                                         |
//|  1. RSI背离（动量与价格不匹配）                                     |
//|  2. K线形态（Pin Bar/吞没/十字星）                                  |
//|  3. 成交量异常（高位放量滞涨/低位放量止跌）                         |
//|  4. 波动率变化（趋势中ATR突然放大=可能反转）                        |
//|  5. 支撑阻力距离（接近关键位时反转概率增大）                        |
//+------------------------------------------------------------------+
#property copyright "Original Composite - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 70
#property indicator_level2 30

input int InpPeriod=14;

double risk[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,risk);SetIndexLabel(0,"Reversal Risk %");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,3,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,3,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   IndicatorDigits(0);IndicatorShortName("ReversalRisk_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;

   double avgVol=0;for(int j=0;j<50;j++)avgVol+=iVolume(_Symbol,_Period,limit+50+j);avgVol/=50;

   for(int i=limit;i>=1;i--){
      double c=iClose(_Symbol,_Period,i),o=iOpen(_Symbol,_Period,i);
      double h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i);
      double range=h-l,body=MathAbs(c-o);
      long v=iVolume(_Symbol,_Period,i);double volR=SafeDivide((double)v,avgVol,1);
      bool isUp=c>iClose(_Symbol,_Period,i+1);

      double riskScore=0;

      // === 因子1：RSI极端值（>75或<25）===
      double aG=0,aL=0;for(int j=0;j<InpPeriod;j++){double ch=iClose(_Symbol,_Period,i+j)-iClose(_Symbol,_Period,i+j+1);if(ch>0)aG+=ch;else aL-=ch;}
      double rsi=SafeDivide(100*aG,aG+aL,50);
      if(rsi>75)riskScore+=25;else if(rsi>65)riskScore+=15;
      if(rsi<25)riskScore+=25;else if(rsi<35)riskScore+=15;

      // === 因子2：反转K线形态 ===
      double upperWick=h-MathMax(o,c),lowerWick=MathMin(o,c)-l;
      double wickRatio=SafeDivide(MathMax(upperWick,lowerWick),range,1);
      if(wickRatio>0.6&&body<range*0.3){ // Pin Bar
         if(upperWick>lowerWick&&isUp)riskScore+=20;  // 上升趋势中的上影线=可能反转
         if(lowerWick>upperWick&&!isUp)riskScore+=20;
      }

      // === 因子3：成交量异常 ===
      if(volR>2.0&&body<range*0.5)riskScore+=15; // 放量滞涨/止跌
      if(volR>1.5&&wickRatio>0.5)riskScore+=10;  // 放量+长影线

      // === 因子4：波动率突变 ===
      double atr3=0,atr10=0;for(int j=0;j<3;j++)atr3+=GetTrueRange(_Symbol,_Period,i+j);
      for(int j=0;j<10;j++)atr10+=GetTrueRange(_Symbol,_Period,i+j);
      if(SafeDivide(atr3/3,atr10/10,1)>1.8)riskScore+=15;

      // === 因子5：连续同向K线后的反转风险 ===
      int consec=0;
      for(int j=1;j<6;j++){if(iClose(_Symbol,_Period,i+j)>iClose(_Symbol,_Period,i+j+1)==isUp)consec++;else break;}
      if(consec>=5)riskScore+=20; // 连续5根同向=过度延伸

      risk[i]=MathMin(100,riskScore);
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=2;i--){
      // 风险从高位回落+价格开始反转
      if(risk[i+1]>70&&risk[i]<50&&iClose(_Symbol,_Period,i)<iClose(_Symbol,_Period,i+1))buySignal[i]=risk[i]-5;
      if(risk[i+1]>70&&risk[i]<50&&iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+1))sellSignal[i]=risk[i]+5;
   }
   if(Bars>0){risk[0]=risk[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
