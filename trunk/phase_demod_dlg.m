function varargout = phase_demod_dlg(varargin)
% PHASE_DEMOD_DLG MATLAB code for phase_demod_dlg.fig
%      PHASE_DEMOD_DLG, by itself, creates a new PHASE_DEMOD_DLG or raises the existing
%      singleton*.
%
%      H = PHASE_DEMOD_DLG returns the handle to a new PHASE_DEMOD_DLG or the handle to
%      the existing singleton*.
%
%      PHASE_DEMOD_DLG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PHASE_DEMOD_DLG.M with the given input arguments.
%
%      PHASE_DEMOD_DLG('Property','Value',...) creates a new PHASE_DEMOD_DLG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before phase_demod_dlg_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to phase_demod_dlg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help phase_demod_dlg

% Last Modified by GUIDE v2.5 19-Feb-2015 07:18:59

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @phase_demod_dlg_OpeningFcn, ...
                   'gui_OutputFcn',  @phase_demod_dlg_OutputFcn, ...
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


% --- Executes just before phase_demod_dlg is made visible.
function phase_demod_dlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to phase_demod_dlg (see VARARGIN)

% Choose default command line output for phase_demod_dlg
handles.output = hObject;

try
	load([mfilename '_cfg.mat']);

	fl = fieldnames(handles);
	for fi = 1:numel(fl)
		if strcmp(get(handles.(fl{fi}),'Type'),'uicontrol') && strcmp(get(handles.(fl{fi}),'Style'),'edit')
			set(handles.(fl{fi}),'String',dlg_cfg.(fl{fi}));
		end
	end

	set(hObject,'Position',dlg_cfg.position);
catch
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes phase_demod_dlg wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = phase_demod_dlg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in openfile_btn.
function openfile_btn_Callback(hObject, eventdata, handles)
% hObject    handle to openfile_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[dlg_name,dlg_path]=uigetfile({'*.wav','Wave files (*.wav)'},'Выберите файл для обработки',get(handles.openfile_edit,'String'));
if dlg_name==0
	return
end
set(handles.openfile_edit,'String',fullfile(dlg_path,dlg_name));


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(hObject, 'Visible','off');
pause(0.2);

fl = fieldnames(handles);
for fi = 1:numel(fl)
	if strcmp(get(handles.(fl{fi}),'Type'),'uicontrol') && strcmp(get(handles.(fl{fi}),'Style'),'edit')
		dlg_cfg.(fl{fi}) = get(handles.(fl{fi}),'String');
	end
end

dlg_cfg.position = get(hObject,'Position');

save([mfilename '_cfg.mat'], 'dlg_cfg');

% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes on button press in process_btn.
function process_btn_Callback(hObject, eventdata, handles)
% hObject    handle to process_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
filename = get(handles.openfile_edit,'String');
[x,fs] = wavread(filename);
x(:,2:end) = [];
t = (0:size(x,1)-1)'/fs;
w = str2double(get(handles.filterlp_cutoff_edit,'String'))*2/fs;
b = fir1(round(str2double(get(handles.filterlp_order_edit,'String'))*fs), w);

f1 = str2double(get(handles.freq1_edit,'String'));
f2 = str2double(get(handles.freq2_edit,'String'));
report_str = ['F1=' num2str(f1) '; F2=' num2str(f2) '; LP filter order=' num2str(numel(b)) ', cutoff=' num2str(w) '.'];

f1 = filter(b,1, x.*cos(2*pi*f1*t));
f2 = filter(b,1, x.*cos(2*pi*f2*t));

[cur_dir, cur_name] = fileparts(filename);
figure('NumberTitle','off', 'Name',cur_name, 'Units','normalized', 'Position',[0 0 1 1]);
subplot(2,1,1);
plot(t,x);
title(filename,'Interpreter','none');
subplot(2,1,2);
ord2 = fix(numel(b)/2);
plot(t(1:end-ord2+1),f1(ord2:end)-f2(ord2:end));
title(report_str);

set(zoom,'ActionPostCallback',@on_zoom_pan);
set(pan ,'ActionPostCallback',@on_zoom_pan);
zoom('xon');
set(pan, 'Motion', 'horizontal');


function on_zoom_pan(hObject, eventdata) %#ok<INUSD>
%	Usage example:
%	set(zoom,'ActionPostCallback',@on_zoom_pan);
%	set(pan ,'ActionPostCallback',@on_zoom_pan);
%	zoom('xon');
%	set(pan, 'Motion', 'horizontal');

x_lim=xlim();

data=guidata(hObject);
if isfield(data,'user_data') && isfield(data.user_data.x_len)
	rg=x_lim(2)-x_lim(1);
	if x_lim(1)<0
		x_lim=[0 rg];
	end
	if x_lim(2)>data.user_data.x_len
		x_lim=[max(0, data.user_data.x_len-rg) data.user_data.x_len];
	end
end

child=get(hObject,'Children');
set( child( strcmp(get(child,'type'),'axes') & not(strcmp(get(child,'tag'),'legend')) ), 'XLim', x_lim);
