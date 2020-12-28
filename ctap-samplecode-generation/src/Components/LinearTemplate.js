import {inputCorrection} from './BranchTemplate'

const LinearTemplate = (basicInfo, inputFields) => {

    let ctap_args = new Array([]);
    let stepSetsArray = new Array([]);
    let HYDRA_presetting = new Array([]);

    if (basicInfo.checkedHYDRA) {
        HYDRA_presetting.push(`HYDRA = true;`);
        HYDRA_presetting.push(`PARAM = param_sweep_setup(project_dir);`);
        HYDRA_presetting.push(`Cfg.HYDRA.ifapply = HYDRA;`);
        HYDRA_presetting.push(`Cfg.HYDRA.chanloc = '${basicInfo.eegChanloc}';`);
        HYDRA_presetting.push(`Cfg.HYDRA.PARAM = PARAM;`);
        HYDRA_presetting.push(`Cfg.HYDRA.FULL_CLEAN_SEED = false;`);
        if (basicInfo.checkHydraTimeRange && !basicInfo.checkHydraCleanSeed) {
            HYDRA_presetting.push(`Cfg.HYDRA.provide_seed_timerange = true;`)
            HYDRA_presetting.push(`Cfg.HYDRA.cleanseed_timerange = ${basicInfo.checkHydraTimeRange};`);
        } else if (basicInfo.checkHydraCleanSeed && !basicInfo.checkHydraTimeRange) {
            HYDRA_presetting.push(`Cfg.HYDRA.provide_seed_timerange = false;`)
            HYDRA_presetting.push(`Cfg.HYDRA.seed_fname = ${basicInfo.checkHydraCleanSeed};`);
        }
    }

    let data_dir = '';
    if(basicInfo.checkOwnDataPath){
        data_dir = `data_dir = '${basicInfo.inputdatapath}';`
    }else{
        data_dir = `data_dir = append(reporoot,'ctap/data/test_data');`
    }
    
    inputFields.forEach((inputField, index) => {
        let funcs = ``;
        inputField.funcsSettings.forEach(funcsSetting => {
            funcs = funcs + `@${funcsSetting.funcName}, `;
            let funcN = funcsSetting.funcName;
            if(funcN){
                funcN = funcN.slice(5,funcN.length)
            }
            ctap_args.push(`out.${funcN}=struct(${inputCorrection(funcsSetting.funcP)})`)
        });
        stepSetsArray.push(`stepSet(${index + 1}).id = [num2str(${index + 1}), '${inputField.stepID}'];`);
        stepSetsArray.push(`stepSet(${index + 1}).funH{${funcs}};`);
    })


    return new Array(
        `%% Runtime options for CTAP:`,
        `DEBUG = false;`,
        `OVERWRITE = true;`,
        ``,
        `%% Basic setting`,
        `pipeline_name = '${basicInfo.pipelineName}';`,
        "FILE_ROOT = mfilename('fullpath');",
        `reporoot = FILE_ROOT(1:strfind(FILE_ROOT, fullfile('ctap', 'templates', '${basicInfo.projectRoot}', 'ctap_linear_template')) - 1);`,
        `project_dir = FILE_ROOT(1:strfind(FILE_ROOT, fullfile('ctap_linear_template')) - 1);`,
        `${data_dir}`,
        ``,
        `Cfg.env.paths = cfg_create_paths(project_dir, pipeline_name, {''}, 1);`,
        `Cfg.eeg.chanlocs = '${basicInfo.eegChanloc}';`,
        `Cfg.eeg.reference = {${inputCorrection(basicInfo.eegReference)}};`,
        `Cfg.eeg.veogChannelNames = {${inputCorrection(basicInfo.eegVeogChannelNames)}};`,
        `Cfg.eeg.heogChannelNames = {${inputCorrection(basicInfo.eegHeogChannelNames)}};`,
        `Cfg.grfx.on = false;`,
        `Cfg.MC = get_meas_cfg_MC(Cfg, data_dir, 'eeg_ext', '*${basicInfo.eegType}', 'sbj_filt', ${basicInfo.sbj_filt});`,
        `${HYDRA_presetting.join('\n')}`,
        `%% Pipeline setting`,
        `clear Pipe;`,
        `${stepSetsArray.join('\n')}`,
        `${[ctap_args.join('\n')]}`,
        `Cfg.pipe.stepSets = stepSet;`,
        `Cfg.pipe.runSets = {stepSet(1).id};`,
        `Cfg = ctap_auto_config(Cfg, out);`,
        ` `,
        `%% Run the pipe`,
        `CTAP_pipeline_looper(Cfg, 'debug', DEBUG, 'overwrite', OVERWRITE);`,
        `clear i stepSet Filt ctap_args`

    )

};

export default LinearTemplate;
