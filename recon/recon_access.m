function [dataflow, prmflow, status] = recon_access(status, echo_onoff, dataflow, prmflow)
% recon & cali governing function
% [dataflow, prmflow, status] = recon_access(status)

% Copyright Dier Zhang
% 
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
% 
%     http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

if nargin<2
    echo_onoff = false;
end
if nargin<3
    % initial
    dataflow = struct();
    prmflow = struct();
end
status.echo_onoff = echo_onoff;

% go
if echo_onoff, fprintf('Recon Series %d\n', status.seriesindex); end

% initial steps (and initial GPU)
if echo_onoff, fprintf('  initial (GPU)...'); end
tic;
[dataflow, prmflow, status] = nodesentry(dataflow, prmflow, status, 'initial');
timecost = toc;
if statuscheck(status, timecost, echo_onoff)
    return;
end

% load calibration tables
if echo_onoff, fprintf('  load calibration tables...'); end
tic;
[dataflow, prmflow, status] = nodesentry(dataflow, prmflow, status, 'loadcorrs');
timecost = toc;
if statuscheck(status, timecost, echo_onoff)
    return;
end

% load rawdata
if echo_onoff, fprintf('  read rawdata...'); end
tic;
[dataflow, prmflow, status] = nodesentry(dataflow, prmflow, status, 'loadrawdata');
timecost = toc;
if statuscheck(status, timecost, echo_onoff)
    return;
end
% for large data we should employ view buffer in loading data, TBC

% run pipe nodes
pipefields = fieldnames(prmflow.pipe);
for i_node = 1:length(pipefields)
    node = pipefields{i_node};
    if echo_onoff, fprintf('  [recon node] %s...', node); end
    tic;
    [dataflow, prmflow, status] = nodesentry(dataflow, prmflow, status, node);
    timecost = toc;
    if statuscheck(status, timecost, echo_onoff)
        return;
    end
end
if echo_onoff, fprintf('Done\n'); end

end


function failedflag = statuscheck(status, timecost, echo_onoff)

% failedflag = false;
if ~status.jobdone
    if echo_onoff, fprintf(' (%.2fsec)  failed\n', timecost); end
    failedflag = true;
elseif status.errorcode==0
    if echo_onoff, fprintf(' (%.2fsec)  done\n', timecost); end
    failedflag = false;
else
    if echo_onoff, fprintf(' (%.2fsec)  error: %d\n', timecost, status.errorcode); end
    failedflag = false;
end

if status.errorcode~=0
    if ischar(status.errormsg)
        warning(status.errormsg);
    elseif isa(status.errormsg, 'MException')
        warning(status.errormsg.getReport);
    else
        % error in throwing error?? what are you thinking?
        warning('Error in throwing error message!');
    end
end

end