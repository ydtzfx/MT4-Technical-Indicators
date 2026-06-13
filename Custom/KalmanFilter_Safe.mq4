//+------------------------------------------------------------------+
//|                                           KalmanFilter_Safe.mq4   |
//|  卡尔曼滤波器 — 信号处理指标                                      |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：x̂_k = x̂_{k-1} + K_k * (z_k - x̂_{k-1})                    |
//|  K_k = P_{k-1} / (P_{k-1} + R), P_k = (1-K_k)*P_{k-1} + Q        |
//|  过程噪声Q和观测噪声R自适应：波动大→增大Q（更灵敏），波动小→减小Q  |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5

input double InpQ=0.01;    // 过程噪声(自适应基础值)
input double InpR=0.1;     // 观测噪声

double kf[],upper[],lower[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,kf);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Kalman");
   SetIndexStyle(1,DRAW_LINE,STYLE_DOT,1,clrLimeGreen);SetIndexBuffer(1,upper);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"KF+σ");
   SetIndexStyle(2,DRAW_LINE,STYLE_DOT,1,clrTomato);SetIndexBuffer(2,lower);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexLabel(2,"KF-σ");
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(3,buySignal);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(4,sellSignal);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("Kalman_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-300;if(limit<0)limit=0;

   double xHat=0,P=1; // 初始状态
   for(int i=limit+200;i>=1;i--){
      double z=iClose(_Symbol,_Period,i); // 观测值
      if(i>=limit+199){xHat=z;P=1;}
      else{
         // 自适应Q：波动大时增大过程噪声
         double atr=0;for(int j=0;j<5;j++)atr+=GetTrueRange(_Symbol,_Period,i+j);atr/=5;
         double longATR=0;for(int j=0;j<50;j++)longATR+=GetTrueRange(_Symbol,_Period,i+j);longATR/=50;
         double qAdapt=InpQ*MathMax(0.5,MathMin(3.0,atr/longATR));

         // 预测
         double xPred=xHat; // 假设价格不变（随机游走先验）
         double pPred=P+qAdapt;

         // 更新
         double K=pPred/(pPred+InpR);
         xHat=xPred+K*(z-xPred);
         P=(1-K)*pPred;
      }
      if(i<=limit){
         double sigma=MathSqrt(P);
         kf[i]=xHat;upper[i]=xHat+2*sigma;lower[i]=xHat-2*sigma;
         buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
      }
   }
   for(int i=limit;i>=2;i--){
      double c=iClose(_Symbol,_Period,i),c1=iClose(_Symbol,_Period,i+1);
      if(c1<=lower[i+1]&&c>lower[i])buySignal[i]=iLow(_Symbol,_Period,i)-5*Point;
      if(c1>=upper[i+1]&&c<upper[i])sellSignal[i]=iHigh(_Symbol,_Period,i)+5*Point;
      if(c1<=kf[i+1]&&c>kf[i]&&kf[i]>kf[i+1])buySignal[i]=iLow(_Symbol,_Period,i)-8*Point;
   }
   if(Bars>0){kf[0]=kf[1];upper[0]=upper[1];lower[0]=lower[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
