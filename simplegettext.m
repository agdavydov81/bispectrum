classdef simplegettext < handle
	%simplegettext - simple localisation class

	properties
		messages_filename;
		messages;
		language;
	end

	methods(Static)
		function lng = identify_language()
			[~,w] = weekday(728647,'long','local');
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
		
		function str_tr = translate(obj, str_eng)
			if isa(str_eng,'cell')
				str_tr = cellfun(@(x) obj.translate(x), str_eng, 'UniformOutput',false);
				return
			end

			str_tr = str_eng;

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
		end
	end
end
