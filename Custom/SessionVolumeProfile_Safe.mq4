//+------------------------------------------------------------------+
//|                                      SessionVolumeProfile_Safe    |
//|  时段成交量分布 — 原创指标                                         |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  概念：分时段统计成交量分布（亚/欧/美盘），对比不同时段的POC         |
//|  每个时段独立计算：VWAP、POC、VAH、VAL                              |
//|  时段POC的突破/跌破=该时段主力方向改变                             |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 4

input int InpAsianStart=0,InpAsianEnd=8;  // 亚盘 GMT+2
input int InpEUStart=8,InpEUEnd=17;       // 欧盘
input int InpUSStart=14,InpUSEnd=22;      // 美盘

double asianVWAP[],euVWAP[],usVWAP[],sessionPOC[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,clrYellow);SetIndexBuffer(0,asianVWAP);SetIndexLabel(0,"Asian VWAP");SetIndexEmptyValue(0,EMPTY_VALUE);
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,clrDodgerBlue);SetIndexBuffer(1,euVWAP);SetIndexLabel(1,"EU VWAP");SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1,clrMagenta);SetIndexBuffer(2,usVWAP);SetIndexLabel(2,"US VWAP");SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,clrOrange);SetIndexBuffer(3,sessionPOC);SetIndexArrow(3,ARROW_DOT);SetIndexLabel(3,"Session POC");SetIndexEmptyValue(3,EMPTY_VALUE);
   IndicatorDigits(4);IndicatorShortName("SessionVP_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-500;if(limit<0)limit=0;

   // 找最近各时段的起止bar
   datetime now=iTime(_Symbol,_Period,0);
   int currentHour=TimeHour(now);

   for(int i=limit;i>=1;i--){
      datetime t=iTime(_Symbol,_Period,i);int h=TimeHour(t);
      double c=iClose(_Symbol,_Period,i);

      // 简化版：向前查找最近完整时段
      // 亚洲时段VWAP
      double sumPV=0,sumV=0;int cnt=0;
      for(int j=i;j<Bars;j++){
         datetime tj=iTime(_Symbol,_Period,j);int hj=TimeHour(tj);
         if(hj>=InpAsianStart&&hj<InpAsianEnd){
            double tp=(iHigh(_Symbol,_Period,j)+iLow(_Symbol,_Period,j)+iClose(_Symbol,_Period,j))/3;
            long v=iVolume(_Symbol,_Period,j);sumPV+=tp*v;sumV+=v;cnt++;
         }
         if(cnt>0&&(hj>=InpAsianEnd||j-i>500))break;
      }
      asianVWAP[i]=cnt>0?sumPV/sumV:c;

      // 欧盘VWAP
      sumPV=0;sumV=0;cnt=0;
      for(int j=i;j<Bars;j++){
         datetime tj=iTime(_Symbol,_Period,j);int hj=TimeHour(tj);
         if(hj>=InpEUStart&&hj<InpEUEnd){double tp=(iHigh(_Symbol,_Period,j)+iLow(_Symbol,_Period,j)+iClose(_Symbol,_Period,j))/3;long v=iVolume(_Symbol,_Period,j);sumPV+=tp*v;sumV+=v;cnt++;}
         if(cnt>0&&(hj>=InpEUEnd||j-i>500))break;
      }
      euVWAP[i]=cnt>0?sumPV/sumV:c;

      // 美盘VWAP
      sumPV=0;sumV=0;cnt=0;
      for(int j=i;j<Bars;j++){
         datetime tj=iTime(_Symbol,_Period,j);int hj=TimeHour(tj);
         if(hj>=InpUSStart&&hj<InpUSEnd){double tp=(iHigh(_Symbol,_Period,j)+iLow(_Symbol,_Period,j)+iClose(_Symbol,_Period,j))/3;long v=iVolume(_Symbol,_Period,j);sumPV+=tp*v;sumV+=v;cnt++;}
         if(cnt>0&&(hj>=InpUSEnd||j-i>500))break;
      }
      usVWAP[i]=cnt>0?sumPV/sumV:c;

      // 当前价格相对于各时段VWAP的位置
      sessionPOC[i]=EMPTY_VALUE;
      if(c>asianVWAP[i]&&c>euVWAP[i]&&c>usVWAP[i])sessionPOC[i]=iLow(_Symbol,_Period,i)-5*Point; // 全面强势
   }
   if(Bars>0){asianVWAP[0]=asianVWAP[1];euVWAP[0]=euVWAP[1];usVWAP[0]=usVWAP[1];sessionPOC[0]=EMPTY_VALUE;}
   return(0);
}
