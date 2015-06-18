function varargout = reg2alp_dlg(varargin)
% REG2ALP_DLG MATLAB code for reg2alp_dlg.fig
%      REG2ALP_DLG, by itself, creates a new REG2ALP_DLG or raises the existing
%      singleton*.
%
%      H = REG2ALP_DLG returns the handle to a new REG2ALP_DLG or the handle to
%      the existing singleton*.
%
%      REG2ALP_DLG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in REG2ALP_DLG.M with the given input arguments.
%
%      REG2ALP_DLG('Property','Value',...) creates a new REG2ALP_DLG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before reg2alp_dlg_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to reg2alp_dlg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help reg2alp_dlg

% Last Modified by GUIDE v2.5 18-Jun-2015 11:54:34

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @reg2alp_dlg_OpeningFcn, ...
                   'gui_OutputFcn',  @reg2alp_dlg_OutputFcn, ...
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


% --- Executes just before reg2alp_dlg is made visible.
function reg2alp_dlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to reg2alp_dlg (see VARARGIN)

% Choose default command line output for reg2alp_dlg
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

load_dlg_config(handles);

% UIWAIT makes reg2alp_dlg wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject, 'Visible','off');
pause(0.2);

save_dlg_config(handles);

% Hint: delete(hObject) closes the figure
delete(hObject);


function load_dlg_config(handles, hObject)
try
	load([mfilename '_cfg.mat']);

	fl = fieldnames(handles);
	for fi = 1:numel(fl)
		if strcmp(get(handles.(fl{fi}),'Type'),'uicontrol') && isfield(dlg_cfg,fl{fi})
			switch get(handles.(fl{fi}),'Style')
				case 'edit'
					set(handles.(fl{fi}),'String',dlg_cfg.(fl{fi}));
				case {'checkbox' 'popupmenu'}
					set(handles.(fl{fi}),'Value',dlg_cfg.(fl{fi}));
			end
		end
	end

	% Position to center of screen
	if nargin<2
		hObject = handles.figure1;
	end
	old_units = get(hObject,'Units');
	scr_sz = get(0,'ScreenSize');
	set(hObject,'Units',get(0,'Units'));
	cur_pos = get(hObject,'Position');
	set(hObject,'Position',[(scr_sz(3)-cur_pos(3))/2, (scr_sz(4)-cur_pos(4))/2, cur_pos([3 4])]);
	set(hObject,'Units',old_units); 	
catch %#ok<CTCH>
end	


function save_dlg_config(handles)
fl = fieldnames(handles);
for fi = 1:numel(fl)
	if strcmp(get(handles.(fl{fi}),'Type'),'uicontrol')
		switch get(handles.(fl{fi}),'Style')
			case 'edit'
				dlg_cfg.(fl{fi}) = get(handles.(fl{fi}),'String');
			case {'checkbox' 'popupmenu'}
				dlg_cfg.(fl{fi}) = get(handles.(fl{fi}),'Value');
		end
	end
end

save([mfilename '_cfg.mat'], 'dlg_cfg'); 


% --- Outputs from this function are returned to the command line.
function varargout = reg2alp_dlg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in wav_select_btn.
function wav_select_btn_Callback(hObject, eventdata, handles)
% hObject    handle to wav_select_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[dlg_name,dlg_path] = uigetfile({'*.wav','Wave files (*.wav)';'*.*','All files'}, 'Выберите файл для обработки' , get(handles.wav_edit,'String'));
if dlg_name==0
	return;
end
set(handles.wav_edit,'String',fullfile(dlg_path,dlg_name));


% --- Executes on button press in wav_play_btn.
function wav_play_btn_Callback(hObject, eventdata, handles)
% hObject    handle to wav_play_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
dos(['start "" "' get(handles.wav_edit,'String') '"']);


% --- Executes on button press in dir_select_btn.
function dir_select_btn_Callback(hObject, eventdata, handles)
% hObject    handle to dir_select_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
dlg_name = uigetdir(get(handles.dir_edit,'String'), 'Выберите директорию для сохранения результата');
if dlg_name==0
	return
end
set(handles.dir_edit,'String',dlg_name); 


function [region_pos, region_name] = safe_wav_regions_read(wav_file)
% Функция [region_pos, region_name] = safe_wav_regions_read(wav_file) предназначена для загрузки
%   регионов из .wav файла.
%   Параметры:
%       wav_file - имя файла, откуда будут загружены регионы;
%       region_pos - матрица Nx2 регионов [начало длинна] (в отсчетах начиная с 1).
%		region_name - cell имен регионов
%
%   See also WAV_REGIONS_WRITE.

%   Версия: 1.1
%   Автор: Давыдов А.Г. (18.05.2010)
region_pos = zeros(0, 2);
region_name= {};

try
	txt_file=tempname();
	[dos_status,dos_result] = dos(['"' which('WavRegionsExtractor.exe') '" "' wav_file '" "' txt_file '"']); %#ok<NASGU,ASGLU>
	[a b region_name]=textread(txt_file,'%d%d%s', 'whitespace','\t'); %#ok<REMFF1>
	delete(txt_file);
	region_pos=[a+1, b];
catch %#ok<CTCH>
end


% --- Executes on button press in process_btn.
function process_btn_Callback(hObject, eventdata, handles)
% hObject    handle to process_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
wav_filename = get(handles.wav_edit,'String');
[x,fs] = wavread(wav_filename);

[reg_pos, reg_name] = safe_wav_regions_read(wav_filename);

kill_ind = reg_pos(:,2)==0;
reg_name(kill_ind) = [];
reg_pos(kill_ind,:) = [];

kill_ind = ~cellfun(@isempty, regexp(reg_name, '^Cue \d+$', 'match','once'));
reg_name(kill_ind) = [];
reg_pos(kill_ind,:) = [];

[sv,si] = sort(reg_pos(:,1));
reg_name = reg_name(si);
reg_pos = reg_pos(si,:);

reg_pos(:,2) = reg_pos(:,1) + reg_pos(:,2) - 1;

dir_path = get(handles.dir_edit,'String');
if ~exist(dir_path,'dir')
	mkdir(dir_path);
end

wait_h = waitbar(0,'Обработка', 'WindowStyle','modal');
for ri = 1:size(reg_pos,1)
	cur_dir = dir_path;
	if get(handles.save_to_subfolders,'Value')
		cur_dir = fullfile(cur_dir, regexprep(reg_name{ri},'\d*$',''));
		if ~exist(cur_dir,'dir')
			mkdir(cur_dir);
		end
	end

	cur_name = fullfile(cur_dir, [reg_name{ri} '.wav']);

	if get(handles.save_all_instances,'Value')
		name_cnt = 0;
		while exist(cur_name,'file')
			name_cnt = name_cnt + 1;
			cur_name = fullfile(cur_dir, sprintf('%s_(%03d).wav',reg_name{ri},name_cnt));
		end
	end

	if ~exist(cur_name,'file')
		wavwrite(x(reg_pos(ri,1):reg_pos(ri,2)), fs, cur_name);
	end

	waitbar(ri/size(reg_pos,1), wait_h, sprintf('Обработка %d/%d',ri,size(reg_pos,1)));
end
delete(wait_h);
