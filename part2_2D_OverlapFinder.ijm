/*
 * The purpose of this macro is to take cells that have been pulled from images using part1_cellFinder_2channel
 * and find Objects in each channel, then calculate if they are overlapping. 
 * 
 */

fPath = getDirectory("Choose a Directory");
fList=getFileList(fPath); //find a list of every file in the folder
File.makeDirectory(fPath+"coloc_Results"); //make a directory to store results
run("Clear Results"); //clear previous results
updateResults(); //clear results
run("Set Measurements...", "area mean integrated redirect=None decimal=3");
setBackgroundColor(0,0,0);
setForegroundColor(255,255,255);


//make a dialog to allow user to set some options
Dialog.create("Options"); //off the following options:
Dialog.addRadioButtonGroup("Foreground Colour: ", newArray("White","Black"), 1, 2, "Black");
Dialog.addCheckbox("Subtract Background?: ", false); 
Dialog.addNumber("Mutual Overlap % Required: ", 25); //How much objects have to overlap to be considered as overlapping
Dialog.addNumber("Threshold ratio (vs. mean intensity): ", 1.5); //this is the same as that used to delineate ORBs
Dialog.show();
bgSub = Dialog.getCheckbox();
fGColour = Dialog.getRadioButton();
overlap = Dialog.getNumber()/100;
thrshLev = Dialog.getNumber();

//make some arrays to store data
titleArray=newArray();
orbArray=newArray();
orbOverlapArray=newArray();
proteinArray=newArray();
//proteinOverlapArray=newArray();
setBatchMode(true);
fileCount = lengthOf(fList); //how many files in the folder
mark = 0; //make a mark


for (i=0;i<fileCount;i++){
	temp = fList[i];
	if (temp == "coloc_Results/"){ //if the item in question is the output folder
		mark = 1; //increment the mark
	}
}

if (mark != 0){ //if the mark has been incremented 
	fileCount = fileCount -1; //reduce the count of the files by 1
}


//there needs to be 2 images for each cell; c1 and c2, so 
if (fileCount/2 == floor(fileCount/2)){ //the analysis will only run if you have an even number of files in the folder

for (i=0;i<fileCount;i=i+2){ //for every other image in the input  folder
	if (fList[i] != "coloc_Results/"){ //if its not the results folder
		nom = split(fList[i], ".");
		nom = nom[0];
		if (roiManager("Count") > 0){
			roiManager("deselect");
			roiManager("delete");
		}
		open(fPath+fList[i]); //open the channel 1 image
		if (fGColour=="Black"){
		run("Invert LUT");}

		roiManager("add");
		roiManager("select", 0);
		if (bgSub ==true){
			run("Subtract Background...", "rolling=5");
		}
		roiManager("measure"); //measure the mean intensity
		meanC1 = getResult("Mean",nResults-1);
		run("Select None");
		run("Duplicate..."," ");
		getRawStatistics(nPixels, mean, min, max, std, histogram);
		setThreshold(meanC1*thrshLev, max+1); //set thresholds based on mean intensity
		run("Convert to Mask");//turn the image into a mask
		rename("c1Mask");

		open(fPath+fList[i+1]); //open the channel 2 image
		if (fGColour=="Black"){
		run("Invert LUT");}
		
		roiManager("add");
		roiManager("select", 1);
		if (bgSub ==true){
			run("Subtract Background...", "rolling=5");
		}
		roiManager("measure"); //measure the mean intensity
		meanC2 = getResult("Mean",nResults-1);
		run("Select None");
		run("Duplicate..."," ");
		getRawStatistics(nPixels, mean, min, max, std, histogram);
		setThreshold(meanC2*thrshLev, max+1); //set thresholds based on mean intensity
		run("Convert to Mask");//turn the image into a mask
		rename("c2Mask");

		roiManager("deselect");
		roiManager("delete");

		
		selectWindow("c1Mask");
		run("Select None");
		run("Analyze Particles...", "size=9-198 circularity=0-1.00 clear add"); //this deletes all prevous ROIs
		c1_count=roiManager("count");
		print(c1_count);
		selectWindow("c2Mask");
		run("Select None");
		run("Analyze Particles...", "size=9-198 circularity=0-1.00 add");
		c2_count=roiManager("count")- c1_count;
		run("Select All");
		run("Duplicate..."," ");//this is a duplicate of C2, but really it's a blank canvas
		orbOverlapArray=Array.concat(orbOverlapArray,0);
		for (p=0;p<c1_count;p++){ //for every object you found in the first channel
			for (p2=c1_count;p2<c1_count+c2_count;p2++){ //for each of the objects in the second channel
				run("Select All");
				run("Clear");
				roiManager("Select",p2); //fill in that c2 object
				roiManager("Fill");
				roiManager("Select",p); //find the channel1 object again
				roiManager("Measure"); //then measure how much of it is covered by signal in the second channel
					if ((getResult("RawIntDen",nResults-1)/255)/getResult("Area",nResults-1) >overlap){ //if there's overlap
						run("Select All");
						run("Clear"); //delete everything
						roiManager("Select",p); //find the c1 object
						roiManager("Fill"); //fill it in
						roiManager("Select",p2); //determine if the c2 object is overlapped by signal in c1
						roiManager("Measure");
						if ((getResult("RawIntDen",nResults-1)/255)/getResult("Area",nResults-1) >overlap){
							orbOverlapArray[lengthOf(orbOverlapArray)-1] = orbOverlapArray[lengthOf(orbOverlapArray)-1]+1;
						}
					}
			}
		}
		close();
		imageCalculator("AND create", "c1Mask","c2Mask");
		run("Images to Stack");
		saveAs("tif",fPath+"coloc_Results/"+nom+"_stack.tif");
		titleArray=Array.concat(titleArray,fList[i]);
		orbArray=Array.concat(orbArray,c1_count);
		proteinArray=Array.concat(proteinArray,c2_count);
		close();
	}
	else { //if it is the results folder, make sure you decrement i, just in case the results folder is the first thing in the file List
		i= i-1;
	}
}
Array.print(orbArray);
run("Clear Results");
updateResults();
for (i=0;i<lengthOf(titleArray);i++){
	setResult("Name",nResults,titleArray[i]);
	setResult("C1 Foci #",nResults-1,orbArray[i]);
	setResult("C2 Foci #",nResults-1,proteinArray[i]);
	setResult("# Mutually Overlapping objects",nResults-1,orbOverlapArray[i]);
	
}
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
saveAs("results", fPath+"coloc_Results/"+d2s(year,0)+d2s(month,0)+d2s(dayOfMonth,0)+"_"+d2s(hour,0)+d2s(minute,0)+"results.csv");
}
else{
	waitForUser("You don't have an even number of items in the folder.\n Check the folder contents and try again");}

