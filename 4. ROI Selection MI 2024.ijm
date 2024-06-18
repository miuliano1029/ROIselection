//2024: UPDATE by MI. This macro was modified for a few reasons. 
//(1) Scale for length measurements was from a previous correction. Macro now prompts for image scale at the beginning, allowing for use across different images.
//(2) Naming ROIs individually, making it easier to identify the appropriate item if one needs to go back and re-measure lengths.
//(3) This now allow you to set an input folder rather than opening up each file individually. However, you need to start with a folder containing only the TIF files
//(4) Option to record LENGTH, AREA, or BOTH

//this macro is to select ROI and split them by channel, saving each channel in individual folders

//the basic process is that it asks you to open all the images you want ROI from, select a folder
//to save the output ROI images in (creating subfolders for each channel) as well as the zip file
//for the ROImanager metadata detailing where in the image the ROI were taken from
//once complete, the lengths or area will also be printed and exported to an excel file

input = getDirectory("Choose folder for starting images");
ROIdir = getDirectory("Choose folder for ROI files");
File.setDefaultDir(ROIdir);
list = getFileList(input);
list = Array.sort(list);

Dialog.create("Experiment Info");
		Dialog.addString("Date","yyyy-mm-dd",10);
		Dialog.addString("Title","Experiment",10);
		Dialog.addNumber("Pixel Scale:", 0.10049847,8,5,"(um/pixel)");
		Dialog.addMessage("0.10049847 = 2048x2048 60x on the dragonfly");
//additional commonly used scale values can be included here for convenience
date = Dialog.getString();
experiment = Dialog.getString();
scale = Dialog.getNumber();
print("\\Clear")
roiManager("reset");
Dialog.show();
Dialog.create("Channel Info");
	choices = newArray("rectangle","polygon");
	choices2=newArray("length","area","both");
	Dialog.addChoice("What shape ROI?",choices,"polygon");
	Dialog.addChoice("Record",choices2,"length");
	Dialog.addNumber("How many channels?",3,0,1,"channel/s");
Dialog.show();
numChan = Dialog.getNumber();
choice = Dialog.getChoice();
choice2 = Dialog.getChoice();
Dialog.create("what colors\nare they");
	channels = newArray("Red","Green","Blue");
	for(n=0;n<numChan;n++){
		Dialog.addChoice("color",channels,channels[n]);
	}		
		
Dialog.show();
chanArray = newArray();
ROIArray = newArray();
for(n=0;n<numChan;n++) {
	chanArray = Array.concat(chanArray,Dialog.getChoice());
	if(File.exists(input+chanArray[n])!=1) {
		File.makeDirectory(ROIdir+chanArray[n]);
	}
		//ROIpath = ROIdir+chanArray[n];
	ROIpath = getDirectory("Choose folder for the " + chanArray[n]+" channel");
	ROIArray = Array.concat(ROIArray, ROIpath);
}

merge = ROIdir+"Merge";
File.makeDirectory(merge);
mergedir = getDirectory("Choose folder for merged dendrite images");

zipfile = ROIdir+"ROIs";
File.makeDirectory(zipfile);
zipfiledir = getDirectory("Choose folder for ROI .zip files");

 for(d=0;d<list.length;d++)
        {
open(input+list[d]);
run("Properties...", "channels="+numChan+" slices=1 frames=1 unit=micron pixel_width="+scale+" pixel_height="+scale+"");
	title = getTitle();
	//creates a loop for multiple rois in one image
	Dialog.create("Repeat?");
		Dialog.addMessage("Do you have a new ROI in frame?");
		//if you answer "yes" in lowercase it will continue, if
		//anything else it will close the image and continue to the next one
		Dialog.addString("", "yes or no",20);
		Dialog.show();
	repeat = Dialog.getString();
	roiManager("reset");
	while (repeat == "yes") {
		run("Original Scale");
		title = getTitle();
		//this is the function, see the bottom of the macro
    if (choice2 == "area"){
    	ROIarea();}
 	if (choice2 == "length"){
		ROIlength();}
	if (choice2 == "both"){
		ROIboth();}
		
	Dialog.create("Repeat?");
			Dialog.addMessage("Do you have another ROI in frame?");
			Dialog.addString("", "yes or no",30);
			Dialog.show();
		repeat = Dialog.getString();
	}
	if(repeat != "yes") {
		run("ROI Manager...");
		if(roiManager("count") > 0) {
			roiManager("Save", zipfiledir +title+"_ROI.zip");
			close();
		}
		else {
			close();
		}
	}
}

//this function prompts you to create the ROI it will then measure the region selected and
//copy it in each channel and save each channel as an individual image with the color in the name

function	ROIlength(){
	run("Set Measurements...", "display redirect=None decimal=5");
	setTool(choice);
	title=getTitle();
	selectWindow(title);
	waitForUser ("Select ROI then hit OK");
	roiManager("Add");
	count = roiManager("count");
	roiManager("Select", count-1);
	num = (count+1)/2;
    roiManager("Rename", title+" ROI "+num);
	selectWindow(title);
	c=0;
	for(l=0;l<numChan;l++) {	
		setSlice(l+1);
		run("Copy");
		run("Internal Clipboard");
		selectWindow("Clipboard");
		run(chanArray[l]);
		count = roiManager("count");
		num = (count+1)/2;
		saveAs("Tiff", ROIArray[l] +title+" "+num+" "+chanArray[l]);
		rename(chanArray[l]);
		selectWindow(title);
		c=c+1;
	}
run("Merge Channels...", "c1=Red c2=Green c3=Blue create ignore");
saveAs("Tiff", mergedir +title+" "+num);
close();
	selectWindow(title);
	setTool("polyline");
		waitForUser ("Measure dendrite length");
		roiManager("Add");
		count = roiManager("count");
		roiManager("Select", count-1);
		n = count/2;
				roiManager("Rename", title+" Length "+n);
				run("Measure");
				length = getResult("Length",0);	
	}
	
function ROIarea(){
	run("Set Measurements...", "area display redirect=None decimal=5");
	setTool(choice);
	title=getTitle();
	selectWindow(title);
	waitForUser ("Select ROI then hit OK");
	roiManager("Add");
	count = roiManager("count");
	roiManager("Select", count-1);
	num = (count);
    roiManager("Rename", title+" ROI "+count);
	selectWindow(title);
	c=0;
	for(l=0;l<numChan;l++) {	
		setSlice(l+1);
		run("Copy");
		run("Internal Clipboard");
		selectWindow("Clipboard");
		run(chanArray[l]);
		count = roiManager("count");
		saveAs("Tiff", ROIArray[l] +title+" "+num+" "+chanArray[l]);
		rename(chanArray[l]);
		selectWindow(title);
		c=c+1;
	}
run("Merge Channels...", "c1=Red c2=Green c3=Blue create ignore");
saveAs("Tiff", mergedir +title+" "+num);
close();
selectWindow(title);
		roiManager("Select", count-1);
		run("Measure");		
}

function ROIboth(){
	run("Set Measurements...", "area display redirect=None decimal=5");
	setTool(choice);
	title=getTitle();
	selectWindow(title);
	waitForUser ("Select ROI then hit OK");
	roiManager("Add");
	count = roiManager("count");
	roiManager("Select", count-1);
	num = (count+1)/2;
    roiManager("Rename", title+" ROI "+num);
    roiManager("Select", count-1);
		run("Measure");	
	selectWindow(title);
	c=0;
	for(l=0;l<numChan;l++) {	
		setSlice(l+1);
		run("Copy");
		run("Internal Clipboard");
		selectWindow("Clipboard");
		run(chanArray[l]);
		count = roiManager("count");
		num = (count+1)/2;
		saveAs("Tiff", ROIArray[l] +title+" "+num+" "+chanArray[l]);
		rename(chanArray[l]);
		selectWindow(title);
		c=c+1;
	}
run("Merge Channels...", "c1=Red c2=Green c3=Blue create ignore");
saveAs("Tiff", mergedir +title+" "+num);
close();
	selectWindow(title);
	setTool("polyline");
		waitForUser ("Measure dendrite length");
		roiManager("Add");
		count = roiManager("count");
		roiManager("Select", count-1);
		n = count/2;
				roiManager("Rename", title+" Length "+n);
				run("Measure");
				length = getResult("Length",0);	
	}
	
selectWindow("Results");
saveAs("Text", ROIdir + date + " " + experiment +" ROI selection.csv");
run("Clear Results");
roiManager("reset");
