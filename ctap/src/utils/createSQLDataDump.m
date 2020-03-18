function charArr = createSQLDataDump(subjectnr, measurement, dataArr, formatArr)

%{
subjectnr = 1;
measurement = 'measurement';

M = load('/ukko/projects/ReKnow/Data/processed/ReKnowPilot/features/bandpowers/ReKnowPilot001_bandpowers.mat');
i_Meta = M.INFO;
M = rmfield(M,'INFO');
[i_data_array, i_labels, n_factors] = data2array(M, [],...
                'outputFormat', 'long',...
                'factors_variable', 'SEGMENT');            
%dataArr = i_data_array(1:100,:);
dataArr = i_data_array;
formatArr = {'%s','%s','%f','%s','%u','%u','%s'};

tmp = cellfun(@(x) num2str(x,'%u'), dataArr(:,3), 'UniformOutput', false);
%}

lineStart = sprintf('INSERT INTO restab VALUES (NULL,%u,''%s'',',subjectnr, measurement);
charArr=repmat(lineStart,size(dataArr,1),1);
for m = 1:size(dataArr,2)
   
    if strcmp(formatArr{m},'%s')
        %m_char = char(dataArr(:,m));
        m_char = char(cellfun(@(x) sprintf('''%s''',x), dataArr(:,m),...
                        'UniformOutput', false));
    else
        %m_char = char(cellfun(@(x) num2str(x,formatArr{m}), dataArr(:,m),...
        %                'UniformOutput', false));
        m_char = char(cellfun(@(x) sprintf(formatArr{m},x), dataArr(:,m),...
                        'UniformOutput', false));
    end
    if m==1
        charArr = [charArr,m_char];
        %charArr = strcat(charArr,m_char);
    else
        charArr = [charArr,repmat(',',size(dataArr,1),1),m_char];
        %charArr = strcat(charArr,',',m_char);
    end
    %disp(m_char(1:2,:))
end
charArr = [charArr,repmat(');',size(dataArr,1),1)];

%{
savefile = '/home/jussi/tmp/dump.txt';

fileID = fopen(savefile,'w');
for i=1:size(charArr,1)
    fprintf(fileID,'%s\n',charArr(i,:));
end
fclose(fileID);

% To load result into DB:
% cat <savefile> | sqlite3 <dbfile> 
%}
