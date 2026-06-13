//+------------------------------------------------------------------+
//|                                                BBIBOLL_Safe.mq4   |
//|  多空布林带（BBI + BOLL）— 不含未来函数                           |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：                                                             |
//|  BBI = (MA3 + MA6 + MA12 + MA24) / 4                               |
//|  Upper = BBI + K * StdDev(BBI_vals, N)                              |
//|  Lower = BBI - K * StdDev(BBI_vals, N)                              |
//|                                                                   |
//|  BBI综合了多条均线，比单一均线更稳定                               |
//|  再加上标准差通道，形成BBI布林带                                   |
//|                                                                   |
//|  信号逻辑（无未来函数）：                                          |
//|  - 买入：价格从下轨下方回升确认(bar[1]) + BBI走平或上翘           |
//|  - 卖出：价格从上轨上方回落确认(bar[1]) + BBI走平或下倾           |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 7

input int    InpBBIPeriod = 11;     // BBI标准差周期
input double InpK = 2.0;            // 宽度倍数
input color  InpBBIColor = clrOrange;   // BBI颜色
input color  InpBandColor = clrRoyalBlue; // 轨线颜色

double bbi[],upper[],lower[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,InpBBIColor);SetIndexBuffer(0,bbi);SetIndexLabel(0,"BBI");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,InpBandColor);SetIndexBuffer(1,upper);SetIndexLabel(1,"Upper");
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1,InpBandColor);SetIndexBuffer(2,lower);SetIndexLabel(2,"Lower");
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(3,buySignal);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(4,sellSignal);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,Cyan);SetIndexBuffer(5,strongBuy);SetIndexArrow(5,ARROW_BUY);SetIndexEmptyValue(5,EMPTY_VALUE);
   SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,4,DeepPink);SetIndexBuffer(6,strongSell);SetIndexArrow(6,ARROW_SELL);SetIndexEmptyValue(6,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("BBIBOLL_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-100;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--) {
      double prices[100];for(int j=0;j<100&&(i+j<Bars);j++)prices[j]=iClose(_Symbol,_Period,i+j);
      double ma3=CalculateMA(prices,3,MA_SMA,0),ma6=CalculateMA(prices,6,MA_SMA,0);
      double ma12=CalculateMA(prices,12,MA_SMA,0),ma24=CalculateMA(prices,24,MA_SMA,0);
      bbi[i]=(ma3+ma6+ma12+ma24)/4.0;
      // 计算BBI值序列的标准差
      double bbiVals[30];for(int j=0;j<InpBBIPeriod;j++){
         double p3=CalculateMA(prices,3,MA_SMA,j),p6=CalculateMA(prices,6,MA_SMA,j);
         double p12=CalculateMA(prices,12,MA_SMA,j),p24=CalculateMA(prices,24,MA_SMA,j);
         bbiVals[j]=(p3+p6+p12+p24)/4.0;
      }
      double sdSum=0;for(int j=0;j<InpBBIPeriod;j++)sdSum+=(bbiVals[j]-bbi[i])*(bbiVals[j]-bbi[i]);
      double stdDev=MathSqrt(sdSum/InpBBIPeriod);
      upper[i]=bbi[i]+InpK*stdDev;lower[i]=bbi[i]-InpK*stdDev;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   // 信号（bar[1]+确认）
   for(int i=limit;i>=1;i--) {
      double c=iClose(_Symbol,_Period,i),c1=iClose(_Symbol,_Period,i+1);
      // 从下轨下方回升+BBI走平或上翘 → 买入
      if(c1<=lower[i+1]&&c>lower[i]&&bbi[i]>=bbi[i+1]) {
         buySignal[i]=iLow(_Symbol,_Period,i)-10*Point;
         // 强化买入：布林带扩展(带宽增大)或BBI明显上翘(>1Point)
         if((upper[i]-lower[i])>(upper[i+1]-lower[i+1])||(bbi[i]-bbi[i+1])>Point)
            strongBuy[i]=buySignal[i];
      }
      // 从上轨上方回落+BBI走平或下倾 → 卖出
      if(c1>=upper[i+1]&&c<upper[i]&&bbi[i]<=bbi[i+1]) {
         sellSignal[i]=iHigh(_Symbol,_Period,i)+10*Point;
         // 强化卖出：布林带扩展(带宽增大)或BBI明显下倾(>1Point)
         if((upper[i]-lower[i])>(upper[i+1]-lower[i+1])||(bbi[i+1]-bbi[i])>Point)
            strongSell[i]=sellSignal[i];
      }
   }
   if(Bars>0){bbi[0]=bbi[1];upper[0]=upper[1];lower[0]=lower[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=strongSell[0]=EMPTY_VALUE;}
   return(0);
}
