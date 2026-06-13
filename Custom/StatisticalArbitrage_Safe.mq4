//+------------------------------------------------------------------+
//|                                      StatisticalArbitrage_Safe    |
//|  统计套利信号 — 原创指标                                           |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  概念：用线性回归建立两个品种的关系：Price1 = α + β*Price2 + ε     |
//|  残差ε即为错误定价，回归均值时产生套利机会                         |
//|  ε>2σ→做空品种1/做多品种2，ε<-2σ→做多品种1/做空品种2              |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_minimum -4
#property indicator_maximum 4
#property indicator_level1 2
#property indicator_level2 -2

input string InpHedgeSymbol="EURUSD";input int InpPeriod=50;input int InpHalfLife=10;

double residualZ[],spread[],signalLine[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,residualZ);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Residual Z");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,clrYellow);SetIndexBuffer(1,spread);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Spread");
   SetIndexStyle(2,DRAW_LINE,STYLE_DOT,1,clrGray);SetIndexBuffer(2,signalLine);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexLabel(2,"Signal");
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(3,buySignal);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(4,sellSignal);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);
   IndicatorDigits(2);IndicatorShortName("StatArb_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      // 收集两个品种的对数价格
      double sumX=0,sumY=0,sumXY=0,sumX2=0;int n=0;
      for(int j=0;j<InpPeriod&&(i+j<Bars);j++){
         int b2=iBarShift(InpHedgeSymbol,_Period,iTime(_Symbol,_Period,i+j));
         if(b2>=0){double p1=MathLog(iClose(_Symbol,_Period,i+j)),p2=MathLog(iClose(InpHedgeSymbol,_Period,b2));sumX+=p2;sumY+=p1;sumXY+=p2*p1;sumX2+=p2*p2;n++;}
      }
      if(n<20){residualZ[i]=0;spread[i]=0;}
      else{
         double beta=SafeDivide(n*sumXY-sumX*sumY,n*sumX2-sumX*sumX,0);
         double alpha=SafeDivide(sumY-beta*sumX,n,0);
         int b2Now=iBarShift(InpHedgeSymbol,_Period,iTime(_Symbol,_Period,i));
         double p1Now=MathLog(iClose(_Symbol,_Period,i)),p2Now=b2Now>=0?MathLog(iClose(InpHedgeSymbol,_Period,b2Now)):p1Now;
         spread[i]=p1Now-(alpha+beta*p2Now); // 残差=实际-预测
      }
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   // 残差的ZScore
   for(int i=limit;i>=1;i++){
      double sum=0;for(int j=0;j<InpHalfLife;j++)sum+=spread[i+j];double mean=sum/InpHalfLife;
      double sd=0;for(int j=0;j<InpHalfLife;j++){double d=spread[i+j]-mean;sd+=d*d;}
      sd=MathSqrt(sd/InpHalfLife);residualZ[i]=sd>0?(spread[i]-mean)/sd:0;
      double s=0;for(int j=0;j<5;j++)s+=residualZ[i+j];signalLine[i]=s/5;
   }
   for(int i=limit;i>=2;i--){
      if(residualZ[i+1]<-2&&residualZ[i]>-2)buySignal[i]=-2.5;
      if(residualZ[i+1]>2&&residualZ[i]<2)sellSignal[i]=2.5;
   }
   if(Bars>0){residualZ[0]=residualZ[1];spread[0]=spread[1];signalLine[0]=signalLine[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
