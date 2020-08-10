/*
 * 
 * 
 * 
 */

//Set easurements and bg/fg colours

setBatchMode(true);
run("Set Measurements...", "area mean standard min shape integrated redirect=None decimal=3");
setBackgroundColor(0,0,0);
setForegroundColor(255,255,255);

//Prompt the user to select a folder containing images of cells produced by the part1 macros
fPath=getDirectory("Choose a Directory");
fList=getFileList(fPath);
run("Clear Results"); 
updateResults();

//Prepare arrays to store results, and directories to store outputs
File.makeDirectory(fPath+"cell_output/");
countArray=newArray(lengthOf(fList));
cellAreaArray=newArray(lengthOf(fList));
cellMeanArray=newArray(lengthOf(fList));
ORB_propArray=newArray(lengthOf(fList));
ORB_intArray=newArray(lengthOf(fList));
cellIntArray= newArray(lengthOf(fList));
cellAreaArray_ORBs=newArray(0);
cellMeanArray_ORBs=newArray(0);
meanInt=newArray(lengthOf(fList));
volumeArray=newArray(0);
meanArray=newArray(0);
maxArray=newArray(0);
nameArray=newArray(0);
circArray=newArray(0);

//For every file in the folder
for (i=0;i<lengthOf(fList);i++){
	namePart=substring(fList[i],lengthOf(fList[i])-4,lengthOf(fList[i]));
	//if it's not a csv file or the output folder
	if(namePart!=".csv" && fList[i]!="cell_output/"){
		
		if(roiManager("Count")>0){
			roiManager("Deselect");
			roiManager("Delete");
		}
		//open the image and initialise the ROI from the overlay
		open(fPath+fList[i]);
		roiManager("Add");
		roiManager("Select",0);

		//measure the basic info about the cell
		run("Clear Outside");
		run("Measure");
		meanInt[i]=getResult("Mean",nResults-1);
		cellMeanArray[i]=getResult("Mean",nResults-1);
		cellAreaArray[i]=getResult("Area",nResults-1);
		cellIntArray[i]=getResult("RawIntDen",nResults-1);
		run("Clear Results"); 
		updateResults();
		selectWindow(fList[i]);
		w=getWidth();
		h=getHeight();
		nS=nSlices;
		if (nS<2){
			nS=2;
		}
		threshMult=1.5; //**********change this value to change the multiplier!*********
		roiManager("Select",0);
		roiManager("Delete");

		//set the slice to the middle focal plane (or the first, if there's only one)
		setSlice(floor(nS/2));

		//As long as the mean intensity of the cell is low enough that ORBs can be detected
		// without being saturated (i.e. >65535), then the cell can be analysed
		if (meanInt[i]*threshMult<65535){
			print(fList[i]);
			//Find all the objects between 9 and 198 pixels in size that are 1.5* the mean intensity of the cell
			//and measure them
			run("Duplicate..."," ");
			setThreshold(meanInt[i]*threshMult, 65535);
			run("Convert to Mask");
			saveAs("tiff",fPath+"cell_output/obj_"+fList[i]);
			run("Analyze Particles...", "size=9-198 pixel clear include add");
			selectWindow(fList[i]);
			roiManager("Measure");
			
		}

		//if the mean intensity is too high, don't analyse the cell
		else{
			print(fList[i], "Threshold too high to detect ORBs");
		}

		
		countArray[i]=nResults; //this can be 0, if the mean intensity is too high, or no objects brighter than 1.5*
		//the mean intensity of the cell have been found
		volumeTemp=newArray(nResults);
		meanTemp=newArray(nResults);
		maxTemp=newArray(nResults);
		nameTemp=newArray(nResults);
		circTemp=newArray(nResults);
		cellAreaArrayTemp=newArray(nResults);
		cellMeanArrayTemp=newArray(nResults);
		ORB_propArray[i]=0;
		ORB_intArray [i] = 0;
		for (q=0;q<nResults;q++){ //for each orb in the image, pull out some measurements
			nameTemp[q]=fList[i];
			volumeTemp[q]=getResult("Area",q);
			meanTemp[q]=getResult("Mean",q);
			maxTemp[q]=getResult("Max",q);
			circTemp[q]=getResult("Circ.",q);
			cellAreaArrayTemp[q]=cellAreaArray[i];
			cellMeanArrayTemp[q]=cellMeanArray[i];
			ORB_propArray[i] = ORB_propArray[i]+getResult("Area",q);
			ORB_intArray[i] = ORB_intArray[i]+getResult("RawIntDen",q);
		}

		//add those measurements to the arrays that contain that data
		nameArray=Array.concat(nameArray,nameTemp);
		circArray=Array.concat(circArray,circTemp);
		volumeArray=Array.concat(volumeArray,volumeTemp);
		meanArray=Array.concat(meanArray,meanTemp);
		cellMeanArray_ORBs=Array.concat(cellMeanArray_ORBs,cellMeanArrayTemp);
		cellAreaArray_ORBs=Array.concat(cellAreaArray_ORBs,cellAreaArrayTemp);
		maxArray=Array.concat(maxArray,maxTemp);
		run("Close All");
	}
}
run("Clear Results"); 
updateResults();

//for every cell, save the data about orbs within it
for (i=0;i<lengthOf(fList);i++){
	setResult("Filename",nResults,fList[i]);
	setResult("Count",nResults-1,countArray[i]);	
	setResult("Area",nResults-1,cellAreaArray[i]);
	setResult("ORB Proportion",nResults-1,ORB_propArray[i]/cellAreaArray[i]);	
	setResult("Cell Full Signal", nResults-1, cellIntArray[i]);
	setResult("ORB Full Signal", nResults-1, ORB_intArray[i]);
	setResult("ORB Signal Proportion",nResults-1,ORB_intArray[i]/cellIntArray[i]);
}
saveAs("Results",fPath+"cell_output/count_results.csv");
	
run("Clear Results"); 
updateResults();

//for every ORB, save the data describing it, and some data about the cell containing it
for (i=0;i<lengthOf(nameArray);i++){
	setResult("Filename",nResults,nameArray[i]);
	setResult("Area",nResults-1,volumeArray[i]);
	setResult("Mean",nResults-1,meanArray[i]);
	setResult("Max",nResults-1,maxArray[i]);	
	setResult("Circ.",nResults-1,circArray[i]);
	setResult("Cell Mean",nResults-1,cellMeanArray_ORBs[i]);
	setResult("Cell Area",nResults-1,cellAreaArray_ORBs[i]);
	setResult("ORB Proportion",nResults-1,volumeArray[i]/cellAreaArray_ORBs[i]);
}
saveAs("Results",fPath+"cell_output/size_results.csv");
		
