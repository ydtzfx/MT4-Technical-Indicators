#include "../Include/Common.mqh"
//+------------------------------------------------------------------+
//|                                        EntropyIndicator_Safe.mq4  |
//|  信息熵指标（Shannon Entropy）— 信息论指标                         |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：H = -Σ(p_i * log₂(p_i))，p_i为价格变化在各区间的概率        |
//|  高熵=市场无序/盘整，低熵=市场有序/趋势                            |
//|  熵值突变（从高到低）=盘整结束→趋势启动                           |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 7
#property indicator_level1 2.5

input int InpPeriod=20;input int InpBins=8; // 价格变化分桶数

double entropy[],smoothEntropy[],change[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,entropy);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"Entropy");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,clrYellow);SetIndexBuffer(1,smoothEntropy);SetIndexEmptyValue(1,EMPTY_VALUE);SetIndexLabel(1,"Smooth");
   SetIndexStyle(2,DRAW_HISTOGRAM,STYLE_SOLID,1);SetIndexBuffer(2,change);SetIndexEmptyValue(2,EMPTY_VALUE);SetIndexLabel(2,"ΔEntropy");
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(3,buySignal);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(4,sellSignal);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);
	   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexBuffer(5,strongBuy);SetIndexArrow(5,ARROW_BUY);SetIndexEmptyValue(5,EMPTY_VALUE);
	   SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexBuffer(6,strongSell);SetIndexArrow(6,ARROW_SELL);SetIndexEmptyValue(6,EMPTY_VALUE);
   IndicatorDigits(3);IndicatorShortName("Entropy_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      // 收集价格变化
      double changes[];ArrayResize(changes,InpPeriod);double maxC=0,minC=99999;
      for(int j=0;j<InpPeriod;j++){changes[j]=iClose(_Symbol,_Period,i+j)-iClose(_Symbol,_Period,i+j+1);double ac=MathAbs(changes[j]);if(ac>maxC)maxC=ac;if(ac<minC)minC=ac;}

      // 分桶统计概率
      double bins[];ArrayResize(bins,InpBins);ArrayInitialize(bins,0);
      double binWidth=(maxC-minC)/InpBins;if(binWidth<Point)binWidth=Point;
      for(int jj=0;j<InpPeriod;j++){
         int b=(int)((changes[j]-minC)/binWidth);b=MathMax(0,MathMin(InpBins-1,b));bins[b]++;
      }

      // 计算香农熵
      double H=0;for(b=0;b<InpBins;b++){if(bins[b]>0){double p=bins[b]/InpPeriod;H-=p*MathLog(p)/MathLog(2);}}
      entropy[i]=H;change[i]=entropy[i+1]-entropy[i]; // 正=熵下降（有序化）
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   for(i=limit;i>=1;i++){double s=0;for(int jjj=0;j<5;j++)s+=entropy[i+j];smoothEntropy[i]=s/5;}

   for(i=limit;i>=3;i--){
      // 熵从高位骤降 = 市场从无序进入有序 → 跟趋势
      if(entropy[i+2]>2.5&&entropy[i]<1.8&&iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+3))buySignal[i]=entropy[i]-0.2;
      if(entropy[i+2]>2.5&&entropy[i]<1.8&&iClose(_Symbol,_Period,i)<iClose(_Symbol,_Period,i+3))sellSignal[i]=entropy[i]+0.2;
      // 熵从低位急升 = 趋势结束进入混沌
      if(entropy[i+1]<1.5&&entropy[i]>2.2)sellSignal[i]=entropy[i]+0.2;
      // Strong: base buy + change>0(ordering) + deeper threshold(tighter order)
      if(entropy[i+2]>2.5&&entropy[i]<1.8&&iClose(_Symbol,_Period,i)>iClose(_Symbol,_Period,i+3)&&change[i]>0&&entropy[i]<1.5)strongBuy[i]=entropy[i]-0.3;
      // Strong: base sell(trend) + change>0 + deeper threshold
      if(entropy[i+2]>2.5&&entropy[i]<1.8&&iClose(_Symbol,_Period,i)<iClose(_Symbol,_Period,i+3)&&change[i]>0&&entropy[i]<1.5)strongSell[i]=entropy[i]+0.3;
      // Strong: base sell(trend-end) + change<0(entropy rising) + price declining
      if(entropy[i+1]<1.5&&entropy[i]>2.2&&change[i]<0&&iClose(_Symbol,_Period,i)<iClose(_Symbol,_Period,i+2))strongSell[i]=entropy[i]+0.3;
   }
   if(Bars>0){entropy[0]=entropy[1];smoothEntropy[0]=smoothEntropy[1];change[0]=change[1];buySignal[0]=sellSignal[0]=strongBuy[0]=strongSell[0]=EMPTY_VALUE;}
   return(0);
}
