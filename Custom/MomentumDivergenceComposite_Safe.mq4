//+------------------------------------------------------------------+
//|                                MomentumDivergenceComposite_Safe   |
//|  多周期动量背离复合 — 原创指标                                     |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  创新：同时在三个时间维度检测动量+背离                              |
//|  - 短周期(5bar)：捕捉即时背离                                       |
//|  - 中周期(20bar)：确认中期方向                                      |
//|  - 长周期(50bar)：过滤大势                                          |
//|  计算多周期背离共振得分：背离周期越多、越同步=信号越强              |
//+------------------------------------------------------------------+
#property copyright "Original Composite - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_minimum -100
#property indicator_maximum 100
#property indicator_level1 60
#property indicator_level2 -60

input int InpShort=5,InpMid=20,InpLong=50;

double composite[],shortDiv[],midDiv[],longDiv[],signal[];

int init() {
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);SetIndexBuffer(0,composite);SetIndexLabel(0,"MDC");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,clrYellow);SetIndexBuffer(1,shortDiv);SetIndexLabel(1,"Short("+IntegerToString(InpShort)+")");
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1,clrOrange);SetIndexBuffer(2,midDiv);SetIndexLabel(2,"Mid("+IntegerToString(InpMid)+")");
   SetIndexStyle(3,DRAW_LINE,STYLE_SOLID,1,clrMagenta);SetIndexBuffer(3,longDiv);SetIndexLabel(3,"Long("+IntegerToString(InpLong)+")");
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,3,clrYellow);SetIndexBuffer(4,signal);SetIndexLabel(4,"Resonance Signal");SetIndexEmptyValue(4,EMPTY_VALUE);
   IndicatorDigits(0);IndicatorShortName("MDC_Safe");return(0);
}
int deinit(){return(0);}

// 计算动量背离得分：价格[i] vs 价格[i+period]的ROC与动量对比
double CalcMomentumDivergence(int period,int bar){
   double priceNow=iClose(_Symbol,_Period,bar),pricePast=iClose(_Symbol,_Period,bar+period);
   double priceROC=pricePast>0?100*(priceNow-pricePast)/pricePast:0;
   // 找周期内的最高价和对应的价格ROC
   double hh=priceNow;for(int j=1;j<=period/2;j++){double h=iHigh(_Symbol,_Period,bar+j);if(h>hh)hh=h;}
   // 背离：价格创新高但ROC下降=顶背离(负分)，价格创新低但ROC上升=底背离(正分)
   double score=0;
   if(priceROC>0&&priceNow>=hh*0.995)score=-50; // 顶背离风险
   else if(priceROC<0&&priceNow<=hh*0.9)score=50; // 底背离机会
   return score;
}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpLong*2;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      shortDiv[i]=CalcMomentumDivergence(InpShort,i);
      midDiv[i]=CalcMomentumDivergence(InpMid,i);
      longDiv[i]=CalcMomentumDivergence(InpLong,i);
      // 三周期共振加权：短周期权重最高（反应最快）
      composite[i]=0.5*shortDiv[i]+0.3*midDiv[i]+0.2*longDiv[i];
      signal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=2;i--){
      // 三周期同时从负转正 = 强烈底背离共振买入
      if(shortDiv[i+1]<=0&&shortDiv[i]>0&&midDiv[i]>0&&longDiv[i]>0)signal[i]=-70;
      // 三周期同时从正转负 = 强烈顶背离共振卖出
      if(shortDiv[i+1]>=0&&shortDiv[i]<0&&midDiv[i]<0&&longDiv[i]<0)signal[i]=70;
      // 单周期超强信号
      if(composite[i+1]<-60&&composite[i]>-60)signal[i]=-70;
      if(composite[i+1]>60&&composite[i]<60)signal[i]=70;
   }
   if(Bars>0){composite[0]=composite[1];shortDiv[0]=shortDiv[1];midDiv[0]=midDiv[1];longDiv[0]=longDiv[1];signal[0]=EMPTY_VALUE;}
   return(0);
}
