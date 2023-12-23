/******************
Input: crp.sav
Output: SAS-Normality_Test_crp.pdf
Written by:Tingwei Adeck
Date: Sep 28 2022
Description: Normality Tests in SAS
Requirements: Need library called project, crp.sav.
Dataset description: Data obtained from Dr. Gaddis (small dataset)
******************/

/*DATA models (The way to read files when working locally, notice I am working on the SAS cloud)
INFILE 'c:\MyRawData\Models.dat' TRUNCOVER;
INPUT Model $ 1-12 Class $ Price Frame $ 28-38;
RUN;*/


%let path=/home/u40967678/sasuser.v94;


libname project
    "&path/sas_umkc/input";

/*FILENAME REFFILE '/home/u40967678/sasuser.v94/sas_umkc/src/chol.csv'*/
filename crp
    "&path/sas_umkc/input/crp.sav";
    
ods pdf file=
    "&path/sas_umkc/output/SAS-Normality_Test_crp.pdf";
    
options papersize=(8in 4in) nonumber nodate;


/* Assuming items are separated by a space */
/*%let data_list = %str(glucose cholesterol);*/

proc import file= crp
    out=project.crp
	dbms=sav
	replace;
run;

proc univariate data=project.crp normal;
    histogram Baseline_CRP / normal;
run;

/*normalize the dataset is different from transforming the dataset*/
proc stdize data=project.crp out=project.crp_normalized;
   var Baseline_CRP;
run;

/*get the mean and stdev of the normalized data*/
proc means data=project.crp_normalized Mean StdDev ndec=2; 
   var Baseline_CRP;
run;

/*normality of normalized data should not change from the original data but it should reveal skewness and kurtosis clearer*/
proc univariate data=project.crp_normalized normal;
    histogram Baseline_CRP / normal;
run;

data project.crp_transformed;
    set project.crp;
    Log_Baseline_CRP = log(Baseline_CRP);
    Log_CRP_6WK = log(CRP_6WK);
run;

proc print data=project.crp_transformed;

proc stdize data=project.crp_transformed out=project.crp_transformed_normalized;
   var Baseline_CRP;
run;

/*test for normality of transformed normalized data,Shapiro-Wilk test shows normality with p > 0.05*/
proc univariate data=project.crp_transformed_normalized normal;
    histogram Log_Baseline_CRP / normal;
run;

proc means data= project.crp_transformed_normalized skewness kurtosis;
run;

/*Bootstrapping in SAS is a little complicated but easily achieved in SPSS*/

data project.crp_boots;
    set project.crp_transformed;
run;

proc surveyselect data=project.crp_boots out=project.outboot
seed=30459584
method=urs /* specify the type of random sampling */
samprate=100 /* get a sample of the same size as
our original data set */
outhits /*give the times a record chosen*/
rep=1000; /* specify the number of bootstrap samples
that we want */
run;

proc univariate data=project.outboot;
var Baseline_CRP;
by Replicate;
output out=project.outall kurtosis=curt; /* ODS does the same thing*/
run;


ods pdf close;