//+------------------------------------------------------------------+
//|                                                    DPO_Safe.mq4   |
//|  去趋势价格振荡器（DPO）— 不含未来函数                             |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：DPO=Price-SMA(Price,N/2+1), 移后N/2+1根bar                 |
//|  去除长期趋势，仅保留短期周期波动                                  |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_level1 0

input int InpPeriod=20;

double dpo[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,2);SetIndexBuffer(0,dpo);SetIndexEmptyValue(0,EMPTY_VALUE);SetIndexLabel(0,"DPO");
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(1,buySignal);SetIndexArrow(1,ARROW_BUY);SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(2,sellSignal);SetIndexArrow(2,ARROW_SELL);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexBuffer(3,strongBuy);SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexArrow(3,233);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexBuffer(4,strongSell);SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexArrow(4,234);SetIndexEmptyValue(4,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("DPO_Safe("+IntegerToString(InpPeriod)+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   int shift=InpPeriod/2+1;if(limit>Bars-2)limit=Bars-InpPeriod*2;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      double s=0;for(int j=shift;j<shift+InpPeriod;j++)s+=iClose(_Symbol,_Period,i+j);
      double sma=s/InpPeriod;dpo[i]=iClose(_Symbol,_Period,i)-sma;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=1;i--){
      if(dpo[i+1]<0&&dpo[i]>0){
         if(dpo[i]>Point*50&&dpo[i+2]<0)strongBuy[i]=dpo[i]-0.0002;
         else buySignal[i]=dpo[i]-0.0001;
      }
      if(dpo[i+1]>0&&dpo[i]<0){
         if(dpo[i]<-Point*50&&dpo[i+2]>0)strongSell[i]=dpo[i]+0.0002;
         else sellSignal[i]=dpo[i]+0.0001;
      }
   }
   if(Bars>0){dpo[0]=dpo[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=EMPTY_VALUE;strongSell[0]=EMPTY_VALUE;}
   return(0);
}
