// Macro to select z slices for max projection from 4D TIFFs from in vivo imaging
// 		(1) Open image
//		(2) Select channel (if >1 channels)
//		(3) Despeckle and guassian blur... do this on the 3D image!
//		(4) Select slices for max projection
// 		(5) Save max projection in designated folder with suffix _MAX[lower]to[upper].tif



// Dialog box made using Script Parameters: https://imagej.net/Script_Parameters
// These are 'global' parameters, so you can use them inside of functions 
// below without explicitly mentioning them as inputs

// Input and output folders:
#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory: maxZ projections", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix
// Options for processing... default is no because should be already done on 3D image
#@ Boolean (label = "Run Despeckle?", value=false, persist=false) option_despeckle
#@ Boolean (label = "Run Guassian Smoothing?", value=false, persist=false) option_smoothing
#@ Float (label = "Sigma for smoothing", value=0.5, persist=false) smoothing_sigma

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

print("Done!");

function processFile(input, output, file) {
	
	// Do the processing here by adding your own code.
	close("*");
	
	print("Processing: " + file);
	path = input + File.separator + file;
	open(path); // open the file
	stack_name = File.getName(path);
	selectWindow(stack_name);
	
	// Choose channel for analysis and isolate that channel
	getDimensions(width, height, channels, slices, frames);
	if (channels > 1){
	Dialog.createNonBlocking("Choose the channel...");
	Dialog.addString("Channel: ", "");
	Dialog.show();
	new_channel = Dialog.getString();
	run("Split Channels");
	stack_name = "C"+new_channel+"-"+stack_name;
	selectWindow(stack_name);
	close("\\Others");
	}
	
	// Despeckle and Smooth image if previously selected
	if (option_despeckle == true){
		run("Despeckle", "stack");
		print("Ran Despeckle");
	}
	if (option_smoothing == true){
		run("Gaussian Blur...", "sigma="+d2s(smoothing_sigma,2)+" stack"); 
		print("Ran Guassian Blur");
		}
	setMinAndMax(0, 1311); // Increase B/C

	// Generate a dialog box to determine slices for MaxZ projection and execute maximum projection
	Dialog.createNonBlocking("Choose the top and bottom Z slices...");
	Dialog.addString("Lowest: ", "");
	Dialog.addString("Highest: ", "");
	Dialog.show();
	lowest = Dialog.getString();
	highest = Dialog.getString();
	selectWindow(stack_name);
	run("Z Project...", "start=" + lowest + " stop=" + highest + " projection=[Max Intensity] all"); // all indicates all time frames
	setMinAndMax(0, 1311); // Increase B/C
	
	// Save Zmax projection 
	zmax_name = "MAX_"+stack_name;
	selectWindow(zmax_name); // Make sure to select the Max projection window
	zmax_name = replace(zmax_name,suffix,".tif"); // rename max file name for saving
	zmax_file = replace(stack_name,".tif","_MAX"+lowest+"to"+highest+".tif");
	saveAs("tiff", output + File.separator + zmax_file); // save MAX projection as .tif
	// Note: zmax_name is also the name of the max projection window. stack_name is that of the z-stack
	close("*");
	
}
