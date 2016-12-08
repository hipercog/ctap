function result = classifskew(x,group,predictset,varargin)

%Classifskew applies classification rules for low dimensional skewed data with known group structure. It
% is based on the adjusted outlyingness (see adjustedoutlyingness.m). 
%
% The methods are fully described in:
%   Hubert, M. and Van der Veeken, S. (2010),
%   "Fast and Robust Classifiers Adjusted for Skewness", 
%   Proceedings in Computational Statistics, 2010, 
%   edited by Y. Lechevallier and G. Saporta, Springer-Verlag, Heidelberg, 1135-1142.
%   
%   and
%
%   Hubert, M. and Van der Veeken, S. (2010),
%   "Robust Classification for Skewed Data", 
%   Advances in Data Analysis and Classification, 4, 239-254. 
%
%
% Required input arguments:
%           x : Training data set (matrix of size n by p)
%       group : Column vector containing the group numbers of the training
%               set x. 
%  predictset : Contains a new data set (a matrix of size n1 by p) from which the 
%               class memberships are unknown and should be predicted. 
%
% Optional input arguments:
%      method : Classification rules
%               Possible values are 1 : based on the minimal Adjusted
%                                       Outlyingness. (default)                                      
%                                   2 : based on the Rank of the Adjusted
%                                       Outlyingness.
%                                   3 : based on the Signed Adjusted Outlyingness of Adjusted
%                                       Outlyingness.
%               (see "Fast and Robust Classifiers Adjusted for Skewness" for details)
%     classic : If equal to one, the classification is also done with the
%               Stahel-Donoho outlyingness instead of the Adjusted
%               Outlyingness. (default=0)
%      
% I/O:
%   result=classifskew(x,group,predictset,varargin)
%
% The output of CLASSIFSKEW is a structure containing:
%                result.method : Number indicating the classification method. 
%                                This is the same as the input argument method. 
%          result.grouppredict : Vector that indicates to which group the observations of predictset are assigned.
%    result.adjustedoutlgroups : Structure containing a vector for each group. The vector gives the adjusted 
%                                outlyingness of all the group members relative to their own group. 
%   result.adjustedoutlpredict : Structure containing a vector for each group. The vector gives the
%                                adjusted outlyingness of the observations in the predictset relative to the 
%                                different groups. 
%             result.flagtrain : Structure containing a vector for each group. Observations from a group that have
%                                an adjusted outlyingness (relative to their group) that exceeds a certain cutoff value
%                                can be considered as outliers and receive a flag equal to 0. The regular observations
%                                receive a flag 1. 
%           result.flagpredict : Structure containing a vector for each group. Observations from predictset that have
%                                an adjusted outlyingness (relative to a group) that exceeds a certain cutoff value can
%                                be considered as outliers for that specific group and receive a flag equal to 0. The
%                                regular observations  receive a flag 1. 
%               result.classic : If the input argument 'classic' is equal to one, this structure contains the results
%                                obtained by using the Stahel-Donoho outlyingness instead of the adjusted outlyingness.  
%
% This function is part of LIBRA: the Matlab Library for Robust Analysis,
% available at:
%              http://wis.kuleuven.be/stat/robust.html
%
% Written by Stephan Van der Veeken, Mia Hubert
% Created on 10/03/2010
% Last Revision: 18/06/2010

if (nargin<3)
    error('LIBRA:classifskew: At least 3 input arguments required (the training data, the group vector and the data that need to be classified.')
end

[n,p]=size(x);
[n1,p1]=size(predictset);
if p~=p1
    error('LIBRA:classifskew: The dimension of predictset should be the same as the dimension of x.')
end
if size(group,1)~=1
    group=group';
end
if n ~= length(group)
    error('LIBRA:classifskew: The number of observations is not the same as the length of the group vector!')
end
g=group;
countsorig=tabulate(g); 
[lev,levi,levj]=unique(g);
levorig=lev;
%Redefining the group number
if any(lev~= (1:length(lev)))
    lev=1:length(lev);
    g=lev(levj);
    counts=tabulate(g);
else
    counts=countsorig;
end

if ~all(counts(:,2)) %some groups have zero values, omit those groups
    disp(['Warning: group(s) ', num2str(counts(counts(:,2)==0,1)'), 'are empty']);
    empty=counts(counts(:,2)==0,:);
    counts=counts(counts(:,2)~=0,:);
else
    empty=[];
end

if any(counts(:,2)<5) %some groups have less than 5 observations
    error(['Group(s) ', num2str(counts(counts(:,2)<5,1)'), ' have less than 5 observations.']);
end

ng=size(counts,1);
counter=1;
default=struct('method',1,'classic',0);
list=fieldnames(default);
result=default;
IN=length(list);
i=1;
%reading the user's input
if nargin>3
    %
    %placing inputfields in array of strings
    %
    for j=1:nargin-3
        if rem(j,2)~=0
            chklist{i}=varargin{j};
            i=i+1;
        end
    end
    %
    %Checking which default parameters have to be changed
    % and keep them in the structure 'result'.
    %
    while counter<=IN
        index=strmatch(list(counter,:),chklist,'exact');
        if ~isempty(index) %in case of similarity
            for j=1:nargin-3 %searching the index of the accompanying field
                if rem(j,2)~=0 %fieldnames are placed on odd index
                    if strcmp(chklist{index},varargin{j})
                        I=j;
                    end
                end
            end
            result=setfield(result,chklist{index},varargin{I+1});
            index=[];
        end
        counter=counter+1;
    end
end

classic=result.classic;
method=result.method;

%-----------Main Part-------------------
group=struct;
pred=struct;
A=zeros(n1,ng);
for iClass = 1:ng
    indexgroup = find(g == iClass);
    groupi = x(indexgroup,:);
    aogroup=adjustedoutlyingness(groupi,'predictset',predictset,'classic',classic); 
    aototal=aogroup.adjout;
    indexoutl=find(aogroup.flagtrain==0);
    outlgroupi=groupi(indexoutl,:);
    l1=size(outlgroupi,1);
    indexnonoutl=find(aogroup.flagtrain==1);
    nonoutlgroupi=groupi(indexnonoutl,:);
    aoreduced=adjustedoutlyingness(nonoutlgroupi,'predictset',[predictset;outlgroupi]);
    if ~isempty(outlgroupi)
        aooutl=aoreduced.adjoutpredict((n1+1):(n1+l1));  
        aototal(indexoutl)=aooutl;
    end
    group.result{iClass}=aototal;
    pred.result{iClass}=aoreduced.adjoutpredict(1:n1); 
    A(:,iClass)=pred.result{iClass};
    flagtrain.result{iClass}=aogroup.flagtrain;
    flagpredict.result{iClass}=aoreduced.flagpredict(1:n1);
    if classic==1
        groupcl.result{iClass}=aogroup.classic.outl;
        predcl.result{iClass}=aogroup.classic.outlpredict;
        flagtraincl.result{iClass}=aogroup.classic.flagtrain;
        flagpredictcl.result{iClass}=aogroup.classic.flagpredict;
    end
end

[C,I]=min(A,[],2);
assignedgr1=I;

if (method==1)
    assignedgr=assignedgr1;
end

if (method==2)
    rank=zeros(n1,ng);
    for l=1:n1
        for i=1:ng
            rank(l,i)=sum(A(l,i)>=group.result{i})/counts(i,2);
        end
        minrank=min(rank(l,:));
        [z,I]=find(rank(l,:)==minrank);
        if length(I)==1
            assignedgr(l)=I;
        else
            assignedgr(l)=assignedgr1(l);
        end
    end
    assignedgr=assignedgr';
end

if (method==3)
    C=zeros(n1,ng);
    for i=1:ng
        s=adjustedoutlyingness(group.result{i},'predictset',A(:,i));
        C(:,i)=s.adjoutpredict.*sign(A(:,i)-median(group.result{i}));
    end
    [z,I]=min(C,[],2);
    assignedgr=I;
end

for i=1:length(assignedgr)
    assignedgr(i)=levorig(assignedgr(i));
end

% In case that the option classic is chosen, the 3 methods are performed
% with the Stahel-Donoho outlyingness instead of the Adjusted outlyingness.
if classic==1
    A=zeros(n1,ng);
    for i=1:ng
        A(:,i)=predcl.result{i};
    end
    [C,I]=min(A,[],2);
    assignedgr1cl=I;
    if (method==1)
        assignedgrcl=assignedgr1cl;
    end

    if (method==2)
        rankcl=zeros(n1,ng);
        for l=1:n1
            for i=1:ng
                rankcl(l,i)=sum(A(l,i)>=groupcl.result{i})/counts(i,2);
            end
            minrankcl=min(rank(l,:));
            [z,I]=find(rankcl(l,:)==minrankcl);
            if length(I)==1
                assignedgrcl(l)=I;
            else
                assignedgrcl(l)=assignedgr1cl(l);
            end
        end
        assignedgrcl=assignedgrcl';
    end

    if (method==3)
        C=zeros(n1,ng);
        for i=1:ng
            s=adjustedoutlyingness(group.result{i},'predictset',A(:,i),'classic',1);
            C(:,i)=s.classic.outlpredict.*sign(A(:,i)-median(groupcl.result{i}));
        end
        [z,I]=min(C,[],2);
        assignedgrcl=I;
    end
    for i=1:length(assignedgrcl)
        assignedgrcl(i)=levorig(assignedgrcl(i));
    end
    classic=struct('group',{assignedgrcl},'adjustedoutlgroups',{groupcl.result},'adjustedoutlpredict',{predcl.result},'flagtrain',...
        {flagtraincl.result},'flagpredict',{flagpredictcl.result});

end

result=struct('method',{method},'group',{assignedgr},'adjustedoutlgroups',{group.result},'adjustedoutlpredict',...
    {pred.result},'flagtrain',{flagtrain.result},'flagpredict',{flagpredict.result},'classic',{classic});










