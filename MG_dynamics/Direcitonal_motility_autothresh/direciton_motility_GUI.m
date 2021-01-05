function varargout = direciton_motility_GUI(varargin)
% DIRECITON_MOTILITY_GUI MATLAB code for direciton_motility_GUI.fig
%      DIRECITON_MOTILITY_GUI, by itself, creates a new DIRECITON_MOTILITY_GUI or raises the existing
%      singleton*.
%
%      H = DIRECITON_MOTILITY_GUI returns the handle to a new DIRECITON_MOTILITY_GUI or the handle to
%      the existing singleton*.
%
%      DIRECITON_MOTILITY_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DIRECITON_MOTILITY_GUI.M with the given input arguments.
%
%      DIRECITON_MOTILITY_GUI('Property','Value',...) creates a new DIRECITON_MOTILITY_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before direciton_motility_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to direciton_motility_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help direciton_motility_GUI

% Last Modified by GUIDE v2.5 04-Aug-2020 00:00:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @direciton_motility_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @direciton_motility_GUI_OutputFcn, ...
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


% --- Executes just before direciton_motility_GUI is made visible.
function direciton_motility_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to direciton_motility_GUI (see VARARGIN)

% Choose default command line output for direciton_motility_GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes direciton_motility_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = direciton_motility_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in radiobutton1.
function radiobutton1_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton1
