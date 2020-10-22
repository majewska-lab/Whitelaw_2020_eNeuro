// Macro to pre-process hyperstacks from 2-photon imaging (Olympus Fluoview computer)
//  (1) Convert image to hyperstack (fluoview output is in 'xyztc', different than default for imageJ
//	(2) Options to despeckle and smooth (Guassian blur):
//			-run at this stage to not interfere with the autocropping when making maxZ projections
//	(3) Run 3D correct plugin on images
//	(4) Save to output folder, with '_3Dcorrect' appended to file name
//	Uses the batch processing macro template from FIJI/ImageJ website
//		-Brendan Whitelaw, Majewska lab, University of Rochester Neuroscience


// Dialog box made using Script Parameters: https://imagej.net/Script_Parameters
// These are 'global' parameters, so you can use them inside of functions 
// below without explicitly mentioning them as inputs

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix
#@ Integer (label = "Number of z-slices", value=31, persist=false) z_slices
#@ Integer (label = "Number of channels", value=1, persist=false) n_channels
#@ Integer (label = "Channel for motion correction", value=1, persist=false) ch_motion
#@ Boolean (label = "Run Despeckle?", value=true, persist=false) option_despeckle
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

function processFile(input, output, file) {
	
	// Do the processing here by adding your own code.
	print("Processing: " + file);
	open(input + File.separator + file);

	// Convert Fluoview multiTIFFs to hyperstacks (NOTE: 1 channel images ONLY)
	// Check if the stack is already a hyperstack
	ismystack = Stack.isHyperstack;
	// If already a hyperstack, print out z and t dimensions and move on
	if (ismystack == true){
		print("Already a hyperstack");
		Stack.getDimensions(width, height, channels, slices, frames);
		print("z="+slices+"; t="+frames+"; c="+channels);
	}
	// If not already a hyperstack, use given z-dimension, calculate t-dimension from that
	else{
		print("Converting to hyperstack...");
		// Get initial dimensions
		Stack.getDimensions(width, height, channels, slices, frames);
		print("initial slices: " + slices);
		print("number of z-slices: " + z_slices);
		print("number of channels: " + n_channels);
		// Calculate number of time frames and use to generate hyperstack
		t_frames = slices/(z_slices*n_channels);
		print("time points: " + t_frames);
		// Convert to hyperstack
		run("Stack to Hyperstack...", "order=xyztc channels="+n_channels+" slices="+z_slices+" frames="+t_frames+" display=Color");
	}
	
	// Despeckle if desired
	if (option_despeckle == true){
		run("Despeckle", "stack");
		print("Ran Despeckle");
	}
	// Smooth (Guassian blur) if desired
	if (option_smoothing == true){
		run("Gaussian Blur...", "sigma="+d2s(smoothing_sigma,2)+" stack"); 
		print("Ran Guassian Blur");
		}
	
	// Run 3D correct plugin to correct Drift... takes a long time
	run("Correct 3D drift", "channel="+ch_motion+" multi_time_scale sub_pixel edge_enhance only=200 lowest=1 highest="+z_slices+"");
	selectWindow("registered time points");
	file_name = replace(file,".tif","");
	saveAs('tiff',output + File.separator + file_name + "_3Dcorrect.tif");
	
	close("*");
}
