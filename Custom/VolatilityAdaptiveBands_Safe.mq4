#include "../Include/Common.mqh"
#include "../Include/PriceData.mqh"
//+------------------------------------------------------------------+
//|                                    VolatilityAdaptiveBands_Safe   |
//|  波动率自适应通道 — 原创指标                                       |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  创新：通道宽度同时由三个因素决定：                                 |
//|  1. ATR（基础波动率）+ 2. 趋势强度调幅（趋势强=宽，盘整=窄）        |
//|  + 3. 成交量修正（放量=宽，缩量=窄）                                |
//|  相比固定参数的Bollinger/Keltner更智能                            |
//+------------------------------------------------------------------+
#property copyright "Original Composite - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 7

input int InpATRPeriod=14;input double InpBaseMult=1.5;input int InpADXPeriod=14;

double mid[],upper[],lower[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrYellow);SetIndexBuffer(0,mid);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"VAB Mid");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,clrRoyalBlue);SetIndexBuffer(1,upper);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"VAB Upper");
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1,clrRoyalBlue);SetIndexBuffer(2,lower);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexLabel(2,"VAB Lower");
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(3,buySignal);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(4,sellSignal);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(5,strongBuy);SetIndexArrow(5,233);SetIndexEmptyValue(5,EMPTY_VALUE);SetIndexLabel(5,"Strong Buy");
   SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(6,strongSell);SetIndexArrow(6,234);SetIndexEmptyValue(6,EMPTY_VALUE);SetIndexLabel(6,"Strong Sell");
   IndicatorDigits(4);IndicatorShortName("VABands_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   double avgVol=0;for(int j=0;j<50;j++)avgVol+=iVolume(_Symbol,_Period,limit+j+10);avgVol/=50;

   for(int i=limit;i>=1;i--){
      // EMA中线
      double p[40];for(int jj=0;j<40;j++)p[j]=iClose(_Symbol,_Period,i+j);
      double ema=p[39];double a=2.0/21;for(int jjj=38;j>=0;j--)ema=p[j]*a+ema*(1-a);mid[i]=ema;

      // ATR
      double atr=0;for(int jjjj=0;j<InpATRPeriod;j++)atr+=GetTrueRange(_Symbol,_Period,i+j);atr/=InpATRPeriod;

      // ADX趋势强度修正
      double tStr=0;for(int jjjjj=0;j<InpADXPeriod;j++){double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j),pc=iClose(_Symbol,_Period,i+j+1);tStr+=MathMax(h-l,MathMax(MathAbs(h-pc),MathAbs(l-pc)));}tStr/=InpADXPeriod;double adxRatio=SafeDivide(tStr,atr,1);

      // 成交量修正
      double volAdj=SafeDivide((double)iVolume(_Symbol,_Period,i),avgVol,1);
      volAdj=MathMax(0.7,MathMin(1.5,volAdj)); // 限制在0.7-1.5

      // 自适应宽度 = BaseMult * ATR * ADX比率 * 成交量修正
      double bandWidth=InpBaseMult*atr*(0.5+0.5*MathMin(adxRatio/2,2))*volAdj;

      upper[i]=ema+bandWidth;lower[i]=ema-bandWidth;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=2;i--){
      double c=iClose(_Symbol,_Period,i),c1=iClose(_Symbol,_Period,i+1);
      double volRatio=SafeDivide((double)iVolume(_Symbol,_Period,i),avgVol,1);
      double adxRatio2=SafeDivide(tStr,atr,1);
      if(c1<=lower[i+1]&&c>lower[i]){
         buySignal[i]=iLow(_Symbol,_Period,i)-5*Point;
         // 强信号：突破下轨+强趋势+放量
         if(adxRatio2>1.5&&volRatio>1.3)strongBuy[i]=iLow(_Symbol,_Period,i)-12*Point;
      }
      if(c1>=upper[i+1]&&c<upper[i]){
         sellSignal[i]=iHigh(_Symbol,_Period,i)+5*Point;
         // 强信号：跌破上轨+强趋势+放量
         if(adxRatio2>1.5&&volRatio>1.3)strongSell[i]=iHigh(_Symbol,_Period,i)+12*Point;
      }
   }
   if(Bars>0){mid[0]=mid[1];upper[0]=upper[1];lower[0]=lower[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=EMPTY_VALUE;strongSell[0]=EMPTY_VALUE;}
   return(0);
}
