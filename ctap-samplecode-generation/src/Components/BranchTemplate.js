export const inputCorrection = (value) => {
    let result = [];
    let v = value.replace(/[^A-Za-z0-9\,]/g,'');
    v = v.split(',');
    v.forEach(i=>{
        let field ;
        !isNaN(i.trim())|| i.trim().toLowerCase() === "true" || i.trim().toLowerCase() === "false"  ? field =`${i.trim().toLowerCase()}`: field = `'${i.trim()}'`;
        result.push(field);
    });
    return result.join(', ');
}

const BranchTemplate = (basicInfo, inputFields) => {

    let HYDRA_presetting = new Array([]);
    let pipeArr = '';
    let branchSrcInfo = {};
    let pipeSegments = new Array([]);

    if (basicInfo.checkedHYDRA) {
        HYDRA_presetting.push(`HYDRA = true;`);
        HYDRA_presetting.push(`PARAM = param_sweep_setup(project_dir);`);
        HYDRA_presetting.push(`Cfg.HYDRA.ifapply = HYDRA;`);
        HYDRA_presetting.push(`Cfg.HYDRA.chanloc = '${basicInfo.eegChanloc}';`);
        HYDRA_presetting.push(`Cfg.HYDRA.PARAM = PARAM;`);
        HYDRA_presetting.push(`Cfg.HYDRA.FULL_CLEAN_SEED = false;`);
        if (basicInfo.checkHydraTimeRange && !basicInfo.checkHydraCleanSeed) {
            HYDRA_presetting.push(`Cfg.HYDRA.provide_seed_timerange = true;`);
            HYDRA_presetting.push(`Cfg.HYDRA.cleanseed_timerange = ${basicInfo.checkHydraTimeRange};`);
        } else if (basicInfo.checkHydraCleanSeed && !basicInfo.checkHydraTimeRange) {
            HYDRA_presetting.push(`Cfg.HYDRA.provide_seed_timerange = false;`);
            HYDRA_presetting.push(`Cfg.HYDRA.seed_fname = ${basicInfo.checkHydraCleanSeed};`);
        }
    }

    let data_dir = '';
    if (basicInfo.checkOwnDataPath) {
        data_dir = `data_dir = '${basicInfo.inputdatapath}';`;
    } else {
        data_dir = `data_dir = append(reporoot,'ctap/data/test_data');`;
    }

    inputFields.map((inputField, index) => {
        let stepSetsArray = new Array([]);
        let ctap_args = new Array([]);
        let funcs = ``;
        let subpipe = "@sbf_" + inputField.pipeSegmentID + ", ";
        pipeArr = pipeArr + subpipe;

        let srcid;
        if (index === 0) {
            branchSrcInfo[inputField.pipeSegmentID] = {
                '0': "".concat(1, inputField.stepID),
                '1': ""
            };
            console.log(branchSrcInfo)
            srcid = "";
        } else {
            console.log('2')
            console.log(branchSrcInfo)
            branchSrcInfo[inputField.pipeSegmentID] = {
                '0': "".concat(1, inputField.stepID),
                '1': "".concat(branchSrcInfo[inputField.pipeSegment_srcid]['1'], inputField.pipeSegment_srcid, '#')
            };
            srcid = "".concat(branchSrcInfo[inputField.pipeSegmentID]['1'], branchSrcInfo[inputField.pipeSegment_srcid]['0']);
        };

        inputField.linearSettings.map((linearSetting, indexl) => {
            let funcs = ``;
            linearSetting.funcsSettings.forEach(funcsSetting => {
                funcs = funcs + `@${funcsSetting.funcName}, `;
                let funcN = funcsSetting.funcName;
                if (funcN) {
                    funcN = funcN.slice(5, funcN.length)
                }

                ctap_args.push(`   out.${funcN}=struct(${inputCorrection(funcsSetting.funcP)});`)
            });
            stepSetsArray.push(`   stepSet(${indexl + 1}).id = [num2str(${index + 1}), '${linearSetting.stepID}'];`);
            stepSetsArray.push(`   stepSet(${indexl + 1}).funH{${funcs}};`);
        });

        //pipeSegments
        let pipeSegment = new Array(
            `function [Cfg, out] = pipeSegment_${inputField.pipeSegmentID}(Cfg)`,
            `   %%%%%%%% Define hierarchy %%%%%%%%`,
            `   Cfg.id = '${inputField.pipeSegmentID}';`,
            `   Cfg.srcid = {${srcid}};`,
            `   %%%%%%%% Define pipeline %%%%%%%%`,
            `   i = 1; %stepSet 1`,
            `${stepSetsArray.join('\n')}`,
            `${[ctap_args.join('\n')]}`,
            `   Cfg.pipe.runSets = {stepSet(:).id};`,
            `   Cfg.pipe.stepSets = stepSet;`,
            `end`,
            ``
        )
        pipeSegments.push(`${pipeSegment.join('\n')}`);
    })

    pipeArr = `pipeArr = {${pipeArr}};`

    let results = new Array(
        `%% Runtime options for CTAP:`,
        `PREPRO = true;`,
        `STOP_ON_ERROR = true;`,
        `OVERWRITE_OLD_RESULTS = true;`
        ``,
        `%% Basic setting`,
        `pipeline_name = '${basicInfo.pipelineName}';`,
        `FILE_ROOT = mfilename('fullpath');`,
        `reporoot = FILE_ROOT(1:strfind(FILE_ROOT, fullfile('ctap', 'templates', '${basicInfo.projectRoot}', 'ctap_linear_template')) - 1);`,
        `project_dir = FILE_ROOT(1:strfind(FILE_ROOT, fullfile('ctap_linear_template')) - 1);`,
        `${data_dir}`,
        `[Cfg, ~] = sbf_cfg(project_dir, pipeline_name);`,
        `Cfg.grfx.on = false;`,
        `Cfg.MC = get_meas_cfg_MC(Cfg, data_dir, 'eeg_ext', '*${basicInfo.eegType}', 'sbj_filt', ${basicInfo.sbj_filt});`,
        `${HYDRA_presetting.join('\n')}`,
        ``,
        `%% run pipe`,
        `clear Pipe;`,
        `${pipeArr}`,
        `runps = 1:length(pipeArr);`,
        `if PREPRO`,
        `   CTAP_pipeline_brancher(Cfg, pipeArr, 'runPipes', runps, 'dbg', STOP_ON_ERROR, 'ovw', OVERWRITE_OLD_RESULTS);`,
        `end`,
        ` `,
        `%% PipeSegments`,
        `function [Cfg, out] = sbf_cfg(project_root_folder, ID)`,
        `   Cfg.id = ID;`,
        `   Cfg.srcid = {''};`,
        `   Cfg.env.paths.projectRoot = project_root_folder;`,
        `   % Define important directories and files`,
        `   Cfg.env.paths.branchSource = '';`,
        `   Cfg.env.paths.ctapRoot = fullfile(Cfg.env.paths.projectRoot, Cfg.id);`,
        `   Cfg.env.paths.analysisRoot = Cfg.env.paths.ctapRoot;`,
        `   Cfg.eeg.chanlocs = '${basicInfo.eegChanloc}';`,
        `   Cfg.eeg.reference = {${inputCorrection(basicInfo.eegReference)}};`,
        `   Cfg.eeg.veogChannelNames = {${inputCorrection(basicInfo.eegVeogChannelNames)}};`,
        `   Cfg.eeg.heogChannelNames = {${inputCorrection(basicInfo.eegHeogChannelNames)}};`,
        `   out = struct([]);`,
        `end`,
        ``,
        `${pipeSegments.join('\n')}`,
    );
    return results;

};

export default BranchTemplate;
