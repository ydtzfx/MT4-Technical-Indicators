//+------------------------------------------------------------------+
//|                                   AdaptiveSignalFusion_Safe.mq4   |
//|  自适应信号融合器 — 原创复合指标                                   |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  创新点：根据市场波动率动态调整RSI/MACD/Stoch三大振荡器的权重      |
//|  - 高波动期：增加Stochastic权重（对快速反转敏感）                   |
//|  - 低波动期：增加MACD权重（趋势跟踪更可靠）                         |
//|  - 中等波动：RSI权重最大（超买超卖最有效）                          |
//|  融合信号 = W1*RSI_signal + W2*MACD_signal + W3*Stoch_signal       |
//|  输出：一个综合信号值 [-100, 100]，>30买入，<-30卖出               |
//+------------------------------------------------------------------+
#property copyright "Original Composite - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_minimum -100
#property indicator_maximum 100
#property indicator_level1 30
#property indicator_level2 -30

input int InpRSIPeriod=14, InpMACDFast=12, InpMACDSlow=26, InpStochK=5, InpStochD=3;

double fusionLine[],signalLine[],buySignal[],sellSignal[],strengthBar[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,fusionLine);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Fusion");
   SetIndexStyle(1,DRAW_LINE,STYLE_DOT,1,clrYellow);SetIndexBuffer(1,signalLine);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Signal");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_HISTOGRAM,STYLE_SOLID,2);SetIndexBuffer(4,strengthBar);SetIndexEmptyValue(4,EMPTY_VALUE);SetIndexLabel(4,"Strength");
   IndicatorDigits(1);IndicatorShortName("AdaptiveFusion_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      // === RSI计算 ===
      double aG=0,aL=0;for(int j=0;j<InpRSIPeriod;j++){double ch=iClose(_Symbol,_Period,i+j)-iClose(_Symbol,_Period,i+j+1);if(ch>0)aG+=ch;else aL-=ch;}
      aG/=InpRSIPeriod;aL/=InpRSIPeriod;double rsi=aL<0.00000001?100:100-100/(1+aG/aL);
      double rsiSignal=(rsi-50)*2; // 映射到[-100,100]

      // === MACD计算 ===
      double p[100];for(int j=0;j<100;j++)p[j]=iClose(_Symbol,_Period,i+j);
      double aF=2.0/(InpMACDFast+1),aS=2.0/(InpMACDSlow+1),eF=0,eS=0;
      for(int j=99;j>=0;j--){if(j==99){eF=p[j];eS=p[j];}else{eF=p[j]*aF+eF*(1-aF);eS=p[j]*aS+eS*(1-aS);}}
      double macd=eF-eS;double macdSignal=macd>0?MathMin(100,macd*5000):MathMax(-100,macd*5000);

      // === Stochastic计算 ===
      double hh=iHigh(_Symbol,_Period,i),ll=iLow(_Symbol,_Period,i);
      for(int j=0;j<InpStochK;j++){double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);if(h>hh)hh=h;if(l<ll)ll=l;}
      double stoch=SafeDivide(100*(iClose(_Symbol,_Period,i)-ll),hh-ll,50);
      double stochSignal=(stoch-50)*2;

      // === 波动率权重计算（基于ATR相对于其均值的偏离）===
      double atr5=0,atr20=0;for(int j=0;j<5;j++)atr5+=GetTrueRange(_Symbol,_Period,i+j);
      for(int j=0;j<20;j++)atr20+=GetTrueRange(_Symbol,_Period,i+j);atr5/=5;atr20/=20;
      double volRatio=SafeDivide(atr5,atr20,1); // >1=高波动，<1=低波动

      double wRSI,wMACD,wStoch;
      if(volRatio>1.5){wRSI=0.2;wMACD=0.3;wStoch=0.5;}       // 高波动：侧重Stoch
      else if(volRatio>1.1){wRSI=0.4;wMACD=0.3;wStoch=0.3;}   // 中高波动
      else if(volRatio>0.9){wRSI=0.5;wMACD=0.25;wStoch=0.25;} // 正常波动：侧重RSI
      else if(volRatio>0.7){wRSI=0.3;wMACD=0.5;wStoch=0.2;}   // 低波动：侧重MACD
      else{wRSI=0.2;wMACD=0.6;wStoch=0.2;}                     // 极低波动：MACD主导

      // === 融合 ===
      fusionLine[i]=wRSI*rsiSignal+wMACD*macdSignal+wStoch*stochSignal;
      strengthBar[i]=MathAbs(fusionLine[i]); // 信号强度

      // Signal line = EMA of fusion
      double sE=fusionLine[i+5];double aSig=2.0/6;
      for(int j=4;j>=0;j--)sE=fusionLine[i+j]*aSig+sE*(1-aSig);
      signalLine[i]=sE;

      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=2;i--){
      if(fusionLine[i+1]<=signalLine[i+1]&&fusionLine[i]>signalLine[i]&&fusionLine[i]>-30)buySignal[i]=fusionLine[i]-5;
      if(fusionLine[i+1]>=signalLine[i+1]&&fusionLine[i]<signalLine[i]&&fusionLine[i]<30)sellSignal[i]=fusionLine[i]+5;
      // 极端信号直接触发
      if(fusionLine[i+1]<-60&&fusionLine[i]>-60)buySignal[i]=-70;
      if(fusionLine[i+1]>60&&fusionLine[i]<60)sellSignal[i]=70;
   }
   if(Bars>0){fusionLine[0]=fusionLine[1];signalLine[0]=signalLine[1];strengthBar[0]=strengthBar[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
