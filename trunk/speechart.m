function varargout = speechart(varargin)
% SPEECHART MATLAB code for speechart.fig
%      SPEECHART, by itself, creates a new SPEECHART or raises the existing
%      singleton*.
%
%      H = SPEECHART returns the handle to a new SPEECHART or the handle to
%      the existing singleton*.
%
%      SPEECHART('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SPEECHART.M with the given input arguments.
%
%      SPEECHART('Property','Value',...) creates a new SPEECHART or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before speechart_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to speechart_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help speechart

% Last Modified by GUIDE v2.5 01-Mar-2013 15:30:11

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @speechart_OpeningFcn, ...
                   'gui_OutputFcn',  @speechart_OutputFcn, ...
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


% --- Executes just before speechart is made visible.
function speechart_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to speechart (see VARARGIN)

% Choose default command line output for speechart
handles.output = hObject;

signal.sample_rate = 11025;
signal.frame_size = round(0.040*signal.sample_rate);
signal.FFT_N = pow2(2+nextpow2(signal.frame_size));
signal.rceps = round(0.004*signal.sample_rate);
signal.lpc_order = round(signal.sample_rate/1000+4);

hold(handles.ax_spectrum, 'on');
gui.fft_hndl =   plot(handles.ax_spectrum, linspace(0,signal.sample_rate/2,signal.FFT_N/2+1), randn(signal.FFT_N/2+1,1));
gui.rceps_hndl = plot(handles.ax_spectrum, linspace(0,signal.sample_rate/2,signal.FFT_N/2+1), randn(signal.FFT_N/2+1,1), 'm');
gui.lpc_hndl =   plot(handles.ax_spectrum, (0:signal.FFT_N/2-1)*signal.sample_rate/signal.FFT_N, randn(signal.FFT_N/2,  1), 'r');
axis(handles.ax_spectrum, [0 signal.sample_rate/2, -60 20]);

recorder=audiorecorder(signal.sample_rate,16,1);
set(recorder, 'TimerFcn',@recorder_callback, 'TimerPeriod',0.005, 'UserData',struct('hObject',hObject, 'handles',handles, 'signal',signal, 'gui',gui));
handles.user.recorder = recorder;
record(recorder);

% Update handles structure
guidata(hObject, handles);


% UIWAIT makes speechart wait for user response (see UIRESUME)
% uiwait(handles.speechart_fig);

% --- Outputs from this function are returned to the command line.
function varargout = speechart_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function varargout = recorder_callback(recorder, eventdata)
	user_info = get(recorder,'UserData');
	if recorder.TotalSamples>recorder.SampleRate*5
		stop(recorder); % Clear audio recorder buffer
		record(recorder);
	end
	if recorder.TotalSamples<user_info.signal.frame_size
		return
	end

	cur_frame = getaudiodata(recorder);
	cur_frame(1:end-user_info.signal.frame_size)=[];

	% Proeemphasis
	cur_frame = filter([1 -0.97],1,cur_frame);
	
	% Windowing
	cur_frame = cur_frame.*hamming(length(cur_frame));

	% FFT spectrum
	fx = fft(cur_frame, user_info.signal.FFT_N);
	fx(length(fx)/2+2:end)=[];
	fx = 10*log10(fx.*conj(fx));

	set(user_info.gui.fft_hndl, 'YData', fx);

	% Real cepstrum
	cur_rceps=ifft([fx; fx(end-1:-1:2)]);
	cur_rceps(user_info.signal.rceps:end-user_info.signal.rceps+2)=0;
	cur_rceps_H=real(fft(cur_rceps));
	cur_rceps_H(length(cur_rceps_H)/2+2:end)=[];
	
	set(user_info.gui.rceps_hndl, 'YData', cur_rceps_H);

	% LPC spectrum
	[cur_a, cur_err_pwr] = lpc(cur_frame, user_info.signal.lpc_order);
	if cur_err_pwr>0
		cur_a=cur_a./sqrt(cur_err_pwr*user_info.signal.frame_size);
	end
	if any(isnan(cur_a))
		cur_a=[1 zeros(1, user_info.signal.lpc_order)];
	end
	cur_lpc_H = freqz(1,cur_a,user_info.signal.FFT_N/2);

	set(user_info.gui.lpc_hndl, 'YData', 10*log10(cur_lpc_H.*conj(cur_lpc_H)));


% --- Executes when user attempts to close speechart_fig.
function speechart_fig_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to speechart_fig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: delete(hObject) closes the figure

stop(handles.user.recorder);
delete(handles.user.recorder);

delete(hObject);
