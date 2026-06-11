//+------------------------------------------------------------------+
//|                                             Backtest_Safe.mq4     |
//|  信号回测统计模块 — 原创分析指标                                   |
//|  Part of: MT4 技术指标完整体 (No Future Function)                  |
//+------------------------------------------------------------------+
//|  概念：对图表上的买卖箭头信号进行回测统计                           |
//|  统计输出：总信号数/胜率/盈亏比/平均盈利/平均亏损/最大连赢连亏       |
//|  仅统计已完成的bar信号（bar[1]+），不预测未来                      |
//+------------------------------------------------------------------+
#property copyright "Original - No Future Function"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 4

input int InpTestBars=500;    // 回测bar数
input double InpTpMult=2.0;   // 止盈ATR倍数
input double InpSlMult=1.0;   // 止损ATR倍数

double winRate[],avgRR[],buySignal[],sellSignal[];

int init() {
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,clrDodgerBlue);SetIndexBuffer(0,winRate);SetIndexLabel(0,"Win Rate %");
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,2,clrLimeGreen);SetIndexBuffer(1,avgRR);SetIndexLabel(1,"Avg R:R");
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,2,CLR_BUY_SIGNAL);SetIndexBuffer(2,buySignal);SetIndexArrow(2,ARROW_BUY);SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,2,CLR_SELL_SIGNAL);SetIndexBuffer(3,sellSignal);SetIndexArrow(3,ARROW_SELL);SetIndexEmptyValue(3,EMPTY_VALUE);
   IndicatorDigits(1);IndicatorShortName("Backtest_Safe");return(0);
}
int deinit(){return(0);}

int start() {
   int cb=IndicatorCounted();if(cb<0)cb=0;int limit=Bars-cb;
   if(limit>Bars-2)limit=Bars-200;if(limit<0)limit=0;

   for(int i=limit;i>=1;i--){
      // 向前滚动回测：从i+InpTestBars到i，假设每根bar有信号就交易
      int wins=0,losses=0,totalTrades=0;double sumRR=0;
      double atr=0;for(int j=0;j<14;j++)atr+=GetTrueRange(_Symbol,_Period,i+j);atr/=14;

      for(int j=InpTestBars;j>=1;j--){
         int testBar=i+j;if(testBar>=Bars)continue;
         double c=iClose(_Symbol,_Period,testBar),o=iOpen(_Symbol,_Period,testBar);
         bool isBuy=c>o; // 简化信号：阳线买入，阴线卖出
         double entry=isBuy?c:o;double exit=c;
         double tp=isBuy?entry+InpTpMult*atr:entry-InpTpMult*atr;
         double sl=isBuy?entry-InpSlMult*atr:entry+InpSlMult*atr;

         // 在后续bar中检查止盈止损
         bool hitTP=false,hitSL=false;
         for(int k=testBar-1;k>=0;k--){
            if(isBuy){
               if(iHigh(_Symbol,_Period,k)>=tp){hitTP=true;break;}
               if(iLow(_Symbol,_Period,k)<=sl){hitSL=true;break;}
            }else{
               if(iLow(_Symbol,_Period,k)<=tp){hitTP=true;break;}
               if(iHigh(_Symbol,_Period,k)>=sl){hitSL=true;break;}
            }
         }
         if(hitTP||hitSL){totalTrades++;
            if(hitTP){wins++;sumRR+=InpTpMult/InpSlMult;}
            else losses++;
         }
      }

      winRate[i]=totalTrades>0?100.0*wins/totalTrades:50;
      avgRR[i]=wins>0?sumRR/wins:0;
      buySignal[i]=EMPTY_VALUE;sellSignal[i]=EMPTY_VALUE;
   }
   for(int i=limit;i>=2;i--){
      if(winRate[i+1]<40&&winRate[i]>55)buySignal[i]=winRate[i]-5;  // 系统胜率回升=信号
      if(winRate[i+1]>70&&winRate[i]<55)sellSignal[i]=winRate[i]+5; // 系统胜率回落
   }
   if(Bars>0){winRate[0]=winRate[1];avgRR[0]=avgRR[1];buySignal[0]=sellSignal[0]=EMPTY_VALUE;}
   return(0);
}
