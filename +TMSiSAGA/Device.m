classdef Device < TMSiSAGA.HiddenHandle
    %DEVICE Class provides access to a single TMSi device.
    %
    %   When a device object is created the initial device config is retrieved from
    %   the device all properties are set and the connection is closed. Depending on
    %   which functions you call some will require to "sync" your MATLAB device object
    %   with the actual device. This will require a call to updateDeviceConfig(). In case
    %   you forgot a warning will be shown in the console.
    %
    %DEVICE Properties:
    %   device_id - Device ID
    %   handle - Internal device handle for TMSi device
    %   is_connected - Keep track whether or not device is connected
    %   docking_station - Contains information about docking station
    %   data_recorder - Contains information about recording device
    %   api_version - Current API version
    %   num_batteries - Number of batteries available
    %   num_channels - Number of channels available
    %   num_hw_channels - Number of hardware channels
    %   num_sensors - Number of sensors
    %   power_state - Current power state of system
    %   batteries - Battery information
    %   time - Time information
    %   max_storage_size - Max available storage size
    %   available_storage_size - Still available storage size
    %   ambulant_recording - Ambulant recording enabled/disabled
    %   available_recordings - Recordings available
    %   name - Name of device
    %   channels - Channels
    %   sensors - Sensors
    %   impedance_mode - Impedance Mode
    %   num_active_channels - Num active channels
    %   num_active_impedance_channels - Num active impedance channels
    %   missing_samples - Missing samples
    %   sample_rate - Sample rate
    %   dividers - Dividers
    %   out_of_sync - Out of Sync with device
    %   is_sampling - True, if a sampler is sampling
    %   pinkey - Pin key
    %   configuration - Contains information on configuration settings
    %
    %DEVICE Methods:
    %   Device - Constructor for Device object.
    %   connect - Connect to the device.
    %   disconnect - Disconnect the device.
    %   start - Start sampling in sample or impedance mode.
    %   stop - Stop sampling.
    %   sample - Retrieve samples from the device.
    %   getMissingSamples - Get missing samples after a sampling session.
    %   changeDataRecorderInterfaceTo - Change the data recorder connection interface.
    %   resetDeviceConfig - Reset the device configuration to factory settings.
    %   enableChannels - Enable channels.
    %   disableChannels - Disable channels.
    %   getSensorChannels - Get all sensor channels.
    %   getActiveChannels - Get all active channels.
    %   updateDeviceConfig - Push the changed device configs to the actual TMSi device.
    %   getDeviceInfo - Get all device information from the device.
    %   updateDynamicInfo - Update dynamic calculated information for the device.
    %   getDeviceStatus - Get device status.
    %   getDeviceConfig - Get device config.
    %   setDeviceConfig - Set device config.
    %   getCurrentBandwidth - Calculates the used bandwidth of the channel configuration in use.
    %   setChannelConfig - Set channel configuration.
    %
    %DEVICE Example
    %   device = library.getFirstAvailableDevice('network', 'electrical');
    %
    %   disp(['Sample Rate: ' num2str(device.sample_rate)]);
    %   disp(['Channel Name: ' device.channels{1}.alternative_name]);
    %   disp(['Unit: ' device.channels{1}.unit_name]);
    %
    
    properties
        % Device ID
        device_id
        
        % Internal device handle for TMSi device
        handle
        
        % Keep track whether or not device is connected
        is_connected
        
        % Contains information about docking station
        docking_station
        
        % Contains information about recording device
        data_recorder
        
        % Current API version
        api_version
        
        % Number of batteries available
        num_batteries
        
        % Number of channels available
        num_channels
        
        % Number of hardware channels
        num_hw_channels
        
        % Number of sensors
        num_sensors
        
        % Current power state of system
        power_state
        
        % Battery information
        batteries
        
        % Time information
        time
        
        %         % Max available storage size. (Card recording, not supported).
        %         max_storage_size
        %
        %         % Still available storage size. (Card recording, not supported).
        %         available_storage_size
        %
        %         % Ambulant recording enabled/disabled. (Card recording, not supported).
        %         ambulant_recording
        %
        %         % Recordings available. (Card recording, not supported).
        %         available_recordings
        
        % Name of device
        name
        
        % Channels
        channels
        
        % Sensors
        sensors
        
        % Impedance Mode
        impedance_mode
        
        % Num active channels
        num_active_channels
        
        % Num active impedance channels
        num_active_impedance_channels
        
        % Missing samples
        missing_samples
        
        % Sample rate
        sample_rate
        
        % Dividers
        dividers
        
        % Out of Sync with device
        out_of_sync
        
        % True, if a sampler is sampling
        is_sampling
        
        % Pin key
        pinkey
        
        % Contains information on configuration settings
        configuration
    end
    
    properties (Access = private)
        % Library
        lib
        
        % Size of sample buffer
        prepared_sample_buffer_length
        
        % Sample buffer
        prepared_sample_buffer
        
        % Active channel indices
        active_channel_indices
        
        % Current counter channel index
        current_counter_channel_index
        
        % Current status channel index
        current_status_channel_index
    end
    
    methods (Access = private)
        
        function updateDeviceConfig_(obj, perform_factory_reset, store_as_default, web_interface_control)
            if ~exist('perform_factory_reset', 'var')
                perform_factory_reset = 0;
            end
            
            if ~exist('store_as_default', 'var')
                store_as_default = 0;
            end
            
            if ~exist('web_interface_control', 'var')
                web_interface_control = 0;
            end
            
            device_config = struct( ...
                'DRSerialNumber', obj.data_recorder.serial_number, ...
                'NrOfChannels', obj.num_channels, ...
                'SetBaseSampleRateHz', uint16(obj.configuration.base_sample_rate), ...
                'SetConfiguredInterface', uint16(TMSiSAGA.TMSiUtils.toInterfaceTypeNumber(obj.data_recorder.interface_type)), ...
                'SetTriggers', int16(obj.configuration.triggers), ...
                'SetRefMethod', int16(TMSiSAGA.TMSiUtils.toReferenceMethodNumber(obj.configuration.reference_method)), ...
                'SetAutoRefMethod', int16(obj.configuration.auto_reference_method), ...
                'SetDRSyncOutDiv', int16(obj.data_recorder.sync_out_divider), ...
                'DRSyncOutDutyCycl', int16(obj.data_recorder.sync_out_duty_cycle), ...
                'SetRepairLogging', int16(obj.configuration.repair_logging), ...
                'PerformFactoryReset', perform_factory_reset, ...
                'StoreAsDefault', store_as_default, ...
                'WebIfCtrl', web_interface_control, ...
                'PinKey', uint8(obj.pinkey) ...
                );
            
            channels = struct();
            for i=1:numel(obj.channels)
                channels(i).ChanNr = obj.channels{i}.number;
                
                if obj.channels{i}.divider ~= -1
                    
                    % divider per channel type
                    channels(i).ChanDivider = obj.dividers(obj.channels{i}.type);
                else
                    channels(i).ChanDivider = -1;
                end
                
                channels(i).AltChanName = obj.channels{i}.alternative_name;
            end
            
            TMSiSAGA.DeviceLib.setDeviceConfig(obj.handle, device_config, channels);
            
            
            TMSiSAGA.TMSiUtils.info(obj.name, 'sent device configuration')
            
            if perform_factory_reset
                msg=cell(10,1);
                msg{1}=sprintf('Please repower Data Recorder to activate factory settings.');
                msg{3}=sprintf('To do this:');
                msg{4}=sprintf('1) Undock Data Recorder from Docking Station.');
                msg{5}=sprintf('2) Remove batteries from Data Recorder.');
                msg{6}=sprintf('3) Wait for 5 seconds.');
                msg{7}=sprintf('4) Insert batteries again.');
                msg{8}=sprintf('5) Dock Data Recorder onto Docking Station.');
                msg{9}=sprintf('6) Press the power button of the Data Recorder.');
                msg{10}=sprintf('7) The default settings are now activated.');
                msgbox(msg)
            end
            
            
            
        end
        
    end
    
    methods
        function obj = Device(lib, device_id, dr_interface_type)
            %DEVICE - Constructor for device object.
            %
            %   obj = Device(lib, device_id, dr_interface_type)
            %
            %   Constructor for a device object. The library is required to be initialized and to
            %   keep track of all connected en sampling devices. Creation of device can be done with
            %   and id and interface type.
            %
            %   obj [out] - Device object.
            %   lib [in] - Library object that keeps track of all the open devices.
            %   device_id [in] - Unique device id for this device.
            %   dr_interface_type [in] - Interface type that is used by the data recorder.
            %
            
            obj.lib = lib;
            obj.data_recorder = TMSiSAGA.DataRecorderInfo();
            obj.docking_station = TMSiSAGA.DockingStationInfo();
            
            obj.device_id = device_id;
            obj.data_recorder.interface_type = dr_interface_type;
            obj.is_connected = false;
            
            obj.api_version = 0;
            
            obj.num_batteries = 0;
            obj.num_channels = 0;
            
            obj.power_state = 0;
            
            obj.batteries = struct();
            obj.time = struct();
            obj.channels = {};
            obj.configuration = struct();
            
            %             % Configuration for card recording, not supported.
            %             obj.max_storage_size = 0;
            %             obj.available_storage_size = 0;
            
            obj.impedance_mode = false;
            obj.num_active_channels = 0;
            obj.out_of_sync = true;
            
            obj.dividers = [0, 0, 0, 0, 0, 0];
            obj.pinkey = [0, 0, 0, 0];
            
            obj.prepared_sample_buffer_length = 0;
        end
        
        function connect(obj, dr_interface_type)
            %CONNECT - Open a connection to a TMSi SAGA device.
            %
            %   connect(obj, dr_interface_type)
            %
            %   Opens a connection to a TMSi SAGA device.
            %
            %   obj [in] - Device object.
            %   dr_interface_type [in] - (Optional) Interface type with which to connect. Defaults
            %       to the one set previously.
            %
            
            if (obj.is_connected)
                return
            end
            
            if ~exist('dr_interface_type', 'var')
                dr_interface_type = obj.data_recorder.interface_type;
            end
            
            % Connect device
            obj.handle = TMSiSAGA.DeviceLib.openDevice(obj.device_id, ...
                TMSiSAGA.TMSiUtils.toInterfaceTypeNumber(dr_interface_type));
            
            obj.is_connected = true;
            TMSiSAGA.TMSiUtils.info('N/A', 'opened connection to device')
            
            obj.lib.deviceConnected(obj);
            
            % Get the device information
            obj.getDeviceInfo();
        end
        
        function disconnect(obj)
            %DISCONNECT - Closes the connection to a TMSi device.
            %
            %   disconnect(obj)
            %
            %   Closes a connection to a TMSi Device.
            %
            %   obj [in] - Device object.
            %
            
            if (~obj.is_connected)
                return
            end
            
            TMSiSAGA.DeviceLib.closeDevice(obj.handle);
            obj.is_connected = false;
            
            TMSiSAGA.TMSiUtils.info(obj.name, 'closed connection to device')
            
            obj.lib.deviceDisconnected(obj);
        end
        
        function start(obj, disable_avg_ref_calculation)
            %START - Start sampling on a TMSi device.
            %
            %   start(obj, disable_avg_ref_calculation)
            %
            %   Starts sampling of a TMSi device.
            %
            %   obj - Device object.
            %   disable_avg_ref_calculation - (Optional) Disable the average reference calculation for
            %       during this sample session.
            
            if ~obj.is_connected
                throw(MException('Device:start', 'Device has not been connected.'));
            end
            
            % Show out of sync warning
            if obj.out_of_sync
                warning('Are you sure you want to start sampling, it seems that the device config is out of sync with your current settings.');
            end
            
            if obj.is_sampling
                return;
            end
            
            if ~exist('disable_avg_ref_calculation', 'var')
                disable_avg_ref_calculation = false;
            end
            
            % Prepare sample buffer
            if obj.prepared_sample_buffer_length == 0
                obj.prepared_sample_buffer_length = max(obj.configuration.base_sample_rate, obj.configuration.alternative_base_sample_rate) * obj.num_channels * 5;
                obj.prepared_sample_buffer = TMSiSAGA.DeviceLib.createDataBuffer(obj.prepared_sample_buffer_length);
            end
            
            % Get channel info values
            %   1. Look up STATUS and COUNTER index
            obj.active_channel_indices = [];
            for channel_index=1:numel(obj.channels)
                if obj.channels{channel_index}.isActive(obj.impedance_mode)
                    obj.active_channel_indices(numel(obj.active_channel_indices) + 1) = channel_index;
                    
                    if obj.channels{channel_index}.isCounter()
                        obj.current_counter_channel_index = numel(obj.active_channel_indices);
                    end
                    
                    if obj.channels{channel_index}.isStatus()
                        obj.current_status_channel_index = numel(obj.active_channel_indices);
                    end
                end
            end
            
            obj.missing_samples = [];
            TMSiSAGA.DeviceLib.resetDeviceDataBuffer(obj.handle);
            
            % Set sampling request
            if obj.impedance_mode
                TMSiSAGA.DeviceLib.setDeviceImpedance(obj.handle, struct('SetImpedanceMode', uint16(1)));
            else
                device_sample_request = struct( ...
                    'SetSamplingMode', uint16(1), ...
                    'DisableAutoswitch', ~obj.configuration.auto_reference_method, ...
                    'DisableRepairLogging', ~obj.configuration.repair_logging, ...
                    'DisableAvrRefCalc', disable_avg_ref_calculation ...
                    );
                TMSiSAGA.DeviceLib.setDeviceSampling(obj.handle, device_sample_request);
            end
            
            obj.is_sampling = true;
            
            % Inform user on start of sampling
            TMSiSAGA.TMSiUtils.info(obj.name, 'started sampling from device')
            TMSiSAGA.TMSiUtils.info(obj.name, ['    autoswitch=' num2str(obj.configuration.auto_reference_method)])
            TMSiSAGA.TMSiUtils.info(obj.name, ['    repair_logging=' num2str(obj.configuration.repair_logging)])
            TMSiSAGA.TMSiUtils.info(obj.name, ['    avr_ref_calc=' num2str(~disable_avg_ref_calculation)])
            
            obj.lib.deviceStartedSampling(obj);
        end
        
        function stop(obj)
            %STOP - Stop sampling on a TMSi device.
            %
            %   stop(obj)
            %
            %   Stops sampling of a TMSi device.
            %
            %   obj - Device object.
            %
            %   Can be called when:
            %   - Device is connected.
            %   - Device is (not) sampling.
            
            if ~obj.is_connected
                throw(MException('Device:stop', 'Device has not been connected.'));
            end
            
            if ~obj.is_sampling
                return
            end
            
            % Stop sampling request
            if obj.impedance_mode
                TMSiSAGA.DeviceLib.setDeviceImpedance(obj.handle, struct('SetImpedanceMode', uint16(0)));
            else
                device_sample_request = struct( ...
                    'SetSamplingMode', uint16(0), ...
                    'DisableAutoswitch', false, ...
                    'DisableRepairLogging', false, ...
                    'DisableAvrRefCalc', false ...
                    );
                TMSiSAGA.DeviceLib.setDeviceSampling(obj.handle, device_sample_request);
            end
            
            obj.is_sampling = false;
            
            % Inform user that sampling has stopped
            TMSiSAGA.TMSiUtils.info(obj.name, 'stopped sampling from device')
            
            obj.lib.deviceStoppedSampling(obj);
        end
        
        function [data, num_sets, data_type] = sample(obj)
            %SAMPLE - Retrieves samples from the device and does some basic processing.
            %
            %   [data, num_sets, data_type] = sample(obj)
            %
            %   Retrieves samples from the device and does some basic processing on them. The
            %   returned samples are in double format, but have been converted from float, int32
            %   or other types. Potential transformations like sensor calculations and/or exponents
            %   have already been applied.
            %
            %   data [out] - Transformed data retrieved from the device.
            %   num_sets [out] - Number of samples per channel present in
            %       data block
            %   data_type [out] - Type of data (1 - Sample data, 2 -
            %       Impedance data, 3 - Recording data (unavailable in 
            %       MATLAB))
            %   obj [in] - Device object.
            %
            %   Can be called when:
            %   - Device is connected.
            %   - Device is sampling.
            
            % Can only be called when sampling
            if ~obj.is_sampling
                throw(MException('Device:sample', 'failed because device was not open for sampling'));
            end
            
            data = [];
            
            % Get data from device and reshape into channels x sets
            [raw_data, num_sets, data_type] = TMSiSAGA.DeviceLib.getDeviceData(obj.handle, obj.prepared_sample_buffer, obj.prepared_sample_buffer_length);
            
            num_channels = obj.num_active_channels;
            if obj.impedance_mode
                num_channels = obj.num_active_impedance_channels;
            end
            
            raw_data = reshape(raw_data(1:(num_sets * num_channels)), [num_channels, num_sets]);
            
            % No need to do anything if empty
            if num_sets == 0
                return
            end
            
            % Data in double format
            data = zeros(num_channels, num_sets);
            
            % Loop over channels and transform raw_data to data
            for i=1:numel(obj.active_channel_indices)
                channel = obj.channels{obj.active_channel_indices(i)};
                
                if channel.isActive(obj.impedance_mode)
                    data(i, :) = channel.transform(raw_data(i, :));
                end
            end
            
            % If repair logging is on, check for missing samples
            missing_samples_mask = bitand(uint32(data(obj.current_status_channel_index, :)), uint32(hex2dec('100')));
            missing_samples_mask(missing_samples_mask > 0) = 1;
            
            if obj.configuration.repair_logging && numel(missing_samples_mask) > 0 && any(missing_samples_mask)
                index = data(obj.current_counter_channel_index, 1);
                count = 0;
                
                for i=1:num_sets
                    if missing_samples_mask(i)
                        count = count + 1;
                    else
                        if count > 0
                            % Clearing previous printed number of missing 
                            % samples
                            if ~isempty(obj.missing_samples)
                                old_print_message = ['Total number of missing samples: ', num2str(sum(obj.missing_samples(2:2:end)))];
                                disp(repmat(char(8),1,length(old_print_message)+2))
                            end
                            
                            % Save the index and total number of missing
                            % samples.
                            obj.missing_samples = [obj.missing_samples, index, count + 1];
                            
                            % Print number of missing samples
                            print_message = ['Total number of missing samples: ', num2str(sum(obj.missing_samples(2:2:end)))];
                            disp(print_message);
                        end
                        
                        index = data(obj.current_counter_channel_index, i);
                        count = 0;
                    end
                end
                
                if count > 0
                    % Clearing previous printed number of missing samples
                    if ~isempty(obj.missing_samples)
                        old_print_message = ['Total number of missing samples: ', num2str(sum(obj.missing_samples(2:2:end)))];
                        disp(repmat(char(8),1,length(old_print_message)+2))
                    end
                    
                    % Save the index and the total number of missing
                    % samples
                    obj.missing_samples = [obj.missing_samples, index, count + 1];
                    
                    % Print number of missing samples
                    print_message = ['Total number of missing samples: ', num2str(sum(obj.missing_samples(2:2:end)))];
                    disp(print_message);
                end
            end
        end
        
        function [data_d, num_sets] = getMissingSamples(obj)
            %GETMISSINGSAMPLES - This function retrieves all missing samples.
            %
            %   [data_d, num_sets] = getMissingSamples(obj)
            %
            %   This function returns a data set with all the missing samples that have
            %   been detected during sampling. A missing sample is detected by checking
            %   the STATUS channel for overflow value.
            %
            %   data_d [out] - Repair data.
            %   num_sets [out] - Number of samples per channel in the
            %       repair data
            %   obj [in] - Device object.
            %
            %   Can be called when:
            %   - Device is connected.
            %   - Device is not sampling.
            
            if obj.is_sampling
                throw(MException('Sampler:getMissingSamples', 'cannot get missing samples while sampling'));
            end
            
            num_samples = 0;
            for i=1:2:numel(obj.missing_samples)
                num_samples = num_samples + obj.missing_samples(i + 1);
            end
            
            num_channels = obj.num_active_channels;
            if obj.impedance_mode
                num_channels = obj.num_active_impedance_channels;
            end
            
            if numel(obj.missing_samples) == 0
                data_d = zeros([num_channels, 0]);
                num_sets = 0;
                return
            end
            
            TMSiSAGA.TMSiUtils.info(obj.name, 'start retrieving missing samples')
            
            d = single(zeros(1, num_samples));
            num_sets = 0;
            num_repaired = 0;
            counter = 1;
            % Number of sample sets must always be 4
            max_number_of_sample_sets = 4; 
            
            for i=1:2:numel(obj.missing_samples)
                sample_start = obj.missing_samples(i);
                num_sample_sets = obj.missing_samples(i + 1);
                
                % Request a repair from the device
                for j=1:max_number_of_sample_sets:num_sample_sets
                    repair_request = struct(...
                        'SampleStartCntr', sample_start + (j - 1), ...
                        'NROfSampleSets', max_number_of_sample_sets ...
                        );
                    
                    [d, n] = TMSiSAGA.DeviceLib.getDeviceRepairData(obj.handle, obj.prepared_sample_buffer, obj.prepared_sample_buffer_length, repair_request);
                    
                    data(counter:(counter + n - 1)) = d(1:n);
                    num_sets = num_sets + n / num_channels;
                    counter = counter + n;
                end
                num_repaired =  num_repaired +obj.missing_samples(i + 1);
                
                % Inform user on the progress of the repair
                TMSiSAGA.TMSiUtils.info(obj.name, ['at sample ' num2str(num_repaired) ' of ' num2str(num_samples)]);
            end
            
            data = reshape(data(1:(num_sets * num_channels)), [num_channels, num_sets]);
            
            % Data in double format
            data_d = zeros(num_channels, num_sets);
            
            % Transforming repaired data
            TMSiSAGA.TMSiUtils.info(obj.name, 'transforming missing sample data')
            
            % Loop over channels and transform raw_data to data
            for i=1:numel(obj.active_channel_indices)
                channel = obj.channels{obj.active_channel_indices(i)};
                
                if channel.isActive(obj.impedance_mode)
                    data_d(i, :) = channel.transform(data(i, :));
                end
            end
            % Inform user that repair has been completed
            TMSiSAGA.TMSiUtils.info(obj.name, 'done retrieving missing samples')
        end
        
        function changeDataRecorderInterfaceTo(obj, dr_interface_type)
            %CHANGEDATARECORDERINTERFACETO - Change interface of the data recorder.
            %
            %   changeDataRecorderInterfaceTo(obj, dr_interface_type)
            %
            %   This function will change the interface type of the data recorder and
            %   immediatly disconnects the device. To use the device you will have to
            %   reconnect to it by help of the library.
            %
            %   obj [in] - Device object.
            %   dr_interface_type [in] - Interface type that is used by the data recorder.
            %
            %   Can be called when:
            %   - Device is connected.
            %   - Device is not sampling.
            
            if ~obj.is_connected
                throw(MException('Device:changeDataRecorderInterfaceTo', 'Can only change interface while connected to device.'));
            end
            
            if obj.is_sampling
                throw(MException('Device:changeDataRecorderInterfaceTo', 'Cannot change data recorder interface while sampling.'));
            end
            
            obj.data_recorder.interface_type = dr_interface_type;
            
            obj.updateDeviceConfig_();
            obj.disconnect();
        end
        
        function resetDeviceConfig(obj)
            %RESETDEVICECONFIG - Will restore the device config back the factory values.
            %
            %   resetDeviceConfig(obj)
            %
            %   Function will reset all configuration back to basic values.
            %
            %   obj [in] - Device object.
            %
            %   Can be called when:
            %   - Device is connected.
            %   - Device is not sampling.
            
            if ~obj.is_connected
                throw(MException('Device:resetDeviceConfig', 'Can only reset device config while connected to device.'));
            end
            
            if obj.is_sampling
                throw(MException('Device:resetDeviceConfig', 'Cannot reset device config while sampling.'));
            end
            
            % Set factory_reset parameter to true and update device
            % configuration.
            obj.updateDeviceConfig(true);
            
            TMSiSAGA.TMSiUtils.info(obj.name, 'reset configuration back to factory settings')
            obj.disconnect
            obj.connect
        end
        
        function enableChannels(obj, channels)
            %ENABLECHANNELS Will enable all channels that are selected.
            %
            %   enableChannels(obj, channels)
            %
            %   This function will enable all channels that are given as parameter. Other
            %   channels will NOT be disabled, it only enables channels. The channels parameter
            %   can be an array of channel numbers, or a cell array of Channel objects. The
            %   channels are only enabled in MATLAB. To ensure the device sees this, call the
            %   updateDeviceConfig() function.
            %
            %   obj [in] - Device object.
            %   channels [in] - An array of channel numbers or a cell array of Channel objects.
            %
            %   Can be called when:
            %   - Device is connected.
            %   - Device is not sampling.
            
            if obj.is_sampling
                throw(MException('Device:enableChannels', 'Cannot enable/disable channels while sampling.'));
            end
            
            for i=1:numel(channels)
                if isa(channels, 'double')
                    obj.channels{channels(i)}.enable();
                else
                    channels{i}.enable();
                end
            end
            
            obj.out_of_sync = true;
        end
        
        function disableChannels(obj, channels)
            %DISABLECHANNELS Will disable all channels that are selected.
            %
            %   disableChannels(obj, channels)
            %
            %   This function will disable all channels that are given as parameter. Other
            %   channels will NOT be enabled, it only disables channels. The channels parameter
            %   can be an array of channel numbers, or a cell array of Channel objects. The
            %   channels are only disabled in MATLAB. To ensure the device sees this, call the
            %   updateDeviceConfig() function.
            %
            %   obj [in] - Device object.
            %   channels [in] - An array of channel numbers or a cell array of Channel objects.
            %
            %   Can be called when:
            %   - Device is connected.
            %   - Device is not sampling.
            
            if obj.is_sampling
                throw(MException('Device:disableChannels', 'Cannot enable/disable channels while sampling.'));
            end
            
            for i=1:numel(channels)
                if isa(channels, 'double')
                    obj.channels{channels(i)}.disable();
                else
                    channels{i}.disable();
                end
            end
            
            obj.out_of_sync = true;
        end
        
        function channels = getSensorChannels(obj)
            %GETSENSORCHANNELS Get a cell array of sensor channels.
            %
            %   channels = getSensorChannels(obj)
            %
            %   This function will return a cell array of Channel objects that are sensors.
            %
            %   channels [out] - Cell array with all sensor channels
            %   obj [in] - Device object.
            %
            
            channels = {};
            
            for i=1:numel(obj.sensors)
                for j=1:obj.sensors{i}.num_channels
                    channels{numel(channels) + 1} = obj.channels{obj.sensors{i}.channel_number + j};
                end
            end
        end
        
        function channels = getActiveChannels(obj)
            %GETACTIVECHANNELS - Get a cell array of active channels.
            %
            %   channels = getActiveChannels(obj)
            %
            %   This function will return a cell array of Channels object of all channels that
            %   are active. A channel is active when the divider of the channel does not equal
            %   -1. When impedance mode is on it will return all channels that are active in
            %   impedance mode.
            %
            %   channels [out] - Cell array with all active channels
            %   obj [in] - Device object.
            %
                        
            channels = {};
            
            for i=1:numel(obj.channels)
                if obj.channels{i}.isActive(obj.impedance_mode)
                    channels{numel(channels) + 1} = obj.channels{i};
                end
            end
        end
        
        function updateDeviceConfig(obj, perform_factory_reset, store_as_default, web_interface_control)
            %UPDATEDEVICECONFIG - Apply config changes to the device.
            %
            %   updateDeviceConfig(obj, perform_factory_reset, store_as_default, web_interface_control)
            %
            %   This function will apply the device config changes that have been made to the Device object, to
            %   the actual TMSi Device. This function will also call getDeviceInfo() and will override all
            %   settings with how they have been interperted by the actual device. So after this call
            %   the device object and TMSi device should be in sync with respect to configuration.
            %   Furthermore, the bandwidth of the updated device config is calculated.
            %
            %   obj [in] - Device object.
            %   perform_factory_reset [in] - (Optional) If true, this will cause an factory reset.
            %   store_as_default [in] - (Optional) If true, will store the current settings as default on TMSi Device.
            %   web_interface_control [in] - (Optional) If true, turn on web interface control.
            %
            %   This function can be called when:
            %   - Device is connected
            %   - Device is not sampling
            %
            
            if obj.is_sampling
                throw(MException('Device:updateDeviceConfig', 'Device config can not be set while sampling.'));
            end
            
            if ~exist('perform_factory_reset', 'var')
                perform_factory_reset = 0;
            end
            
            if ~exist('store_as_default', 'var')
                store_as_default = 0;
            end
            
            if ~exist('web_interface_control', 'var')
                web_interface_control = 0;
            end
            
            obj.updateDeviceConfig_(perform_factory_reset, store_as_default, web_interface_control)
            obj.getDeviceInfo();
        end
        
        function getDeviceInfo(obj)
            %GETDEVICEINFO - Retrieve all device info from a TMSi device.
            %
            %   getDeviceInfo(obj)
            %
            %   This function will retrieve the device status, device config and update dynamic info.
            %
            %   obj [in] - Device object.
            %
            
            if (~obj.is_connected)
                throw(MException('Device:getDeviceInfo', 'Device is not connected.'));
            end
            
            obj.getDeviceStatus();
            obj.getDeviceConfig();
            obj.updateDynamicInfo();
            obj.getCurrentBandwidth();
            
            obj.out_of_sync = false;
        end
        
        function updateDynamicInfo(obj)
            %UPDATEDYNAMICINFO - Update info that has to be calculated based on the device status and config.
            %
            %   updateDynamicInfo(obj)
            %
            %   obj [in] - Device object.
            %
            
            min_divider = 100000;
            for i=1:numel(obj.channels)
                if obj.channels{i}.divider ~= -1 && ~obj.channels{i}.isCounter() && ~obj.channels{i}.isStatus() && obj.channels{i}.divider < min_divider
                    min_divider = obj.channels{i}.divider;
                end
            end
            
            obj.sample_rate = obj.configuration.base_sample_rate / 2^min_divider;
        end
        
        function getDeviceStatus(obj)
            %GETDEVICESTATUS - Get basic status information of the device.
            %
            %   getDeviceStatus(obj)
            %
            %   Information like serial number, battery status, power status, time and storage are retrieved and updated on this
            %   device object.
            %
            %   obj [in] - Device object.
            %
            
            if (~obj.is_connected)
                throw(MException('Device:getDeviceStatus', 'Device has not been connected.'));
            end
            
            device_report = TMSiSAGA.DeviceLib.getDeviceStatus(obj.handle);
            
            % Assign the device report properties to the Device class'
            % properties.
            obj.docking_station.serial_number = int64(device_report.DSSerialNr);
            obj.data_recorder.serial_number = int64(device_report.DRSerialNr);
            obj.docking_station.interface_type = TMSiSAGA.TMSiUtils.toInterfaceTypeString(device_report.DSInterface);
            obj.data_recorder.interface_type = TMSiSAGA.TMSiUtils.toInterfaceTypeString(device_report.DRInterface);
            obj.api_version = int64(device_report.DSDevAPIVersion);
            obj.data_recorder.available = int64(device_report.DRAvailable);
            obj.num_batteries = int64(device_report.NrOfBatteries);
            obj.num_channels = int64(device_report.NrOfChannels);
            
            [device_report, battery_report_list, time_report, storage_report] = ...
                TMSiSAGA.DeviceLib.getFullDeviceStatus(obj.handle, obj.num_batteries);
            
            obj.power_state = int64(device_report.PowerState);
            obj.docking_station.temperature = int64(device_report.DSTemp);
            obj.data_recorder.temperature = int64(device_report.DRTemp);
            
            for i = 1:obj.num_batteries
                obj.batteries(i).id = int64(battery_report_list(i).BatID);
                obj.batteries(i).temprature = int64(battery_report_list(i).BatTemp);
                obj.batteries(i).voltage = int64(battery_report_list(i).BatVoltage);
                obj.batteries(i).remaining_capacity = int64(battery_report_list(i).BatRemainingCapacity);
                obj.batteries(i).full_charge_capacity = int64(battery_report_list(i).BatFullChargeCapacity);
                obj.batteries(i).average_current = int64(battery_report_list(i).BatAverageCurrent);
                obj.batteries(i).minutes_remaining = int64(battery_report_list(i).BatTimeToEmpty);
                obj.batteries(i).capacity = int64(battery_report_list(i).BatStateOfCharge);
                obj.batteries(i).health = int64(battery_report_list(i).BatStateOfHealth);
                obj.batteries(i).cycle_count = int64(battery_report_list(i).BatCycleCount);
            end
            
            obj.time.seconds = int64(time_report.Seconds);
            obj.time.minutes = int64(time_report.Minutes);
            obj.time.hours = int64(time_report.Hours);
            obj.time.day_of_month = int64(time_report.DayOfMonth);
            obj.time.month = int64(time_report.Month);
            obj.time.year = int64(time_report.Year);
            obj.time.week_day = int64(time_report.WeekDay);
            obj.time.year_day = int64(time_report.YearDay);
            
            %             % Status for card recording, not supported.
            %             obj.max_storage_size = int64(storage_report.TotalSizeMB);
            %             obj.available_storage_size = int64(storage_report.UsedSizeMB);
        end
        
        function getDeviceConfig(obj)
            %GETDEVICECONFIG - Get and update specific device configuration information.
            %
            %   getDeviceConfig(obj)
            %
            %   This function will update the device configuration properties as they are currently set
            %   on the device.
            %
            %   obj [in] - Device object.
            %
            
            if (~obj.is_connected)
                throw(MException('Device:getDeviceConfig', 'Device has not been connected.'));
            end
            
            % Retrieve device config and channel config from the device
            [rec_conf, channel_list] = TMSiSAGA.DeviceLib.getDeviceConfig(obj.handle, obj.num_channels);
            
            % Assign the retrieved configuration settings to the Device
            % class' properties
            obj.data_recorder.serial_number = int64(rec_conf.DRSerialNumber);
            obj.data_recorder.id = int64(rec_conf.DRDevID);
            obj.num_hw_channels = int64(rec_conf.NrOfHWChannels);
            obj.num_channels = int64(rec_conf.NrOfChannels);
            obj.num_sensors = int64(rec_conf.NrOfSensors);
            obj.configuration.base_sample_rate = int64(rec_conf.BaseSampleRateHz);
            obj.configuration.alternative_base_sample_rate = int64(rec_conf.AltBaseSampleRateHz);
            obj.configuration.interface_bandwidth = int64(rec_conf.InterFaceBandWidth);
            obj.configuration.triggers = int64(rec_conf.TriggersEnabled);
            obj.configuration.reference_method = TMSiSAGA.TMSiUtils.toReferenceMethodString(int64(rec_conf.RefMethod));
            obj.configuration.auto_reference_method = int64(rec_conf.AutoRefMethod);
            obj.data_recorder.sync_out_divider = int64(rec_conf.DRSyncOutDiv);
            obj.data_recorder.sync_out_duty_cycle = int64(rec_conf.DRSyncOutDutyCycl);
            obj.docking_station.sync_out_divider = int64(rec_conf.DSSyncOutDiv);
            obj.docking_station.sync_out_duty_cycle = int64(rec_conf.DSSyncOutDutyCycl);
            obj.configuration.repair_logging = int64(rec_conf.RepairLogging);
            obj.name = rec_conf.DeviceName;
            
            %             % Configuration for card recording, not supported.
            %             obj.ambulant_recording = int64(rec_conf.AmbRecording);
            %             obj.available_recordings = int64(rec_conf.AvailableRecordings);
            
            % Assign the channel list configuration to the Device class'
            % channel configuration
            obj.num_active_channels = 0;
            obj.num_active_impedance_channels = 0;
            obj.channels = TMSiSAGA.Channel.empty;
            for i=1:numel(channel_list)
                channel_list(i).Number = i - 1;
                obj.channels{i} = TMSiSAGA.Channel(obj, channel_list(i));
                
                if obj.channels{i}.isActive()
                    obj.num_active_channels = obj.num_active_channels + 1;
                    
                    obj.dividers(obj.channels{i}.type) = obj.channels{i}.divider;
                end
                
                if obj.channels{i}.isActive(true)
                    obj.num_active_impedance_channels = obj.num_active_impedance_channels + 1;
                end
            end
            
            sensor_list = TMSiSAGA.DeviceLib.getDeviceSensors(obj.handle, obj.num_sensors);
            for i=1:numel(sensor_list)
                obj.sensors{i} = TMSiSAGA.Sensor(obj, sensor_list(i));
                
                for j=1:numel(obj.sensors{i}.channels)
                    % Channels are counted starting at 0. Hence, 1 is added
                    % to the index of the channel.
                    obj.channels{obj.sensors{i}.channels{j}.channel_number + 1}.sensor_channel = obj.sensors{i}.channels{j};
                end
            end
        end
        
        function setDeviceConfig(obj, config)
            %SETDEVICECONFIG - Set the device configuration to the desired
            %    settings.
            %
            %   setDeviceConfig(obj, config)
            %
            %   Method takes a single struct as input which contains
            %   information on which configuration settings to update and
            %   to what value.
            %
            %   obj [in] - Device object.
            %   config [in] - Struct containing keyword-value combinations 
            %       to update the device configuration
            %
            %   The following keywords are used to update the device 
            %   configuration. All parameters are optional:
            %
            %   - ImpedanceMode - Turn on/off impedance mode.
            %       Input: true/false
            %
            %   - Dividers - Set the dividers to configure the sample
            %   rate for a given type of sensor (base_sample_rate /
            %   2^divider).
            %       Input: Cell array with channel type
            %       ('exg'/'bip'/'aux'/'dig') and integer value.
            %
            %   - BaseSampleRate - Change base sample rate of the
            %   device.
            %       Input: 4000/4096.
            %
            %   - Triggers - Turn on/off triggers.
            %       Input: true/false
            %
            %   - ReferenceMethod - Sets the reference method used by
            %   the device. Common Reference mode uses a single channel,
            %   average reference mod uses the average of all connected
            %   channels to determine the reference.
            %       Input: 'common'/'average'
            %
            %   - AutoReferenceMethod - Sets whether the device will
            %   automatically change from common reference mode to average
            %   reference mode when the common reference channel is
            %   disconnected.
            %       Input: true/false
            %
            %   - RepairLogging - Turns repair logging on or off, so
            %   that missing samples can be retrieved later on.
            %       Input: true/false
            %
            %   - SyncOutDivider - Sets the sync out divider
            %   of the Data Recorder. (sample_rate / SyncOutDivider)
            %       Input: Integer, maximum frequency is Fs/8.
            %
            %   - SyncOutDutyCycle - Sets the duty cycle of
            %   the Data Recorder.
            %       Input: Integer, between 125 and 875 (12.5% to 87.5%)
            %
            %EXAMPLE:
            %   % Update the device configuration to sample all unipolar
            %   % channels at 2000 Hz and all bipolar channels at 1000 Hz.
            %   config = struct('BaseSampleRate', 4000, ...
            %                   'Dividers', {{'exg', 1; 'bip', 2;}});
            %   device.setDeviceConfig(config);
            
            % Device configuration can only be set when the device is
            % connected and not sampling.
            if (~obj.is_connected)
                throw(MException('Device:setDeviceConfig', 'Device has not been connected.'));
            end
            
            if (obj.is_sampling)
                throw(MException('Device:setDeviceConfig', 'Cannot change data recorder configuration while sampling.'));
            end
            
            % Set the ImpedanceMode
            if isfield(config, 'ImpedanceMode')
                if ~isa(config.ImpedanceMode,'logical')
                    throw(MException('Device:SetImpedanceMode', 'ImpedanceMode argument type should be a boolean.'));
                end
                
                obj.impedance_mode = config.ImpedanceMode;
            end
            
            % Set the Dividers
            if isfield(config, 'Dividers')
                for i = 1:size(config.Dividers,1)
                    if ~isa(config.Dividers{i,1}, 'char')
                        throw(MException('Device:setDividers', 'Divider argument type should be a string.'));
                    end
                    
                    obj.dividers(TMSiSAGA.TMSiUtils.toChannelTypeNumber(config.Dividers{i,1})) = config.Dividers{i,2};
                end
            end
            
            % Set the BaseSampleRate
            if isfield(config, 'BaseSampleRate')
                if config.BaseSampleRate ~= 4000 && config.BaseSampleRate ~= 4096
                    throw(MException('Device:setBaseSampleRate', 'Currently only sample rates of 4000 and 4096 are supported as base sample rate.'));
                end
                obj.configuration.base_sample_rate = config.BaseSampleRate;
                
                obj.out_of_sync = true;
            end
            
            % Set the Triggers
            if isfield(config, 'Triggers')
                if ~isa(config.Triggers, 'logical')
                    throw(MException('Device:setTriggers', 'Triggers argument should be true or false.'));
                end
                
                obj.configuration.triggers = config.Triggers;
                
                obj.out_of_sync = true;
            end
            
            % Set the ReferenceMethod
            if isfield(config, 'ReferenceMethod')
                if ~isa(config.ReferenceMethod, 'char')
                    throw(MException('Device:setReferenceMethod', 'Reference method argument should be a string (common, average).'));
                end
                
                if ~strcmp(config.ReferenceMethod, 'common') && ~strcmp(config.ReferenceMethod, 'average')
                    throw(MException('Device:setReferenceMethod', 'Reference method argument should be common or average.'));
                end
                
                obj.configuration.reference_method = config.ReferenceMethod;
                
                obj.out_of_sync = true;
            end
            
            % Set the AutoReferenceMethod
            if isfield(config, 'AutoReferenceMethod')
                if ~isa(config.AutoReferenceMethod, 'logical')
                    throw(MException('Device:setAutoReferenceMethod', 'Change auto reference method argument should be true or false.'));
                end
                
                obj.configuration.auto_reference_method = config.AutoReferenceMethod;
            end
            
            % Set the RepairLogging
            if isfield(config, 'RepairLogging')
                if ~isa(config.RepairLogging, 'logical')
                    throw(MException('Device:setRepairLogging', 'Repair logging argument should be true or false.'));
                end
                
                obj.configuration.repair_logging = config.RepairLogging;
            end
            
            % Set the SyncOutDivider
            if isfield(config, 'SyncOutDivider')
                obj.data_recorder.sync_out_divider = config.SyncOutDivider;
                obj.out_of_sync = true;                
            end
            
            % Set the SyncOutDutyCycle
            if isfield(config, 'SyncOutDutyCycle')
                obj.data_recorder.sync_out_duty_cycle = config.SyncOutDutyCycle;
                obj.out_of_sync = true;  
            end
            
            % Update the device configuration
            obj.updateDeviceConfig();
        end
               
        function getCurrentBandwidth(obj)
            %GETCURRENTBANDWIDTH -  Function that calculates the current bandwidth in use
            %   based on the device configuration. A warning is presented when the interface 
            %   bandwidth of the current configuration is exceeded.
            %
            %   getCurrentBandwidth(obj)
            %
            %   obj [in] - Device object.
            %
            %   Total bandwidth is defined as: 80 * Fs + sum(bandwidth of channel)
            
            % Find the sum of the bandwidth per channel
            obj.configuration.used_bandwidth = 0;
            
            for i = 1:numel(obj.channels)
                obj.configuration.used_bandwidth = obj.configuration.used_bandwidth + obj.channels{i}.bandwidth;
            end
            
            % The overhead bits are mulitplied with the lowest sample rate used in the
            % device.
            max_divider = max(obj.dividers);
            sample_rate_low = obj.configuration.base_sample_rate / 2.^max_divider;
            
            % Bandwidth is defined as sum of all channels + sample rate * overhead
            obj.configuration.used_bandwidth = obj.configuration.used_bandwidth + sample_rate_low * 80;
            
            % Convert bandwidth from bits/sec to Mbits/sec
            obj.configuration.used_bandwidth = double(obj.configuration.used_bandwidth) / 1e6;
            
            % Give feedback to the user on the configured bandwidth that is
            % in use.
            if obj.configuration.used_bandwidth > obj.configuration.interface_bandwidth
                warning('[SAGA DR ] current configuration violates the allowed bandwidth. Please change configuration by adapting sampling rate or disabling channels')
            elseif obj.configuration.used_bandwidth < obj.configuration.interface_bandwidth && strcmp(obj.data_recorder.interface_type, 'wifi')
                disp('[SAGA DR ] current configuration is within WiFi-bandwidth constraints.')
            end
        end
        
        function setChannelConfig(obj, ChannelConfig)
            %SETCHANNELCONFIG - Function that applies the specified channel configuration.
            %
            %   setChannelConfig(obj, ChannelConfig)
            %
            %   Function that applies a specified channel configuration.
            %   When a channel is not present in the specified
            %   configuration, the channel will be disabled.
            %
            %   obj [in] - Device object.
            %   ChannelConfig [in] - Desired channel configuration. 
            % 
            %   ChannelConfig may contain the following name/value pairs:
            %   ChannelConfig.uni - UNI channels, 1-32 for SAGA 32+ or 1-64 
            %       for SAGA 64+
            %   ChannelConfig.bip - BIP channels, 1-4
            %   ChannelConfig.aux - AUX channels, 1-9
            %   ChannelConfig.acc - internal accelerometer channels 0 or 1 
            %       for disbale/enable
            %   ChannelConfig.dig - DIGI configuration, 0 for DIGI Trigger 
            %       or 1 saturation sensor
            
            
            % Check what type of channels need to be configured.
            if ~isfield(ChannelConfig, 'uni')
                ChannelConfig.uni=0;
            end
            if ~isfield(ChannelConfig, 'bip')
                ChannelConfig.bip=0;
            end
            if ~isfield(ChannelConfig, 'aux')
                ChannelConfig.aux=0;
            end
            if ~isfield(ChannelConfig, 'acc')
                ChannelConfig.acc=0;
            end
            if ~isfield(ChannelConfig, 'dig')
                ChannelConfig.dig=0;
            end
            
            count_UNI = 0;
            count_BIP = 0;
            count_AUX = 0;
            count_Dig = 0;
            
            % Enable used channels
            for i=1:length(obj.channels)
                % Enable desired BIP channels
                if (obj.channels{i}.isBip())
                    count_BIP = count_BIP + 1;
                    if ismember(count_BIP, ChannelConfig.bip)
                        obj.enableChannels(i);
                    else
                        obj.disableChannels(i);
                    end
                    % Enable desired UNI channels
                elseif (obj.channels{i}.isExG())
                    count_UNI = count_UNI + 1;
                    if ismember(count_UNI, ChannelConfig.uni + 1) && ~strcmp(obj.channels{i}.name,'CREF') %+1 for CREF channel
                        obj.enableChannels(i);
                    else
                        obj.disableChannels(i);
                    end
                    % Enable desired AUX channels
                elseif (obj.channels{i}.isAux())
                    count_AUX = count_AUX + 1;
                    if ismember(count_AUX, ChannelConfig.aux)
                        obj.enableChannels(i);
                    else
                        obj.disableChannels(i);
                    end
                    % Enable desired Digital/sensor channels
                elseif (obj.channels{i}.isDig())
                    count_Dig=count_Dig+1;
                    if ChannelConfig.dig&&(count_Dig>1)&&(count_Dig<=5) %Enable saturation channels
                        obj.enableChannels(i);
                    elseif ChannelConfig.acc&&(count_Dig>5)&&(count_Dig<=8)%Enable accelerometer channels
                        obj.enableChannels(i);
                    else
                        obj.disableChannels(i);
                    end
                end
            end         
                        
            % Update the device configuration
            obj.updateDeviceConfig();
        end
        
    end
end