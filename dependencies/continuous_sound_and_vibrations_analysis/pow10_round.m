function [A2, A_str, real_digitsL, real_digitsR, imag_digitsL, imag_digitsR]=pow10_round(A, pow10, flag2, mult, SI_prefixes)
% % pow10_round: Round a numeric array to a Specified Digits Place
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
% % pow10_round.m stands for "Power of 10 Round".
% %
% % This program rounds a 2-d matrix of numbers to a a specified digits
% % place.  By specifing the power of 10 so that the furthest digits
% % place of the right is specified.
% %
% % This program support five different styles of rounding the last digit:
% % to the nearest integer, up, down, toward zero, and away from zero.
% %
% % This program supports real and complex numbers.
% %
% % The program outputs the rounded array, a cell string of the
% % rounded matrix the number of digits, to the left and right of the
% % decimal place, and converts the rounded array to a cell array of
% % strings.
% %
% % This program is useful for presenting scientific data that
% % requires rounding to a specified digits place for publication.
% %
% % *********************************************************************
% %
% % Input variables
% %
% % A is the input matrix of number to be rounded.
% %      default is empty array A=[];.
% %
% % pow10 is the power of ten to round the numbers.
% %      pow10 specifies the digits place for rounding,
% %      starting from the decimal point and counting to the left.
% %      default is pow10=0;
% %
% %      pow10=-2 round the hundreths digit.
% %      pow10=-1 round the tenths digit.
% %      pow10=0  round the ones digit.
% %      pow10=1  round the tens digit.
% %
% % flag2 specifiies the style of rounding.
% %      This program supports four different styles of rounding.
% %
% %      flag2 == 1 rounds to the nearest integer
% %      flag2 == 2 rounds up
% %      flag2 == 3 rounds down
% %      flag2 == 4 rounds toward zero
% %      flag2 == 5 rounds away from zero
% %
% %      otherwise round to the nearest integer
% %      default is round to the nearest integer
% %
% % mult is a whole number.  The program rounds the last digit to mult.
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
% % A2 is the rounded numeric array.
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
% Example1='';
%
% D1=pi;        % Double or Complex two dimensional array of numbers
% pow10=-2;     % Round to the hundreths place
%
%               % P1 should be 3.14 which has 3 significant digits.
%
% [P1, P1_str]=pow10_round(D1, pow10);
%
%
% Example2='';
%
% pow10=-3;                     % round to the thousandths digit
% D2=10.^randn(10, 100);        % D2 is the unrounded array
%
%                               % P2 is the rounded array
%                               % of real numbers
%                               % P2_str is the cell array of strings of
%                               % rounded real numbers
%
%  [P2, P2_str]=pow10_round(D2, pow10);
%
%
% Example3='';
%
% D3=log10(randn(10, 100));     % D3 is an unrounded array of complex
%                               % numbers
% [P3, P3_str]=pow10_round(D3, -3);
%
%                               % P3 is the rounded array of
%                               % complex numbers
%                               % P3_str is the cell array of strings of
%                               % rounded complex numbers
%
%
% Example4='';
%
% D4=pi*10^(-5);    % Double or Complex two dimensional array of numbers
% pow10=-7;         % Round to the hundreths place
%
%                   % P1 should be 0.0000314 which has 3 significant digits.
%
% [P1, P1_str]=pow10_round(D4, pow10);
%
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %
% % Program Written by Edward L. Zechmann
% %
% %     date 18 August   2008   Added option to round last digit to a
% %                             multiple of a given number.
% %                             Fixed a bug in rounding powers of 10.
% %
% % modified 25 August   2008   Updated Comments
% %
% % modified 16 August   2010   Changed K to k for SI prefixes.
% %
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

if (nargin < 2 || isempty(pow10)) || ~isnumeric(pow10)
    pow10=0;
end

% power of 10 for rounding
% must be a integer
% pow10 specifies the digits place for rounding
pow10=round(pow10);

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

            % Number of digits to the left of the decimal place
            real_digitsL=max(D1, 0);
            real_digitsL(A==0)=0;

            % rounding factor
            dec=10.^(-pow10);

            % Number of digits to the right of the decimal place
            real_digitsR=max(-pow10, 0).*ones(size(A));

            % Rounding Computation
            % This program supports four different styles of rounding.
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

                real_digitsR(regime < 0)=max(real_digitsR(regime < 0)+3.*regime(regime < 0), 0);
                real_digitsR(regime > 0)=max(3.*regime(regime > 0)-pow10, 0);

            else
                regime=zeros(size(A));
            end

            A2=A2.*10.^(-3.*regime);



        else

            % Round the real part
            Ar=real(A);
            
            B=isinf(Ar);
            Ar(B)=sign(Ar(B)).*10^15;
            
            % Digit furthest to the left of the decimal point
            D1=ceil(log10(abs(Ar)));
            buf1=D1( abs(Ar)-10.^D1 == 0)+1;
            D1( abs(Ar)-10.^D1 == 0)=buf1;

            % Number of digits to the left of the decimal place
            real_digitsL=max(D1, 0);
            real_digitsL(Ar==0)=0;

            % rounding factor
            dec=10.^(-pow10);

            % Number of digits to the right of the decimal place
            real_digitsR=max(-pow10, 0).*ones(size(A));

            % Rounding Computation
            % This program supports four different styles of rounding.
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

                real_digitsR(regimeR < 0)=max(real_digitsR(regimeR < 0)+3.*regimeR(regimeR < 0), 0);
                real_digitsR(regimeR > 0)=max(3.*regimeR(regimeR > 0)-pow10, 0);

            else
                regimeR=zeros(size(A));
            end

            A2r=A2r.*10.^(-3.*regimeR);


            % Round the imaginary part
            Ai=imag(A);

            B=isinf(Ai);
            Ai(B)=sign(Ai(B)).*10^15;
            
            
            % Digit furthest to the left of the decimal point
            D1=ceil(log10(abs(Ai)));
            buf1=D1( abs(Ai)-10.^D1 == 0)+1;
            D1( abs(Ai)-10.^D1 == 0)=buf1;

            % Number of digits to the left of the decimal place
            imag_digitsL=max(D1, 0);
            imag_digitsL(Ai==0)=0;

            % rounding factor
            dec=10.^(-pow10);

            % Number of digits to the right of the decimal place
            imag_digitsR=max(-pow10, 0).*ones(size(A));

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

                imag_digitsR(regimeI < 0)=max(imag_digitsR(regimeI < 0)+3.*regimeI(regimeI < 0), 0);
                imag_digitsR(regimeI > 0)=max(3.*regimeI(regimeI > 0)-pow10, 0);

            else
                regimeI=zeros(size(A));
            end

            A2i=A2i.*10.^(-3.*regimeI);



        end

    else
        warningdlg('Error in p_round Input Matrix A is not numeric');
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
                N=min([1, rtd(e1, e2)]);

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

                if A2i(e1, e2) >= 0
                    aa=' + ';
                else
                    aa=' - ';
                end

                aa1=num2str(A2r(e1, e2), ['%', int2str(rtd(e1, e2)),'.', int2str(real_digitsR(e1, e2)), 'f' ]);
                N=min([1, rtd(e1, e2)]);

                if length(aa1) < N && ~isequal( SI_prefixes, 1)
                    aa1=num2str(real(A2(e1, e2)),['%', int2str(N), '.', int2str(N), 'f']);
                end

                aa2=num2str(abs(A2i(e1, e2)), ['%', int2str(itd(e1, e2)),'.', int2str(imag_digitsR(e1, e2)), 'f' ]);
                N=min([1, itd(e1, e2)]);

                if length(aa2) < N && ~isequal( SI_prefixes, 1)
                    aa2=num2str(abs(A2i(e1, e2)),['%', int2str(N), '.', int2str(N), 'f']);
                end
                A_str{e1, e2}= [aa1, aa, aa2, 'i'];


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

