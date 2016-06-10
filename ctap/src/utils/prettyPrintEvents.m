function [outArr1, outArr2] = prettyPrintEvents(Event)

cueEvent = '30';

cueIdx = find(ismember({Event.type}, cueEvent));

% make a [ncues,1] cell array of data
outArr = cell(length(cueIdx)-1,1);
maxEl = 0;
for i=1:(length(cueIdx)-1)
    
   outArr{i} = {Event(cueIdx(i):(cueIdx(i+1)-1)).type};
   if (length(outArr{i})) > maxEl
      maxEl = length(outArr{i});
   end
end

% make a [ncues, maxEl] cell array of data
outArr2 = cell(length(cueIdx)-1, maxEl);
for i = 1:length(outArr)
    if length(outArr{i}) < maxEl
       tmp = cell(1,maxEl);
       tmp(1:length(outArr{i})) = outArr{i};
    else
       tmp = outArr{i};
    end
    outArr2(i,:) = tmp;  
end
