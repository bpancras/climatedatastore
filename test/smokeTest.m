classdef smokeTest < matlab.unittest.TestCase
% Basic tests to check majority of functionality.

% Copyright 2022 The MathWorks, Inc.
    methods(TestClassSetup)
        % Shared setup for the entire test class
    end

    methods(TestMethodSetup)
        % Setup for each test
    end

    methods(Test, TestTags = {'SupportsMock'})
        % Tests that support mocks

        function climateDataStoreDownloadAsyncTest(testCase)
            datasetName ="satellite-sea-ice-thickness";
            datasetOptions.version = "1_0";
            datasetOptions.variable = "all";
            datasetOptions.satellite = "cryosat_2";
            datasetOptions.cdr_type = ["cdr","icdr"]; 
            datasetOptions.year = "2021"; 
            datasetOptions.month = "03";

            cdsFuture = climateDataStoreDownloadAsync(datasetName, datasetOptions);
            cdsFuture.wait();

            % Validate that the returned class has not changed since test was written
            verifyClass(testCase, cdsFuture, ?climateDataStoreDownloadFuture)
            verifyEqual(testCase, 11, numel(properties(cdsFuture)))
            verifyEqual(testCase, 16, numel(methods(cdsFuture)))

            verifyClass(testCase, cdsFuture.CreateDateTime,?datetime)

            verifyClass(testCase, cdsFuture.Error,?MException)
            verifyEmpty(testCase, cdsFuture.Error)
            
            verifyClass(testCase, cdsFuture.FinishDateTime,?datetime)
            
            verifyClass(testCase, cdsFuture.Function,?function_handle)
            verifyEqual(testCase, cdsFuture.Function,@climateDataStoreDownloadAsync)
            
            verifyClass(testCase, cdsFuture.ID,?string)
            
            verifyClass(testCase, cdsFuture.InputArguments, ?cell)
            verifyEqual(testCase, cdsFuture.InputArguments, {datasetName, datasetOptions})
            
            verifyClass(testCase, cdsFuture.NumOutputArguments,?double)
            verifyEqual(testCase, cdsFuture.NumOutputArguments,2)
            verifyClass(testCase, cdsFuture.OutputArguments,?cell)
            verifyTrue(testCase, exist(cdsFuture.OutputArguments{1},"file") == 2)
            [filepath,~,ext] = fileparts(cdsFuture.OutputArguments{1});
            verifyEqual(testCase, ext,".nc")
            verifyEqual(testCase, cdsFuture.OutputArguments{2}, "Generated using Copernicus Climate Change Service information " + string(datetime('today'),'yyyy'))

            verifyClass(testCase, cdsFuture.RunningDuration,?duration)
            verifyClass(testCase, cdsFuture.StartDateTime,?datetime)
            verifyClass(testCase, cdsFuture.State,?string)
            verifyEqual(testCase, cdsFuture.State,"completed")
            rmdir(filepath,"s")
        end

        function climateDataStoreDownloadAsyncTestNoUnzip(testCase)
            datasetName ="satellite-sea-ice-thickness";
            datasetOptions.version = "1_0";
            datasetOptions.variable = "all";
            datasetOptions.satellite = "cryosat_2";
            datasetOptions.cdr_type = ["cdr","icdr"]; 
            datasetOptions.year = "2021"; 
            datasetOptions.month = "03";


            cdsFuture = climateDataStoreDownloadAsync(datasetName, datasetOptions,"DontExpandZIP",true);
            cdsFuture.wait();

            
            % Validate that the returned class has not changed since test was written
            verifyTrue(testCase, exist(cdsFuture.OutputArguments{1},"file") == 2)
            [~,~,ext] = fileparts(cdsFuture.OutputArguments{1});
            verifyEqual(testCase, ext,".zip")
            delete(cdsFuture.OutputArguments{1})
        end
        
        function seaIceTest(testCase)
            datasetName ="satellite-sea-ice-thickness";
            datasetOptions.version = "1_0";
            datasetOptions.variable = "all";
            datasetOptions.satellite = "cryosat_2";
            datasetOptions.cdr_type = ["cdr","icdr"]; 
            datasetOptions.year = "2021"; 
            datasetOptions.month = "03";


            [downloadedFilePaths,citation] = climateDataStoreDownload(datasetName,datasetOptions);        

            
            [filepath,name,ext] =  fileparts(downloadedFilePaths);
            verifyEqual(testCase, 7,exist(filepath,"dir"))
            verifyTrue(testCase, contains(filepath,datasetName))
            verifyEqual(testCase, 2,exist(fullfile(filepath, name + ext), "file"))
            verifyEqual(testCase, ".nc", ext)
            verifyEqual(testCase, "Generated using Copernicus Climate Change Service information " + string(datetime("now","Format","yyyy")), citation)
            rmdir(filepath,"s")
        end
        
        function cancelTest(testCase)
            datasetName = "cems-glofas-reforecast";
            datasetOptions.variable = "river_discharge_in_the_last_24_hours";
            datasetOptions.product_type = "control_reforecast";
            datasetOptions.format = "grib";
            datasetOptions.system_version = "version_3_1";
            datasetOptions.hydrological_model = "lisflood";
            datasetOptions.hyear = "2018";
            datasetOptions.hmonth = "january";
            datasetOptions.hday = "03";
            datasetOptions.leadtime_hour = "24";
            datasetOptions.area = ["31","-91","29","-89"];
            
            cdsFuture = climateDataStoreDownloadAsync(datasetName, datasetOptions);
            % This test assumes it'll take a second or two to run.  If it return immediately, skip it
            if cdsFuture.State ~= "queued"
                assumeFail(testCase,"Got response before cancelling");
                return
            end
            % Get the running duration to exercise that code
            verifyClass(testCase, cdsFuture.RunningDuration,?duration)

            % Cancel the request
            cdsFuture.cancel();
            verifyEqual(testCase, cdsFuture.State,"failed")

            % Cancel again to make sure that it's a no-op
            cdsFuture.cancel();
        end
        
        function timeoutTest(testCase)
            datasetName = "cems-glofas-reforecast";
            datasetOptions.variable = "river_discharge_in_the_last_24_hours";
            datasetOptions.product_type = "control_reforecast";
            datasetOptions.format = "grib";
            datasetOptions.system_version = "version_3_1";
            datasetOptions.hydrological_model = "lisflood";
            datasetOptions.hyear = "2018";
            datasetOptions.hmonth = "january";
            datasetOptions.hday = "03";
            datasetOptions.leadtime_hour = "24";
            datasetOptions.area = ["31","-91","29","-89"];
            
            cdsFuture = climateDataStoreDownloadAsync(datasetName, datasetOptions);
            % This test assumes it'll take a second or two to run.  If it return immediately, skip it
            if cdsFuture.State ~= "queued"
                assumeFail(testCase,"Got response before waiting");
                return
            end
            
            % Wait only .1 seconds, so it'll timeout.
            failingFunction = @()(cdsFuture.wait(.1));

            verifyError(testCase,failingFunction,"climateDataStore:timeout")
        end
        
        function gribAsyncTest(testCase)
            datasetName = "cems-glofas-reforecast";
            datasetOptions.variable = "river_discharge_in_the_last_24_hours";
            datasetOptions.product_type = "control_reforecast";
            datasetOptions.format = "grib";
            datasetOptions.system_version = "version_3_1";
            datasetOptions.hydrological_model = "lisflood";
            datasetOptions.hyear = "2018";
            datasetOptions.hmonth = "january";
            datasetOptions.hday = "03";
            datasetOptions.leadtime_hour = "24";
            datasetOptions.area = ["31","-91","29","-89"];
            
            cdsFuture = climateDataStoreDownloadAsync(datasetName, datasetOptions);
            try
                % Get the running duration to exercise that code
                verifyClass(testCase, cdsFuture.RunningDuration,?duration)
                % This can take a long time.  Limit the test to 10 seconds.
                cdsFuture.wait(10);
            catch e %#ok<NASGU> 
                assumeFail(testCase,"Timeout waiting for response");
                return
            end
            verifyTrue(testCase, exist(cdsFuture.OutputArguments{1},"file") == 2)
            [~,~,ext] = fileparts(cdsFuture.OutputArguments{1});
            verifyEqual(testCase, ext,".grib")
            verifyEqual(testCase, cdsFuture.OutputArguments{2}, "Generated using Copernicus Climate Change Service information " + string(datetime('today'),'yyyy'))

            verifyEqual(testCase, cdsFuture.State,"completed")
            delete(cdsFuture.OutputArguments{1})
        end

        function csvTest(testCase)
            datasetName = "insitu-observations-surface-land";
            datasetOptions.time_aggregation = "daily";
            datasetOptions.variable = "accumulated_precipitation";
            datasetOptions.usage_restrictions = "unrestricted";
            datasetOptions.data_quality = "passed";
            datasetOptions.year = "2020";
            datasetOptions.month = "01";
            datasetOptions.day = "01";
            datasetOptions.area = ["31","-91","29","-89"];


            [downloadedFilePaths,citation] = climateDataStoreDownload(datasetName,datasetOptions);

            
            verifyTrue(testCase, exist(downloadedFilePaths(1),"file") == 2)
            verifyTrue(testCase, exist(downloadedFilePaths(2),"file") == 2)
            [~,~,ext1] = fileparts(downloadedFilePaths(1));
            verifyEqual(testCase, ext1,".csv")
            [filepath,~,ext2] = fileparts(downloadedFilePaths(2));
            verifyEqual(testCase, ext2,".txt")
            verifyEqual(testCase, citation, "Generated using Copernicus Climate Change Service information " + string(datetime('today'),'yyyy'))

            rmdir(filepath,"s")
        end

        function badDatasetNameAsyncTest(testCase)
            datasetName ="invalidname";
            datasetOptions.version = "1_0";
            datasetOptions.variable = "all";
            datasetOptions.satellite = "cryosat_2";
            datasetOptions.cdr_type = ["cdr","icdr"]; 
            datasetOptions.year = "2021"; 
            datasetOptions.month = "03";


            cdsFuture = climateDataStoreDownloadAsync(datasetName, datasetOptions);


            verifyEqual(testCase, 'climateDataStore:NameNotFound', cdsFuture.Error.identifier)
            verifyEqual(testCase, 'Data Set Name not found', cdsFuture.Error.message)
            verifyClass(testCase, cdsFuture.FinishDateTime,?datetime)
            verifySize (testCase, cdsFuture.FinishDateTime,[1 1])
            verifyEqual(testCase, cdsFuture.NumOutputArguments,0)
            verifyEmpty(testCase, cdsFuture.OutputArguments)
            verifyEqual(testCase, cdsFuture.State,"failed")
        end

        function badDatasetNameTest(testCase)
            datasetName ="invalidname";
            datasetOptions.version = "1_0";
            datasetOptions.variable = "all";
            datasetOptions.satellite = "cryosat_2";
            datasetOptions.cdr_type = ["cdr","icdr"]; 
            datasetOptions.year = "2021"; 
            datasetOptions.month = "03";
            
            failingFunction = @()(climateDataStoreDownload(datasetName, datasetOptions));

            verifyError(testCase,failingFunction,'climateDataStore:NameNotFound')
        end

        function unknownPythonErrorTest(testCase)
            datasetName ="generate-python-error";
            datasetOptions.version = "1_0";
            datasetOptions.variable = "all";
            datasetOptions.satellite = "cryosat_2";
            datasetOptions.cdr_type = ["cdr","icdr"]; 
            datasetOptions.year = "2021"; 
            datasetOptions.month = "03";
            
            failingFunction = @()(climateDataStoreDownload(datasetName, datasetOptions));

            verifyError(testCase,failingFunction,'MATLAB:Python:PyException')
        end

        function badParameterTest(testCase)
            datasetName ="satellite-sea-ice-thickness";
            datasetOptions.version = "1_0";
            datasetOptions.variable = "all";
            datasetOptions.satellite = "invalidsat";
            datasetOptions.cdr_type = ["cdr","icdr"]; 
            datasetOptions.year = "2021"; 
            datasetOptions.month = "03";

            failingFunction = @()(climateDataStoreDownload(datasetName, datasetOptions));

            verifyError(testCase,failingFunction,'climateDataStore:InvalidRequest')

        end

        function noTandCTest(testCase)
            datasetName ="satellite-fire-burned-area";
            datasetOptions.origin = 'esa_cci';
            datasetOptions.sensor = 'modis';
            datasetOptions.variable = 'grid_variables';
            datasetOptions.version = '5_1_1cds';
            datasetOptions.year = '2019';
            datasetOptions.month = '12';
            datasetOptions.nominal_day = '01';

            failingFunction = @()(climateDataStoreDownload(datasetName, datasetOptions));

            verifyError(testCase,failingFunction,'climateDataStore:agreeToTC')

        end
    end

    methods(Test, TestTags = {'SupportsMock','RequiresMock'})
        % Tests that require mocks

        function unknownErrorTest(testCase)
            % Generate an error when request made
            datasetName ="generate-error-at-request";
            datasetOptions.version = "1_0";
            datasetOptions.variable = "all";
            datasetOptions.satellite = "cryosat_2";
            datasetOptions.cdr_type = ["cdr","icdr"]; 
            datasetOptions.year = "2021"; 
            datasetOptions.month = "03";            
            failingFunction = @()(climateDataStoreDownload(datasetName, datasetOptions));
            verifyError(testCase,failingFunction,"MATLAB:UndefinedFunction")
    
            % Generate an error after request made
            datasetName = "generate-error-type1-after-request";
            datasetOptions.variable = "river_discharge_in_the_last_24_hours";
            datasetOptions.product_type = "generate_error";
            datasetOptions.format = "grib";
            datasetOptions.system_version = "version_3_1";
            datasetOptions.hydrological_model = "lisflood";
            datasetOptions.hyear = "2018";
            datasetOptions.hmonth = "january";
            datasetOptions.hday = "03";
            datasetOptions.leadtime_hour = "24";
            datasetOptions.area = ["31","-91","29","-89"];
            
            cdsFuture = climateDataStoreDownloadAsync(datasetName, datasetOptions);
            % This test assumes it'll take a second or two to run.  If it return immediately, skip it
            if cdsFuture.State ~= "queued"
                assumeFail(testCase,"Got response before waiting");
                return
            end
            
            cdsFuture.wait(2);

            verifyEqual(testCase, 'climateDataStore:UnknownError', cdsFuture.Error.identifier)
            verifyEqual(testCase, 'Simulated error after request', cdsFuture.Error.message)
            verifyEqual(testCase, cdsFuture.NumOutputArguments,0)
            verifyEmpty(testCase, cdsFuture.OutputArguments)
            verifyEqual(testCase, cdsFuture.State,"failed")
    
            % Generate an slightly different error after request made
            datasetName = "generate-error-type2-after-request";
            datasetOptions.variable = "river_discharge_in_the_last_24_hours";
            datasetOptions.product_type = "generate_error";
            datasetOptions.format = "grib";
            datasetOptions.system_version = "version_3_1";
            datasetOptions.hydrological_model = "lisflood";
            datasetOptions.hyear = "2018";
            datasetOptions.hmonth = "january";
            datasetOptions.hday = "03";
            datasetOptions.leadtime_hour = "24";
            datasetOptions.area = ["31","-91","29","-89"];
            
            cdsFuture = climateDataStoreDownloadAsync(datasetName, datasetOptions);
            % This test assumes it'll take a second or two to run.  If it return immediately, skip it
            if cdsFuture.State ~= "queued"
                assumeFail(testCase,"Got response before waiting");
                return
            end
            
            cdsFuture.wait(2);

            verifyEqual(testCase, 'climateDataStore:UnknownError', cdsFuture.Error.identifier)
            verifyEqual(testCase, 'Simulated error after request', cdsFuture.Error.message)
            verifyEqual(testCase, cdsFuture.NumOutputArguments,0)
            verifyEmpty(testCase, cdsFuture.OutputArguments)
            verifyEqual(testCase, cdsFuture.State,"failed")
        end

        function externalCancelTest(testCase)
            % Simulate a user cancelling the request on the web site
            datasetName = "external-cancel";
            datasetOptions.variable = "river_discharge_in_the_last_24_hours";
            datasetOptions.product_type = "generate_error";
            datasetOptions.format = "grib";
            datasetOptions.system_version = "version_3_1";
            datasetOptions.hydrological_model = "lisflood";
            datasetOptions.hyear = "2018";
            datasetOptions.hmonth = "january";
            datasetOptions.hday = "03";
            datasetOptions.leadtime_hour = "24";
            datasetOptions.area = ["31","-91","29","-89"];
            
            cdsFuture = climateDataStoreDownloadAsync(datasetName, datasetOptions);
            % This test assumes it'll take a second or two to run.  If it return immediately, skip it
            if cdsFuture.State ~= "queued"
                assumeFail(testCase,"Got response before waiting");
                return
            end
            
            cdsFuture.wait(2);

            verifyEqual(testCase, 'climateDataStore:RequestDeleted', cdsFuture.Error.identifier)
            verifyEqual(testCase, cdsFuture.NumOutputArguments,0)
            verifyEmpty(testCase, cdsFuture.OutputArguments)
            verifyEqual(testCase, cdsFuture.State,"failed")
        end

    end

    methods(Test)
        % These tests don't support mocking

        function noCredentials(testCase)
            %rename the credential file and set up teardown function to restore it
            movefile(fullfile(getUserDirectory,".cdsapirc"),fullfile(getUserDirectory,".cdsapirc_renamed"))
            addTeardown(testCase,@movefile,fullfile(getUserDirectory,".cdsapirc_renamed"),fullfile(getUserDirectory,".cdsapirc"))

            datasetName ="satellite-sea-ice-thickness";
            datasetOptions.version = "1_0";
            datasetOptions.variable = "all";
            datasetOptions.satellite = "nocredentials";
            datasetOptions.cdr_type = ["cdr","icdr"]; 
            datasetOptions.year = "2021"; 
            datasetOptions.month = "03";

            failingFunction = @()(climateDataStoreDownload(datasetName, datasetOptions,"DontPromptForCredentials",true));

            verifyError(testCase,failingFunction,'climateDataStore:needCredentialFile')

        end

        function exampleTest(testCase)
            % Run the examples to make sure they complete
            addpath(fullfile("climatedatastoreToolbox","doc"))
            verifyWarningFree(testCase,str2func("GettingStarted"))
            verifyWarningFree(testCase,str2func("ComparingIceThickness"))
            rmpath(fullfile("climatedatastoreToolbox","doc"))
            close(gcf)
        end
    end

end