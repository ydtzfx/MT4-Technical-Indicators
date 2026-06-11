//+------------------------------------------------------------------+
//|                                                    RVI_Safe.mq4   |
//|  相对活力指数（RVI）— 不含未来函数                                |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：Numerator=(C-O)+2*(C1-O1)+2*(C2-O2)+(C3-O3))/6             |
//|        Denominator=(H-L)+2*(H1-L1)+2*(H2-L2)+(H3-L3))/6          |
//|        RVI=EMA(Num,10)/EMA(Den,10), Signal=EMA(RVI,4)             |
//|  与Stochastic类似但更平滑                                          |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 6

input int InpPeriod=10;

double rvi[],signal[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,clrLimeGreen);SetIndexBuffer(0,rvi);SetIndexLabel(0,"RVI");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrRed);SetIndexBuffer(1,signal);SetIndexLabel(1,"Signal");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(4,strongBuy);SetIndexArrow(4,ARROW_BUY);SetIndexLabel(4,"Strong Buy");SetIndexEmptyValue(4,EMPTY_VALUE);
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(5,strongSell);SetIndexArrow(5,ARROW_SELL);SetIndexLabel(5,"Strong Sell");SetIndexEmptyValue(5,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("RVI_Safe("+IntegerToString(InpPeriod)+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpPeriod*3;if(limit<0)limit=0;

   double num[],den[];ArrayResize(num,Bars);ArrayResize(den,Bars);
   for(int i=Bars-4;i>=1;i--){
      double n=0,d=0;double w[]={1,2,2,1};
      for(int j=0;j<4;j++){
         double o=iOpen(_Symbol,_Period,i+j),h=iHigh(_Symbol,_Period,i+j);
         double l=iLow(_Symbol,_Period,i+j),c=iClose(_Symbol,_Period,i+j);
         n+=(c-o)*w[j];d+=(h-l)*w[j];
      }
      num[i]=n/6;den[i]=d/6;
   }
   double a=2.0/(InpPeriod+1);
   double eNum[],eDen[];ArrayResize(eNum,Bars);ArrayResize(eDen,Bars);
   for(int i=Bars-2;i>=1;i--){
      if(i>=Bars-30){eNum[i]=num[i];eDen[i]=den[i];}
      else{eNum[i]=num[i]*a+eNum[i+1]*(1-a);eDen[i]=den[i]*a+eDen[i+1]*(1-a);}
   }
   for(int i=limit;i>=1;i--){rvi[i]=SafeDivide(eNum[i],eDen[i],0);buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;}
   double aS=2.0/5;
   for(int i=limit;i>=1;i--){
      double e=rvi[i+5];for(int j=4;j>=0;j--)e=rvi[i+j]*aS+e*(1-aS);signal[i]=e;
   }
   for(int i=limit;i>=1;i--){
      double gap=MathAbs(rvi[i]-signal[i]);
      bool rviAboveZero=(rvi[i]>0);
      // 强买：零轴上方金叉 + 开口大
      if(rvi[i+1]<=signal[i+1]&&rvi[i]>signal[i]&&rviAboveZero&&gap>0.0002)strongBuy[i]=rvi[i]-0.0002;
      else if(rvi[i+1]<=signal[i+1]&&rvi[i]>signal[i])buySignal[i]=rvi[i]-0.0001;
      // 强卖：零轴下方死叉 + 开口大
      if(rvi[i+1]>=signal[i+1]&&rvi[i]<signal[i]&&!rviAboveZero&&gap>0.0002)strongSell[i]=rvi[i]+0.0002;
      else if(rvi[i+1]>=signal[i+1]&&rvi[i]<signal[i])sellSignal[i]=rvi[i]+0.0001;
   }
   if(Bars>0){rvi[0]=rvi[1];signal[0]=signal[1];buySignal[0]=sellSignal[0]=strongBuy[0]=strongSell[0]=EMPTY_VALUE;}
   return(0);
}
