function result = iraptWrapper(fileName, data)
    if isempty(fileName) && nargin<2 %Process def file
        fileName = 'D:\Repository\Phase\bispectrum\test_set_16kHz\icassp2017_female.wav';
    elseif isempty(fileName) && nargin==2 %Wride to def file
        fileName = fullfile(pwd, 'Out', 'sound.wav');
    end
    if nargin == 2
        audiowrite(fileName, data.y/max(abs(data.y)), data.Fs);
    end
    CUIhandl = phase_analysis_dlg();
    Hdls = guidata(CUIhandl);
    set(Hdls.ed_filename, 'String', fileName);
    resultHandl = Hdls.btn_calc.Callback(CUIhandl, []);
    data = guihandles(resultHandl);
    result.baseTone = data.user_data.f0_freq;
    close(resultHandl)
    close(CUIhandl)
end