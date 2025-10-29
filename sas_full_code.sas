
/* ---  Import Files --- */
filename prod '/home/u64348240/production.xlsx';
filename sale '/home/u64348240/sales.xlsx';
filename cust '/home/u64348240/customers.xlsx';

proc import datafile=prod out=work.production dbms=xlsx replace; sheet='Sheet1'; getnames=yes; run;
proc import datafile=sale out=work.sales dbms=xlsx replace; sheet='Sheet1'; getnames=yes; run;
proc import datafile=cust out=work.customers dbms=xlsx replace; sheet='Sheet1'; getnames=yes; run;

/* ---  Clean Sales Data --- */
data work.sales_clean;
    set work.sales;
    Date = input(Date, yymmdd10.);
    format Date yymmdd10.;
    Region = propcase(strip(Region));
    PromotionFlag = (upcase(Promotion)='Y');
    if UnitsSold < 0 then UnitsSold = .;
    if Revenue < 0 then Revenue = .;
run;

/* --- Clean Production Data & Feature Engineering --- */
data work.production_clean;
    set work.production;
    Timestamp = input(Timestamp, anydtdtm.);
    format Timestamp datetime20.;
    RuntimeHours = input(translate(RuntimeHours, '.', ','), best12.);
    DowntimeMin = input(translate(DowntimeMin, '.', ','), best12.);
    Output = input(translate(Output, '.', ','), best12.);
    if RuntimeHours > 0 then UptimePct = (RuntimeHours*60 - DowntimeMin) / (RuntimeHours*60);
    else UptimePct = .;
    if UptimePct < 0 then UptimePct = .;
    SaleDate = datepart(Timestamp);
    format SaleDate yymmdd10.;
    MachineNum = input(substr(MachineID,2), 8.);
    MachineGroup = catx("-", put(int((MachineNum-1)/20)*20+1,3.), put(int((MachineNum-1)/20)*20+20,3.));
run;

/* ---  Clean Customers Data --- */
data work.customers_clean;
    set work.customers;
    JoinDate = input(JoinDate, ddmmyy10.);
    LastPurchaseDate = input(LastPurchaseDate, ddmmyy10.);
    DaysSinceLastPurchase = today() - LastPurchaseDate;
run;

/* ---  Daily Sales Summary --- */
proc sql;
    create table daily_sales_summary as
    select Date, Region, CustomerID, sum(Revenue) as DailyRevenue, sum(UnitsSold) as DailyUnitsSold
    from work.sales_clean
    group by Date, Region, CustomerID;
quit;

/* --- Prepare Heatmap Data --- */
proc sql;
    create table heatmap_data as
    select a.Region, b.MachineGroup, sum(a.DailyRevenue) as TotalRevenue, mean(b.UptimePct) as AvgUptime
    from daily_sales_summary as a left join work.production_clean as b on a.Date = b.SaleDate
    group by a.Region, b.MachineGroup;
quit;

/* --- Heatmaps Visualization --- */
proc sgplot data=heatmap_data;
    heatmap x=MachineGroup y=Region / colorresponse=TotalRevenue colormodel=(lightblue blue green yellow orange red);
    gradlegend / title="Total Revenue";
    title "Heatmap of Total Revenue per Machine Group & Region";
run;

proc sgplot data=heatmap_data;
    heatmap x=MachineGroup y=Region / colorresponse=AvgUptime colormodel=(red orange yellow green blue);
    gradlegend / title="Average Uptime %";
    title "Heatmap of Machine Uptime per Machine Group & Region";
run;

/* --- Dashboard Summary --- */
proc sql;
    create table dashboard as
    select a.Region, sum(a.DailyRevenue) as TotalRevenue, mean(b.Output) as AvgOutput, mean(b.UptimePct) as AvgUptime, mean(c.TotalSpend) as AvgCustomerSpend
    from daily_sales_summary as a left join work.production_clean as b on a.Date = b.SaleDate
    left join work.customers_clean as c on a.CustomerID = c.CustomerID
    group by a.Region;
quit;

/* --- Dashboard Visualization --- */
proc sgplot data=dashboard; vbar Region / response=TotalRevenue datalabel datalabelattrs=(weight=bold) fillattrs=(color=lightblue); xaxis label="Region"; yaxis label="Total Revenue"; title "Total Revenue by Region"; run;
proc sgplot data=dashboard; vbar Region / response=AvgOutput datalabel datalabelattrs=(weight=bold) fillattrs=(color=orange); xaxis label="Region"; yaxis label="Average Output (units)"; title "Average Output by Region"; run;
proc sgplot data=dashboard; vbar Region / response=AvgUptime datalabel datalabelattrs=(weight=bold) fillattrs=(color=yellow); xaxis label="Region"; yaxis label="Average Uptime %"; title "Average Uptime by Region"; run;
proc sgplot data=dashboard; vbar Region / response=AvgCustomerSpend datalabel datalabelattrs=(weight=bold) fillattrs=(color=green); xaxis label="Region"; title "Average Customer Spend by Region"; run;
proc sgpanel data=dashboard; panelby Region / columns=1 spacing=5; vbarparm category=Region response=TotalRevenue / fillattrs=(color=lightblue); vbarparm category=Region response=AvgOutput / fillattrs=(color=orange); vbarparm category=Region response=AvgUptime / fillattrs=(color=yellow); vbarparm category=Region response=AvgCustomerSpend / fillattrs=(color=green); title "Combined Dashboard Metrics by Region"; run;



/* ---  Outlier Detection  --- */
proc means data=work.production_clean noprint; var Output; output out=stats_output mean=mean_out std=std_out; run;
data work.prod_outliers; 
    if _n_=1 then set stats_output; 
    set work.production_clean; 
    z_output = (Output - mean_out)/std_out; 
    outlier_flag = (abs(z_output) > 3); 
run;
proc freq data=work.prod_outliers; tables outlier_flag; title "Outlier Summary (Output > 3 STD)"; run;

/* --- Customer Clustering  —--*/
proc standard data=work.customers_clean mean=0 std=1 out=work.cust_std; var TotalSpend Frequency DaysSinceLastPurchase; run;

/* **** ( PROC FASTCLUS و VAR) */
proc fastclus data=work.cust_std maxclusters=3 out=work.customers_cluster seed=12345 var TotalSpend Frequency DaysSinceLastPurchase; run;

proc means data=work.customers_cluster; class cluster; var TotalSpend Frequency DaysSinceLastPurchase; title "Customer Cluster Characteristics"; run;

/* ---  Segment Spend VBAR --- */
proc sql; create table segment_spend as select Segment, avg(TotalSpend) as AvgCustomerSpend from work.customers_clean group by Segment; quit;
proc sgplot data=segment_spend; vbar Segment / response=AvgCustomerSpend datalabel fillattrs=(color=CX2CA02C); xaxis label="Customer Segment"; yaxis label="Avg Customer Spend"; title "Average Customer Spend by Segment"; run;

/* ---  Boxplot  --- */
proc sgplot data=work.prod_outliers;
    vbox Output / category=outlier_flag fillattrs=(color=CX00A9E0) lineattrs=(thickness=2 color=black);
    xaxis label="Outlier Flag";
    yaxis label="Output (units)";
    title "Boxplot of Output by Outlier Flag";
run;

/* ---  Streudiagramm  --- */
proc sgplot data=work.prod_outliers;
    scatter x=TemperatureC y=PressureBar / group=outlier_flag;
    xaxis label="Temperature (C)";
    yaxis label="Pressure (Bar)";
    keylegend / title="Outlier Flag";
    title "Scatter Plot: Pressure vs Temperature by Outlier Flag";
run;


