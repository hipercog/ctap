function [A2, A_str, real_digitsL, real_digitsR, imag_digitsL, imag_digitsR]=sd_round(A, N, flag2, mult, SI_prefixes)
% % sd_round: Rounds an array to a specified number of Significant Digits, significant figures, digits of precision
% %
% % *********************************************************************
% %
% % Syntax;
% %
% % [A2, A_str, real_digitsL, real_digitsR, imag_digitsL,...
% % imag_digitsR]=sd_round(A, N, flag2);
% %
% % *********************************************************************
% %
% % Description
% %
% % sd_round stands for "Significant Digits Round".
% %
% % This program rounds a 2-d matrix of numbers to a specified number
% % of significant digits.
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
% % requires rounding to a specifid number of significant digits
% % for publication.
% %
% % Significant digits are counted starting from the first non-zero
% % digit from the left.
% %
% %
% % *********************************************************************
% %
% % Input variables
% %
% % A is the input matrix of number to be rounded.
% %      default is empty array A=[];.
% %
% % N is the number of significant digits.
% %      default is N=3;
% %
% % flag2 specifiies the style of rounding.
% %      This program supports four different styles of rounding.
% %      flag2 == 1 rounds to the nearest integer
% %      flag2 == 2 rounds up
% %      flag2 == 3 rounds down
% %      flag2 == 4 rounds toward zero
% %      flag2 == 5 rounds away from zero
% %      otherwise round to the nearest integer
% %      default is round to the nearest integer
% %
% % mult is a whole number.  The program rounds the last digit to mult.
% %      It is preferred that mult be between 1 and 9; however, all whole
% %      numberS >= 1 are valid input.  The program rounds mult to the
% %      nearest integer and makes sure the value is at least 1.
% %      default is mult=1;
% %
% % SI_prefixes=0;  % 1 for using SI prefixes (i.e. K for 1000)
% %                 % 0 for not using prefixes.
% %                 % default is SI_prefixes=0;
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
% %
%
% Example1='';
% D1=pi;        % Double or Complex two dimensional array of numbers
% N=3;          % Number of significant digits.  3 is the default
%
% [P1, P1_str]=sd_round(pi, N);
%
% % P1 should be 3.14 which has 3 significant digits.
%
% Example2='';
% D1=pi/1000000;    % Double much smaller than 1
% N=3;              % Number of significant digits.  3 is the default
% flag2=1;           % round to the nearest digit
% mult=5;           % round to a multiple 5
%
% [P1, P1_str]=sd_round(D1, N, 1, 5);
%
% % P1_str should be 0.00000315 which has 3 significant digits.
% % and the last digit is rounded to the nearest multiple of 5.
%
% Example3='';
% N=4;                          % N is the number of significant digits
% D2=10.^randn(10, 100);        % D2 is the unrounded array
% [P2, P2_str]=sd_round(D2, N); % P2 is the rounded array
%                               % of real numbers
%                               % P2_str is the cell array of strings of
%                               % rounded real numbers
% Example4='';
% D3=log10(randn(10, 100));     % D3 is an unrounded array of complex
%                               % numbers
% [P3, P3_str]=sd_round(D3, 4); % P3 is the rounded array of
%                               % complex numbers
%                               % P3_str is the cell array of strings of
%                               % rounded complex numbers
%
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %
% % Program Written by Edward L. Zechmann
% %
% %      date 23 November 2007
% %
% %  modified 26 November 2007   updated comments
% %
% %  modified 17 December 2007   added outputs
% %                              real_digitsL
% %                              real_digitsR
% %                              imag_digitsL
% %                              imag_digitsR
% %
% %  modified 28 December 2007   added string output
% %                              fixed bug in real_digitsR
% %                              fixed bug in imag_digitsR
% %
% %  modified  7 January  2008   fixed bug in real_digitsR
% %                              fixed bug in imag_digitsR
% %                              sped up program by only
% %                              converting the array to strings
% %                              if it is an output argument
% %
% %  modified  1 March    2008   Added support for rounding
% %                              to nearest integer, up, down,
% %                              and toward zero
% %
% %  modified  3 March    2008   updated comments
% %
% %  modified 16 March    2008   Changed Program name from
% %                              p_round to sd_round.
% %                              Added another rounding style
% %                              flag2 =5; (away from 0).
% %                              Updated comments.
% %
% %  modified 18 August   2008   Added option to round last digit to a
% %                              multiple of a given number.
% %                              Fixed a bug in rounding powers of 10.
% %                              Improved examples.
% %
% %  modified 21 August   2008   Fixed a bug in rounding numbers less
% %                              than 1.  Added an example.
% %
% %  modified 25 August   2008   Modified program to recalculate the
% %                              number of digits after rounding,
% %                              because rounding can change the number
% %                              of digits to the left and right of the
% %                              decimal place. Updated Comments
% %
% % modified 16 August   2010   Changed K to k for SI prefixes.
% %
% %
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %
% % Please Feel Free to Modify This Program
% %
% % See Also: pow10_round, round, ceil, floor, fix, fix2, round2, roundd
% %

flag1=0;

if (nargin < 1 || isempty(A)) || ~isnumeric(A)
    flag1=1;
    A=[];
    A2=[];
    warning('Error in p_round did not Input Matrix A');
end

if isempty(A)
    flag1=1;
    A=[];
    A2=[];
    warning('Error in p_round Matrix A is Empty');
end

if (nargin < 2 || isempty(N)) || ~isnumeric(N)
    N=3;
end

if (nargin < 3 || isempty(flag2)) || ~isnumeric(flag2)
    flag2=1;
end

if (nargin < 4 || isempty(mult)) || ~isnumeric(mult)
    mult=1;
end

mult=round(mult);
if mult < 1
    mult=1;
end

if (nargin < 5 || isempty(SI_prefixes)) || ~isnumeric(SI_prefixes)
    SI_prefixes=0;
end

SI_prefixes=SI_prefixes(1);

% Number of digits to keep
N=round(N);

if N < 1
    N=1;
end

if ~isempty(A)
    real_digitsL=zeros(size(A));
    real_digitsR=zeros(size(A));
    imag_digitsL=zeros(size(A));
    imag_digitsR=zeros(size(A));
else
    real_digitsL=[];
    real_digitsR=[];
    imag_digitsL=[];
    imag_digitsR=[];
end

letters={'y', 'z', 'a', 'f', 'p', 'n', '\mu', 'm', '', 'k', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y'};

if isequal(flag1, 0)
    if isnumeric(A)

        if isreal(A)

            B=isinf(A);
            A(B)=sign(A(B)).*10^15;
            
            
            % Digit furthest to the left of the decimal point
            D1=ceil(log10(abs(A)));
            buf1=D1( abs(A)-10.^D1 == 0)+1;
            D1( abs(A)-10.^D1 == 0)=buf1;

            % rounding factor
            dec=10.^(N-D1);

            % Rounding Computation
            % This program supports five different styles of rounding.
            % flag2 == 1 rounds to the nearest integer
            % flag2 == 2 rounds up
            % flag2 == 3 rounds down
            % flag2 == 4 rounds toward zero
            % flag2 == 5 rounds away from zero
            % otherwise round to the nearest integer

            buf=dec./mult;

            switch flag2

                case 1
                    A2=1./buf.*round(buf.*A);
                case 2
                    A2=1./buf.*ceil(buf.*A);
                case 3
                    A2=1./buf.*floor(buf.*A);
                case 4
                    A2=1./buf.*fix(buf.*A);
                case 5
                    A2=sign(A)./buf.*ceil(buf.*abs(A));
                otherwise
                    A2=1./buf.*round(buf.*A);
            end

            A2(A==0)=0;

            if isequal( SI_prefixes, 1)
                regime=floor(log10(abs(A2))./3);
                regime(regime < -9)=0;
                regime(regime > 9)=0;
            else
                regime=zeros(size(A));
            end

            A2=A2.*10.^(-3.*regime);

            % After rounding recalculate the number of significant digits.
            % The number of digits to the left and right of the decimal
            % place can be effected by rounding.

            % Digit furthest to the left of the decimal point
            D1=ceil(log10(abs(A2)));
            buf1=D1( abs(A2)-10.^D1 == 0)+1;
            D1( abs(A2)-10.^D1 == 0)=buf1;

            % Number of digits to the left of the decimal place
            real_digitsL=max(D1, 0);
            real_digitsL(A2==0)=0;

            % rounding factor
            dec=10.^(N-D1);

            % Number of digits to the right of the decimal place
            real_digitsR=max(N-D1, 0);
            real_digitsR(A2==0)=N;

        else

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            % Round the real part
            Ar=real(A);
            
            B=isinf(Ar);
            Ar(B)=sign(Ar(B)).*10^15;
            
            % Digit furthest to the left of the decimal point
            D1=ceil(log10(abs(Ar)));
            buf1=D1( abs(Ar)-10.^D1 == 0)+1;
            D1( abs(Ar)-10.^D1 == 0)=buf1;

            % rounding factor
            dec=10.^(N-D1);

            % Rounding Computation
            % This program supports five different styles of rounding.
            % flag2 == 1 rounds to the nearest integer
            % flag2 == 2 rounds up
            % flag2 == 3 rounds down
            % flag2 == 4 rounds toward zero
            % flag2 == 5 rounds away from zero
            % otherwise round to the nearest integer

            buf=dec./mult;

            switch flag2
                case 1
                    A2r=1./buf.*round(buf.*Ar);
                case 2
                    A2r=1./buf.*ceil(buf.*Ar);
                case 3
                    A2r=1./buf.*floor(buf.*Ar);
                case 4
                    A2r=1./buf.*fix(buf.*Ar);
                case 5
                    A2r=sign(Ar)./buf.*ceil(buf.*abs(Ar));
                otherwise
                    A2r=1./buf.*round(buf.*Ar);
            end

            A2r(Ar==0)=0;

            if isequal( SI_prefixes, 1)
                regimeR=floor(log10(abs(A2r))./3);
                regimeR(regimeR < -9)=0;
                regimeR(regimeR > 9)=0;
            else
                regimeR=zeros(size(A));
            end

            A2r=A2r.*10.^(-3.*regimeR);

            % After rounding recalculate the number of significant digits.
            % The number of digits to the left and right of the decimal
            % place can be effected by rounding.

            % Digit furthest to the left of the decimal point
            D1=ceil(log10(abs(A2r)));
            buf1=D1( abs(A2r)-10.^D1 == 0)+1;
            D1( abs(A2r)-10.^D1 == 0)=buf1;

            % Number of digits to the left of the decimal place
            real_digitsL=max(D1, 0);
            real_digitsL(A2r==0)=0;

            % rounding factor
            dec=10.^(N-D1);

            % Number of digits to the right of the decimal place
            real_digitsR=max(N-D1, 0);
            real_digitsR(A2r==0)=N;

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            % Round the imaginary part
            Ai=imag(A);

            B=isinf(Ai);
            Ai(B)=sign(Ai(B)).*10^15;
            
            
            % Digit furthest to the left of the decimal point
            D1=ceil(log10(abs(Ai)));
            buf1=D1( abs(Ai)-10.^D1 == 0)+1;
            D1( abs(Ai)-10.^D1 == 0)=buf1;

            % rounding factor
            dec=10.^(N-D1);

            % Rounding Computation
            % This program supports five different styles of rounding.
            % flag2 == 1 rounds to the nearest integer
            % flag2 == 2 rounds up
            % flag2 == 3 rounds down
            % flag2 == 4 rounds toward zero
            % flag2 == 5 rounds away from zero
            % otherwise round to the nearest integer

            buf=dec./mult;

            switch flag2
                case 1
                    A2i=1./buf.*round(buf.*Ai);
                case 2
                    A2i=1./buf.*ceil(buf.*Ai);
                case 3
                    A2i=1./buf.*floor(buf.*Ai);
                case 4
                    A2i=1./buf.*fix(buf.*Ai);
                case 5
                    A2i=sign(Ai)./buf.*ceil(buf.*abs(Ai));
                otherwise
                    A2i=1./buf.*round(buf.*Ai);
            end


            A2i(Ai==0)=0;

            if isequal( SI_prefixes, 1)
                regimeI=floor(log10(abs(A2i))./3);
                regimeI(regimeI < -9)=0;
                regimeI(regimeI > 9)=0;
            else
                regimeI=zeros(size(A));
            end

            A2i=A2i.*10.^(-3.*regimeI);

            % After rounding recalculate the number of significant digits.
            % The number of digits to the left and right of the decimal
            % place can be effected by rounding.

            % Digit furthest to the left of the decimal point
            D1=ceil(log10(abs(A2i)));
            buf1=D1( abs(A2i)-10.^D1 == 0)+1;
            D1( abs(A2i)-10.^D1 == 0)=buf1;

            % Number of digits to the left of the decimal place
            imag_digitsL=max(D1, 0);
            imag_digitsL(A2i==0)=0;

            % rounding factor
            dec=10.^(N-D1);

            % Number of digits to the right of the decimal place
            imag_digitsR=max(N-D1, 0);
            imag_digitsR(A2i==0)=N;

        end

    else
        warningdlg('Error in sd_round Input Matrix A is not numeric');
        A2=A;
    end
end

% % Convert the rounded array to string format with specified
% % number of significant digits.

[m1, n1]=size(A);

A_str=cell(size(A));

real_digitsL(isinf(real_digitsL))=15;
real_digitsR(isinf(real_digitsR))=15;

imag_digitsL(isinf(imag_digitsL))=15;
imag_digitsR(isinf(imag_digitsR))=15;

rtd=round(real_digitsL+real_digitsR);
itd=round(imag_digitsL+imag_digitsR);


% Output the cell array of strings if it is in the output argument list
if nargout > 1 && isequal(flag1, 0)

    % This code formats the rounded numbers into a cell array
    % of strings.
    if isreal(A)

        for e1=1:m1
            for e2=1:n1;

                aa2=num2str(A2(e1, e2), ['%', int2str(rtd(e1, e2)), '.', int2str(real_digitsR(e1, e2)), 'f' ]);
                if length(aa2) < N && ~isequal( SI_prefixes, 1)
                    aa2=num2str(A2(e1, e2),['%', int2str(N), '.', int2str(N), 'f']);
                end

                if isequal( SI_prefixes, 1)
                    A_str{e1, e2}=[aa2 letters{regime(e1, e2)+9}];
                else
                    A_str{e1, e2}=aa2;
                end

            end
        end

        A2=A2.*10.^(3.*regime);

    else


        for e1=1:m1
            for e2=1:n1;

                aa1=num2str(A2r(e1, e2), ['%', int2str(rtd(e1, e2)),'.', int2str(real_digitsR(e1, e2)), 'f' ]);
                if length(aa1) < N && ~isequal( SI_prefixes, 1)
                    aa1=num2str(A2r(e1, e2),['%', int2str(N), '.', int2str(N), 'f']);
                end

                aa2=num2str(abs(A2i(e1, e2)), ['%', int2str(itd(e1, e2)),'.', int2str(imag_digitsR(e1, e2)), 'f' ]);
                if length(aa2) < N && ~isequal( SI_prefixes, 1)
                    aa2=num2str(abs(A2i(e1, e2)),['%', int2str(N), '.', int2str(N), 'f']);
                end

                if imag(A2i(e1, e2)) >= 0
                    aa=' + ';
                else
                    aa=' - ';
                end

                if isequal( SI_prefixes, 1)
                    A_str{e1, e2}= [aa1, letters{regimeR(e1, e2)+9} aa, aa2, letters{regimeI(e1, e2)+9} 'i'];
                else
                    A_str{e1, e2}= [aa1, aa, aa2, 'i'];
                end

            end
        end



        % Add the real and imaginary parts together
        A2=A2r.*10.^(3.*regimeR)+i*A2i.*10.^(3.*regimeI);

    end

else
    A_str={};
end


