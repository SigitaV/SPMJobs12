% (inputDir, outputDir, parameters, together);
% build first level model and estimate with classic ReML
% output files:
%   for each subject, generates beta weights = (conditions + 1 constant)*runs.  
%       The beta weights are averaged amplitudes (across time) for each condition at each voxel.
%   model specification generates SPM.mat 
%       which is then overwritten by estimation, finally SPM.mat has both specification and estimated parameters
%   ResMS, variance of error
%   mask, voxels included in the analysis
%   RPV, estimated resels per voxel
%
%   SPM.mat can be used by Reviewed, Result
% 
% inputDir
    % swmt_s0215_r01.nii
    % swmt_s0215_r02.nii
    % swmt_s0215_r03.nii
    % 
    % swmt_s0216_r01.nii
    % swmt_s0216_r02.nii
    % swmt_s0216_r03.nii
    % swmt_s0216_r04.nii
% outputDir
    % generate_multiconds.m --> to generate the following mat files for each subject_run
    % s0215_r01_multiconds.mat
    % s0215_r02_multiconds.mat
    % s0215_r03_multiconds.mat
    % these files could be generated by python script
    % there should be a separate file for each run for each subject
    %     if not, say s0215_r01_multiconds.mat is missing, swmt_s0215_r01.nii processing will be skipped/ignored
    % The order of conditions/names should be the same across subjects and does not need to follow the presentation order
    %     e.g., subject 1 has conditions C A T, subject 2 should have the same conditions; the actual presentation might be random
    % If you enter a single number for the durations it will be assumed that all trials conform to this duration. 
    % If you have multiple different durations, then the number must match the number of onset times.    
    % e.g., 
        % clear
        % names{1}='jol2';
        % onsets{1}=[27.0, 195.0, 153.0, 234.0, 111.0, 66.0, 48.0, 246.0, 231.0, 201.0];
        % durations{1}=[0];
        % names{2}='jol3';
        % onsets{2}=[30.0, 81.0, 213.0, 165.0, 36.0, 189.0, 204.0, 78.0, 255.0, 228.0, 249.0, 90.0, 6.0, 216.0, 54.0, 75.0, 162.0, 168.0, 63.0, 180.0];
        % durations{2}=[0];
        % names{3}='arrow';
        % onsets{3}=[120, 270];
        % durations{3}=[30, 30];
        % save s0215_r01_multiconds.mat
        % clear
    % ...
    % 
    % autocreate folders
    % s0215_SPM -> SPM.mat, betas
    % s0216_SPM -> SPM.mat, betas
    % ...
% parameters = {tr(seconds), nslices, refslice};
%       e.g.,  {2.5, 26, 25}  nslices for microtime resolution, refslice for microtime onset
% if output nii files exist with same name, overwrite without any prompt
%
% optional input: together = 0/1 (default 1) if 0 only generates job_.mat files, 1 run the jobs and clean up afterwards
% 
% note: 
%   uses SPM functions; SPM must be added to your matlab path: File -> Set Path... -> add with subfolders. 
%   tested under SPM 12-6225 (with mac lion 10.7.5 and matlab 2012b)
%   if you use this job_function for the first time, consider running only one subject and check the results before processing all 
%
% author = jerryzhujian9@gmail.com
% date: December 10 2014, 11:13:30 AM CST
% inspired by http://www.aimfeld.ch/neurotools/neurotools.html
% https://www.youtube.com/playlist?list=PLcNEqVlhR3BtA_tBf8dJHG2eEcqitNJtw

%------------- BEGIN CODE --------------
function [output1,output2] = main(inputDir, outputDir, parameters, together, email)
% email is optional, if not provided, no email sent
% (re)start spm
spm('fmri');
if ~exist('together','var'), together = 1; end
[tr, nslices, refslice] = parameters{:};

startTime = ez.moment();
onsetFiles = ez.ls(outputDir,'s\d\d\d\d_r\d\d_multiconds\.mat$'); % runFiles across all subjects
[dummy onsetFileNames] = cellfun(@(e) ez.splitpath(e),onsetFiles,'UniformOutput',false);
onsetFileNames = cellfun(@(e) regexp(e,'_', 'split'),onsetFileNames,'UniformOutput',false);
subjects = cellfun(@(e) e{end-2},onsetFileNames,'UniformOutput',false);  
subjects = ez.unique(subjects); % returns {'s0215';'s0216'}

for n = 1:ez.len(subjects)
    subject = subjects{n};
    ez.print(['Processing ' subject ' ...']);

    load('mod_first.mat');
    % fill out output dir
    SPMFolder = ez.joinpath(outputDir,[subject '_SPM']);
    ez.mkdir(SPMFolder);
    matlabbatch{1}.spm.stats.fmri_spec.dir = {SPMFolder};
    % fill out timing info
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT = tr;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = nslices;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = refslice;
    % fill out sessions/scans/runs for one subject
    onsetFiles = ez.ls(outputDir,[subject '_r\d\d_multiconds\.mat$']); % onsetFiles for one subject
    % runFiles matching onsetFiles for one subject
    [dummy onsetFileNames] = cellfun(@(e) ez.splitpath(e),onsetFiles,'UniformOutput',false);
    onsetFileNames = cellfun(@(e) regexp(e,'_', 'split'),onsetFileNames,'UniformOutput',false);
    runs = cellfun(@(e) e{end-1},onsetFileNames,'UniformOutput',false);
    runsString = sprintf('%s|', runs{:}); runsString = ['(', runsString(1:end-1) ')'];  % construct a regular expression |
    runFiles = ez.ls(inputDir, [subject, '_', runsString, '.nii$']); 
    sess = matlabbatch{1}.spm.stats.fmri_spec.sess; % sess structure
    matlabbatch{1}.spm.stats.fmri_spec.sess = repmat([sess], 1, ez.len(runFiles)); % create certain number of sessions
    % now onsetFiles, runFiles, runs have same matched length
    runs = cellfun(@(e) e(2:end),runs,'UniformOutput',false);  % tranform 'r02' --> '02'
    for m = 1:ez.len(runFiles)
        runFile = runFiles{m};
        [dummy runFileName] = ez.splitpath(runFile);
        runVolumes = cellstr(spm_select('ExtList',inputDir,[runFileName '\.nii$'],[1:1000]));
        runVolumes = cellfun(@(e) ez.joinpath(inputDir,e),runVolumes,'UniformOutput',false);
        matlabbatch{1}.spm.stats.fmri_spec.sess(1,m).scans = runVolumes;
        % match s0215_r02_multicond.mat
        runNr = sprintf('%02d', ez.num(runs{m}));
        matlabbatch{1}.spm.stats.fmri_dcspec.sess(1,m).multi = ez.ls(outputDir,[subject '_r' runNr '_multiconds.mat$']);
    end
    cd(outputDir);
    save(['job_first_' subject '.mat'], 'matlabbatch');

    if together
        spm_jobman('run',matlabbatch);
        fig = spm_figure('FindWin','Graphics');
        ez.export(ez.joinpath(outputDir,[subject '_design.pdf']),fig);
    end

    clear matlabbatch;

    ez.pprint('****************************************'); % pretty colorful print
end
ez.pprint('Done!');
finishTime = ez.moment();
if exist('email','var'), try, batmail(mfilename, startTime, finishTime); end; end;
end % of main function
%------------- END OF CODE --------------