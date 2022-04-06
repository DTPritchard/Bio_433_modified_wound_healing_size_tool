//Variable declaration
var filter_radius = 20; 
var threshold = 100;
var sat_pix = 0.001;
var width = getWidth;
var height = getHeight;
var min_area = 100;
var ort = "No";
var scale = "No";
var diagonal= "No";
var express_mode = false;

// ----------------------------------------------------------------------------------------------------------------------
// Auxiliary functions (Suarez-Arnedo et al., 2020)
// ----------------------------------------------------------------------------------------------------------------------
function edge_min_coordinates(arr_ROI) 
{
   arr_min = newArray();
   arr_min = Array.concat(arr_min, arr_ROI [0]);
   for (x = 1; x< arr_ROI.length - 2; x++)
   {
         if (arr_ROI [x-1] > arr_ROI [x] && arr_ROI [x] < arr_ROI [x+1])
         {
            arr_min = Array.concat(arr_min, arr_ROI [x]);
         }
   }
    
   return arr_min;   

}

// ----------------------------------------------------------------------------------------------------------------------
function edge_max_coordinates(arr_ROI) 
{
   arr_max = newArray();
   for (x = 1; x< arr_ROI.length - 2; x++)
   {
         if (arr_ROI [x-1] < arr_ROI [x] && arr_ROI [x] > arr_ROI [x+1])
         {
            arr_max = Array.concat(arr_max, arr_ROI [x]);
         }
   }
   
   arr_max = Array.concat(arr_max, arr_ROI [arr_ROI.length - 1]);
   
   return arr_max;   
}

// ----------------------------------------------------------------------------------------------------------------------
function diff_arrays(arr_max, arr_min)
{
     arr_diff = newArray();
     for (x = 0; x< arr_max.length-1; x++)
     {
           arr_diff = Array.concat(arr_diff, arr_max [x] - arr_min [x]);
     }
     return arr_diff;
}

//------------------------------------------------------------------------------------------------------------------------
function scale_fixed(scale)
{
	getPixelSize(unit, pw, ph);
   if(scale=="Yes")
	{
   run("Set Scale...", "distance=1 known="+pw+" unit=" + unit+" global");
	}
	if(scale=="No")
	{
   run("Set Scale...", "distance=1 known="+pw+" unit=" + unit);
	}

}

//------------------------------------------------------------------------------------------------------------------------
function diagonal_fixed(diagonal, angle)
{
	
   if(diagonal=="Yes")
	{
	angle1=(90-(angle-90));
	beta = angle1 * (PI/180);
   correct_angle=sin(beta);
	}
	if(diagonal=="No")
	{
   correct_angle=1;
	}
	return correct_angle;


}


// ----------------------------------------------------------------------------------------------------------------------
// Functions (DTP)
// ----------------------------------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------------------------------------
// FUNCTION: AreaSelectionSatisfaction
//      Task: Asks user if they are satisfied with the selected area
//      Accepts: None
//      Returns: True if answered "yes", or false if answered "no"
// ----------------------------------------------------------------------------------------------------------------------

function AreaSelectionSatisfaction() 
{

area_satisfied = newArray("Yes","No");
    Dialog.create("Area Selection Satisfaction Step");
    Dialog.addChoice("Are you satisfied with the highlighted area?", area_satisfied);
    Dialog.show();
    area_satisfied = Dialog.getChoice();

    if (area_satisfied == "Yes") {
        return true;
    else {
        return false;

        }
    }  
}


//------------------------------------------------------------------------------------------------------------------------
// FUNCTION: continueAnalysis
//      Task: Asks user if they want to continue with the analysis
//      Accepts: None
//      Returns: True if answered "yes", or false if answered "no"
// ----------------------------------------------------------------------------------------------------------------------
function continueAnalysis() 
{

continueAnalysisStatus = newArray("Yes","No");
    Dialog.create("Continue Status");
    Dialog.addChoice("Do you want to continue the analysis", continueAnalysisStatus);
    Dialog.show();
    continueAnalysisStatus = Dialog.getChoice();

    if (continueAnalysisStatus == "Yes") {
        return true;
    else {
        return false;

        }
    }  
}

// ----------------------------------------------------------------------------------------------------------------------
// FUNCTION: processImage
//      Task: For batch processing, function identifies gap area (via image segmentation) and output measurements 
//      Accepts: the image file, the image file number in the directory, whether express_mode is activated or not. 
//      Returns: Outputs measurements in a table and annotated images with highlighted gap area. 
// ----------------------------------------------------------------------------------------------------------------------



function processImage(imageFile, currentRowNumber, express_mode_status) {
    findParameterStatus=true;
    open(imageFile);

    // DTP ADDITION: Region of Interest Verification
        // The code below allows the user to inspect the highlighted area before continuing on with the analysis
        // If the user is not satisfied with the area, the user can reset the parameters or skip the analysis. 
        // When the user is satisfied or decides to pass, this loop will end. 

    while (findParameterStatus) {
        filename = getTitle();
        continueAnalysisStatus = true;
        run("Select None");
        snapshot();
        setupUndo();
        if (express_mode_status == false) {
            run("Wound healing size tool options");
        } 
        run("Options...", " black");
        run("Duplicate...", "duplicate");
        setForegroundColor(0, 0, 0);
        setBackgroundColor(255, 255, 255);
        roiManager("reset");
        roiManager("Associate", "true");
        run("8-bit");
       

        if (isOpen("ROI Manager")) 
       {
          selectWindow("ROI Manager");
          run("Select None");
          run("Close");
       }
       
       getPixelSize(unit, pw, ph);
       
       run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
       run("Enhance Contrast...", "saturated="+sat_pix+" normalize");
       run("Variance...", "radius="+filter_radius+" stack"); 
       setThreshold(0, threshold);
       run("Convert to Mask", "black");
       run("Fill Holes");
       run("Select All");
       run("Analyze Particles...", 
              "size="+min_area+"-Infinity circularity=0.00-1.00 show=Nothing add stack");
       run("Revert");
       roiManager("Show None");
       close();
      
       if (roiManager("count")>1)
       {
           area_large = newArray(roiManager("count"));
           for (i = 0; i<(roiManager("count")); i++)
           {
               roiManager("select", i)
               getStatistics(area_large[i], mean, min, max, std, histogram);
           }
           largest = 0;
           for (i = 0; i<(roiManager("count")); i++)
           {
               if (area_large[i]>largest)
               {
                   largest = area_large[i];
                   large = i+1;
               }
           }
           roiManager("select", large);
       }
       
       else
       {
           roiManager("select", 0);
       }
        reset();
        setupUndo();
        roiManager("Set Color", "cyan");
        
        continueAnalysisStatus = true;

        // DTP: Dialog boxes to ask user if the select area is satisfactory for user, only if express_mode is false. 
        //      If express mode is true, then this step is bypassed (after one cycle). 

        if(express_mode_status == false) {
           area_satisfied = getBoolean("Are you satisfied with the highlighted area?");

           if (area_satisfied) {
            findParameterStatus = false;

           } else if (!area_satisfied) {
                retryParameters = getBoolean("Do you want to reset the parameters and try again (click yes to reset parameters; click no to skip analysis of this image)");
                
                if (retryParameters) {
                    roiManager("reset");
                }

                if (!retryParameters) {
                    findParameterStatus = false;
                    continueAnalysisStatus = false;
                }
            }

        } else {
            findParameterStatus = false;
        }
    }
    

    // DTP: Continue area analysis after user's inputs

    if (continueAnalysisStatus) {
        //wait(5000);
        Roi.getContainedPoints(xpoints, ypoints);
        min_x = edge_min_coordinates(xpoints);
        max_x = edge_max_coordinates(xpoints);
        diff_vec = diff_arrays(max_x , min_x);

        Array.getStatistics(diff_vec, low, high, avg_width, std_dist);

        List.setMeasurements;  
        angle = List.getValue("Angle");
        correct_angle = diagonal_fixed(diagonal, angle);

        avg_width = (avg_width*pw)*correct_angle;
        std_dist = (std_dist*pw);

        run("Set Scale...", "distance=1 known="+pw+" unit=" + unit);
        run("Set Measurements...", "display redirect=None decimal=3");
        getStatistics(area, mean, min, max, std, histogram);
        height_total=getHeight()*pw;
        width_total=getWidth()*pw;
        total_area=(height_total*width_total);
        area_fraction=(area/total_area)*100;

        title_image=getTitle();

        setResult("Label", currentRowNumber, title_image);
        updateResults();

        setResult("Area "+unit+"^2", currentRowNumber, area);
        updateResults();
        
        setResult("Area %", currentRowNumber, area_fraction);
        updateResults();
        
        setResult("Width "+unit, currentRowNumber, avg_width);
        updateResults();
        
        setResult("Standard deviation "+unit, currentRowNumber, std_dist);
        updateResults();
        
        setResult("Variance window radius parameter ", currentRowNumber, filter_radius);
        updateResults();
        
        setResult("Threshold value parameter ", currentRowNumber, threshold);
        updateResults();
        setResult("Percentage of saturated pixels parameter ", currentRowNumber, sat_pix);
        updateResults();
        
        scale_fixed(scale);
        setTool("rectangle");
        
        // DTP: Annotate the ROI on the image
        run("Overlay Options...", "stroke=cyan width=5 fill=none set");
        run("Add Selection...");

        //setTool("text");
        //setFont("SansSerif", 48, " antialiased");
        //setColor("black");
        //Overlay.drawString(area, 1204, 1218, 0.0);
        //Overlay.show();

     
    }

    else {
        
        title_image=getTitle();
        setResult("Label", currentRowNumber, title_image);
        updateResults();
        
        setResult("Area "+unit+"^2", currentRowNumber, "Null");
        updateResults();
        
        setResult("Area %", currentRowNumber, "Null");
        updateResults();
    
        setResult("Width "+unit, currentRowNumber, "Null");
        updateResults();
    
        setResult("Standard deviation "+unit, currentRowNumber, "Null");
        updateResults();
        
        setResult("Variance window radius parameter ", currentRowNumber, "Null");
        updateResults();
        
        setResult("Threshold value parameter ", currentRowNumber, "Null");
        updateResults();
        
        setResult("Percentage of saturated pixels parameter ", currentRowNumber, "Null");
        updateResults();
       
        scale_fixed(scale);
        setTool("rectangle");
    }
}


// ----------------------------------------------------------------------------------------------------------------------
// TOOL: Wound Size Tool - Process Single Image
//      Task: A macro that processes just a single image. Requires user to open image beforehand and click on it to start processing
//      Accepts: None
//      Returns: Outputs measurements in a table and annotated image with highlighted gap area.
// ----------------------------------------------------------------------------------------------------------------------

macro 'Wound Size Analysis | Process Single Image Tool - C358Dc2C9acD1cD47D59D6cD72Db6Db7Dc4C89bD01D0aD10D4aD58D64D70CdddD5bD62DaaDe1C68aD0fCbccD28D6aD92Dd9C9abD2aCeeeD38D45D5dD73D74D80D81D82D83D84D85D87D88D89D8aD8bD90D91D93D94D95D97D98D99D9aD9bD9cD9dD9eD9fDa7Da9DabDacDadDaeDc9DfeC67aD02D04D07D0bD30DefCabcD8fC9abD17D1dD2fD31D34D46D50D67D79D7eDa2Da5Db3Db9Dc3DceDd2De5Df6CdddD4dD8eDa8DafC79aD1eD3dDb4DbdDeeCccdD41De6DecDf2C9abD11D24D27D3eD69Da1DbfDd8DdfDebC579Dc6DdaDe8CabcD12D6fD8cDbeDdeDedDf5C8abD29D43DbaDbcDe3Df9CdddD21D3aD66D78D96Db1Dc5C78aD7aDb8CccdDf7C9abD15DfbC68aD09D7fDfcCbbcD51DbbDc1Df4CdeeDd3C89bD0cD18D1aD20D2eD32D5fD7dDcaCcddD13D25Da4Db5DfdC579D06D08D19D60Df0CaacD3bC89bD23D2cD5aD65D68D6bD7cDa6Dd1Dd5DeaDf1DffC78aD05D14D22D35D36D42D44D57D63D76Dc8Dd4Dd7De2DfaCbcdD1fD3fD54De7C68aD0dD0eD5eDb0Dc0DdcDddCabcD26D3cD48D6eDd6DdbDe9CddeD2dD75D7bD86D8dDa0Da3C79bD16D4eD5cDb2CcddD77Dc7DcbC57aD49Dd0CccdD33D37D4fD52D55D6dDccDcfC469D03D40De0CbccD2bD53DcdDf3C68aD4bC579D1bD39D4cD61CabcD56D71De4Df8C469D00' {
    

    
    findParameterStatus=true;


    // DTP ADDITION: Region of Interest Verification
        // The code below allows the user to inspect the highlighted area before continuing on with the analysis
        // If the user is not satisfied with the area, the user can reset the parameters or skip the analysis. 
        // When the user is satisfied or decides to pass, this loop will end. 


    while (findParameterStatus) {
        filename = getTitle();
        continueAnalysisStatus = true;
        run("Select None");
           snapshot();
           setupUndo();
           run("Wound healing size tool options");
           run("Options...", " black");
           run("Duplicate...", "duplicate");
           setForegroundColor(0, 0, 0);
           setBackgroundColor(255, 255, 255);
           roiManager("reset");
           roiManager("Associate", "true");
           run("8-bit");
           
           if (isOpen("ROI Manager")) 
           {
              selectWindow("ROI Manager");
              run("Select None");
              run("Close");
           }
           
           getPixelSize(unit, pw, ph);
           run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
           run("Enhance Contrast...", "saturated="+sat_pix+" normalize");
           run("Variance...", "radius="+filter_radius+" stack"); 
           setThreshold(0, threshold);
           run("Convert to Mask", "black");
           run("Fill Holes");
           run("Select All");
           run("Analyze Particles...", 
                  "size="+min_area+"-Infinity circularity=0.00-1.00 show=Nothing add stack");
           run("Revert");
           roiManager("Show None");
           close();
          
           if (roiManager("count")>1)
           {
               area_large = newArray(roiManager("count"));
               for (i = 0; i<(roiManager("count")); i++)
               {
                   roiManager("select", i)
                   getStatistics(area_large[i], mean, min, max, std, histogram);
               }
               largest = 0;
               for (i = 0; i<(roiManager("count")); i++)
               {
                   if (area_large[i]>largest)
                   {
                       largest = area_large[i];
                       large = i+1; 
                            // DTP MODIFICATION: adding "+1" results in selecting the 2nd largest area
                            // This is the correct ROI for the field of view in the Echo Revolve Microscope 
                   }
               }
               roiManager("select", large);
           }

           else
           {
               roiManager("select", 0);
           }

            reset();
            setupUndo();
            roiManager("Set Color", "cyan");


            continueAnalysisStatus = true;


            // DTP: Dialog boxes to ask user if the select area is satisfactory for user   
            area_satisfied = getBoolean("Are you satisfied with the highlighted area?");

            if (area_satisfied) {
            findParameterStatus = false;

            } else if (!area_satisfied) {
                retryParameters = getBoolean("Do you want to reset the parameters and try again (click yes to reset parameters; click no to skip analysis of this image)");
                
                if (retryParameters) {
                    roiManager("reset");
            }
                
            if (!retryParameters) {
                    findParameterStatus = false;
                    continueAnalysisStatus = false;
            }
        }
    }


    // DTP: Continue area analysis after user's inputs

    if (continueAnalysisStatus) {
        //wait(5000);
        Roi.getContainedPoints(xpoints, ypoints);
        min_x = edge_min_coordinates(xpoints);
        max_x = edge_max_coordinates(xpoints);
        diff_vec = diff_arrays(max_x , min_x);

        Array.getStatistics(diff_vec, low, high, avg_width, std_dist);
        
        List.setMeasurements;  
        angle = List.getValue("Angle");
        correct_angle = diagonal_fixed(diagonal, angle);
       
        avg_width = (avg_width*pw)*correct_angle;
        std_dist = (std_dist*pw);

        run("Set Scale...", "distance=1 known="+pw+" unit=" + unit);
        run("Set Measurements...", "display redirect=None decimal=3");
        getStatistics(area, mean, min, max, std, histogram);
        height_total=getHeight()*pw;
        width_total=getWidth()*pw;
        total_area=(height_total*width_total);
        area_fraction=(area/total_area)*100;
      
        n1=getValue("results.count");
        title_image=getTitle();

        setResult("Label", n1, title_image);
        updateResults();

        setResult("Area "+unit+"^2", n1, area);
        updateResults();
        
        setResult("Area %", n1, area_fraction);
        updateResults();
        
        setResult("Width "+unit, n1, avg_width);
        updateResults();
        
        setResult("Standard deviation "+unit, n1, std_dist);
        updateResults();
        
        setResult("Variance window radius parameter ", n1, filter_radius);
        updateResults();
        
        setResult("Threshold value ", n1, threshold);
        updateResults();
        
        setResult("Percentage of saturated pixels", n1, sat_pix);
        updateResults();
        
        scale_fixed(scale);
        setTool("rectangle");

        // DTP: Annotate the ROI on the image
        run("Overlay Options...", "stroke=cyan width=5 fill=none set");
        run("Add Selection...");

        //setTool("text");
        //setFont("SansSerif", 48, " antialiased");
        //setColor("black");
        //Overlay.drawString(area, 1204, 1218, 0.0);
        //Overlay.show();
         
    }

    else {
          
        title_image=getTitle();

        setResult("Label", n1, title_image);
        updateResults();

        setResult("Area "+unit+"^2", n1, "Null");
        updateResults();
        
        setResult("Area %", n1, "Null");
        updateResults();
        
        setResult("Width "+unit, n1, "Null");
        updateResults();
        
        setResult("Standard deviation "+unit, n1, "Null");
        updateResults();
        
        setResult("Variance window radius parameter ", n1, "Null");
        updateResults();
        
        setResult("Threshold value parameter ", n1, "Null");
        updateResults();
        
        setResult("Percentage of saturated pixels parameter ", n1, "Null");
        updateResults();
        
        scale_fixed(scale);
        setTool("rectangle");
    }
}

// ----------------------------------------------------------------------------------------------------------------------
// TOOL: Wound Size Tool - Process Multiple Images
//      Task: A macro button that gets user to select input directory and apply the processImage function to all images in directory
//      Accepts: Input directory selection
//      Returns: Outputs measurements in a table and annotated images with highlighted gap area.
// ----------------------------------------------------------------------------------------------------------------------


macro "Wound Size Analysis | Process Multiple Images Action Tool - C358Dc2C9acD1cD47D59D6cD72Db6Db7Dc4C89bD01D0aD10D4aD58D64D70CdddD5bD62DaaDe1C68aD0fCbccD28D6aD92Dd9C9abD2aCeeeD38D45D5dD73D74D80D81D82D83D84D85D87D88D89D8aD8bD90D91D93D94D95D97D98D99D9aD9bD9cD9dD9eD9fDa7Da9DabDacDadDaeDc9DfeC67aD02D04D07D0bD30DefCabcD8fC9abD17D1dD2fD31D34D46D50D67D79D7eDa2Da5Db3Db9Dc3DceDd2De5Df6CdddD4dD8eDa8DafC79aD1eD3dDb4DbdDeeCccdD41De6DecDf2C9abD11D24D27D3eD69Da1DbfDd8DdfDebC579Dc6DdaDe8CabcD12D6fD8cDbeDdeDedDf5C8abD29D43DbaDbcDe3Df9CdddD21D3aD66D78D96Db1Dc5C78aD7aDb8CccdDf7C9abD15DfbC68aD09D7fDfcCbbcD51DbbDc1Df4CdeeDd3C89bD0cD18D1aD20D2eD32D5fD7dDcaCcddD13D25Da4Db5DfdC579D06D08D19D60Df0CaacD3bC89bD23D2cD5aD65D68D6bD7cDa6Dd1Dd5DeaDf1DffC78aD05D14D22D35D36D42D44D57D63D76Dc8Dd4Dd7De2DfaCbcdD1fD3fD54De7C68aD0dD0eD5eDb0Dc0DdcDddCabcD26D3cD48D6eDd6DdbDe9CddeD2dD75D7bD86D8dDa0Da3C79bD16D4eD5cDb2CcddD77Dc7DcbC57aD49Dd0CccdD33D37D4fD52D55D6dDccDcfC469D03D40De0CbccD2bD53DcdDf3C68aD4bC579D1bD39D4cD61CabcD56D71De4Df8C469D00" {
       
    run("Clear Results"); // clear the results table of any previous measurements

    setBatchMode(false);//  ImageJ showings the processing steps during macro

    // Show the user a dialog to select a directory of images
    inputDirectory = getDirectory("Choose a Directory of Images"); 

    // Get the list of files from that directory. 
    // NOTE: if there are non-image files in this directory, it may cause the macro to crash
    fileList = getFileList(inputDirectory);

    //Set initial measurements
    run("Set Measurements...", "display redirect=None decimal=3");

    //For each image file in the selected directory, run the "processImage" function to analyze wound area. 
    for (i = 0; i < fileList.length; i++)
    {
        processImage(fileList[i], i, express_mode);
    }

    //Show a message to let user know that the analysis is complete
    Dialog.create("Process Complete");
    Dialog.addMessage("Wound size analysis is complete.");
    Dialog.show();


}


// ----------------------------------------------------------------------------------------------------------------------
// TOOL: Wound healing size Manual Tool (Suarez-Arnedo et al., 2020)
// ----------------------------------------------------------------------------------------------------------------------

macro 'Wound healing size Manual Tool - C89bD19D5dD6eDd2C579D03D0cCbccDe2C123DdaC9abD04D2bD42D49D65D7cC78aD00D02D23D48D4dD5eDb0Df0DfdCdddD4cD5aC111Dc8De9DeaC9abD11D17D1dD1fD22D25D38D4fD62D6bD95Da3Dc5De4De7C68aD0bD60CccdD8eC469D0dD0eDb2DfcCabcD01D27D3aD50D6dD7bD7dC89aDd6CeeeD80D90C001D8bDddC8abD6aDd3C679Df1DfbCccdD47C333D98D99D9fC9acD15D29D35D66C79aD34D3bD4aD4bD7eD92Dd4CeeeD37D52D5cD72D73D74D77D7aD81D82D83D84D85D86D93D94Dc3C222D9aD9bD9cD9dDabDacDadDbbDbcDbdDcbDccDcdC78aDf4CdddD41D67D71Da5Dd1De3DefC555D97CabcD40C89bD2dD30D3cD3dD46Da2Db4Dc2De0C000D88D89D8aD9eDb6Db7Db8Db9DbaC89bD12D1bD1cD2eD53D68D8fDb3De1DeeC579D18Df9CbcdD10D39D6cD6fDe8C233Da9C78aD43D55Dc1Dc4CddeD13D2cD78C122DaaDceC68aD0fD14D36D57D5bD61D69Da4Df3DfaCcddD24D54D56Dd5C569DdeDf8C79bD32D51Da0DffC111Dc7Dc9C8abD16D7fDe5De6C67aD06D07D09D59Dc0Df2CccdD21D33D4eD5fD64D79Da1Db1C345DcfCabcD20D76C68aD3fC789Dd7CbbcD1eD44D63C579D05D1aDf6CbccD28D2aD91Df5C122Da7CdddD3eD45D58CdddDedC111D8cDcaDdbC89bD31C344Dc6C68aD2fDd0DfeC778D96CabcD26DdfC57aD08C233DebCdeeD70D75C579Df7C445Da6C899Dd9C568Dd8C333DafDbfC444D8dC888D87Db5C223Da8C778DecC469D0a'

{
	
    roiManager("Add");
    roiManager("select", 1);
    reset();
    setupUndo();
    roiManager("Set Color", "cyan");
    getPixelSize(unit, pw, ph);
    run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");

    Roi.getContainedPoints(xpoints, ypoints);
    min_x = edge_min_coordinates(xpoints);
    max_x = edge_max_coordinates(xpoints);
    diff_vec = diff_arrays(max_x , min_x);

    Array.getStatistics(diff_vec, low, high, avg_width, std_dist);

    List.setMeasurements;  
    angle = List.getValue("Angle");
    correct_angle = diagonal_fixed(diagonal, angle);

    avg_width = (avg_width*pw)*correct_angle;
    std_dist = (std_dist*pw);

    run("Set Scale...", "distance=1 known="+pw+" unit=" + unit);
    run("Set Measurements...", "redirect=None decimal=3");
    getStatistics(area, mean, min, max, std, histogram);
    height_total=getHeight()*pw;
    width_total=getWidth()*pw;
    total_area=(height_total*width_total);
    area_fraction=(area/total_area)*100;

    n1=getValue("results.count");
    title_image=getTitle();
    setResult("Label", n1, title_image);
    setResult("Area "+unit+"^2", n1, area);
    setResult("Area %", n1, area_fraction);
    setResult("Width "+unit, n1, avg_width);
    setResult("Standard deviation "+unit, n1, std_dist);
    scale_fixed(scale);
    setTool("rectangle");

    // DTP: Annotate the ROI on the image
    run("Overlay Options...", "stroke=cyan width=5 fill=none set"); 
    run("Add Selection...");

    roiManager("Delete");

}


//
// ----------------------------------------------------------------------------------------------------------------------
// Additional Tools/Functions/Macros (Formerally named "Tooltips & Dialogs")

// ----------------------------------------------------------------------------------------------------------------------
// TOOL: Rotate image 90 degrees (Suarez-Arnedo et al., 2020)
// ----------------------------------------------------------------------------------------------------------------------

macro 'Rotate 90° Tool - C000D14D15D16D17D23D32D42D52D62D72CaacD19D6fDa8DaaC79bD55D6cDffCdddD70D7cDbcDdaDddDf8C469DecCbccD83C9abD74CeeeDb0Dc0C112D33CabcD2cD3dDbfDd6C89bD1bD1eD1fD2dD2fD36D44D4cD75D87D8cDb1Db4DdcCeeeD01D02D09D0aD0bD0cD0dD0eD0fD1aD2aD39D3aD46D49D4aD59D5aD69D6aD79D7aD88D89D8aD98D99D9aDa9Db5Db8Db9Dc8Dc9DcaDd8Dd9Df9C777D41D51CcccD60C9abD37D81D8bD93De1DedCeeeD00D10D20D30D40D50D80D90Da0Dd0De0Df0C000D22CabcD3cD8fDa7De2DfbC89bD3eD4bDa2Dc1Dc5De5CddeD3fD68D94De9C68aD6dCccdD45D47D7eD86DbbDc6Dd2De6DefDfeC9abD2bD48D67D7bD92D9fDabDadDbdDccDd1DdbDdeDe7Df1Df2C334D82CbbcD38D4eD6bD84D95D9eDa3DaeDb7C8abD1cDd5Df4C79aD34D65D85Dc4DcbDd3CdddDa6CaabD21CabcD4fD91DbaDc3DceDcfDd7DdfDebDf6C89bD35D7dDa5DafDb6De4DeaC68aD4dD56D6eD76D77D7fD96Df7DfdCbcdD5eDfcC333D71C888D31CcddD66D78D9cDd4Df5DfaC9acD57D5dD9bDa1Db2DbeC222D05D06D07CdeeD29C78aD54D8eDa4Dc2De3DeeC666D61CdddD5cDe8Df3CabbD64C57aDacCbccD11D3bD58Dc7C233D26D27CccdD8dD97C000D13C455D25C444D04D63C78aD5fDcdC567D28CbbbD03C579D2eCbccD5bDb3C333D24C344D53C334D18C666D08C68aD1dD9dC111D73C555D43C667D12'

{
	snapshot();
    run("Rotate 90 Degrees Right");
    setTool("rectangle");
    
   
}

// ----------------------------------------------------------------------------------------------------------------------
// MACRO: Save results (for echo revolve)
//      Task: 
//      Accepts: 
//      Returns: 
// ----------------------------------------------------------------------------------------------------------------------

macro "Save Results Table as CSV Action Tool - C00cO11cc" {
       saveAs("Results");
    }

// ----------------------------------------------------------------------------------------------------------------------
// MACRO: Save Annotated Images
//      Task: 
//      Accepts: 
//      Returns: 
// ----------------------------------------------------------------------------------------------------------------------


macro "Save Annotated Images Action Tool - C00cO11cc" {
       run("Save all images");
    }

//From examples
macro 'Save all images' {
    
  if (nImages==0)
     exit("No images are open");
  dir = getDirectory("Choose a Directory");
  for (n=1; n<=nImages; n++) {
     selectImage(n);
     title = getTitle;
     saveAs("jpeg", dir+title.replace("/","_"));
  } 
  //close("*");

}


// ----------------------------------------------------------------------------------------------------------------------
// MACRO: Wound healing size tool options (Suarez-Arnedo et al., 2020)
//      Task: Asks user for analysis parameters for gap image analysis
//      Accepts: Variance window radius, Threshold value, percentage of saturated pixels, set global scale, diagonal scratch adjustment
//      Returns: None
//      DTP Modification: Set scale bar to 10X objective on an Echo Revolve Microscope
// ----------------------------------------------------------------------------------------------------------------------


macro 'Wound healing size tool options'
{

set_scale_global = newArray("Yes","No");
    is_diagonal = newArray("Yes","No");

    Dialog.create("Wound healing size options");
    Dialog.addNumber("Variance window radius", filter_radius);
    Dialog.addSlider("Threshold value", 0, 255,  threshold);
    Dialog.addNumber("Percentage of saturated pixels", sat_pix);
    Dialog.addChoice("Set Scale global?", set_scale_global);
    Dialog.addChoice("The scratch is diagonal?", is_diagonal);
    Dialog.addCheckbox("Apply these settings to the rest of the images?", false);


    Dialog.show();
    
    filter_radius = Dialog.getNumber();
    threshold = Dialog.getNumber();
    sat_pix = Dialog.getNumber();

    scale = Dialog.getChoice();
    diagonal = Dialog.getChoice();
    express_mode = Dialog.getCheckbox();
    run("Set Scale...", "distance=709 known=0.36 unit=mm"); // DTP: Set the scale bar to the correct scale for a 10X objective lens view on Echo Revolve Microscope

    scale_fixed(scale);
  
}


// ----------------------------------------------------------------------------------------------------------------------
// MACRO: User defined background (Suarez-Arnedo et al., 2020)
// ----------------------------------------------------------------------------------------------------------------------
macro 'User defined background'
{
    Dialog.create("Background specification")
    Dialog.addMessage("ROI belonging to the gap in the wound must be white, select " +  
                                         "Invert' to turn it to white, 'Keep' to keep it as it is");
    arr_res = newArray("Keep", "Invert");
    Dialog.addChoice("Invert the colour?", arr_res);
    Dialog.show();
    res = Dialog.getChoice();
    if (res=="Invert")
        {
          run("Invert", "stack");
        }   
} 
