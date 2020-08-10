/*
 * The purpose of this macro is to pull out a list of crude measurements for all of the cells in a folder
 * such as the output folder produced by the part1 macros (i.e. images of individual cells). You can use
 * the results list to get the distribution of various measurements across the whole population of your data.
 * We used the results output of this macro to determine the appropriate ratio of puncta intensity vs. mean cell intensity
 * for the part3 analysis.
 */

//Set the measurements
run("Set Measurements...", "area mean standard min shape redirect=None decimal=3");
setBackgroundColor(0,0,0);
setForegroundColor(255,255,255);

//Prompt the user to specify a driectory containing only images of the cells they want to analyse
fPath=getDirectory("Choose a Directory");
fList=getFileList(fPath);
run("Clear Results"); 
updateResults();

//Initialise a series of arrays to store results
meanInt=newArray(lengthOf(fList));
minInt=newArray(lengthOf(fList));
maxInt=newArray(lengthOf(fList));
stdInt=newArray(lengthOf(fList));
meanStd=newArray(lengthOf(fList));
minStd=newArray(lengthOf(fList));
maxStd=newArray(lengthOf(fList));
areaArray=newArray(lengthOf(fList));
ratioArray=newArray(lengthOf(meanInt));


setBatchMode(true);
for (i=0;i<lengthOf(fList);i++){
	if(fList[i]!="results.csv" && fList[i]!="results.xls"){
		open(fPath+fList[i]);
		if(roiManager("Count")>0){
			roiManager("Deselect");
			roiManager("Delete");
		}
		roiManager("Add");
		//the image should load with an ROI overlay which can be added as an ROI, then measured
		roiManager("Select",0);
		run("Measure");

		//Pull the results from the results table into the arrays
		areaArray[i]=getResult("Area",nResults-1);
		meanInt[i]=getResult("Mean",nResults-1);
		minInt[i]=getResult("Min",nResults-1);
		maxInt[i]=getResult("Max",nResults-1);
		stdInt[i]=getResult("StdDev",nResults-1);
		ratioArray[i]=getResult("Max",nResults-1)/getResult("Mean",nResults-1);
		minStd[i]=getResult("Min",nResults-1);
		meanStd[i]=getResult("Mean",nResults-1);
		maxStd[i]=getResult("Max",nResults-1);
		run("Close All");
	}
}
run("Clear Results"); 
updateResults();

//Make a new results table containing *everything*, and save it to a csv file
for (i=0;i<lengthOf(fList);i++){
	setResult("Filename",nResults,fList[i]);
	setResult("Area",nResults-1,areaArray[i]);
	setResult("Mean",nResults-1,meanInt[i]);
	setResult("Max",nResults-1,maxInt[i]);
	setResult("Min",nResults-1,minInt[i]);
	setResult("StdDev",nResults-1,stdInt[i]);
	setResult("Ratio",nResults-1,ratioArray[i]);
	setResult("MeanStd",nResults-1,meanStd[i]);
	setResult("MaxStd",nResults-1,maxStd[i]);
	setResult("MinStd",nResults-1,minStd[i]);
	
}
saveAs("Results",fPath+"results.csv");
	
	