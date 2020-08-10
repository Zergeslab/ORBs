/*
 * The purpose of this macro is to isolate cells from multichannel Z-stack images of fluorescently stained yeast cells
 * Briefly, it will perform a Max-intensity z-Stack, and a bandpass fourier filter operation, then find bright objects
 * and outline them. A single plane from the Z-stack is selected, then the ROIs are saved as images of individual cells
 * in a new directory called output in the same folder as the image comes from. Each channel is saved as a separate image 
 * Previously-saved ROIs can be used as well.
 * 
 * Caveats: See comments for specific warnings/changes
 * */
 

//Get info about the image, and set up the macro
imList=getList("image.titles");
fPath=getInfo("image.directory");
File.makeDirectory(fPath+"output\\");
//This is formatted for windows; switch it to fpath+"output/" for mac
if(roiManager("count")>0){
	roiManager("deselect");
	roiManager("delete");
}
fPref=split(imList[0],".");
//If you have dots in your filenames that are not due to the file type, this will cause a naming error
fPref=fPref[0]; 
run("Clear Results");
updateResults();
imName=imList[0];

//This dialog allows the user to specify which 2 channels to save
Dialog.create("Select Your Channel for finding cells");
Dialog.addNumber("Cell finder Channel: ",1);
Dialog.addNumber("Colocalization Channel: ",2);
Dialog.addRadioButtonGroup("Use Predefined ROIs?: ", newArray("Yes","No"), 1, 2, "No");
Dialog.show();
cSelect=Dialog.getNumber();
cSelect2=Dialog.getNumber();
oldROIs = Dialog.getRadioButton();


//if you're not using old ROIs, you need to define new ones.
if (oldROIs =="No"){
	run("Duplicate...", "duplicate channels="+cSelect+"-"+cSelect2);
	selectWindow(imList[0]);
	close();
	rename(imName);
	run("Invert LUT");
	Stack.setChannel(cSelect2);
	run("Invert LUT");
	//if you've been looking at white images on black backgrounds, comment out the line above.
	Stack.setChannel(cSelect);
	run("Z Project...", "projection=[Max Intensity]");
	setSlice(1);
	run("Duplicate...", " ");
	//This scaling is specific to our camera and lens - you need to work out your own
	run("Bandpass Filter...", "filter_large=40 filter_small=3 suppress=None tolerance=5");
	setAutoThreshold("Li dark");
	//Li dark was the best threshold for us - your algorithm of choice might be different
	waitForUser("Set Threshold");
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Fill Holes");
	run("Watershed");
	run("Analyze Particles...", "size=3-Infinity circularity=0.4-1.00 exclude clear include add");
	//these parameters were good at finding yeast in our images - your objects might be bigger or smaller
	
	selectWindow("MAX_"+imList[0]);
	close();
}
else{
	roiManager("Open","")
	//allows the user to find the previously-saved ROIs
	Stack.setChannel(cSelect);
	run("Invert LUT");
	Stack.setChannel(cSelect2);
	run("Invert LUT");
	
}

//Having defined the ROIs, the user selects the right z-slice to save
cellCount=roiManager("Count");
print(cellCount);
selectWindow(imName);
zCount=nSlices;
waitForUser("Please Select the correct z-slice");


//For every ROI, select it in each channel, then save the images in the output folder, then close the image.
for (i=0;i<cellCount;i++){
	selectWindow(imName);
	Stack.setChannel(cSelect);
	roiManager("Select",i);
	run("Duplicate...", " ");
	saveAs("tiff",fPath+"output\\"+fPref+"_"+i+"_c"+cSelect+".tif");
	close();
	selectWindow(imName);
	Stack.setChannel(cSelect2);
	roiManager("Select",i);
	run("Duplicate...", " ");
	saveAs("tiff",fPath+"output\\"+fPref+"_"+i+"_c"+cSelect2+".tif");
	close();
}
selectWindow(imName);
close();