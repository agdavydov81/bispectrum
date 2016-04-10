classdef simplegettext < handle
	%simplegettext - simple localisation class

	properties
		messages_filename;
		messages;
		language;
	end

	methods(Static)
		function lng = identify_language()
			[X,w] = weekday(728647,'long','local');
			lang_list = {'eng', 'Monday'; % ISO 639-3 codes
						 'rus', 'Понедельник';
						 'eus', 'Astelehena';
						 'spa', 'lunes'};
			ind = find(strcmp(w,lang_list(:,2)),1);
			if isempty(ind)
				ind = 1;
			end
			lng = lang_list{ind,1};
		end
	end

	methods
		function obj = simplegettext(messages_filename_in, language_in)
			if nargin<1 || isempty(messages_filename_in) || ~exist(messages_filename_in,'file')
				st = dbstack('-completenames');
				if numel(st)>=2
					messages_filename_in = st(2).file;
					[cur_path, cur_name] = fileparts(messages_filename_in);
					messages_filename_in = fullfile(cur_path, [cur_name '_lang.mat']);
				end
			end
			if exist(messages_filename_in, 'file')
				obj.messages_filename = messages_filename_in;
				obj.messages = load(obj.messages_filename,'messages');
				obj.messages = obj.messages.messages;
			end

			if nargin<2 || isempty(language_in)
				language_in = simplegettext.identify_language();
			end
			obj.language = language_in;
		end
		
		function [str_tr, is_translation_found] = translate(obj, str_eng)
			if isa(str_eng,'cell')
				[str_tr is_translation_found] = cellfun(@(x) obj.translate(x), str_eng, 'UniformOutput',false);
				return
			end

			str_tr = str_eng;
			is_translation_found = false;

			if ~isa(str_eng,'char') || isempty(obj.messages) || isempty(str_eng)
				return
			end
			
			msg_ind = find(strcmp(str_eng, {obj.messages.msg}),1);
			if isempty(msg_ind)
				return
			end
			
			transl_ind = find(strcmp(obj.language, obj.messages(msg_ind).translates(:,1)),1);
			if isempty(transl_ind)
				return
			end

			str_tr = obj.messages(msg_ind).translates{transl_ind, 2};
			is_translation_found = true;
		end
		
		function translate_ui(obj,hObject,is_report_unfound)
			if nargin<3
				is_report_unfound = false;
			end

			ch_list = get(hObject,'Children');
			for ci = 1:numel(ch_list)
				translate_ui(obj,ch_list(ci),is_report_unfound);
			end

			fl_name = '';
			if strcmp(get(hObject,'Type'),'uipanel')
				fl_name = 'Title';
			end
			if strcmp(get(hObject,'Type'),'uicontrol') && ...
				any(strcmp(get(hObject,'Style'),{'text','pushbutton','checkbox'}))
					fl_name = 'String';
			end
			if ~isempty(fl_name)
				str_eng = get(hObject,fl_name);
				[str_tr, is_translation_found] = obj.translate(str_eng);
				if is_translation_found
					set(hObject,fl_name,str_tr);
				elseif is_report_unfound
					disp(sprintf('Translation not found:\n%s\n',str_eng)); %#ok<DSPS>
				end
			end
		end
	end
end
