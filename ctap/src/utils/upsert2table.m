function T = upsert2table(T, varname, rowname, newdata)
% upsert2table: A helper function to insert data into Matlab table
%
%{
% test code:
tab = table({1;'a';{'a','b'}}, [false;true;true], [1;2;3],...
                'rowNames', {'r1','r2','r3'},...
                'variableNames', {'v1','v2','v3'})

class(tab.('v1')('r1'))
class(tab.('v2')('r1'))
class(tab.('v3')('r1'))

upsert2table(tab, 'v1', 'r1', 1:9)
upsert2table(tab, 'v2', 'r1', true)
upsert2table(tab, 'v3', 'r1', 999)

upsert2table(tab, 'v2', 'r1', 'jee')
upsert2table(tab, 'v3', 'r1', false)
%}

% check that the row exists
if ~ismember(rowname, T.Properties.RowNames)
    
    T = sbf_add_new_row(T, rowname); %add empty row
    %error('upsert2table:inputMismatch',...
    %      'Row name ''%s'' not found.', rowname);
end


if ismember(varname, T.Properties.VariableNames)
    T = sbf_add_to_existing_variable(T, varname, rowname, newdata);
else
    T = sbf_add_to_new_variable(T, varname, rowname, newdata);
end

    % Insert into existing variable
    function T = sbf_add_to_existing_variable(T, varname, rowname, newdata)

        if iscell(T.(varname)(rowname))
            % elements are cell arrays
 
            if iscell(newdata)
                T.(varname)(rowname) = newdata; %no need to wrap
            else
                T.(varname)(rowname) = {newdata}; %wrap into cell
            end

        elseif isnumeric(T.(varname)(rowname))
            % elements are numeric -> check newdata type and store
            if isnumeric(newdata)
                T.(varname)(rowname) = newdata;
            else 
                error('upsert2table:inputMismatch',...
                    'Variable ''%s'' is numeric but ''newdata'' contains ''%s''.',...
                    varname, class(newdata));
            end

        elseif islogical(T.(varname)(rowname))
            % elements are logical -> check newdata type and store
            if islogical(newdata)
                T.(varname)(rowname) = newdata;
            else 
                error('upsert2table:inputMismatch',...
                    'Variable ''%s'' is logical but ''newdata'' contains ''%s''.',...
                    varname, class(newdata));
            end

        elseif ischar(T.(varname)(rowname))
            % elements are char: possible but very hard to work with
            warning('upsert2table:unsupportedDataFormat',...
                    'Table elements can be char but this leads into problems. Consider a cell array of char instead.');
        
        else
            error('upsert2table:unsupportedDataFormat',...
                  'Variable ''%s'' is of unsupported type ''%s''.', ...
                  varname, class(T.(varname)(rowname)) );
        end

    end


    % Insert into a new variable
    function T = sbf_add_to_new_variable(T, varname, rowname, newdata)

        if isnumeric(newdata)
            T2 = table(NaN(size(T,1),1),...
                'VariableNames', {varname},...
                'RowNames', T.Properties.RowNames);

            T2.(varname)(rowname) = newdata;

        elseif ischar(newdata)
            T2 = table(repmat({''}, size(T,1), 1),...
                'VariableNames', {varname},...
                'RowNames', T.Properties.RowNames);

            T2.(varname)(rowname) = {newdata};
        else
            error('upsert2table:unknownDataType',...
                  'Unknown input data type: %s.', class(newdata) );
        end

        T = [T T2];
    end


    % Insert a new empty row to bottom of T
    function T = sbf_add_new_row(T, rowname)
        
        T2 = T(1,:);
        T2.Properties.RowNames = {rowname};
        
        for k = 1:size(T2,2)
            if isnumeric( T2{1,k} )
                T2{1,k} = NaN;
                
            elseif islogical( T2{1,k} )
                T2{1,k} = false;
                
            elseif iscell( T2{1,k} )
                % note: table elements can be cell arrays of just about
                % anything -> makes things tricky...
                if isnumeric( T2{1,k}{1} )
                    T2{1,k} = {NaN};
                    
                elseif islogical( T2{1,k}{1} )
                    T2{1,k} = {false};
                    
                elseif ischar( T2{1,k}{1} )
                    T2{1,k} = {''};
                
                else
                    error('upsert2table:unsupportedVariableClass',...
                    'Unsupported class %s found.', class(T2{1,k}{1}) );
                end
            else 
                error('upsert2table:unsupportedVariableClass',...
                    'Unsupported class %s found.', class(T2{1,k}) );
            end
        end
        T = [T; T2];
 
    end

end


% One possible way of adding data to table. Saved here for reference.
%{
if ismember(EEG.CTAP.measurement.casename, rejtab.Properties.RowNames)
    % if no exsiting vars for this step, append new columns
    if ~ismember([func '_' badname], rejtab.Properties.VariableNames)
        rejtab.([func '_' badname]) = cell(height(rejtab), 1);
    end
    if ~ismember([func '_pc'], rejtab.Properties.VariableNames)
        rejtab.([func '_pc']) = cell(height(rejtab), 1);
    end
else
    % append empty row
    tmp = cell2table(cell(1, width(rejtab))...
        , 'RowNames', {EEG.CTAP.measurement.casename}...
        , 'VariableNames', rejtab.Properties.VariableNames);
    rejtab = [rejtab; tmp]; %union(rejtab, tmptab);
end

rejtab.([func '_' badname])(EEG.CTAP.measurement.casename) = {bdstr};
rejtab.([func '_pc'])(EEG.CTAP.measurement.casename) = {detected.prc};
%}

