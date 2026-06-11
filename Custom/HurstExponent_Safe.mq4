//+------------------------------------------------------------------+
//|                                          HurstExponent_Safe.mq4   |
//|  赫斯特指数（Hurst Exponent）— 分形统计指标                       |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：R/S = c * N^H → log(R/S) = log(c) + H*log(N)               |
//|  H>0.5 = 趋势持续（有记忆性），H<0.5 = 均值回归（反持续性）        |
//|  H=0.5 = 随机游走                                                   |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_minimum 0.2
#property indicator_maximum 0.8
#property indicator_level1 0.5

input int InpPeriod=50; // 估计Hurst的窗口

double hurst[],trendStr[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,3,clrDodgerBlue);SetIndexBuffer(0,hurst);SetIndexLabel(0,"Hurst");
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,1);SetIndexBuffer(1,trendStr);SetIndexLabel(1,"Trend Bias");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   IndicatorDigits(3);IndicatorShortName("Hurst_Safe("+IntegerToString(InpPeriod)+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpPeriod*2;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      double returns[];ArrayResize(returns,InpPeriod);
      for(int j=0;j<InpPeriod;j++)returns[j]=iClose(_Symbol,_Period,i+j)-iClose(_Symbol,_Period,i+j+1);

      // 对多个子周期计算R/S
      double sumRS=0;int nLevels=0;
      int sizes[]={10,20,30,50}; // 不同子窗口大小
      for(int s=0;s<4;s++){
         int subN=sizes[s];if(subN>InpPeriod)continue;
         for(int start=0;start<InpPeriod-subN;start+=subN/2){
            double mean=0;for(int j=0;j<subN;j++)mean+=returns[start+j];mean/=subN;
            double dev[];ArrayResize(dev,subN);double cumDev=0;
            double maxDD=0,minDD=999;for(int j=0;j<subN;j++){cumDev+=returns[start+j]-mean;dev[j]=cumDev;if(cumDev>maxDD)maxDD=cumDev;if(cumDev<minDD)minDD=cumDev;}
            double range=maxDD-minDD;
            double std=0;for(int j=0;j<subN;j++)std+=(returns[start+j]-mean)*(returns[start+j]-mean);std=MathSqrt(std/subN);
            if(std>0){sumRS+=MathLog(range/std)/MathLog(subN);nLevels++;}
         }
      }
      hurst[i]=nLevels>0?MathMax(0.2,MathMin(0.8,sumRS/nLevels)):0.5;
      trendStr[i]=(hurst[i]-0.5)*200; // 正=趋势倾向，负=回归倾向
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=2;i--){
      // Hurst从<0.5翻到>0.5 = 市场从回归转为趋势 → 跟趋势方向
      if(hurst[i+1]<0.5&&hurst[i]>0.5&&iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+3))buySignal[i]=0.45;
      if(hurst[i+1]<0.5&&hurst[i]>0.5&&iClose(_Symbol,_Period,i)<iClose(_Symbol,_Period,i+3))sellSignal[i]=0.55;
      // Hurst极高(>0.7)后回落 = 趋势衰竭
      if(hurst[i+1]>0.7&&hurst[i]<0.65)sellSignal[i]=0.6;
   }
   if(Bars>0){hurst[0]=hurst[1];trendStr[0]=trendStr[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
