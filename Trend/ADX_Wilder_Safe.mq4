//+------------------------------------------------------------------+
//|                                            ADX_Wilder_Safe.mq4    |
//|  经典Wilder ADX — 不含未来函数                                    |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  Welles Wilder原始ADX公式：使用SMMA而非EMA                         |
//+------------------------------------------------------------------+
#property copyright "Open Source - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 7
#property indicator_minimum 0
#property indicator_maximum 100

input int InpPeriod=14;

double adx[],pdi[],mdi[],buySignal[],sellSignal[],strongBuy[],strongSell[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrYellow);SetIndexBuffer(0,adx);SetIndexLabel(0,"ADX");
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,clrLimeGreen);SetIndexBuffer(1,pdi);SetIndexLabel(1,"+DI");
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1,clrTomato);SetIndexBuffer(2,mdi);SetIndexLabel(2,"-DI");
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(3,buySignal);SetIndexArrow(3,ARROW_BUY);SetIndexEmptyValue(3,EMPTY_VALUE);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(4,sellSignal);SetIndexArrow(4,ARROW_SELL);SetIndexEmptyValue(4,EMPTY_VALUE);
   SetIndexBuffer(5,strongBuy);SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,4,clrCyan);SetIndexArrow(5,233);SetIndexEmptyValue(5,EMPTY_VALUE);
   SetIndexBuffer(6,strongSell);SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,4,clrDeepPink);SetIndexArrow(6,234);SetIndexEmptyValue(6,EMPTY_VALUE);
   IndicatorDigits(1);IndicatorShortName("ADX_Wilder");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-InpPeriod*3;if(limit<0)limit=0;

   double tr[],pdm[],mdm[],atr[],pdiRaw[],mdiRaw[],dx[];
   ArrayResize(tr,Bars);ArrayResize(pdm,Bars);ArrayResize(mdm,Bars);ArrayResize(atr,Bars);
   ArrayResize(pdiRaw,Bars);ArrayResize(mdiRaw,Bars);ArrayResize(dx,Bars);

   for(int i=Bars-2;i>=1;i--){
      double h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i),pc=iClose(_Symbol,_Period,i+1);
      tr[i]=MathMax(h-l,MathMax(MathAbs(h-pc),MathAbs(l-pc)));
      double ph=iHigh(_Symbol,_Period,i+1),pl=iLow(_Symbol,_Period,i+1);
      double up=h-ph,dn=pl-l;pdm[i]=(up>dn&&up>0)?up:0;mdm[i]=(dn>up&&dn>0)?dn:0;
   }
   // Wilder SMMA
   for(int i=Bars-InpPeriod-1;i>=1;i--){
      if(i>=Bars-InpPeriod-2){double s=0;for(int j=0;j<InpPeriod;j++)s+=tr[i+j];atr[i]=s/InpPeriod;s=0;for(int j=0;j<InpPeriod;j++)s+=pdm[i+j];pdiRaw[i]=s/InpPeriod;s=0;for(int j=0;j<InpPeriod;j++)s+=mdm[i+j];mdiRaw[i]=s/InpPeriod;}
      else{atr[i]=(atr[i+1]*(InpPeriod-1)+tr[i])/InpPeriod;pdiRaw[i]=(pdiRaw[i+1]*(InpPeriod-1)+pdm[i])/InpPeriod;mdiRaw[i]=(mdiRaw[i+1]*(InpPeriod-1)+mdm[i])/InpPeriod;}
      pdi[i]=SafeDivide(100*pdiRaw[i],atr[i],0);mdi[i]=SafeDivide(100*mdiRaw[i],atr[i],0);
      double dxi=SafeDivide(100*MathAbs(pdi[i]-mdi[i]),pdi[i]+mdi[i],0);dx[i]=dxi;
   }
   // ADX = SMMA of DX
   for(int i=Bars-InpPeriod*2-1;i>=1;i--){
      if(i>=Bars-InpPeriod*2-2){double s=0;for(int j=0;j<InpPeriod;j++)s+=dx[i+j];adx[i]=s/InpPeriod;}
      else adx[i]=(adx[i+1]*(InpPeriod-1)+dx[i])/InpPeriod;
      if(i<=limit){buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;}
   }
   for(int i=limit;i>=1;i--){
      strongBuy[i]=EMPTY_VALUE;strongSell[i]=EMPTY_VALUE;
      // Strong buy: pDI cross above mDI + ADX>20 + ADX rising + ADX>25
      if(pdi[i+1]<=mdi[i+1]&&pdi[i]>mdi[i]&&adx[i]>20&&adx[i]>adx[i+1]&&adx[i]>25)strongBuy[i]=10;
      // Strong sell: mDI cross above pDI + ADX>20 + ADX rising + ADX>25
      if(mdi[i+1]<=pdi[i+1]&&mdi[i]>pdi[i]&&adx[i]>20&&adx[i]>adx[i+1]&&adx[i]>25)strongSell[i]=90;
      // Normal buy (multi-condition — strong must be checked before normal)
      if(pdi[i+1]<=mdi[i+1]&&pdi[i]>mdi[i]&&adx[i]>20)buySignal[i]=10;
      // Normal sell
      if(mdi[i+1]<=pdi[i+1]&&mdi[i]>pdi[i]&&adx[i]>20)sellSignal[i]=90;
   }
   if(Bars>0){adx[0]=adx[1];pdi[0]=pdi[1];mdi[0]=mdi[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;strongBuy[0]=EMPTY_VALUE;strongSell[0]=EMPTY_VALUE;}
   return(0);
}
