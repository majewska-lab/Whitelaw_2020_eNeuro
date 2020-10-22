// Script to process time-series images (2D only), after maximum Z projections.
// Gives options to do 3 different processing steps:
// 		(1) Multistack Reg: additional registration step in case there's still some xy drift
//		(2) Autocrop: get rid of blank space around edges leftover from registration (either correct3Ddrift or MultistackReg)
//		(3) Bleach correction, histogram matching method: good for photobleaching
// Then saves file with the _processed.tif suffix

/*
 * Macro template to process multiple images in a folder
 */

// Dialog box made using Script Parameters: https://imagej.net/Script_Parameters
// These are 'global' parameters, so you can use them inside of functions 
// below without explicitly mentioning them as inputs
 
// File inputs and outputs
#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix
// Processing options
#@ Boolean (label = "Run MultiStackReg for 2D image registration?", value=true, persist=false) option_msreg
#@ Boolean (label = "Run Autocrop?", value=true, persist=false) option_crop
#@ Boolean (label = "Trim Edges?", value=true, persist=false) option_trim
#@ Boolean (label = "Run Bleach Correction (histogram method)?", value=true, persist=false) option_hist

// See also Process_Folder.py for a version of this code
// in the Python scripting language.

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}

function processFile(input, output, file) {
	// Do the processing here by adding your own code.
	print("Processing: " + file);
	open(input + File.separator + file);


	// Run Autocrop to get rid of blank space around edges
	// Do once before multistack-reg (? for some reason after, it makes a movement artifact)
	if (option_crop == true){
		getDimensions(width, height, channels, slices, frames);
		print("timepoints="+frames);
		// Convoluted way to do the autocrop by running through each frame
		for(i = 0; i < frames; i++) {
			t_frame = i+1; // this is the time frame/slice
			roiManager("reset");
			run("Slice Keeper", "first="+t_frame+" last="+t_frame+" increment=1"); // Isolate frame
			setBackgroundColor(0, 0, 0);
			run("Select Bounding Box"); // Automaticall select bounding box
			roiManager("Add"); // Add boudning box to ROI manager
			close(); // Close isolated slice
			roiManager("Select", 0);
			run("Crop");
			run("Select None");
		}		
		print("Ran Autocrop, part 1");
	}

	// Run Multistack Reg
	if (option_msreg == true){
		run("MultiStackReg", "stack_1=" + file + " action_1=Align file_1=[] stack_2=None action_2=Ignore file_2=[] transformation=[Rigid Body]");
		print("Ran Multistack Reg");
	}
	
	// Run Autocrop to get rid of blank space around edges
	// Run again after multistack reg just in case there's significant registration
	if (option_crop == true){
		getDimensions(width, height, channels, slices, frames);
		print("timepoints="+frames);
		// Convoluted way to do the autocrop by running through each frame
		for(i = 0; i < frames; i++) {
			t_frame = i+1; // this is the time frame/slice
			roiManager("reset");
			run("Slice Keeper", "first="+t_frame+" last="+t_frame+" increment=1"); // Isolate frame
			setBackgroundColor(0, 0, 0);
			run("Select Bounding Box"); // Automaticall select bounding box
			roiManager("Add"); // Add boudning box to ROI manager
			close(); // Close isolated slice
			roiManager("Select", 0);
			run("Crop");
			run("Select None");
		}		
		print("Ran Autocrop, part 2");
	}

	// Run trim 10 pixels off each edge
	if (option_trim == true) {
		getDimensions(width, height, channels, slices, frames);
		roiManager("reset");
		new_width = width - 20;
		new_height = height - 20;
		makeRectangle(10,10,new_width,new_height); 
		roiManager("Add"); 
		roiManager("Select", 0);
		run("Crop");
		run("Select None");
	}

	// Run Bleach correction (histogram method)
	if (option_hist == true){
		run("Bleach Correction", "correction=[Histogram Matching]");
		print("Ran Bleach correction, histogram method");
		selectWindow("DUP_"+file); // Select the corrected image
		close("\\Others"); // Close the non-corrected image
		rename(file); // Rename the corrected image to that of the original image
	}
	
	// Save processed image with the _processed.tif suffix
	new_file = replace(file,".tif","_processed.tif");
	print("Saving to: " + output);
	saveAs('tiff',output + File.separator + new_file);
	close("*");	

	print("DONE!");
}
