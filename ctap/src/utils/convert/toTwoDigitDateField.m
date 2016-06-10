function dateField = toTwoDigitDateField(dateField)

if numel(dateField) < 2
    dateField = ['0' dateField];


% switch type
%     
%     case 'year'
%     
%     case 'month'
%         if numel(dateField) > 2
%             dateField = ['0' dateField]
%     case 'day'
%     
%     case 'hour'
%     
%     case 'minute'
%     
%     case 'second'
% end
end
