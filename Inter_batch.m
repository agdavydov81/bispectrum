function Inter_batch()
files_path='d:\Matlab_work\birings\';
files_names={'4_1', '4_2', '4_3' '5_1', '5_2', '5_3' '6_1', '6_2', '6_3' '7_1', '7_2', '7_3'};
pemut={[2 3 4 5 6 7 8 9 10], [4 6 8 10], [6 9], 8, 10};
F_base=40.83;

%for F_base=38:.01:42

for file_ind=1:length(files_names)
    CNT=1;
    for prmut_i=1:length(pemut)
        cur_var=pemut{prmut_i};
        for permut_j=1:length(cur_var)
            Intercomponent_Analysis([files_path files_names{file_ind} '.wav'], F_base, 1, [prmut_i cur_var(permut_j)], 1, 0.5, 0.5, 0, 0);
            fname=sprintf('%s_%04d.png',files_names{file_ind}, CNT);
            CNT=CNT+1;
            print('-dpng',fname);
            close(gcf);
        end
    end
end
