function varargout = ICA_dialog(varargin)
% ICA_DIALOG M-file for ICA_dialog.fig
%      ICA_DIALOG, by itself, creates a new ICA_DIALOG or raises the existing
%      singleton*.
%
%      H = ICA_DIALOG returns the handle to a new ICA_DIALOG or the handle to
%      the existing singleton*.
%
%      ICA_DIALOG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ICA_DIALOG.M with the given input arguments.
%
%      ICA_DIALOG('Property','Value',...) creates a new ICA_DIALOG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ICA_dialog_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ICA_dialog_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ICA_dialog

% Last Modified by GUIDE v2.5 06-May-2013 20:33:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ICA_dialog_OpeningFcn, ...
                   'gui_OutputFcn',  @ICA_dialog_OutputFcn, ...
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


% --- Executes just before ICA_dialog is made visible.
function ICA_dialog_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ICA_dialog (see VARARGIN)

% Choose default command line output for ICA_dialog
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ICA_dialog wait for user response (see UIRESUME)
% uiwait(handles.figure1);

	if exist('ICA_dialog.mat','file')
		load('ICA_dialog.mat','cfg');
	else
	    cfg.file='';
		cfg.f0=100;
		cfg.f0_bnd=0.035;
		cfg.type=2;
		cfg.phase=1;
		cfg.factor=[1 2; 1 3; 2 4];
		cfg.env_sel=[0.5 0.5];
		cfg.debug=0;
	end
	if size(cfg.factor,2)<4
		cfg.factor(4,1)=0;
	end

	set(handles.ed_file, 'String', cfg.file);
	set(handles.ed_f0,   'String', num2str(cfg.f0));
	if isfield(cfg,'f0_bnd')
		set(handles.ed_f0_bnd,   'String', num2str(cfg.f0_bnd));
	end

	if cfg.phase==0
		set(handles.rb_phase1, 'Value', 1);
	else
		set(handles.rb_phase2, 'Value', 1);
	end;

	if cfg.type==0
		set(handles.rb_type1, 'Value', 1);
		set(handles.rb_phase2, 'Value', 1);
	else
		set(handles.rb_type2, 'Value', 1);
	end;

	set(handles.tbl_factor, 'Data', cfg.factor);

	set(handles.ed_sel_beg, 'String', cfg.env_sel(1));
	set(handles.ed_sel_end, 'String', cfg.env_sel(2));
	
	set(handles.cb_debug, 'Value', cfg.debug);
	
	uipanel1_SelectionChangeFcn(hObject, eventdata, handles);


% --- Outputs from this function are returned to the command line.
function varargout = ICA_dialog_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function ed_file_Callback(hObject, eventdata, handles)
% hObject    handle to ed_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_file as text
%        str2double(get(hObject,'String')) returns contents of ed_file as a double


% --- Executes during object creation, after setting all properties.
function ed_file_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in bnt_file_sel.
function bnt_file_sel_Callback(hObject, eventdata, handles)
% hObject    handle to bnt_file_sel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[dlg_file,dlg_path]=uigetfile({'*.wav', 'Звуковые файлы (*.wav)'; '*.*', 'Все файлы (*.*)'}, 'Выберите файл для обработки', get(handles.ed_file,'String'));
if dlg_file~=0
	set(handles.ed_file,'String',fullfile(dlg_path, dlg_file));
end

function ed_f0_Callback(hObject, eventdata, handles)
% hObject    handle to ed_f0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_f0 as text
%        str2double(get(hObject,'String')) returns contents of ed_f0 as a double


% --- Executes during object creation, after setting all properties.
function ed_f0_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_f0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ed_sel_beg_Callback(hObject, eventdata, handles)
% hObject    handle to ed_sel_beg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_sel_beg as text
%        str2double(get(hObject,'String')) returns contents of ed_sel_beg as a double


% --- Executes during object creation, after setting all properties.
function ed_sel_beg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_sel_beg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ed_sel_end_Callback(hObject, eventdata, handles)
% hObject    handle to ed_sel_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_sel_end as text
%        str2double(get(hObject,'String')) returns contents of ed_sel_end as a double


% --- Executes during object creation, after setting all properties.
function ed_sel_end_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_sel_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cb_debug.
function cb_debug_Callback(hObject, eventdata, handles)
% hObject    handle to cb_debug (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cb_debug


% --- Executes on button press in btn_calc.
function btn_calc_Callback(hObject, eventdata, handles)
% hObject    handle to btn_calc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	cfg=update_config(handles);

	Intercomponent_Analysis(cfg.file, cfg.f0, cfg.type, cfg.factor, cfg.phase, cfg.env_sel(1), cfg.env_sel(2), 0, cfg.debug, cfg.f0_bnd);

function cfg=update_config(handles)
	cfg.file= get(handles.ed_file, 'String');
	cfg.f0=   str2double(get(handles.ed_f0,   'String'));
	cfg.f0_bnd=   str2double(get(handles.ed_f0_bnd,   'String'));

	cfg.type= get(handles.rb_type2, 'Value');
	cfg.phase=get(handles.rb_phase2, 'Value');

	cfg.factor=get(handles.tbl_factor, 'Data');
	cfg.factor(any(isnan(cfg.factor) | cfg.factor==0, 2), :)=[];

	cfg.env_sel(1)=str2double(get(handles.ed_sel_beg, 'String'));
	cfg.env_sel(2)=str2double(get(handles.ed_sel_end, 'String'));

	cfg.debug=get(handles.cb_debug, 'Value');

	save('ICA_dialog.mat','cfg');


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

update_config(handles);

% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes when selected object is changed in uipanel1.
function uipanel1_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel1 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

	if get(handles.rb_type1, 'Value')
		set(handles.rb_phase1, 'Enable', 'off');
		set(handles.rb_phase2, 'Value', 1);
	else
		set(handles.rb_phase1, 'Enable', 'on');
	end



function ed_f0_bnd_Callback(hObject, eventdata, handles)
% hObject    handle to ed_f0_bnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_f0_bnd as text
%        str2double(get(hObject,'String')) returns contents of ed_f0_bnd as a double


% --- Executes during object creation, after setting all properties.
function ed_f0_bnd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_f0_bnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


