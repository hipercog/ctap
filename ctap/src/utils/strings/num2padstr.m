function numbers_str = num2padstr(numbers)

% Determine the maximum number of digits needed based on the largest number
numDigits = ceil(log10(max(numbers)));

% Create the format string dynamically based on the number of digits
formatStr = sprintf('%%0%dd', numDigits);

% Convert the array to string and left-pad with zeros
numbers_str = arrayfun(@(n) sprintf(formatStr, n), numbers, 'Un', false);

end