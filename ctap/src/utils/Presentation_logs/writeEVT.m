function writeEVT(events,srate,filepath,paradigm)
% Author Tommi Makkonen
% 5.2.2018

fileID = fopen(filepath,'wt');
fprintf(fileID,'Tmu\tCode\tTriNo\tComnt\n');
for e=1:size(events,2)
    tmu = (events(1,e).latency-1) / srate * 1e6;
    code = 1;
    
    if strcmp(paradigm,'multi')
        
        if strcmp(events(1,e).type,'boundary')
            code = 41;
            trino = 'boundary';

        elseif strcmp(events(1,e).type,'stand')
            trino = '11';
        elseif strcmp(events(1,e).type,'gap')
            trino = '2';
        elseif strcmp(events(1,e).type,'novel')
            trino = '3';    
        elseif strcmp(events(1,e).type,'freq1')
            trino = '4';
        elseif strcmp(events(1,e).type,'freq2')
            trino = '5';
        elseif strcmp(events(1,e).type,'loc1')
            trino = '6';
        elseif strcmp(events(1,e).type,'loc2')
            trino = '7';
        elseif strcmp(events(1,e).type,'int')
            trino = '8';
        elseif strcmp(events(1,e).type,'dur')
            trino = '9';
        end
        comnt = events(1,e).type;
        
    elseif strcmp(paradigm,'av')
        % Responses 1 and 3
        trino = '99';
        type = events(1,e).type;
        
        if strcmp(events(1,e).type,'boundary')
            code = 41;
            trino = 'boundary';

        elseif strcmp(type,'sound_NOTNOVEL')
            trino = '211';
        elseif strcmp(type,'STD1nn')
            trino = '10';
        elseif strcmp(type,'STD2nn')
            trino = '11';
        elseif strcmp(type,'STD1nov')
            trino = '12';
        elseif strcmp(type,'STD2nov')
            trino = '13';
        end
        
        if length(type) > 11
            if strcmp(type(1:11),'sound_NOVEL')
                trino = num2str(100+str2double(type(12:end)));
            end
        end
        
        if strcmp(type,'1') 
            trino = '100';
            comnt = 'Response';
        elseif strcmp(type,'3')
            trino = '103';
            comnt = 'Response';
        else
            comnt = events(1,e).type;
        end
        
    elseif strcmp(paradigm,'swi')
        trino = '99';
        type = events(1,e).type;
        
        if strcmp(events(1,e).type,'boundary')
            code = 41;
            trino = 'boundary';

        elseif strcmp(type,'std1')
            trino = '11';
        elseif strcmp(type,'std_aft1')
            trino = '12';
        elseif strcmp(type,'std_aft2')
            trino = '13';
        elseif strcmp(type,'std_aft3')
            trino = '14';
        elseif strcmp(type,'std1_nov')
            trino = '15';
        elseif strcmp(type,'std2_nov')
            trino = '16';
        elseif strcmp(type,'std3_nov')
            trino = '17';
        
        elseif strcmp(type,'Dog_A_S1_Cat_V')
            trino = '21';
        elseif strcmp(type,'Dog_A_S2_Cat_V')
            trino = '22';   
        elseif strcmp(type,'Cat_A_S1_Dog_V')
            trino = '23';
        elseif strcmp(type,'Cat_A_S2_Dog_V')
            trino = '24';    
            
        elseif strcmp(type,'Dog_A_S1_Dog_V')
            trino = '31';
        elseif strcmp(type,'Dog_A_S2_Dog_V')
            trino = '32';
        elseif strcmp(type,'Cat_A_S1_Cat_V')
            trino = '33';
        elseif strcmp(type,'Cat_A_S2_Cat_V')
            trino = '34';    
        end
        
        if strcmp(type,'1')
            trino = '100';
            comnt = 'Response';
        else
            comnt = events(1,e).type;
        end
        
    end
        
    
    
    fprintf(fileID,'%.0f\t%i\t%s\t%s\n',tmu,code,trino,comnt);
end
fclose(fileID);
    
    