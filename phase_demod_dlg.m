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

% Last Modified by GUIDE v2.5 26-Feb-2015 06:28:42

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
		if strcmp(get(handles.(fl{fi}),'Type'),'uicontrol') && isfield(dlg_cfg,fl{fi})
			switch get(handles.(fl{fi}),'Style')
				case 'edit'
					set(handles.(fl{fi}),'String',dlg_cfg.(fl{fi}));
				case {'checkbox' 'popupmenu'}
					set(handles.(fl{fi}),'Value',dlg_cfg.(fl{fi}));
			end
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


% --- Executes on button press in inputfile_btn.
function inputfile_btn_Callback(hObject, eventdata, handles)
% hObject    handle to inputfile_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[dlg_name,dlg_path]=uigetfile({'*.wav','Wave files (*.wav)'},'Выберите файл для обработки',get(handles.inputfile_edit,'String'));
if dlg_name==0
	return
end
set(handles.inputfile_edit,'String',fullfile(dlg_path,dlg_name));


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(hObject, 'Visible','off');
pause(0.2);

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

dlg_cfg.position = get(hObject,'Position');

save([mfilename '_cfg.mat'], 'dlg_cfg');

% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes on button press in process_btn.
function process_btn_Callback(hObject, eventdata, handles)
% hObject    handle to process_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
filename = get(handles.inputfile_edit,'String');
[x,fs] = wavread(filename);
x(:,2:end) = [];
if get(handles.inputfile_invert,'Value')
	x = x(end:-1:1,:);
end

eval(['F=' get(handles.freq_f,'String') ';']);
F = F(:)';
Kk = str2double_my(get(handles.freq_k,'String'));
eval(['phi=' get(handles.freq_phase_shift,'String') ';']);
phi = phi(1); % parfor fix
isclip = get(handles.freq_isclip,'Value');

w = str2double_my(get(handles.filterlp_cutoff_edit,'String'))*2/fs;
b = fir1(round(str2double_my(get(handles.filterlp_order_edit,'String'))*fs), w);
ord2 = fix(numel(b)/2);

x = [x; zeros(ord2,1)];
t = (0:size(x,1)-1)'/fs;

report_str = ['F=' get(handles.freq_f,'String') '; Kk=' num2str(Kk) '; LP filter order=' num2str(numel(b)) ', cutoff=' num2str(w) '.'];

try
	if get(handles.gui_usepool,'Value') && matlabpool('size')==0
		local_jm=findResource('scheduler','type','local');
		if local_jm.ClusterSize>1
			matlabpool('local');
		end
	end
catch
end

Y = cell(size(F));
parfor fi = 1:numel(F)
	Y{fi} = proc_signal(x, F(fi), t, 0, isclip, b)  -  proc_signal(x, Kk*F(fi), t, phi, isclip, b);
end
Y = cell2mat(Y);
x(end-ord2+1:end) = [];
t(end-ord2+1:end) = [];

[cur_dir, cur_name] = fileparts(filename);
figure('NumberTitle','off', 'Name',cur_name, 'Units','normalized', 'Position',[0 0 1 1]);
subplot(2,1,1);
plot(t,x);
x_lim = t([1 end])';
axis([x_lim max(abs(x))*1.1*[-1 1]]);
title(filename,'Interpreter','none');

subplot(2,1,2);
if size(Y,2) == 1
	plot(t,Y);
	xlim(x_lim);
else
	imagesc(t,F,Y');
	pal = get(handles.gui_palette,'String');
	pal = pal{get(handles.gui_palette,'Value')};
	colormap(getcolormap(pal));
	axis('xy');
end
title(report_str);

set(zoom,'ActionPostCallback',@on_zoom_pan);
set(pan ,'ActionPostCallback',@on_zoom_pan);
zoom('xon');
set(pan, 'Motion', 'horizontal');


function x = str2double_my(str)
if any(str==',')
	errordlg('При указании чисел с плавающей запятой в полях ввода должна использоваться точка, а не запятая.');
	error('Incorrect input parameters.');
end
x = str2double(str);


function y = proc_signal(x,f,t,phi,isclip,b)
y = cos(2*pi*f*t+phi);
if isclip
	ii = y>=0;
	y(ii) = 1;
	y(~ii) = -1;
end
y = filter(b,1, x.*y);
y(1:fix(numel(b)/2)) = [];


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


function map = getcolormap(colormaptype)
switch lower(colormaptype)
	case 'antigray'
		map=makecolormap([	  0   1   1   1;
							0.4   1   1   1;
							0.9   0   0   0;
							  1   0   0   0]);
	case 'speech'
		map=makecolormap([	0	  0   0   1;...
							1/3	  0   1   0;...
							2/3	  1   0   0;...
							  1	  1   1   0]);
	case 'fire'
		map=makecolormap([	0	  0   0   0;...
						  0.113	0.5   0   0;...
						  0.315	  1   0   0;...
						  0.450	  1 0.5   0;...
						  0.585	  1   1   0;...
						  0.765	  1   1 0.5;...
							  1	  1   1   1]);
	case 'hsl'
		map=makecolormap([	0	  0   0   0;...
							1/7	  1   0   1;...
							2/7	  0   0   1;...
							3/7	  0   1   1;...
							4/7	  0 0.5   0;...
							5/7	  1   1   0;...
							6/7	  1   0   0;...
							  1	  1   1   1]);
	otherwise
		map=colormaptype;
end


function map = makecolormap(map_info)
map=zeros(64,3);
map(1,:)=map_info(1,2:4);
index=1;
for i=2:63
	pos=(i-1)/63;
	while map_info(index,1)<=pos
		index=index+1;
	end
	map(i,:)=map_info(index-1,2:4)+(map_info(index,2:4)-map_info(index-1,2:4))*(pos-map_info(index-1,1))/(map_info(index,1)-map_info(index-1,1));
end
map(64,:)=map_info(end,2:4);
