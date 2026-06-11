//+------------------------------------------------------------------+
//|                                              Vortex_Safe.mq4      |
//|  漩涡指标（Vortex Indicator）— 不含未来函数                       |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  公式：VM+ = Σ|H-L_prev| / ΣTR, VM- = Σ|L-H_prev| / ΣTR           |
//|  VM+ > VM- = 上升趋势, VM+ < VM- = 下降趋势                       |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property link      ""
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 4

input int InpPeriod=14;

double vmp[],vmm[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrLimeGreen);SetIndexBuffer(0,vmp);SetIndexLabel(0,"VM+");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2,clrTomato);SetIndexBuffer(1,vmm);SetIndexLabel(1,"VM-");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("Vortex_Safe("+IntegerToString(InpPeriod)+")");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpPeriod*3;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--) {
      double sumVMp=0,sumVMm=0,sumTR=0;
      for(int j=0;j<InpPeriod;j++) {
         double h=iHigh(_Symbol,_Period,i+j),l=iLow(_Symbol,_Period,i+j);
         double ph=iHigh(_Symbol,_Period,i+j+1),pl=iLow(_Symbol,_Period,i+j+1),pc=iClose(_Symbol,_Period,i+j+1);
         sumVMp+=MathAbs(h-pl);sumVMm+=MathAbs(l-ph);
         sumTR+=MathMax(h-l,MathMax(MathAbs(h-pc),MathAbs(l-pc)));
      }
      vmp[i]=SafeDivide(sumVMp,sumTR,0);vmm[i]=SafeDivide(sumVMm,sumTR,0);
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=1;i--) {
      if(vmp[i+1]<=vmm[i+1]&&vmp[i]>vmm[i])buySignal[i]=vmp[i]*0.9;
      if(vmp[i+1]>=vmm[i+1]&&vmp[i]<vmm[i])sellSignal[i]=vmp[i]*1.1;
   }
   if(Bars>0){vmp[0]=vmp[1];vmm[0]=vmm[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
