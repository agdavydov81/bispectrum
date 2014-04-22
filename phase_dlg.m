function varargout = phase_dlg(varargin)
% PHASE_DLG MATLAB code for phase_dlg.fig
%      PHASE_DLG, by itself, creates a new PHASE_DLG or raises the existing
%      singleton*.
%
%      H = PHASE_DLG returns the handle to a new PHASE_DLG or the handle to
%      the existing singleton*.
%
%      PHASE_DLG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PHASE_DLG.M with the given input arguments.
%
%      PHASE_DLG('Property','Value',...) creates a new PHASE_DLG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before phase_dlg_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to phase_dlg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help phase_dlg

% Last Modified by GUIDE v2.5 01-Jun-2013 08:29:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @phase_dlg_OpeningFcn, ...
                   'gui_OutputFcn',  @phase_dlg_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before phase_dlg is made visible.
function phase_dlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to phase_dlg (see VARARGIN)

% Choose default command line output for phase_dlg
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes phase_dlg wait for user response (see UIRESUME)
% uiwait(handles.figure1);

	if exist([mfilename() '_cfg.mat'],'file')
		load([mfilename() '_cfg.mat'],'dlg_cfg');
	else
		dlg_cfg.signal_ed = '';
		dlg_cfg.centralfreq_ed = '5000';
		dlg_cfg.omegafreq_ed = '2000';
		dlg_cfg.passband_ed = '100';
		dlg_cfg.passorder_ed = '0.05';
	end
	
	fl = fieldnames(dlg_cfg);
	for fi=1:numel(fl)
		set(handles.(fl{fi}), 'String', dlg_cfg.(fl{fi}));
	end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

	fl = fieldnames(handles);
	fl = regexp(fl,'.+_ed$','match','once');
	fl(cellfun(@isempty, fl)) = [];

	for fi=1:numel(fl)
		dlg_cfg.(fl{fi}) = get(handles.(fl{fi}), 'String');
	end

	save([mfilename() '_cfg.mat'],'dlg_cfg');

% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Outputs from this function are returned to the command line.
function varargout = phase_dlg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function omegafreq_ed_Callback(hObject, eventdata, handles)
% hObject    handle to omegafreq_ed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of omegafreq_ed as text
%        str2double(get(hObject,'String')) returns contents of omegafreq_ed as a double


% --- Executes during object creation, after setting all properties.
function omegafreq_ed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to omegafreq_ed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function centralfreq_ed_Callback(hObject, eventdata, handles)
% hObject    handle to centralfreq_ed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of centralfreq_ed as text
%        str2double(get(hObject,'String')) returns contents of centralfreq_ed as a double


% --- Executes during object creation, after setting all properties.
function centralfreq_ed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to centralfreq_ed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function passband_ed_Callback(hObject, eventdata, handles)
% hObject    handle to passband_ed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of passband_ed as text
%        str2double(get(hObject,'String')) returns contents of passband_ed as a double


% --- Executes during object creation, after setting all properties.
function passband_ed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to passband_ed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function signal_ed_Callback(hObject, eventdata, handles)
% hObject    handle to signal_ed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of signal_ed as text
%        str2double(get(hObject,'String')) returns contents of signal_ed as a double


% --- Executes during object creation, after setting all properties.
function signal_ed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to signal_ed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in signal_btn.
function signal_btn_Callback(hObject, eventdata, handles)
% hObject    handle to signal_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[dlg_file,dlg_path]=uigetfile({'*.wav', 'Звуковые файлы (*.wav)'; '*.*', 'Все файлы (*.*)'}, 'Выберите файл для обработки', get(handles.signal_ed,'String'));
if dlg_file~=0
	set(handles.signal_ed,'String',fullfile(dlg_path, dlg_file));
end


function passorder_ed_Callback(hObject, eventdata, handles)
% hObject    handle to passorder_ed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of passorder_ed as text
%        str2double(get(hObject,'String')) returns contents of passorder_ed as a double


% --- Executes during object creation, after setting all properties.
function passorder_ed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to passorder_ed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in process_btn.
function process_btn_Callback(hObject, eventdata, handles)
% hObject    handle to process_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	[x,fs]=wavread(get(handles.signal_ed,'String'));

	cfg.central_freq = str2double(get(handles.centralfreq_ed,'String'));
	cfg.omega_freq =   str2double(get(handles.omegafreq_ed,'String'));
	cfg.pass_band =    str2double(get(handles.passband_ed,'String'));
	cfg.pass_order =   str2double(get(handles.passorder_ed,'String'));
	cfg.pass_order = round((cfg.pass_order*fs)/2)+1;
	
	phmtr_type =	find([	get(handles.outtype_btn1,'Value');
							get(handles.outtype_btn2,'Value');
							get(handles.outtype_btn3,'Value') ]);

						
	switch(phmtr_type)
		case 1
			y = phasometer_galaev_kivva(x, fs, cfg);
			y_t = (0:length(y)-1)/fs;
		case 2
%			[out_dphi, out_dphi_t]=Intercomponent_Analysis(x, gcd(cfg.central_freq), ret_type, K, phasometr_type, amp_thres_beg, amp_thres_end, freq_factor, is_display, F0_bnd)
		case 3
%			[out_dphi, out_dphi_t]=Intercomponent_Analysis(x, F_base, ret_type, K, phasometr_type, amp_thres_beg, amp_thres_end, freq_factor, is_display, F0_bnd)
		otherwise
			error('Unknown phasometer type');
	end

	figure();
	plot(y_t,y);

function y = phasometer_galaev_kivva(x, fs, cfg)
	x_lo = sel_band(x, fs, cfg.central_freq-cfg.omega_freq+cfg.pass_band*[-0.5 0.5], cfg.pass_order);
	x_c  = sel_band(x, fs, cfg.central_freq           +cfg.pass_band*[-0.5 0.5], cfg.pass_order);
	x_hi = sel_band(x, fs, cfg.central_freq+cfg.omega_freq+cfg.pass_band*[-0.5 0.5], cfg.pass_order);

	x_loc = sel_band(x_c.*x_lo, fs, cfg.omega_freq+cfg.pass_band*[-0.5 0.5], cfg.pass_order);
	x_hic = sel_band(x_c.*x_hi, fs, cfg.omega_freq+cfg.pass_band*[-0.5 0.5], cfg.pass_order);

	y = sel_band(x_loc.*x_hic, fs, cfg.pass_band*0.5, cfg.pass_order);

function y = sel_band(x, fs, band, order)
	b = fir1(order, band*2/fs);
	y= filtfilt(b, 1, x);


% --- Executes on button press in outtype_btn1.
function outtype_btn1_Callback(hObject, eventdata, handles)
% hObject    handle to outtype_btn1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of outtype_btn1


% --- Executes on button press in outtype_btn2.
function outtype_btn2_Callback(hObject, eventdata, handles)
% hObject    handle to outtype_btn2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of outtype_btn2


% --- Executes on button press in outtype_btn3.
function outtype_btn3_Callback(hObject, eventdata, handles)
% hObject    handle to outtype_btn3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of outtype_btn3
