function [A2, A_str, real_digitsL, real_digitsR, imag_digitsL, imag_digitsR]=m_round(A, round_kind, round_digits, flag1, mult, SI_prefixes)
% % m_round: Rounds an array to a specified number of significant digits or a specified digits place: significant figures, sigfigs
% %
% % Syntax;
% %
% % [A2, A_str, real_digitsL, real_digitsR, imag_digitsL, imag_digitsR]=m_round(A, round_kind, round_digits, flag1, mult);
% %
% % *********************************************************************
% %
% % Description
% %
% % m_round stands for multple round.  It allows for two kinds of rounding.
% %
% % This program rounds a 2-d matrix of numbers to a specified number
% % of significant digits or specirfied digits place.
% %
% % This program support five different styles of rounding the last digit:
% % to the nearest integer, up, down, toward zero, and away from zero.
% %
% % This program supports real and complex numbers.
% %
% % The program outputs the rounded array, a cell string of the
% % rounded matrix the number of digits, to the left and right of the
% % decimal place.
% %
% % This program is useful for presenting scientific data that
% % requires rounding to a specifid number of significant digits or a
% % specified digits place for publication.
% %
% % Significant digits are counted starting from the first non-zero
% % digit from the left.
% %
% % There are several input and output variables which are described in 
% % more detail in the sections below.  
% % 
% %
% % *********************************************************************
% %
% % Input variables
% %
% % A is the input matrix of number to be rounded.
% %      default is empty array A=[];.
% %                         
% % round_kind=1;           % Can be an array consisting of 0 and 1 with 
% %                         % the same size as variable "A" 
% %                         %
% %                         % Can be a scalar, 0 or 1.
% %                         %
% %                         % round_kind=1; rounds to specified number of 
% %                         % significant digits
% %                         %
% %                         % round_kind=0; rounds to specified digits 
% %                         % place.
% %                         % 
% %                         % default is round_kind=1;
% %
% % round_digits=3;         % Each element of round_digits either specifies 
% %                         % the number of significant digits or the 
% %                         % digits place.  
% %                         % 
% %                         % Can be an array of values 
% %                         % with the same size as variable "A" 
% %                         %
% %                         % Can be a scalar.
% %                         % 
% %                         % if round_kind==1 number of significant digits
% %                         % if round_kind==0 specified digits place
% %                         %
% %                         % default is round_digits=3;
% %
% % flag1 specifies the style of rounding.
% %      This program supports four different styles of rounding.
% %      flag1 == 1 rounds to the nearest integer
% %      flag1 == 2 rounds up
% %      flag1 == 3 rounds down
% %      flag1 == 4 rounds toward zero
% %      flag1 == 5 rounds away from zero
% %      otherwise round to the nearest integer
% %      default is round to the nearest integer
% %
% % mult is a scalar whole number.  The program rounds the last digit to mult.
% %      It is preferred that mult be between 1 and 9; however, all whole
% %      numbers >= 1 are valid input.  The program rounds mult to the
% %      nearest integer and makes sure the value is at least 1.
% %      default is mult=1;
% % 
% % SI_prefixes=0;  % 1 for using SI prefixes (i.e. K for 1000)
% %                 % 0 for not using prefixes.  
% %                 % default is SI_prefixes=0;
% %      
% % 
% %
% % *********************************************************************
% %
% % Output variables
% %
% % A2 is the rounded array.
% %
% % A_str           % The rounded array is converted to a cell
% %                 % string format with the specified rounding and showing
% %                 %  the trainling zeros.
% %                 % This is convenient for publishing tables in a tab
% %                 % delimited string format
% %
% % real_digitsL    % The number of real digits to the left of the decimal
% %                 % point
% %
% % real_digitsR    % The number of real digits to the right of the decimal
% %                 % point
% %
% % imag_digitsL    % The number of imaginary digits to the left of the
% %                 % decimal point
% %
% % imag_digitsR 	% The number of imaginary digits to the right of the
% %                 % decimal point
% %
% % *********************************************************************
% 
%
%
% Example1='1';
%
% D1=pi*[1 1 1];            % Double or Complex two dimensional array of numbers
% 
% round_kind=[1 0 0];       % 1 round to specified number of significant
%                           % digits.
%                           %
%                           % 0 round to specifid digits place
%
% round_digits=[3 0 -1];    % Type of rounding depends on round_kind
%                           %
%                           % if round_kind==1 number of significant digits
%                           % if round_kind==0 spcecified digits place
%                           % 3 round to 3 significant digits
%                           % 0 round to the ones place
%
% [P1, P1_str]=m_round(D1, round_kind, round_digits);
%
% % P1_str{1,1} should be 3.14 which has 3 significant digits.
%
%
%
% Example='2';
%
% D1=pi/1000000;    % Double much smaller than 1
% N=3;              % Number of significant digits.  3 is the default
% flag1=1;           % round to the nearest digit
% mult=5;           % round to a multiple 5
%
% [P1, P1_str]=m_round(D1, 1, N, 1, 5);
%
% % P1_str should be 0.00000315 which has 3 significant digits.
% % and the last digit is rounded to the nearest multiple of 5.
%
%
%
% Example='3';
%
% N=4;                              % N is the number of significant digits
% D2=10.^randn(10, 100);            % D2 is the unrounded array
% [P2, P2_str]=m_round(D2, 1, N);   % P2 is the rounded array
%                                   % of real numbers
%                                   % P2_str is the cell array of strings of
%                                   % rounded real numbers
% Example='4';
% D3=log10(randn(10, 100));         % D3 is an unrounded array of complex
%                                   % numbers
% [P3, P3_str]=m_round(D3, 1, 4);   % P3 is the rounded array of
%                                   % complex numbers
%                                   % P3_str is the cell array of strings of
%                                   % rounded complex numbers
%
%
% Example='4';
% D3=(randn(10, 100)+randn(10, 100)*i))*10^16;         
%                                   % D3 is an unrounded array of complex numbers
% [P3, P3_str]=m_round(D3, 1, 4, 1, 1, 1);   
%                                   % P3 is the rounded array of
%                                   % complex numbers
%                                   % P3_str is the cell array of strings of
%                                   % rounded complex numbers
%
% 
% % *********************************************************************
% % 
% %
% % Subprograms
% %
% % 
% % List of Dependent Subprograms for 
% % m_round
% % 
% % FEX ID# is the File ID on the Matlab Central File Exchange
% % 
% % 
% % Program Name   Author   FEX ID#
% % 1) pow10_round		Edward L. Zechmann			
% % 2) sd_round		Edward L. Zechmann			
% % 
% % *********************************************************************
% %
% % Program Written by Edward L. Zechmann
% %
% %     date  9 January    2009
% %
% % modified 11 January    2009     Vectorized
% %
% % modified 22 January    2009     Updated Comments
% % 
% % modified  6 October     2009    Updated comments
% % 
% % 
% % 
% % *********************************************************************
% %
% % Please Feel Free to Modify This Program
% %
% % See Also: sd_round, pow10_round, round, ceil, floor, fix, fix2, round2, round
% %


if (nargin < 1 || isempty(A)) || ~isnumeric(A)
    A=[];
    A2=[];
    warning('Error in m_round did not Input Matrix A');
end

if (nargin < 2 || isempty(round_kind)) || ~isnumeric(round_kind)
    round_kind=1;
end

if (nargin < 3 || isempty(round_digits)) || ~isnumeric(round_digits)
    round_digits=3;
end

if (nargin < 4 || isempty(flag1)) || ~isnumeric(flag1)
    flag1=1;
end

if (nargin < 5 || isempty(mult)) || ~isnumeric(mult)
    mult=1;
end

mult=round(mult(1));
if mult < 1
    mult=1;
end

if (nargin < 6 || isempty(SI_prefixes)) || ~isnumeric(SI_prefixes)
    SI_prefixes=0;
end


[m1 n1]=size(A);
[m2]=numel(round_kind);
[m3]=numel(round_digits);

if (isequal(m2, 1) && isequal(m3, 1)) || (all(all((1-round_kind(1,1))-round_kind)) && all(all((1-round_digits(1,1))-round_digits)))

    if isequal(round_kind(1,1), 1)
        [A2, A_str, real_digitsL, real_digitsR, imag_digitsL, imag_digitsR]=sd_round(A, round_digits(1,1), flag1, mult, SI_prefixes);
    else
        [A2, A_str, real_digitsL, real_digitsR, imag_digitsL, imag_digitsR]=pow10_round(A, round_digits(1,1), flag1, mult, SI_prefixes);
    end

else

    A2=zeros(m1, n1);
    A_str=cell(m1, n1);
    real_digitsL=zeros(m1, n1);
    real_digitsR=zeros(m1, n1);
    imag_digitsL=zeros(m1, n1);
    imag_digitsR=zeros(m1, n1);

    [m4 n4]=size(round_kind);
    [m5 n5]=size(round_digits);
    
    for e1=1:m1;
        for e2=1:n1;
            
            ix4=min([e1, m4]);
            iy4=min([e2, n4]);
            ix5=min([e1, m5]);
            iy5=min([e2, n5]);
            
            if isequal(round_kind(ix4, iy4), 1)
                [A22, A_str2, real_digitsL2, real_digitsR2, imag_digitsL2, imag_digitsR2]=sd_round(A(e1, e2), round_digits(ix5, iy5), flag1, mult, SI_prefixes);
            else
                [A22, A_str2, real_digitsL2, real_digitsR2, imag_digitsL2, imag_digitsR2]=pow10_round(A(e1, e2), round_digits(ix5, iy5), flag1, mult, SI_prefixes);
            end

            A2(e1, e2)=A22;
            A_str{e1, e2}=A_str2{1,1};
            real_digitsL(e1, e2)=real_digitsL2;
            real_digitsR(e1, e2)=real_digitsR2;
            imag_digitsL(e1, e2)=imag_digitsL2;
            imag_digitsR(e1, e2)=imag_digitsR2;

        end
    end
end


